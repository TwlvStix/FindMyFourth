'use strict';

/**
 * Trust System Notification Hooks
 *
 * High-level API surface imported directly by Trust System Cloud Functions.
 * Each hook maps a business event to one or more notification operations
 * (immediate routeNotification calls or scheduled Cloud Task jobs).
 *
 * sourceId conventions:
 *   - Game events:  sourceId = gameId  (enables cancelGameJobs queries)
 *   - User events:  sourceId = userId  (dedup scoped to user)
 *
 * All hooks accept an optional `db` (Firestore instance) for testing.
 * When omitted, router and scheduler each default to admin.firestore().
 */

const { randomUUID } = require('crypto'); // Node 20 built-in — no extra dependency
const { scheduleJob, cancelGameJobs } = require('./scheduler');
const { routeNotification } = require('./router');

// ── Time constants ────────────────────────────────────────────────────────────

const MS_IN_HOUR  = 60 * 60 * 1000;
const MS_IN_30MIN = 30 * 60 * 1000;

// ── Game lifecycle hooks ──────────────────────────────────────────────────────

/**
 * Called when a game is confirmed (all players joined, tee time locked).
 * Schedules the host check-in pipeline and player fallback confirms.
 *
 * Timeline relative to teeTime:
 *   +5h  — host_checkin_due (initial, always fires)
 *   +24h — host_checkin_fallback to host (condition: host_not_checked_in)
 *   +24h — player_fallback_confirm to each non-host player (condition: host_not_checked_in)
 *   +29h — host_checkin_due REMINDER to host (condition: host_not_checked_in)
 *
 * @param {string}   gameId
 * @param {Date|string} teeTime      - Date or ISO string of the scheduled tee time
 * @param {string}   hostUserId
 * @param {string[]} playerUserIds   - All players including the host
 * @param {string}   courseName
 * @param {string}   gameDate        - Pre-formatted date string, e.g. "Feb 18"
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{
 *   hostCheckinJobId:         string,
 *   hostCheckinReminderJobId: string,
 *   hostFallbackJobId:        string,
 *   playerFallbackJobIds:     Record<string, string>,
 * }>}
 */
async function onGameConfirmed(gameId, teeTime, hostUserId, playerUserIds, courseName, gameDate, db) {
  const teeMs = new Date(teeTime).getTime();

  // Jobs 1–3 are independent of each other — schedule in parallel.
  const [hostCheckinJobId, hostCheckinReminderJobId, hostFallbackJobId] = await Promise.all([

    // 1. host_checkin_due (initial) — teeTime + 5h, always fires regardless of check-in state
    scheduleJob({
      eventId:         randomUUID(),
      eventType:       'host_checkin_due',
      recipientUserId: hostUserId,
      sourceId:        gameId,
      data:            { course_name: courseName, game_id: gameId, hours_remaining: '0' },
      scheduleTime:    new Date(teeMs + 5 * MS_IN_HOUR),
      conditionCheck:  'always',
      isReminder:      false,
    }, db),

    // 2. host_checkin_due (reminder) — teeTime + 29h, only if host still hasn't checked in.
    // hours_remaining: assumes a 48h total check-in window → 48-29 = 19h remaining at send time.
    // Adjust if the check-in window policy changes.
    scheduleJob({
      eventId:         randomUUID(),
      eventType:       'host_checkin_due',
      recipientUserId: hostUserId,
      sourceId:        gameId,
      data:            { course_name: courseName, game_id: gameId, hours_remaining: '19' },
      scheduleTime:    new Date(teeMs + 29 * MS_IN_HOUR),
      conditionCheck:  'host_not_checked_in',
      isReminder:      true,
    }, db),

    // 3. host_checkin_fallback — teeTime + 24h, only if host hasn't checked in
    scheduleJob({
      eventId:         randomUUID(),
      eventType:       'host_checkin_fallback',
      recipientUserId: hostUserId,
      sourceId:        gameId,
      data:            { course_name: courseName, game_id: gameId },
      scheduleTime:    new Date(teeMs + 24 * MS_IN_HOUR),
      conditionCheck:  'host_not_checked_in',
      isReminder:      false,
    }, db),
  ]);

  // 4. player_fallback_confirm — teeTime + 24h for each non-host player.
  // Host receives host_checkin_fallback instead.
  const nonHostPlayers = playerUserIds.filter((uid) => uid !== hostUserId);
  const playerFallbackJobIds = {};

  await Promise.all(nonHostPlayers.map(async (uid) => {
    playerFallbackJobIds[uid] = await scheduleJob({
      eventId:         randomUUID(),
      eventType:       'player_fallback_confirm',
      recipientUserId: uid,
      sourceId:        gameId,
      data:            { course_name: courseName, date: gameDate, game_id: gameId },
      scheduleTime:    new Date(teeMs + 24 * MS_IN_HOUR),
      conditionCheck:  'host_not_checked_in',
      isReminder:      false,
    }, db);
  }));

  return { hostCheckinJobId, hostCheckinReminderJobId, hostFallbackJobId, playerFallbackJobIds };
}

