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
 */

const admin = require('firebase-admin');
const { getEventConfig, TrustEventType, NotificationPriority, TrustCategory } = require('./event-registry');
const { getUserPreferences } = require('./preferences-service');
const { send } = require('./fcm-sender');
const { buildPushPayload, buildInAppNotification } = require('./template-engine');
const logger = require('./logger');
// Late require to avoid circular dependency (scheduler.js imports router.js)
let _scheduleJob;
function getScheduleJob() {
  if (!_scheduleJob) _scheduleJob = require('./scheduler').scheduleJob;
  return _scheduleJob;
}

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
  TrustEventType.GAME_AUTO_CANCELLED,
  TrustEventType.GAME_ALERT_DEFERRED,
]);

/**
 * These event types use notification_prefs.social_alerts.enabled for their
 * preference gate, separate from trust categories.
 */
const SOCIAL_ALERT_TYPES = new Set([
  TrustEventType.FRIEND_REQUEST_RECEIVED,
  TrustEventType.FRIEND_REQUEST_ACCEPTED,
  TrustEventType.JOIN_REQUEST_NEW,
  TrustEventType.JOIN_REQUEST_APPROVED,
  TrustEventType.JOIN_REQUEST_DECLINED,
  TrustEventType.JOIN_REQUEST_ROUND_FILLED,
  TrustEventType.JOIN_REQUEST_EXPIRED,
]);

const MS_IN_24H = 24 * 60 * 60 * 1000;
const MS_IN_4H  =  4 * 60 * 60 * 1000;
const QUIET_HOURS_TIMEZONE = 'America/Vancouver';
const VAN_WEEKDAY_FORMATTER = new Intl.DateTimeFormat('en-US', {
  timeZone: QUIET_HOURS_TIMEZONE,
  weekday: 'short',
});
const VAN_DATE_PARTS_FORMATTER = new Intl.DateTimeFormat('en-CA', {
  timeZone: QUIET_HOURS_TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hourCycle: 'h23',
});
const VAN_TZ_OFFSET_FORMATTER = new Intl.DateTimeFormat('en-US', {
  timeZone: QUIET_HOURS_TIMEZONE,
  timeZoneName: 'shortOffset',
  hour: '2-digit',
  minute: '2-digit',
  hourCycle: 'h23',
});

function getVanDateParts(now = new Date()) {
  const out = {};
  const parts = VAN_DATE_PARTS_FORMATTER.formatToParts(now);
  for (const part of parts) {
    if (part.type === 'year' || part.type === 'month' || part.type === 'day' ||
        part.type === 'hour' || part.type === 'minute') {
      out[part.type] = Number(part.value);
    }
  }
  return out;
}

function getVanOffsetMinutes(atUtcDate) {
  const parts = VAN_TZ_OFFSET_FORMATTER.formatToParts(atUtcDate);
  const tzPart = parts.find((part) => part.type === 'timeZoneName');
  if (!tzPart || typeof tzPart.value !== 'string') {
    return 0;
  }
  const match = tzPart.value.match(/^GMT([+-])(\d{1,2})(?::?(\d{2}))?$/);
  if (!match) {
    return 0;
  }
  const sign = match[1] === '-' ? -1 : 1;
  const hours = Number(match[2]);
  const minutes = match[3] ? Number(match[3]) : 0;
  return sign * (hours * 60 + minutes);
}

function localVanToUtcDate(year, month, day, hour, minute) {
  const baseUtcMs = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
  let utcMs = baseUtcMs;
  for (let i = 0; i < 3; i++) {
    const offsetMinutes = getVanOffsetMinutes(new Date(utcMs));
    const nextUtcMs = baseUtcMs - offsetMinutes * 60 * 1000;
    if (nextUtcMs === utcMs) break;
    utcMs = nextUtcMs;
  }
  return new Date(utcMs);
}

function addUtcDays(year, month, day, delta) {
  const d = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
  d.setUTCDate(d.getUTCDate() + delta);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
  };
}

// ── Pure helpers ─────────────────────────────────────────────────────────────

/**
 * Returns true if the given HH:MM time falls within the quiet window [start, end).
 * Handles both same-day and overnight (cross-midnight) windows.
 *
 * @param {string} start - 'HH:MM' start of quiet window (inclusive)
 * @param {string} end   - 'HH:MM' end of quiet window (exclusive)
 * @param {string} nowHHMM - current Vancouver time as 'HH:MM'
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
 * Returns a Date representing the next UTC occurrence of endHHMM in Vancouver local time.
 * If endHHMM has already passed for the current Vancouver day, rolls to next day.
 *
 * @param {string} endHHMM - 'HH:MM' quiet window end time (Vancouver local)
 * @returns {Date}
 */
