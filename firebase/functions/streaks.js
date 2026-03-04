/**
 * Weekly Streak System Cloud Functions
 *
 * Implements a seasonal weekly streak feature for outdoor golf rounds.
 * Season runs May 1 - Oct 31 in Vancouver time (America/Vancouver).
 * Weeks are Monday-Sunday, identified by Monday's date (YYYY-MM-DD).
 *
 * Core concepts:
 *   - Week counts if user has at least one verified outdoor round that week
 *   - Pending weeks protect users from false breaks during verification lag
 *   - Freeze earned at 4 consecutive weeks, single-use per season
 *   - Milestones at 4, 8, 13, 26 weeks
 *
 * Exports:
 *   Orchestrators (called from confirmation_flow.js):
 *     onRoundPending     - Called when game transitions to 'played'
 *     onRoundVerified    - Called when round verification completes
 *     clearPendingForAllParticipants - Called after onRoundVerified
 *
 *   Callable:
 *     deployStreakFreeze - User deploys their freeze for current week
 *
 *   Scheduled job handlers:
 *     fridayNudgeHandler      - Friday 18:00 Vancouver
 *     sundayPromptHandler     - Sunday 20:00 Vancouver
 *     mondayRolloverHandler   - Monday 00:01 Vancouver
 *     seasonCloseHandler      - Nov 1 00:05 Vancouver
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { routeNotification } = require('./notifications/trust/router');
const { randomUUID } = require('crypto');

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const kTimezone = "America/Vancouver";
const kSeasonStartMonth = 3;  // March (1-indexed)
const kSeasonStartDay = 1;
const kSeasonEndMonth = 10;   // October (1-indexed)
const kSeasonEndDay = 31;
const kFreezeUnlockThreshold = 4;
const kMilestones = [4, 8, 13, 26];
const kBatchChunkSize = 450; // Safe margin under Firestore's 500 limit

/**
 * Commits batch writes in chunks to stay under Firestore's 500-operation limit.
 * @param {FirebaseFirestore.Firestore} db
 * @param {Array<{ref: DocumentReference, data: object}>} updates
 * @param {number} chunkSize
 */
async function commitInChunks(db, updates, chunkSize = kBatchChunkSize) {
  for (let i = 0; i < updates.length; i += chunkSize) {
    const batch = db.batch();
    const chunk = updates.slice(i, i + chunkSize);
    for (const { ref, data } of chunk) {
      batch.update(ref, data);
    }
    await batch.commit();
  }
}

// Intl formatters (same pattern as game_alerts.js)
const vanDatePartsFormatter = new Intl.DateTimeFormat("en-CA", {
  timeZone: kTimezone,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});

const vanWeekdayFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: kTimezone,
  weekday: "short",
});

const vanTzOffsetFormatter = new Intl.DateTimeFormat("en-US", {
  timeZone: kTimezone,
  timeZoneName: "shortOffset",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});

// ─────────────────────────────────────────────────────────────────────────────
// TIMEZONE UTILITIES (based on game_alerts.js patterns)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Extracts Vancouver-local date parts from a Date object.
 * Returns { year, month, day, hour, minute } where month is 1-12.
 */
function getVancouverDateParts(now = new Date()) {
  const out = {};
  const parts = vanDatePartsFormatter.formatToParts(now);
  for (const part of parts) {
    if (
      part.type === "year" ||
      part.type === "month" ||
      part.type === "day" ||
      part.type === "hour" ||
      part.type === "minute"
    ) {
      out[part.type] = Number(part.value);
    }
  }
  return out;
}

/**
 * Returns the Vancouver timezone offset in minutes at a given UTC instant.
 * Handles DST transitions correctly.
 */
function getVancouverOffsetMinutes(atUtcDate) {
  const parts = vanTzOffsetFormatter.formatToParts(atUtcDate);
  const tzPart = parts.find((part) => part.type === "timeZoneName");
  if (!tzPart || typeof tzPart.value !== "string") {
    return 0;
  }
  const match = tzPart.value.match(/^GMT([+-])(\d{1,2})(?::?(\d{2}))?$/);
  if (!match) {
    return 0;
  }
  const sign = match[1] === "-" ? -1 : 1;
  const hours = Number(match[2]);
  const minutes = match[3] ? Number(match[3]) : 0;
  return sign * (hours * 60 + minutes);
}

/**
 * Converts Vancouver-local date/time to UTC Date.
 * Uses 3-iteration algorithm to handle DST boundaries.
 */
