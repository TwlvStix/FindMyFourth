'use strict';

/**
 * Trust System Template Engine
 *
 * Transforms Trust System event data into two output formats:
 *
 *   buildPushPayload()       → TrustNotificationPayload for FCM Sender
 *   buildInAppNotification() → Firestore document for users/{userId}/notifications
 *
 * Both methods delegate template rendering to event-registry.js and produce
 * output that integrates with the existing notification schema used by chat
 * and game notifications.
 */

const admin = require('firebase-admin');
const { getEventConfig, renderTemplate } = require('./event-registry');

// ── Internal helpers ──────────────────────────────────────────────────────────

/**
 * Interpolates {game_id} in a string using eventData.game_id.
 * Silent if game_id is absent (trust_alerts/badge links have no {game_id}).
 *
 * @param {string} str
 * @param {object} eventData
 * @returns {string}
 */
function interpolateGameId(str, eventData) {
  if (eventData.game_id == null) return str;
  return str.replace(/\{game_id\}/g, String(eventData.game_id));
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Builds a TrustNotificationPayload for the FCM Sender.
 *
 * @param {string}  eventType  - A TrustEventType value (snake_case)
 * @param {object}  eventData  - Template variables (e.g. course_name, game_id, reason)
 * @param {string}  eventId    - Unique event/document ID
 * @param {boolean} [isReminder=false] - If true, renders the reminderTemplate (host_checkin_due only)
 * @returns {{
 *   title: string,
 *   body: string,
 *   deepLink: string,
 *   eventType: string,
 *   eventId: string,
 *   priority: string,
 *   threadId: string,
 *   androidChannelId: string,
 * }}
 * @throws {Error} if eventType is unknown, template variant is missing, or required vars are absent
 */
function buildPushPayload(eventType, eventData, eventId, isReminder = false) {
  const config = getEventConfig(eventType);
  const { title, body } = renderTemplate(eventType, eventData, isReminder);

  const deepLink = interpolateGameId(config.deepLink, eventData);
  const threadId = interpolateGameId(config.threadId, eventData);

  return {
    title,
    body,
    deepLink,
    eventType,
    eventId,
    priority:         config.priority,
    threadId,
    androidChannelId: config.androidChannelId,
  };
}

/**
 * Builds a Firestore document for users/{userId}/notifications.
 *
 * Matches the schema used by existing chat and game notifications so that
 * Trust System notifications appear inline in the user's notification list.
 *
 * @param {string} eventType - A TrustEventType value (snake_case)
 * @param {object} eventData - Template variables; also carries game_id and game_ref
 * @param {string} eventId   - Unique event/document ID
 * @returns {{
 *   type: string,
 *   title: string,
 *   body: string,
 *   read: false,
 *   createdAt: FirebaseFirestore.FieldValue,
 *   data: { gameId: string|null, gameRef: string|null, eventId: string, eventType: string },
 * }}
 * @throws {Error} if eventType is unknown or required template vars are absent
 */
function buildInAppNotification(eventType, eventData, eventId) {
  // Validate event type (propagates unknown-type error)
  getEventConfig(eventType);

  // Always use the primary template for in-app; reminders are push-only
  const { title, body } = renderTemplate(eventType, eventData, false);

  return {
    type:      eventType,
    title,
    body,
    read:      false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    data: {
      gameId:    eventData.game_id  != null ? eventData.game_id  : null,
      gameRef:   eventData.game_ref != null ? eventData.game_ref : null,
      eventId,
      eventType,
    },
  };
}

module.exports = { buildPushPayload, buildInAppNotification };
