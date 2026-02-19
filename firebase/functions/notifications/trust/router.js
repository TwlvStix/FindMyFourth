'use strict';

/**
 * Trust System Notification Router
 *
 * Single public method: routeNotification(event, db?)
 *
 * Pipeline:
 *   1. Dedup     — drop if already sent within 24h
 *   2. Cap       — drop if maxDeliveries reached
 *   3. Prefs     — drop if push disabled or category muted (CRITICAL bypass applies)
 *   4. Quiet hrs — hold if in quiet window (CRITICAL priority and imminent cancellation bypass)
 *   5. In-app    — always write to users/{uid}/notifications once past gates
 *   6. Devices   — load active FCM tokens
 *   7. Payload   — render push payload via template engine
 *   8. Fan-out   — send to each device
 *   9. Post-send — log result, delete invalid tokens
 *
 * NOTE: Quiet hours currently assume UTC. Timezone support is planned for a future session.
 */

const admin = require('firebase-admin');
const { getEventConfig, TrustEventType, NotificationPriority, TrustCategory } = require('./event-registry');
const { getUserPreferences } = require('./preferences-service');
const { send } = require('./fcm-sender');
const { buildPushPayload, buildInAppNotification } = require('./template-engine');
const logger = require('./logger');

// ── Constants ────────────────────────────────────────────────────────────────

/**
 * These three event types bypass ALL preference checks (pushEnabled + category).
 * They represent enforcement actions the user must receive regardless of settings.
 * Note: cooldown_started is HIGH priority (not CRITICAL), so it is still subject
 * to quiet hours despite being in this bypass set.
 */
const CRITICAL_BYPASS_TYPES = new Set([
  TrustEventType.COOLDOWN_STARTED,
  TrustEventType.RESTRICTION_STARTED,
  TrustEventType.SUSPENSION_STARTED,
]);

/**
 * These two event types use notification_prefs.game_alerts.enabled rather than
 * trustCategories for their preference gate, matching the existing game/chat
 * notification architecture.
 */
const GAME_ALERT_TYPES = new Set([
  TrustEventType.GAME_SPOT_OPENED,
  TrustEventType.GAME_CANCELLED,
]);

const MS_IN_24H = 24 * 60 * 60 * 1000;
const MS_IN_4H  =  4 * 60 * 60 * 1000;

// ── Pure helpers ─────────────────────────────────────────────────────────────

/**
 * Returns true if the given HH:MM time falls within the quiet window [start, end).
 * Handles both same-day and overnight (cross-midnight) windows.
 *
 * @param {string} start - 'HH:MM' start of quiet window (inclusive)
 * @param {string} end   - 'HH:MM' end of quiet window (exclusive)
 * @param {string} nowHHMM - current UTC time as 'HH:MM'
 * @returns {boolean}
 */
function isInQuietWindow(start, end, nowHHMM) {
  if (start <= end) {
    // Same-day window e.g. 13:00–15:00
    return nowHHMM >= start && nowHHMM < end;
  } else {
    // Overnight window e.g. 22:00–07:00
    return nowHHMM >= start || nowHHMM < end;
  }
}

/**
 * Returns a Date representing the next UTC occurrence of endHHMM.
 * If endHHMM has already passed for the current UTC day, rolls to the next day.
 *
 * @param {string} endHHMM - 'HH:MM' quiet window end time (UTC)
 * @returns {Date}
 */
function computeReleaseAt(endHHMM) {
  const now = new Date();
  const [h, m] = endHHMM.split(':').map(Number);
  const release = new Date(Date.UTC(
    now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),
    h, m, 0, 0,
  ));
  if (release <= now) {
    release.setUTCDate(release.getUTCDate() + 1);
  }
  return release;
}

/**
 * Returns current UTC time as a zero-padded 'HH:MM' string.
 * Extracted as a named function so tests can freeze time via jest.useFakeTimers().
 *
 * @returns {string}
 */
function getNowHHMM() {
  const now = new Date();
  const h = String(now.getUTCHours()).padStart(2, '0');
  const m = String(now.getUTCMinutes()).padStart(2, '0');
  return `${h}:${m}`;
}

/**
 * Returns true if event.data.game_start_iso falls at or before releaseAt + 4h.
 * Used to bypass quiet hours for game_cancelled when the game is imminent.
 * Safe-defaults to false on any missing or unparseable value.
 *
 * @param {object} event
 * @param {Date}   releaseAt
 * @returns {boolean}
 */