function localVancouverToUtcDate(year, month, day, hour, minute) {
  const baseUtcMs = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
  let utcMs = baseUtcMs;
  for (let i = 0; i < 3; i++) {
    const offsetMinutes = getVancouverOffsetMinutes(new Date(utcMs));
    const nextUtcMs = baseUtcMs - offsetMinutes * 60 * 1000;
    if (nextUtcMs === utcMs) break;
    utcMs = nextUtcMs;
  }
  return new Date(utcMs);
}

/**
 * Returns the ISO day of week in Vancouver time (1=Mon, 7=Sun).
 */
function getVancouverIsoWeekday(date = new Date()) {
  const dayStr = vanWeekdayFormatter.format(date);
  const dayMap = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };
  return dayMap[dayStr] || 1;
}

/**
 * Returns the Monday week key (YYYY-MM-DD) for a given date in Vancouver time.
 * All streak week tracking uses this key format.
 */
function weekStartMondayKey(input = new Date()) {
  const date = input instanceof Date ? input : new Date(input);
  const parts = getVancouverDateParts(date);
  const isoWeekday = getVancouverIsoWeekday(date);

  // Calculate days to subtract to get to Monday
  const daysToSubtract = isoWeekday - 1;

  // Create a UTC date for the Vancouver date, then subtract days
  const utcDate = Date.UTC(parts.year, parts.month - 1, parts.day, 12, 0, 0);
  const mondayUtc = new Date(utcDate - daysToSubtract * 24 * 60 * 60 * 1000);

  // Format as YYYY-MM-DD
  const y = mondayUtc.getUTCFullYear();
  const m = String(mondayUtc.getUTCMonth() + 1).padStart(2, '0');
  const d = String(mondayUtc.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Returns the previous week's Monday key.
 */
function getPreviousWeekKey(input = new Date()) {
  const currentWeekKey = weekStartMondayKey(input);
  const [y, m, d] = currentWeekKey.split('-').map(Number);
  const mondayDate = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
  const prevMondayDate = new Date(mondayDate.getTime() - 7 * 24 * 60 * 60 * 1000);

  const py = prevMondayDate.getUTCFullYear();
  const pm = String(prevMondayDate.getUTCMonth() + 1).padStart(2, '0');
  const pd = String(prevMondayDate.getUTCDate()).padStart(2, '0');
  return `${py}-${pm}-${pd}`;
}

/**
 * Returns the season ID (year string) for a given date.
 * Season is determined by the year when the season started.
 */
function seasonIdForDate(input = new Date()) {
  const date = input instanceof Date ? input : new Date(input);
  const parts = getVancouverDateParts(date);

  // If we're before May 1, we're in the previous year's season (which would be ended)
  // If we're after Oct 31, we're in the off-season (between seasons)
  // Season ID is always the year the season runs in
  return String(parts.year);
}

/**
 * Returns the season window { start: Date, end: Date } for a given date's season.
 */
function seasonWindowFor(input = new Date()) {
  const seasonId = seasonIdForDate(input);
  const year = Number(seasonId);

  const start = localVancouverToUtcDate(year, kSeasonStartMonth, kSeasonStartDay, 0, 0);
  const end = localVancouverToUtcDate(year, kSeasonEndMonth, kSeasonEndDay, 23, 59);

  return { start, end };
}

/**
 * Checks if a given date falls within the active season.
 */
function isInSeason(input = new Date()) {
  const date = input instanceof Date ? input : new Date(input);
  const parts = getVancouverDateParts(date);

  // Check month boundaries (May through October, inclusive)
  if (parts.month < kSeasonStartMonth || parts.month > kSeasonEndMonth) {
    return false;
  }

  // Check day boundaries for edge months
  if (parts.month === kSeasonStartMonth && parts.day < kSeasonStartDay) {
    return false;
  }
  if (parts.month === kSeasonEndMonth && parts.day > kSeasonEndDay) {
    return false;
  }

  return true;
}

/**
 * Returns the milestone level for a given week count.
 * Returns 0 if no milestone reached, otherwise the highest milestone achieved.
 */
function milestoneFor(weeks) {
  let milestone = 0;
  for (const m of kMilestones) {
    if (weeks >= m) milestone = m;
  }
  return milestone;
}

/**
 * Checks if a game is an outdoor round (counts for streaks).
 * Indoor/sim rounds do not count.
 */
function isOutdoorRound(gameData) {
  if (!gameData) return false;

  // Explicitly marked as sim/indoor
  if (gameData.is_sim === true) return false;
  if (gameData.venue_type === 'indoor') return false;
  if (gameData.venue_type === 'simulator') return false;

  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// ORCHESTRATORS — Called from confirmation_flow.js
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Called when a game transitions to 'played' status.
 * Adds the week key to streak_weeks_pending for all participants.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} gameId
 * @param {FirebaseFirestore.Timestamp|Date} teeTime
 * @param {string[]} playerUids - All app user UIDs in the game
 * @param {Object} gameData - Game document data
 */
async function onRoundPending(db, gameId, teeTime, playerUids, gameData) {
  // Skip non-outdoor rounds
  if (!isOutdoorRound(gameData)) {
    console.log(`[Streaks] onRoundPending: game ${gameId} is not outdoor, skipping`);
    return;
  }

  // Convert tee time to Date
  const teeDate = teeTime instanceof Date ? teeTime :
    (teeTime && typeof teeTime.toDate === 'function' ? teeTime.toDate() : new Date(teeTime));

  // Skip off-season rounds
  if (!isInSeason(teeDate)) {
    console.log(`[Streaks] onRoundPending: game ${gameId} is off-season, skipping`);
    return;
  }

  const weekKey = weekStartMondayKey(teeDate);

  if (!playerUids || playerUids.length === 0) {
    console.log(`[Streaks] onRoundPending: game ${gameId} has no players, skipping`);
    return;
  }

  // Batch update all players (use set with merge to handle missing docs gracefully)
  const batch = db.batch();
  for (const uid of playerUids) {
    const userRef = db.collection('users').doc(uid);
    batch.set(userRef, {
      streak_weeks_pending: admin.firestore.FieldValue.arrayUnion(weekKey),
    }, { merge: true });
  }

  try {
    await batch.commit();
    console.log(
      `[Streaks] onRoundPending: added week ${weekKey} to pending for ${playerUids.length} player(s) in game ${gameId}`
    );
  } catch (err) {
    console.error(`[Streaks] onRoundPending: batch failed for game ${gameId}:`, err);
  }
}

/**
 * Called when round verification completes.
 * Processes streak updates for all present players.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {FirebaseFirestore.DocumentReference} gameRef
 * @param {FirebaseFirestore.Timestamp|Date} teeTime
 * @param {string[]} presentUids - UIDs of players marked present
 */
async function onRoundVerified(db, gameRef, teeTime, presentUids) {
  // Fetch game data
  let gameData = {};
  try {
    const gameSnap = await gameRef.get();
    if (gameSnap.exists) gameData = gameSnap.data();
  } catch (err) {
    console.warn(`[Streaks] onRoundVerified: could not fetch game data:`, err);
    return;
  }

  // Skip non-outdoor rounds
  if (!isOutdoorRound(gameData)) {
    console.log(`[Streaks] onRoundVerified: game ${gameRef.id} is not outdoor, skipping`);
    return;
  }

  // Convert tee time to Date
  const teeDate = teeTime instanceof Date ? teeTime :
    (teeTime && typeof teeTime.toDate === 'function' ? teeTime.toDate() : new Date(teeTime));

  // Skip off-season rounds
  if (!isInSeason(teeDate)) {
    console.log(`[Streaks] onRoundVerified: game ${gameRef.id} is off-season, skipping`);
    return;
  }

  const weekKey = weekStartMondayKey(teeDate);
  const currentSeasonId = seasonIdForDate(teeDate);

  if (!presentUids || presentUids.length === 0) {
    console.log(`[Streaks] onRoundVerified: no present players, skipping`);
    return;
  }

  // Process each present player in a transaction
  const notificationsToSend = [];

  for (const uid of presentUids) {
    try {
      const result = await _processVerifiedRoundForUser(db, uid, weekKey, currentSeasonId);
      if (result.notification) {
        notificationsToSend.push({ uid, ...result.notification });
      }
    } catch (err) {
      console.error(`[Streaks] onRoundVerified: error processing user ${uid}:`, err);
    }
  }

  // Queue notifications after all commits (avoid duplicate emits on retry)
  for (const notif of notificationsToSend) {
    try {
      await routeNotification({
        eventId: randomUUID(),
        eventType: notif.eventType,
        recipientUserId: notif.uid,
        sourceId: notif.uid,
        data: notif.data || {},
      }, db);
    } catch (err) {
      console.warn(`[Streaks] onRoundVerified: failed to send ${notif.eventType} to ${notif.uid}:`, err);
    }
  }

  console.log(
    `[Streaks] onRoundVerified: processed ${presentUids.length} player(s) for week ${weekKey}`
  );
}

/**
 * Processes streak update for a single user in a transaction.
 * Returns { notification } if a notification should be sent.
 */
async function _processVerifiedRoundForUser(db, uid, weekKey, currentSeasonId) {
  const userRef = db.collection('users').doc(uid);

  return db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) {
      console.warn(`[Streaks] _processVerifiedRoundForUser: user ${uid} not found`);
      return { notification: null };
    }

    const userData = userSnap.data();

    // Initialize streak fields if needed
    let currentWeeks = userData.streak_current_weeks || 0;
    let previousWeeks = userData.streak_previous_weeks || null;
    let longestWeeks = userData.streak_longest_weeks || 0;
    let userSeasonId = userData.streak_season_id || null;
    let weeksPlayed = Array.isArray(userData.streak_weeks_played) ? [...userData.streak_weeks_played] : [];
    let weeksPending = Array.isArray(userData.streak_weeks_pending) ? [...userData.streak_weeks_pending] : [];
    let freezeEarned = userData.streak_freeze_earned || false;
    let freezeUsed = userData.streak_freeze_used || false;
    let milestoneLevel = userData.streak_milestone_level || 0;

    // Remove from pending
    weeksPending = weeksPending.filter(w => w !== weekKey);

    // Check for season mismatch (new season)
    if (userSeasonId !== currentSeasonId) {
      // Reset for new season, but this is the first week
      previousWeeks = currentWeeks > 0 ? currentWeeks : previousWeeks;
      currentWeeks = 1;
      weeksPlayed = [weekKey];
      freezeEarned = false;
      freezeUsed = false;
      milestoneLevel = 0;
      userSeasonId = currentSeasonId;

      const update = {
        streak_current_weeks: currentWeeks,
        streak_previous_weeks: previousWeeks,
        streak_longest_weeks: Math.max(longestWeeks, 1),
        streak_season_id: userSeasonId,
        streak_weeks_played: weeksPlayed,
        streak_weeks_pending: weeksPending,
        streak_last_completed_week_key: weekKey,
        streak_freeze_earned: freezeEarned,
        streak_freeze_used: freezeUsed,
        streak_freeze_used_week_key: null,
        streak_milestone_level: 0,
        streak_notif_state: {},
      };

      transaction.update(userRef, update);
      return { notification: null };
    }

    // Week already played - idempotent
    if (weeksPlayed.includes(weekKey)) {
      // Just remove from pending if it was there
      transaction.update(userRef, {
        streak_weeks_pending: weeksPending,
      });
      return { notification: null };
    }

    // Add week to played
    weeksPlayed.push(weekKey);
    weeksPlayed.sort(); // Keep sorted

    // Recompute consecutive streak
    const { consecutiveWeeks, lastWeekKey } = _computeConsecutiveStreak(weeksPlayed, userData.streak_freeze_used_week_key);
    currentWeeks = consecutiveWeeks;

    // Update longest
    longestWeeks = Math.max(longestWeeks, currentWeeks);

    // Check freeze unlock
    const wasFrezeEarned = freezeEarned;
    if (!freezeEarned && currentWeeks >= kFreezeUnlockThreshold) {
      freezeEarned = true;
    }

    // Check milestone
    const newMilestone = milestoneFor(currentWeeks);
    const milestoneReached = newMilestone > milestoneLevel;
    milestoneLevel = newMilestone;

    const update = {
      streak_current_weeks: currentWeeks,
      streak_longest_weeks: longestWeeks,
      streak_weeks_played: weeksPlayed,
      streak_weeks_pending: weeksPending,
      streak_last_completed_week_key: lastWeekKey,
      streak_freeze_earned: freezeEarned,
      streak_milestone_level: milestoneLevel,
    };

    transaction.update(userRef, update);

    // Determine notification to send
    let notification = null;
    if (freezeEarned && !wasFrezeEarned) {
      notification = {
        eventType: 'streak_freeze_unlocked',
        data: { current_weeks: String(currentWeeks) },
      };
    } else if (milestoneReached && newMilestone > 0) {
      notification = {
        eventType: 'streak_milestone_reached',
        data: {
          current_weeks: String(currentWeeks),
          milestone: String(newMilestone),
        },
      };
    }

    return { notification };
  });
}

