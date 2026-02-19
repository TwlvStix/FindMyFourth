'use strict';

/**
 * Trust System Structured Logger
 *
 * Wraps firebase-functions logger so every Trust notification emits a
 * consistent JSON payload that Cloud Logging auto-indexes.
 *
 * Every entry contains these 10 fields:
 *   eventId         {string}       — unique event/document ID
 *   eventType       {string}       — TrustEventType value (snake_case)
 *   recipientUserId {string}       — UID of the notification recipient
 *   platform        {string|null}  — 'ios' | 'android' | 'unknown' | null
 *   deviceId        {string|null}  — Firestore device doc ID, or null
 *   status          {string}       — terminal pipeline status (sent, deduped, …)
 *   errorCode       {string|null}  — FCM error code, or null
 *   latencyMs       {number|null}  — FCM round-trip ms, or null
 *   dropReason      {string|null}  — human-readable drop/hold reason, or null
 *   timestamp       {string}       — ISO-8601 UTC at time of log call
 *
 * Public API:
 *   logNotificationEvent(event, status, opts?)
 *     — Pipeline-level drop / hold events with no per-device context.
 *       opts: { dropReason?, latencyMs?, errorCode? }
 *
 *   logFcmSend(event, deviceId, platform, sendResult)
 *     — Per-device FCM send result. sendResult is a SendResult from fcm-sender.
 *       Severity: info on success, warn for non-fatal errors, error for auth_error.
 */

const functions = require('firebase-functions');

const log = functions.logger;

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Builds the base structured payload with all 10 required fields.
 * Absent values are always null (never omitted) so log-based metric filters
 * such as `jsonPayload.errorCode != null` work reliably.
 *
 * @param {object} event
 * @param {string} status
 * @param {object} overrides - field overrides / additions
 * @returns {object}
 */
function buildPayload(event, status, overrides) {
  return Object.assign(
    {
      eventId:         event.eventId        || null,
      eventType:       event.eventType      || null,
      recipientUserId: event.recipientUserId || null,
      platform:        null,
      deviceId:        null,
      status,
      errorCode:       null,
      latencyMs:       null,
      dropReason:      null,
      timestamp:       new Date().toISOString(),
    },
    overrides,
  );
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Logs a pipeline-level event (drop or hold) with no per-device context.
 *
 * Severity is always 'info' — these are expected operational outcomes.
 *
 * @param {{eventId: string, eventType: string, recipientUserId: string}} event
 * @param {string} status  — e.g. 'deduped', 'cap_reached', 'preference_disabled',
 *                           'quiet_held', 'no_devices'
 * @param {{ dropReason?: string, latencyMs?: number, errorCode?: string }} [opts]
 */
function logNotificationEvent(event, status, opts) {
  const o = opts || {};
  const payload = buildPayload(event, status, {
    dropReason: o.dropReason || null,
    latencyMs:  typeof o.latencyMs === 'number' ? o.latencyMs : null,
    errorCode:  o.errorCode || null,
  });
  log.info('trust.notification', payload);
}

/**
 * Logs a per-device FCM send result.
 *
 * Severity:
 *   success              → info
 *   token_invalid        → info  (expected churn; router deletes the token)
 *   rate_limit / server_error retries exhausted → warn
 *   invalid_arg / unknown → warn
 *   auth_error           → error (requires immediate attention)
 *
 * @param {{eventId: string, eventType: string, recipientUserId: string}} event
 * @param {string} deviceId
 * @param {string} platform  — 'ios' | 'android' | 'unknown'
 * @param {{
 *   success: boolean,
 *   latencyMs: number,
 *   errorCode?: string,
 *   tokenInvalid?: boolean
 * }} sendResult
 */
function logFcmSend(event, deviceId, platform, sendResult) {
  const status    = sendResult.success ? 'sent' : 'fcm_error';
  const errorCode = sendResult.errorCode || null;

  const payload = buildPayload(event, status, {
    platform,
    deviceId,
    errorCode,
    latencyMs: sendResult.latencyMs,
  });

  if (!sendResult.success) {
    // auth_error is a misconfiguration / credential failure — page-worthy.
    const isAuthError = errorCode && errorCode.includes('authentication-error');
    if (isAuthError) {
      log.error('trust.fcm_send', payload);
    } else {
      log.warn('trust.fcm_send', payload);
    }
  } else {
    log.info('trust.fcm_send', payload);
  }
}

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  logNotificationEvent,
  logFcmSend,
};