/**
 * Called when the host submits their check-in.
 * Cancels all pending scheduled jobs for the game (reminder + fallbacks),
 * then schedules player_rate_due for each player at now + 30min.
 *
 * playerUserIds should include everyone who should rate (host + players).
 * The hook does not filter — caller controls the list.
 *
 * @param {string}   gameId
 * @param {string}   hostUserId      - Included for API symmetry; not used internally
 * @param {string[]} playerUserIds   - All players to receive a rating prompt
 * @param {string}   courseName
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ cancelledCount: number, playerRateJobIds: Record<string, string> }>}
 */
async function onHostCheckinCompleted(gameId, hostUserId, playerUserIds, courseName, db) {
  // Cancel all pending jobs for this game (checkin reminders, fallbacks)
  const { count: cancelledCount } = await cancelGameJobs(gameId, db);

  // Schedule player_rate_due for each player at now + 30min
  const rateAt = new Date(Date.now() + MS_IN_30MIN);
  const playerRateJobIds = {};

  await Promise.all(playerUserIds.map(async (uid) => {
    playerRateJobIds[uid] = await scheduleJob({
      eventId:         randomUUID(),
      eventType:       'player_rate_due',
      recipientUserId: uid,
      sourceId:        gameId,
      data:            { course_name: courseName, game_id: gameId },
      scheduleTime:    rateAt,
      conditionCheck:  'always',
      isReminder:      false,
    }, db);
  }));

  return { cancelledCount, playerRateJobIds };
}

/**
 * Called when a game is cancelled by the host.
 * Cancels all pending scheduled jobs, then immediately notifies each player.
 *
 * Note: game_start_iso is deliberately not included in the notification data.
 * A cancellation held in quiet hours until 7am is acceptable — the game is
 * already cancelled and a delay of a few hours doesn't matter. To enable
 * imminent-game quiet-hour bypass, add game_start_iso to the data map at
 * the call site; no changes to this hook or the router are needed.
 *
 * @param {string}   gameId
 * @param {string[]} playerUserIds
 * @param {string}   courseName
 * @param {string}   gameDate        - Pre-formatted date string, e.g. "Feb 18"
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ cancelledCount: number, notifyResults: Array<{userId: string, result: string}> }>}
 */
async function onGameCancelled(gameId, playerUserIds, courseName, gameDate, db) {
  const { count: cancelledCount } = await cancelGameJobs(gameId, db);

  const notifyResults = await Promise.all(playerUserIds.map(async (uid) => {
    const res = await routeNotification({
      eventId:         randomUUID(),
      eventType:       'game_cancelled',
      recipientUserId: uid,
      sourceId:        gameId,
      data:            { game_date: gameDate, course_name: courseName, game_id: gameId },
    }, db);
    return { userId: uid, result: res.result };
  }));

  return { cancelledCount, notifyResults };
}

// ── Trust enforcement hooks ───────────────────────────────────────────────────

/**
 * Called when a strike is recorded against a user.
 *
 * @param {string} userId
 * @param {string} reason - Human-readable reason, e.g. "confirmed no-show"
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onStrikeIssued(userId, reason, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'strike_issued',
    recipientUserId: userId,
    sourceId:        userId,
    data:            { reason },
  }, db);
}

/**
 * Called when a 24-hour cooldown is applied (2 active strikes).
 *
 * @param {string} userId
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onCooldownStarted(userId, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'cooldown_started',
    recipientUserId: userId,
    sourceId:        userId,
    data:            {},
  }, db);
}

/**
 * Called when an account restriction is applied.
 * Sends an immediate restriction_started notification and schedules a
 * restriction_ended notification for when the restriction lifts.
 *
 * @param {string}      userId
 * @param {string}      duration  - Human-readable, e.g. "7 days"
 * @param {Date|string} endDate   - When the restriction ends
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ notifyResult: object, restrictionEndedJobId: string }>}
 */
async function onRestrictionStarted(userId, duration, endDate, db) {
  const notifyResult = await routeNotification({
    eventId:         randomUUID(),
    eventType:       'restriction_started',
    recipientUserId: userId,
    sourceId:        userId,
    data:            { duration },
  }, db);

  const restrictionEndedJobId = await scheduleJob({
    eventId:         randomUUID(),
    eventType:       'restriction_ended',
    recipientUserId: userId,
    sourceId:        userId,
    data:            {},
    scheduleTime:    endDate,
    conditionCheck:  'always',
  }, db);

  return { notifyResult, restrictionEndedJobId };
}