/**
 * Computes consecutive streak from sorted week keys.
 * A freeze used week is treated as a played week.
 */
function _computeConsecutiveStreak(weeksPlayed, freezeUsedWeekKey) {
  if (!weeksPlayed || weeksPlayed.length === 0) {
    return { consecutiveWeeks: 0, lastWeekKey: null };
  }

  // Include freeze week in the set
  const allWeeks = new Set(weeksPlayed);
  if (freezeUsedWeekKey) {
    allWeeks.add(freezeUsedWeekKey);
  }

  // Sort all weeks
  const sortedWeeks = Array.from(allWeeks).sort();

  // Find longest consecutive chain ending at the most recent week
  let streak = 1;
  let lastWeek = sortedWeeks[sortedWeeks.length - 1];

  for (let i = sortedWeeks.length - 2; i >= 0; i--) {
    const currentWeek = sortedWeeks[i];
    const nextWeek = sortedWeeks[i + 1];

    // Check if consecutive (next week should be exactly 7 days after current)
    const [cy, cm, cd] = currentWeek.split('-').map(Number);
    const [ny, nm, nd] = nextWeek.split('-').map(Number);

    const currentDate = new Date(Date.UTC(cy, cm - 1, cd));
    const nextDate = new Date(Date.UTC(ny, nm - 1, nd));
    const diffDays = (nextDate.getTime() - currentDate.getTime()) / (24 * 60 * 60 * 1000);

    if (Math.abs(diffDays - 7) < 0.5) {
      streak++;
    } else {
      break;
    }
  }

  return { consecutiveWeeks: streak, lastWeekKey: lastWeek };
}

