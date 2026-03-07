'use strict';

/**
 * Trust System FCM Sender
 *
 * Wraps admin.messaging().send() with Trust System payload construction,
 * error classification, and exponential-backoff retry logic.
 *
 * Usage:
 *   const { send } = require('./fcm-sender');
 *   const result = await send(fcmToken, deviceId, payload);
 *
 * @param {string} fcmToken          - Device FCM registration token
 * @param {string} deviceId          - Opaque device identifier (returned in result)
 * @param {object} payload           - TrustNotificationPayload (see below)
 * @param {number} [baseDelayMs=1000]- Base retry delay in ms; pass 0 in tests
 * @returns {Promise<SendResult>}
 *
 * TrustNotificationPayload shape:
 *   title            {string}
 *   body             {string}
 *   deepLink         {string}
 *   eventType        {string}  - TrustEventType value (snake_case)
 *   eventId          {string}  - unique event/document ID
 *   priority         {string}  - NotificationPriority value
 *   threadId         {string}  - iOS notification group identifier
 *   androidChannelId {string}  - Android notification channel ID
 *   gameId           {string}  - (optional) game ID for routing compatibility
 *
 * SendResult shape:
 *   success       {boolean}
 *   deviceId      {string}
 *   errorCode     {string|undefined}   - present on failure
 *   tokenInvalid  {boolean|undefined}  - true only for unregistered/invalid token errors
 *   latencyMs     {number}
 */

const admin = require('firebase-admin');
const { PRIORITY_FCM_CONFIG } = require('./event-registry');

// ── Internal helpers ──────────────────────────────────────────────────────────

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Classifies a Firebase Messaging error code.
 *
 * Returns one of:
 *   'token_invalid' — token is dead; no retry
 *   'rate_limit'    — throttled; retry up to 3 total attempts
 *   'server_error'  — transient fault; retry up to 5 total attempts
 *   'invalid_arg'   — bad payload; no retry
 *   'auth_error'    — credentials failure; no retry
 *   'unknown'       — anything else; no retry
 */
function classifyError(code) {
  switch (code) {
    case 'messaging/registration-token-not-registered':
    case 'messaging/invalid-registration-token':
      return 'token_invalid';

    case 'messaging/message-rate-exceeded':
    case 'messaging/too-many-requests':
      return 'rate_limit';

    case 'messaging/server-unavailable':
    case 'messaging/internal-error':
      return 'server_error';

    case 'messaging/invalid-argument':
      return 'invalid_arg';

    case 'messaging/authentication-error':
      return 'auth_error';

    default:
      return 'unknown';
  }
}

/**
 * Calls admin.messaging().send(message) up to maxAttempts times.
 *
 * Retry delay schedule (attempt is 0-indexed):
 *   attempt 0 → first try, no preceding delay
 *   attempt 1 → first retry, delay = baseDelayMs * 4^0 = baseDelayMs
 *   attempt 2 → second retry, delay = baseDelayMs * 4^1
 *   attempt N → delay = baseDelayMs * 4^(N-1)
 *
 * Each attempt is retried only if the previous attempt threw the same
 * retriable category. The error category is checked once before entering
 * the retry loop (by the caller).
 *
 * @returns {Promise<string>} messageId on success
 * @throws  last error when all attempts are exhausted
 */
async function sendWithRetry(message, maxAttempts, baseDelayMs) {
  let lastError;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    if (attempt > 0) {
      const delayMs = baseDelayMs * Math.pow(4, attempt - 1);
      await sleep(delayMs);
    }

    try {
      return await admin.messaging().send(message);
    } catch (err) {
      lastError = err;
    }
  }

  throw lastError;
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Sends a Trust System push notification to a single device token.
 *
 * Non-retriable errors are returned immediately (no retry).
 * Retriable errors (rate_limit, server_error) use sendWithRetry which
 * includes the first attempt — so maxAttempts is the total call count.
 */
async function send(fcmToken, deviceId, payload, baseDelayMs = 1000) {
  const startTime = Date.now();

  // Resolve priority-specific FCM delivery parameters
  const priorityCfg = PRIORITY_FCM_CONFIG[payload.priority] || PRIORITY_FCM_CONFIG['DEFAULT'];
  const { androidPriority, apnsPriority, interruptionLevel } = priorityCfg;

  // Build the Admin SDK Message
  const message = {
    token: fcmToken,
    notification: {
      title: payload.title,
      body:  payload.body,
      // Include image URL for rich notifications (works on both iOS and Android)
      ...(payload.imageUrl && { imageUrl: payload.imageUrl }),
    },
    data: {
      // Trust System keys (canonical)
      deep_link:  payload.deepLink,
      event_type: payload.eventType,
      event_id:   payload.eventId,
      // Compatibility keys for legacy Flutter client routing
      // The Flutter client normalizes event_type → type, but having both
      // reduces reliance on client-side normalization and aids debugging.
      type: payload.eventType,
      // Game ID for direct routing (when available)
      ...(payload.gameId && { game_id: payload.gameId }),
    },
    android: {
      priority: androidPriority,
      notification: {
        channelId: payload.androidChannelId,
        sound:     'default',
      },
    },
    apns: {
      headers: {
        'apns-priority': apnsPriority,
      },
      payload: {
        aps: {
          'thread-id':          payload.threadId,
          'interruption-level': interruptionLevel,
          sound:                'default',
          'mutable-content':    1,
        },
      },
    },
  };

  // Attempt the first send to classify any error before deciding on retry strategy
  let firstError;
  try {
    await admin.messaging().send(message);
    return {
      success:   true,
      deviceId,
      latencyMs: Date.now() - startTime,
    };
  } catch (err) {
    firstError = err;
  }

  const errorCode = firstError.code || 'unknown';
  const category  = classifyError(errorCode);

  // ── Non-retriable paths ──────────────────────────────────────────────────

  if (category === 'token_invalid') {
    return {
      success:      false,
      deviceId,
      errorCode,
      tokenInvalid: true,
      latencyMs:    Date.now() - startTime,
    };
  }

  if (category === 'invalid_arg') {
    return {
      success:   false,
      deviceId,
      errorCode,
      latencyMs: Date.now() - startTime,
    };
  }

  if (category === 'auth_error') {
    return {
      success:   false,
      deviceId,
      errorCode,
      latencyMs: Date.now() - startTime,
    };
  }

  if (category === 'unknown') {
    return {
      success:   false,
      deviceId,
      errorCode,
      latencyMs: Date.now() - startTime,
    };
  }

  // ── Retriable paths ──────────────────────────────────────────────────────
  // rate_limit → 3 total attempts; server_error → 5 total attempts.
  // The first attempt already failed above, so remaining = maxAttempts - 1.
  // We call sendWithRetry with (maxAttempts - 1) to get the right total.

  const maxAttempts = category === 'rate_limit' ? 3 : 5;
  const remainingAttempts = maxAttempts - 1;

  try {
    // sendWithRetry will sleep before attempt 1 (first retry), etc.
    await sendWithRetry(message, remainingAttempts, baseDelayMs);
    return {
      success:   true,
      deviceId,
      latencyMs: Date.now() - startTime,
    };
  } catch (finalErr) {
    const finalCode = finalErr.code || errorCode;
    return {
      success:   false,
      deviceId,
      errorCode: finalCode,
      latencyMs: Date.now() - startTime,
    };
  }
}

module.exports = { send };