/**
 * Called when an account is suspended pending manual review.
 *
 * @param {string} userId
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onSuspensionStarted(userId, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'suspension_started',
    recipientUserId: userId,
    sourceId:        userId,
    data:            {},
  }, db);
}

/**
 * Called when a user is flagged as a no-show by the host.
 *
 * @param {string} userId
 * @param {string} courseName
 * @param {string} date       - Pre-formatted date string, e.g. "Feb 18"
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onNoShowFlagged(userId, courseName, date, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'no_show_flagged',
    recipientUserId: userId,
    sourceId:        userId,
    data:            { course_name: courseName, date },
  }, db);
}

/**
 * Called when a no-show flag is cleared because another player confirmed attendance.
 *
 * @param {string} userId
 * @param {string} courseName
 * @param {string} date       - Pre-formatted date string, e.g. "Feb 18"
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onDisputeResolved(userId, courseName, date, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'dispute_resolved',
    recipientUserId: userId,
    sourceId:        userId,
    data:            { course_name: courseName, date },
  }, db);
}

// ── Badge hooks ───────────────────────────────────────────────────────────────

/**
 * Called when a user earns a new trust badge.
 *
 * @param {string}        userId
 * @param {string}        badgeName      - e.g. "Verified Regular"
 * @param {number|string} roundsCount
 * @param {number|string} uniquePlayers
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onBadgeEarned(userId, badgeName, roundsCount, uniquePlayers, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'badge_earned',
    recipientUserId: userId,
    sourceId:        userId,
    data:            {
      badge_name:     badgeName,
      rounds_count:   String(roundsCount),
      unique_players: String(uniquePlayers),
    },
  }, db);
}

// ── Game alert hooks ──────────────────────────────────────────────────────────

/**
 * Called when a spot opens in a game (player left or was removed).
 * Notifies all users in playerUserIds immediately.
 *
 * Uses game_alerts.enabled preference (not trustCategories) — consistent with
 * the existing game alert architecture.
 *
 * @param {string[]}      playerUserIds   - Users to notify
 * @param {string}        gameId
 * @param {string}        courseName
 * @param {string}        gameDate        - Pre-formatted date string, e.g. "Feb 18"
 * @param {number|string} spotsRemaining
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<Array<{ userId: string, result: string }>>}
 */
async function onSpotOpened(playerUserIds, gameId, courseName, gameDate, spotsRemaining, db) {
  return Promise.all(playerUserIds.map(async (uid) => {
    const res = await routeNotification({
      eventId:         randomUUID(),
      eventType:       'game_spot_opened',
      recipientUserId: uid,
      sourceId:        gameId,
      data:            {
        game_date:       gameDate,
        course_name:     courseName,
        spots_remaining: String(spotsRemaining),
        game_id:         gameId,
      },
    }, db);
    return { userId: uid, result: res.result };
  }));
}

// ── Social hooks ──────────────────────────────────────────────────────────────

/**
 * Called when a user receives a friend request.
 * Notifies the recipient immediately.
 *
 * @param {string} recipientUserId - User receiving the request
 * @param {string} senderUserId    - User sending the request
 * @param {string} senderName      - Display name of sender
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onFriendRequestReceived(recipientUserId, senderUserId, senderName, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'friend_request_received',
    recipientUserId: recipientUserId,
    sourceId:        `friend_request_${senderUserId}_${recipientUserId}`,
    data:            { sender_name: senderName, sender_id: senderUserId },
  }, db);
}

/**
 * Called when a friend request is accepted.
 * Notifies the original requester.
 *
 * @param {string} recipientUserId - Original requester receiving the notification
 * @param {string} acceptorUserId  - User who accepted the request
 * @param {string} acceptorName    - Display name of acceptor
 * @param {FirebaseFirestore.Firestore} [db]
 */
async function onFriendRequestAccepted(recipientUserId, acceptorUserId, acceptorName, db) {
  return routeNotification({
    eventId:         randomUUID(),
    eventType:       'friend_request_accepted',
    recipientUserId: recipientUserId,
    sourceId:        `friend_accept_${acceptorUserId}_${recipientUserId}`,
    data:            { acceptor_name: acceptorName, acceptor_id: acceptorUserId },
  }, db);
}

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  onGameConfirmed,
  onHostCheckinCompleted,
  onGameCancelled,
  onStrikeIssued,
  onCooldownStarted,
  onRestrictionStarted,
  onSuspensionStarted,
  onNoShowFlagged,
  onDisputeResolved,
  onBadgeEarned,
  onSpotOpened,
  onFriendRequestReceived,
  onFriendRequestAccepted,
};