/**
 * Clears pending weeks for all participants after verification.
 * Called after onRoundVerified to clean up no-shows.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {FirebaseFirestore.DocumentReference} gameRef
 * @param {FirebaseFirestore.Timestamp|Date} teeTime
 */
async function clearPendingForAllParticipants(db, gameRef, teeTime) {
  // Convert tee time to Date
  const teeDate = teeTime instanceof Date ? teeTime :
    (teeTime && typeof teeTime.toDate === 'function' ? teeTime.toDate() : new Date(teeTime));

  const weekKey = weekStartMondayKey(teeDate);

  // Query all participants for this game
  const participantsSnap = await db
    .collection('game_participants')
    .where('game_ref', '==', gameRef)
    .get();

  const batch = db.batch();
  let count = 0;

  for (const doc of participantsSnap.docs) {
    const data = doc.data();
    const userRef = data.user_ref;
    if (userRef && typeof userRef.id === 'string') {
      // Use set with merge to handle missing docs gracefully
      batch.set(userRef, {
        streak_weeks_pending: admin.firestore.FieldValue.arrayRemove(weekKey),
      }, { merge: true });
      count++;
    }
  }

  if (count > 0) {
    await batch.commit();
    console.log(`[Streaks] clearPendingForAllParticipants: cleared week ${weekKey} from ${count} participant(s)`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE — deployStreakFreeze
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for deployStreakFreeze callable.
 *
 * Input: { weekKey: string }
 * Output: { success: boolean, streakCurrentWeeks: number, freezeUsed: boolean }
 */
async function _deployStreakFreezeHandler(data, context, db) {
  const HttpsError = functions.https.HttpsError;

  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { weekKey } = data || {};
  const now = new Date();

  // 1. Validate in-season
  if (!isInSeason(now)) {
    throw new HttpsError("failed-precondition", "Streak freeze can only be used during the season (May 1 - Oct 31).");
  }

  // 2. Validate weekKey is current week
  const currentWeekKey = weekStartMondayKey(now);
  if (typeof weekKey !== 'string' || weekKey !== currentWeekKey) {
    throw new HttpsError("invalid-argument", `Freeze can only be used for the current week (${currentWeekKey}).`);
  }

  const uid = context.auth.uid;
  const userRef = db.collection('users').doc(uid);
  const currentSeasonId = seasonIdForDate(now);

  // Run transaction for atomic freeze deployment
  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User not found.");
    }

    const userData = userSnap.data();

    // 3. Validate season matches
    if (userData.streak_season_id !== currentSeasonId) {
      throw new HttpsError("failed-precondition", "No active streak in current season.");
    }

    // 4. Validate freeze earned
    if (userData.streak_freeze_earned !== true) {
      throw new HttpsError("failed-precondition", "Freeze not yet earned. Reach 4 consecutive weeks first.");
    }

    // 5. Validate freeze not used
    if (userData.streak_freeze_used === true) {
      throw new HttpsError("failed-precondition", "Freeze has already been used this season.");
    }

    // 6. Validate week not already played
    const weeksPlayed = Array.isArray(userData.streak_weeks_played) ? userData.streak_weeks_played : [];
    if (weeksPlayed.includes(weekKey)) {
      throw new HttpsError("failed-precondition", "You've already played this week. Freeze not needed.");
    }

    // Deploy freeze
    const newWeeksPlayed = [...weeksPlayed, weekKey].sort();

    transaction.update(userRef, {
      streak_freeze_used: true,
      streak_freeze_used_week_key: weekKey,
      streak_weeks_played: newWeeksPlayed,
      streak_last_completed_week_key: weekKey,
    });

    return {
      status: 'ok',
      streakCurrentWeeks: userData.streak_current_weeks || 0,
      freezeUsed: true,
    };
  });

  console.log(`[Streaks] deployStreakFreeze: user ${uid} used freeze for week ${weekKey}`);

  return result;
}