function isImminentGameCancellation(event, releaseAt) {
  try {
    const isoStr = event.data && event.data.game_start_iso;
    if (!isoStr) return false;
    const gameStart = new Date(isoStr);
    if (isNaN(gameStart.getTime())) return false;
    return gameStart <= new Date(releaseAt.getTime() + MS_IN_4H);
  } catch (_) {
    return false;
  }
}

/**
 * Builds a notificationLog document.
 *
 * @param {object} event
 * @param {string} status
 * @param {object} [extras] - additional fields (e.g. releaseAt, deviceResults)
 * @returns {object}
 */
function buildLogDoc(event, status, extras) {
  return Object.assign(
    {
      eventType:       event.eventType,
      sourceId:        event.sourceId,
      recipientUserId: event.recipientUserId,
      eventId:         event.eventId,
      status,
      timestamp:       admin.firestore.FieldValue.serverTimestamp(),
    },
    extras || {},
  );
}

// ── Main export ───────────────────────────────────────────────────────────────

/**
 * Routes a Trust System notification event through the full delivery pipeline.
 *
 * @param {{
 *   eventId: string,
 *   eventType: string,
 *   recipientUserId: string,
 *   sourceId: string,
 *   data: Record<string, string>,
 *   isReminder?: boolean,
 *   quietHoursBypass?: boolean,
 * }} event
 *
 * @param {FirebaseFirestore.Firestore} [db] - Firestore instance; defaults to admin.firestore().
 *   Accepts an injected instance for testing.
 *
 * @returns {Promise<{result: string, [key: string]: *}>}
 */