function computeReleaseAt(endHHMM) {
  const now = new Date();
  const nowParts = getVanDateParts(now);
  const [h, m] = endHHMM.split(':').map(Number);
  let release = localVanToUtcDate(nowParts.year, nowParts.month, nowParts.day, h, m);
  if (release <= now) {
    const nextDay = addUtcDays(nowParts.year, nowParts.month, nowParts.day, 1);
    release = localVanToUtcDate(nextDay.year, nextDay.month, nextDay.day, h, m);
  }
  return release;
}

/**
 * Returns current Vancouver time as a zero-padded 'HH:MM' string.
 * Extracted as a named function so tests can freeze time via jest.useFakeTimers().
 *
 * @returns {string}
 */
function getNowHHMM() {
  const now = getVanDateParts();
  const h = String(now.hour).padStart(2, '0');
  const m = String(now.minute).padStart(2, '0');
  return `${h}:${m}`;
}

/**
 * Returns true if quiet hours are active on the current Vancouver day.
 *
 * @param {number[]} activeDays - ISO days (1=Mon ... 7=Sun)
 * @returns {boolean}
 */
function isActiveDay(activeDays) {
  if (!Array.isArray(activeDays) || activeDays.length === 0) return true;
  const dayStr = VAN_WEEKDAY_FORMATTER.format(new Date());
  const dayMap = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };
  const isoDay = dayMap[dayStr];
  if (!isoDay) return true;
  return activeDays.some((d) => Number(d) === isoDay);
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
    } else if (SOCIAL_ALERT_TYPES.has(event.eventType)) {
      // friend_request_received / friend_request_accepted use social_alerts.enabled
      const userDoc      = await db.collection('users').doc(event.recipientUserId).get();
      const rawPrefs     = (userDoc.exists && userDoc.data().notification_prefs) || {};
      const socialAlerts = (rawPrefs.social_alerts && typeof rawPrefs.social_alerts === 'object')
        ? rawPrefs.social_alerts
        : {};
      const socialEnabled = typeof socialAlerts.enabled === 'boolean' ? socialAlerts.enabled : true;

      if (!socialEnabled) {
        await logCol.add(buildLogDoc(event, 'preference_disabled'));
        logger.logNotificationEvent(event, 'preference_disabled', { dropReason: 'social_alerts disabled' });
        return { result: 'preference_disabled' };
      }
    } else {
      const categoryEnabledMap = {
        [TrustCategory.POST_ROUND]:      prefs.trustCategories.postRound,
        [TrustCategory.TRUST_ALERTS]:    prefs.trustCategories.trustAlerts,
        [TrustCategory.BADGES]:          prefs.trustCategories.badges,
        [TrustCategory.WEEKLY_ACTIVITY]: prefs.trustCategories.weeklyActivity,
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
    let activeDays = [];
    try {
      const userDoc = await db.collection('users').doc(event.recipientUserId).get();
      const rawPrefs = (userDoc.exists && userDoc.data().notification_prefs) || {};
      const rawQuietHours = (rawPrefs.quiet_hours && typeof rawPrefs.quiet_hours === 'object')
        ? rawPrefs.quiet_hours
        : {};
      activeDays = Array.isArray(rawQuietHours.active_days) ? rawQuietHours.active_days : [];
    } catch (_) {
      activeDays = [];
    }

    if (isActiveDay(activeDays)) {
      const nowHHMM = getNowHHMM();
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
          const deferredEvent = {
            ...event,
            scheduleTime: releaseAt,
            quietHoursBypass: true,
            conditionCheck: 'always',
          };
          const jobId = await getScheduleJob()(deferredEvent, db);
          await logCol.add(buildLogDoc(event, 'quiet_held', { releaseAt, event, jobId }));
          logger.logNotificationEvent(event, 'quiet_held', { releaseAt: releaseAt.toISOString(), jobId });
          return { result: 'quiet_held', releaseAt, jobId };
        }
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
    .filter((d) => Boolean(d.data().fcmToken))
    .map((d) => ({
      deviceId: d.id,
      fcmToken: d.data().fcmToken,
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
  isActiveDay,
  computeReleaseAt,
  isImminentGameCancellation,
};