/**
 * Callable: deployStreakFreeze
 */
const deployStreakFreeze = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    try {
      return await _deployStreakFreezeHandler(data, context, db);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError(
        "internal",
        `Failed to deploy streak freeze: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULED JOB HANDLERS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Friday 18:00 nudge handler.
 * Sends nudge to users with active streak who haven't played current week.
 */
async function fridayNudgeHandler(db = null) {
  if (!db) db = admin.firestore();
  const now = new Date();

  if (!isInSeason(now)) {
    console.log('[Streaks] fridayNudgeHandler: off-season, skipping');
    return { skipped: true, reason: 'off-season' };
  }

  const currentWeekKey = weekStartMondayKey(now);
  const currentSeasonId = seasonIdForDate(now);
  const dedupeKey = `friday_${currentWeekKey}`;

  // Query users with active streak in current season
  const usersSnap = await db.collection('users')
    .where('streak_season_id', '==', currentSeasonId)
    .where('streak_current_weeks', '>', 0)
    .get();

  let nudgedCount = 0;

  for (const doc of usersSnap.docs) {
    const userData = doc.data();
    const uid = doc.id;

    // Skip if already played current week
    const weeksPlayed = Array.isArray(userData.streak_weeks_played) ? userData.streak_weeks_played : [];
    if (weeksPlayed.includes(currentWeekKey)) continue;

    // Skip if already notified
    const notifState = userData.streak_notif_state || {};
    if (notifState[dedupeKey] === true) continue;

    // Check if user has a scheduled game this week (optional enhancement)
    // For V1, we just send the nudge to everyone without current week play

    try {
      await routeNotification({
        eventId: randomUUID(),
        eventType: 'streak_weekend_nudge',
        recipientUserId: uid,
        sourceId: uid,
        data: {
          current_weeks: String(userData.streak_current_weeks || 0),
        },
      }, db);

      // Mark as notified
      await doc.ref.update({
        [`streak_notif_state.${dedupeKey}`]: true,
      });

      nudgedCount++;
    } catch (err) {
      console.warn(`[Streaks] fridayNudgeHandler: failed to nudge ${uid}:`, err);
    }
  }

  console.log(`[Streaks] fridayNudgeHandler: nudged ${nudgedCount} user(s)`);
  return { nudgedCount };
}

/**
 * Sunday 20:00 freeze prompt handler.
 * Sends freeze prompt to users who have freeze available but haven't played.
 */
async function sundayPromptHandler(db = null) {
  if (!db) db = admin.firestore();
  const now = new Date();

  if (!isInSeason(now)) {
    console.log('[Streaks] sundayPromptHandler: off-season, skipping');
    return { skipped: true, reason: 'off-season' };
  }

  const currentWeekKey = weekStartMondayKey(now);
  const currentSeasonId = seasonIdForDate(now);
  const dedupeKey = `sunday_${currentWeekKey}`;

  // Query users with freeze available
  const usersSnap = await db.collection('users')
    .where('streak_season_id', '==', currentSeasonId)
    .where('streak_freeze_earned', '==', true)
    .where('streak_freeze_used', '==', false)
    .get();

  let promptedCount = 0;

  for (const doc of usersSnap.docs) {
    const userData = doc.data();
    const uid = doc.id;

    // Skip if already played current week
    const weeksPlayed = Array.isArray(userData.streak_weeks_played) ? userData.streak_weeks_played : [];
    if (weeksPlayed.includes(currentWeekKey)) continue;

    // Skip if already notified
    const notifState = userData.streak_notif_state || {};
    if (notifState[dedupeKey] === true) continue;

    try {
      await routeNotification({
        eventId: randomUUID(),
        eventType: 'streak_freeze_prompt',
        recipientUserId: uid,
        sourceId: uid,
        data: {
          current_weeks: String(userData.streak_current_weeks || 0),
        },
      }, db);

      // Mark as notified
      await doc.ref.update({
        [`streak_notif_state.${dedupeKey}`]: true,
      });

      promptedCount++;
    } catch (err) {
      console.warn(`[Streaks] sundayPromptHandler: failed to prompt ${uid}:`, err);
    }
  }

  console.log(`[Streaks] sundayPromptHandler: prompted ${promptedCount} user(s)`);
  return { promptedCount };
}

/**
 * Monday 00:01 rollover handler.
 * Breaks streaks for users who didn't play the previous week.
 */
async function mondayRolloverHandler(db = null) {
  if (!db) db = admin.firestore();
  const now = new Date();

  // Even if off-season, run cleanup
  const previousWeekKey = getPreviousWeekKey(now);
  const currentWeekKey = weekStartMondayKey(now);
  const currentSeasonId = seasonIdForDate(now);
  const dedupeKey = `monday_${currentWeekKey}`;

  // Query users with active streak
  const usersSnap = await db.collection('users')
    .where('streak_season_id', '==', currentSeasonId)
    .where('streak_current_weeks', '>', 0)
    .get();

  let brokenCount = 0;
  const notificationsToSend = [];

  for (const doc of usersSnap.docs) {
    const userData = doc.data();
    const uid = doc.id;

    const weeksPlayed = Array.isArray(userData.streak_weeks_played) ? userData.streak_weeks_played : [];
    const weeksPending = Array.isArray(userData.streak_weeks_pending) ? userData.streak_weeks_pending : [];
    const freezeUsedWeekKey = userData.streak_freeze_used_week_key;

    // Precedence check:
    // 1. Previous week in weeks_played → no-op
    if (weeksPlayed.includes(previousWeekKey)) continue;

    // 2. Freeze used for previous week → no-op
    if (freezeUsedWeekKey === previousWeekKey) continue;

    // 3. Previous week in weeks_pending → no-op (verification still in flight)
    if (weeksPending.includes(previousWeekKey)) continue;

    // 4. Break the streak
    try {
      await doc.ref.update({
        streak_previous_weeks: userData.streak_current_weeks,
        streak_current_weeks: 0,
        streak_last_completed_week_key: null,
      });

      brokenCount++;
      notificationsToSend.push({ uid, previousWeeks: userData.streak_current_weeks });
    } catch (err) {
      console.error(`[Streaks] mondayRolloverHandler: failed to break streak for ${uid}:`, err);
    }
  }

  // Send broken notifications
  for (const { uid, previousWeeks } of notificationsToSend) {
    try {
      await routeNotification({
        eventId: randomUUID(),
        eventType: 'streak_broken',
        recipientUserId: uid,
        sourceId: uid,
        data: {
          previous_weeks: String(previousWeeks),
        },
      }, db);
    } catch (err) {
      console.warn(`[Streaks] mondayRolloverHandler: failed to notify ${uid}:`, err);
    }
  }

  // Cleanup: prune stale pending (>14 days) and old weekly dedupe keys (>4 weeks)
  await _pruneStaleData(db, currentWeekKey);

  console.log(`[Streaks] mondayRolloverHandler: broke ${brokenCount} streak(s)`);
  return { brokenCount };
}

/**
 * Prunes stale pending weeks and old notification dedupe keys.
 * Uses pagination to process all users regardless of count.
 */
async function _pruneStaleData(db, currentWeekKey) {
  // Calculate cutoff week key (4 weeks ago) using direct arithmetic
  // currentWeekKey is already a Monday in YYYY-MM-DD format
  const [y, m, d] = currentWeekKey.split('-').map(Number);
  // Subtract exactly 28 days in UTC (no timezone conversion needed)
  const cutoffDate = new Date(Date.UTC(y, m - 1, d - 28));
  const cutoffWeekKey = `${cutoffDate.getUTCFullYear()}-${String(cutoffDate.getUTCMonth() + 1).padStart(2, '0')}-${String(cutoffDate.getUTCDate()).padStart(2, '0')}`;

  let lastDoc = null;
  let totalPruneCount = 0;

  // Paginate through all users with streak data
  while (true) {
    let query = db.collection('users')
      .where('streak_season_id', '!=', null)
      .limit(kBatchChunkSize);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const usersSnap = await query.get();
    if (usersSnap.empty) break;

    const batch = db.batch();
    let pruneCount = 0;

    for (const doc of usersSnap.docs) {
      const userData = doc.data();
      const weeksPending = Array.isArray(userData.streak_weeks_pending) ? userData.streak_weeks_pending : [];
      const notifState = userData.streak_notif_state || {};

      // Prune stale pending weeks
      const freshPending = weeksPending.filter(w => w >= cutoffWeekKey);
      const pendingChanged = freshPending.length !== weeksPending.length;

      // Prune old weekly dedupe keys
      const freshNotifState = {};
      let notifChanged = false;
      for (const [key, value] of Object.entries(notifState)) {
        // Keep milestone_ and freeze_unlocked keys
        if (key.startsWith('milestone_') || key === 'freeze_unlocked') {
          freshNotifState[key] = value;
          continue;
        }
        // Weekly keys: friday_, sunday_, monday_
        const weekMatch = key.match(/^(friday|sunday|monday)_(.+)$/);
        if (weekMatch && weekMatch[2] < cutoffWeekKey) {
          notifChanged = true;
          continue;
        }
        freshNotifState[key] = value;
      }

      if (pendingChanged || notifChanged) {
        const update = {};
        if (pendingChanged) update.streak_weeks_pending = freshPending;
        if (notifChanged) update.streak_notif_state = freshNotifState;
        batch.update(doc.ref, update);
        pruneCount++;
      }
    }

    if (pruneCount > 0) {
      await batch.commit();
      totalPruneCount += pruneCount;
    }

    lastDoc = usersSnap.docs[usersSnap.docs.length - 1];
  }

  if (totalPruneCount > 0) {
    console.log(`[Streaks] _pruneStaleData: pruned stale data for ${totalPruneCount} user(s)`);
  }
}

/**
 * Season close handler (Nov 1 00:05).
 * Resets streak state for the ending season.
 */
async function seasonCloseHandler(db = null) {
  if (!db) db = admin.firestore();
  const now = new Date();

  // Determine the ending season (previous year if we're in January, otherwise current year)
  const parts = getVancouverDateParts(now);
  const endingSeasonId = String(parts.year);

  // Query users with data from the ending season
  const usersSnap = await db.collection('users')
    .where('streak_season_id', '==', endingSeasonId)
    .get();

  // Collect updates for chunked batch processing
  const updates = [];

  for (const doc of usersSnap.docs) {
    const userData = doc.data();
    const currentWeeks = userData.streak_current_weeks || 0;

    const update = {
      streak_previous_weeks: currentWeeks > 0 ? currentWeeks : (userData.streak_previous_weeks || null),
      streak_current_weeks: 0,
      streak_last_completed_week_key: null,
      streak_weeks_played: [],
      streak_weeks_pending: [],
      streak_freeze_earned: false,
      streak_freeze_used: false,
      streak_freeze_used_week_key: null,
      streak_milestone_level: 0,
      streak_notif_state: {},
      // Keep streak_longest_weeks (lifetime)
      // Keep streak_season_id (will be updated on first new-season round)
    };

    updates.push({ ref: doc.ref, data: update });
  }

  if (updates.length > 0) {
    await commitInChunks(db, updates);
  }

  const resetCount = updates.length;

  console.log(`[Streaks] seasonCloseHandler: reset ${resetCount} user(s) for season ${endingSeasonId}`);
  return { resetCount, seasonId: endingSeasonId };
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────────

module.exports = {
  // Callable (wrapped)
  deployStreakFreeze,

  // Raw handler for testing
  _deployStreakFreezeHandler,

  // Orchestrators (called from confirmation_flow.js)
  onRoundPending,
  onRoundVerified,
  clearPendingForAllParticipants,

  // Scheduled job handlers (used by index.js pubsub wrappers)
  fridayNudgeHandler,
  sundayPromptHandler,
  mondayRolloverHandler,
  seasonCloseHandler,

  // Timezone utilities (exported for testing)
  weekStartMondayKey,
  getPreviousWeekKey,
  seasonIdForDate,
  seasonWindowFor,
  isInSeason,
  milestoneFor,
  isOutdoorRound,
  getVancouverDateParts,
  getVancouverOffsetMinutes,
  localVancouverToUtcDate,
  getVancouverIsoWeekday,

  // Internal helpers (exported for testing)
  _computeConsecutiveStreak,
  _processVerifiedRoundForUser,
  _pruneStaleData,
};
