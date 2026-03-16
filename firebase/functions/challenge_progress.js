'use strict';

/**
 * Challenge Progress — Evaluates challenge progress on every verified round.
 *
 * Called from _finalizeRoundVerification in confirmation_flow.js as a non-fatal
 * step in the post-round verification pipeline.
 *
 * Algorithm:
 *   1. Read game doc (courseRef, game_type, is_2v2, has_side_games)
 *   2. Cache courses collection count for grand_tour dynamic target
 *   3. For each present user (parallelized):
 *      a. Read user doc (streaks, unique_co_players)
 *      b. Read challenge_progress map from user doc
 *      c. Read partner_plays subcollection
 *      d. Evaluate all 24 challenge definitions
 *      e. Write updated challenge_progress map
 *      f. Send notification for newly completed challenges
 *
 * Idempotency: Checks _lastProcessedRound sentinel before processing.
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

const admin = require('firebase-admin');
const { randomUUID } = require('crypto');
const { CHALLENGES } = require('./challenge_definitions');
const { routeNotification } = require('./notifications/trust/router');

// ── Main Entry Point ────────────────────────────────────────────────────────

/**
 * Evaluates challenge progress for all present users after round verification.
 *
 * @param {FirebaseFirestore.Firestore} db - Firestore instance
 * @param {FirebaseFirestore.DocumentReference} gameRef - Reference to the game doc
 * @param {object} roundData - Round record data (tee_time, participant_snapshots, etc.)
 * @param {string[]} presentUids - UIDs of users who were present
 */
async function onRoundVerified(db, gameRef, roundData, presentUids) {
  if (!presentUids || presentUids.length === 0) {
    console.log('[Challenges] onRoundVerified: no present users, skipping');
    return;
  }

  // 1. Read game doc
  let gameData = {};
  try {
    const gameSnap = await gameRef.get();
    if (gameSnap.exists) gameData = gameSnap.data();
  } catch (err) {
    console.warn('[Challenges] onRoundVerified: could not fetch game data:', err);
    return;
  }

  // 2. Cache courses count for grand_tour dynamic target
  let coursesCount = 0;
  try {
    const coursesSnap = await db.collection('courses').count().get();
    coursesCount = coursesSnap.data().count || 0;
  } catch (err) {
    // Non-fatal — grand_tour just won't complete this round
    console.warn('[Challenges] onRoundVerified: could not count courses:', err);
  }

  // 3. Process each present user in parallel
  const userPromises = presentUids.map((uid) =>
    _processUserChallenges(db, uid, gameRef, gameData, roundData, presentUids, coursesCount)
      .catch((err) => {
        console.warn(`[Challenges] onRoundVerified: failed for user ${uid}:`, err);
      })
  );

  await Promise.all(userPromises);

  console.log(
    `[Challenges] onRoundVerified: processed ${presentUids.length} users ` +
    `for game ${gameRef.id}`
  );
}

// ── Per-User Processing ─────────────────────────────────────────────────────

/**
 * Evaluates all challenges for a single user and writes progress updates.
 */
async function _processUserChallenges(db, uid, gameRef, gameData, roundData, presentUids, coursesCount) {
  const userRef = db.collection('users').doc(uid);

  // Read user doc
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.warn(`[Challenges] _processUserChallenges: user ${uid} not found`);
    return;
  }
  const userDoc = userSnap.data();

  // Read existing challenge_progress
  const currentProgress = userDoc.challenge_progress || {};

  // Idempotency check — skip if this round was already processed
  const roundId = roundData._roundRefId || gameRef.id;
  if (currentProgress._lastProcessedRound === roundId) {
    console.log(`[Challenges] _processUserChallenges: round ${roundId} already processed for ${uid}`);
    return;
  }

  // Read partner_plays subcollection
  let partnerPlays = [];
  try {
    const ppSnap = await userRef.collection('partner_plays').get();
    partnerPlays = ppSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (err) {
    console.warn(`[Challenges] _processUserChallenges: could not read partner_plays for ${uid}:`, err);
  }

  // Build evaluation context
  const ctx = {
    db,
    uid,
    gameData,
    roundData,
    userDoc,
    currentProgress,
    presentUids,
    partnerPlays,
    _coursesCount: coursesCount,
  };

  // Evaluate all challenges
  const updatedProgress = { ...currentProgress };
  const newlyCompleted = [];
  const nowTs = admin.firestore.Timestamp.now();

  for (const challenge of CHALLENGES) {
    try {
      const existing = currentProgress[challenge.id] || {};

      // Skip already completed challenges
      if (existing.completedAt) continue;

      // Evaluate (some are async)
      const result = await Promise.resolve(challenge.evaluate(ctx));

      // Build updated progress entry
      const entry = {
        current: result.current,
        target: result.target || challenge.target,
      };

      if (result.data !== undefined) {
        entry.data = result.data;
      }

      if (result.completed && !existing.completedAt) {
        entry.completedAt = nowTs;
        newlyCompleted.push(challenge);
      }

      updatedProgress[challenge.id] = entry;
    } catch (err) {
      // Individual challenge failure is non-fatal
      console.warn(`[Challenges] evaluate failed for ${challenge.id} (user ${uid}):`, err);
    }
  }

  // Write idempotency sentinel
  updatedProgress._lastProcessedRound = roundId;

  // Write updated progress to user doc
  await userRef.update({
    challenge_progress: updatedProgress,
    season_rounds_played: admin.firestore.FieldValue.increment(1),
  });

  // Send notifications for newly completed challenges
  for (const challenge of newlyCompleted) {
    try {
      await routeNotification({
        eventId:         randomUUID(),
        eventType:       'challenge_completed',
        recipientUserId: uid,
        sourceId:        gameRef.id,
        data:            { challenge_name: challenge.name, challenge_id: challenge.id },
      }, db);
    } catch (err) {
      // Non-fatal per notification
      console.warn(
        `[Challenges] notification failed for ${challenge.id} (user ${uid}):`, err
      );
    }
  }

  if (newlyCompleted.length > 0) {
    console.log(
      `[Challenges] user ${uid} completed: ${newlyCompleted.map((c) => c.id).join(', ')}`
    );
  }
}

// ── Exports ─────────────────────────────────────────────────────────────────

module.exports = {
  onRoundVerified,
};