async function routeNotification(event, db) {
  if (!db) db = admin.firestore();

  const logCol = db.collection('notificationLog');

  // ── Step 1: Dedup ──────────────────────────────────────────────────────────
  const sentSnap = await logCol
    .where('eventType',       '==', event.eventType)
    .where('sourceId',        '==', event.sourceId)
    .where('recipientUserId', '==', event.recipientUserId)
    .where('status',          '==', 'sent')
    .orderBy('timestamp', 'desc')
    .get();

  const cutoff = Date.now() - MS_IN_24H;
  const recentSent = sentSnap.docs.filter((d) => {
    const ts = d.data().timestamp;
    if (!ts) return false;
    const ms = typeof ts.toMillis === 'function' ? ts.toMillis() : ts.getTime ? ts.getTime() : 0;
    return ms >= cutoff;
  });

  if (recentSent.length > 0) {
    await logCol.add(buildLogDoc(event, 'deduped'));
    logger.logNotificationEvent(event, 'deduped', { dropReason: 'duplicate within 24h' });
    return { result: 'deduped' };
  }

  // ── Step 2: Delivery cap ───────────────────────────────────────────────────
  const eventConfig = getEventConfig(event.eventType);
  const totalSent   = sentSnap.docs.length; // reuses the same query result

  if (totalSent >= eventConfig.maxDeliveries) {
    await logCol.add(buildLogDoc(event, 'cap_reached'));
    logger.logNotificationEvent(event, 'cap_reached', { dropReason: 'max deliveries reached' });
    return { result: 'cap_reached' };
  }

  // ── Step 3: Preference check ───────────────────────────────────────────────
  const isCriticalBypass = CRITICAL_BYPASS_TYPES.has(event.eventType);
  const prefs = await getUserPreferences(event.recipientUserId);

  if (!prefs.pushEnabled && !isCriticalBypass) {
    await logCol.add(buildLogDoc(event, 'preference_disabled'));
    logger.logNotificationEvent(event, 'preference_disabled', { dropReason: 'push disabled' });
    return { result: 'preference_disabled' };
  }

  if (!isCriticalBypass) {
    if (GAME_ALERT_TYPES.has(event.eventType)) {
      // game_spot_opened / game_cancelled use game_alerts.enabled (not trustCategories)
      const userDoc    = await db.collection('users').doc(event.recipientUserId).get();
      const rawPrefs   = (userDoc.exists && userDoc.data().notification_prefs) || {};
      const gameAlerts = (rawPrefs.game_alerts && typeof rawPrefs.game_alerts === 'object')
        ? rawPrefs.game_alerts
        : {};
      const gameAlertsEnabled = typeof gameAlerts.enabled === 'boolean' ? gameAlerts.enabled : true;

      if (!gameAlertsEnabled) {
        await logCol.add(buildLogDoc(event, 'preference_disabled'));
        logger.logNotificationEvent(event, 'preference_disabled', { dropReason: 'category muted' });
        return { result: 'preference_disabled' };
      }
    } else {
      const categoryEnabledMap = {
        [TrustCategory.POST_ROUND]:   prefs.trustCategories.postRound,
        [TrustCategory.TRUST_ALERTS]: prefs.trustCategories.trustAlerts,
        [TrustCategory.BADGES]:       prefs.trustCategories.badges,
      };
      const categoryEnabled = categoryEnabledMap[eventConfig.category];

      if (categoryEnabled === false) {
        await logCol.add(buildLogDoc(event, 'preference_disabled'));
        logger.logNotificationEvent(event, 'preference_disabled', { dropReason: 'category muted' });
        return { result: 'preference_disabled' };
      }
    }
  }

  // ── Step 4: Quiet hours ────────────────────────────────────────────────────
  const { quietHours } = prefs;
  if (quietHours.enabled && !event.quietHoursBypass) {
    const nowHHMM   = getNowHHMM();
    if (isInQuietWindow(quietHours.start, quietHours.end, nowHHMM)) {
      const releaseAt = computeReleaseAt(quietHours.end);

      // Exception 1: CRITICAL priority always delivers through quiet hours.
      // Note: cooldown_started is HIGH priority, so it is held even though it is
      // in CRITICAL_BYPASS_TYPES (which bypasses preferences, not quiet hours).
      const isCriticalPriority = eventConfig.priority === NotificationPriority.CRITICAL;

      // Exception 2: game_cancelled where game starts within 4h of quiet window end.
      const isImminent = event.eventType === TrustEventType.GAME_CANCELLED
        && isImminentGameCancellation(event, releaseAt);

      if (!isCriticalPriority && !isImminent) {
        await logCol.add(buildLogDoc(event, 'quiet_held', { releaseAt, event }));
        // TODO: schedule Cloud Tasks release task when Cloud Tasks integration is implemented.
        logger.logNotificationEvent(event, 'quiet_held', { dropReason: 'quiet hours' });
        return { result: 'quiet_held', releaseAt };
      }
    }
  }

  // ── Step 5: Write in-app notification ──────────────────────────────────────
  // Always written once past all gate checks, even if push delivery later fails
  // or there are no registered devices. The user must always see this in their
  // in-app notification list.
  const inAppDoc = buildInAppNotification(event.eventType, event.data, event.eventId);
  const inAppRef = await db
    .collection('users')
    .doc(event.recipientUserId)
    .collection('notifications')
    .add(inAppDoc);
  const inAppNotifId = inAppRef.id;

  // ── Step 6: Device token resolution ───────────────────────────────────────
  const devicesSnap = await db
    .collection('users')
    .doc(event.recipientUserId)
    .collection('devices')
    .get();

  const devices = devicesSnap.docs
    .filter((d) => Boolean(d.data().fcm_token))
    .map((d) => ({
      deviceId: d.id,
      fcmToken: d.data().fcm_token,
      platform: d.data().platform || 'unknown',
    }));

  if (devices.length === 0) {
    await logCol.add(buildLogDoc(event, 'dropped_no_devices'));
    logger.logNotificationEvent(event, 'no_devices', { dropReason: 'no registered devices' });
    return { result: 'no_devices', inAppWritten: true, inAppNotifId };
  }

  // ── Step 7: Render push payload ───────────────────────────────────────────
  const payload = buildPushPayload(
    event.eventType,
    event.data,
    event.eventId,
    event.isReminder || false,
  );

  // ── Step 8: Fan-out & send ─────────────────────────────────────────────────
  const sendResults = await Promise.all(
    devices.map(({ deviceId, fcmToken, platform }) => send(fcmToken, deviceId, payload, 0)
      .then((result) => ({ ...result, platform })),
    ),
  );

  // ── Step 9: Post-send ──────────────────────────────────────────────────────
  const deviceResults = sendResults.map((r) => {
    const entry = { deviceId: r.deviceId, success: r.success };
    if (r.errorCode) entry.errorCode = r.errorCode;
    return entry;
  });

  // Emit one structured log entry per device send.
  for (const r of sendResults) {
    logger.logFcmSend(event, r.deviceId, r.platform, r);
  }

  await logCol.add(buildLogDoc(event, 'sent', { deviceResults }));

  // Delete device documents whose tokens have been invalidated by FCM.
  await Promise.all(
    sendResults
      .filter((r) => r.tokenInvalid === true)
      .map((r) =>
        db
          .collection('users')
          .doc(event.recipientUserId)
          .collection('devices')
          .doc(r.deviceId)
          .delete(),
      ),
  );

  const sentCount = sendResults.filter((r) => r.success).length;

  return { result: 'sent', sentCount, inAppWritten: true, inAppNotifId, deviceResults };
}

module.exports = {
  routeNotification,
  // Pure helpers exported for direct unit testing
  isInQuietWindow,
  computeReleaseAt,
  isImminentGameCancellation,
};
