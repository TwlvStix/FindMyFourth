'use strict';

/**
 * Challenge Season Reset — Archives challenge progress and resets counters.
 *
 * Runs annually on March 1 via scheduled Cloud Function.
 * Archives the ending season's challenge_progress to a per-user subcollection,
 * then resets the user's progress map and season_rounds_played counter.
 *
 * Idempotency: Checks for existing archive doc before writing.
 * Does NOT clear unlocked_rewards — those persist across seasons.
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

const admin = require('firebase-admin');

// ── Main Entry Point ────────────────────────────────────────────────────────

/**
 * Archives challenge progress for the ending season and resets user state.
 *
 * @param {FirebaseFirestore.Firestore} [db] - Firestore instance (injectable for tests)
 * @returns {{ archived: number, seasonId: string }}
 */
async function challengeSeasonResetHandler(db = null) {
  if (!db) db = admin.firestore();

  // Ending season = previous year (this runs March 1)
  const endingSeasonId = String(new Date().getFullYear() - 1);

  console.log(`[challengeSeasonReset] Starting reset for season ${endingSeasonId}`);

  // Query users who have the ending season ID
  const usersSnap = await db.collection('users')
    .where('streak_season_id', '==', endingSeasonId)
    .get();

  console.log(`[challengeSeasonReset] Found ${usersSnap.size} users in season ${endingSeasonId}`);

  const archives = [];
  const resets = [];

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const progress = data.challenge_progress;
    if (!progress || Object.keys(progress).length === 0) continue;

    // Skip internal keys only
    const progressKeys = Object.keys(progress).filter((k) => !k.startsWith('_'));
    if (progressKeys.length === 0) continue;

    // Idempotency: skip if already archived
    const archiveRef = doc.ref.collection('challenge_history').doc(endingSeasonId);
    const existing = await archiveRef.get();
    if (existing.exists) continue;

    // Archive progress
    archives.push({
      ref: archiveRef,
      data: {
        challenge_progress: progress,
        season_rounds_played: data.season_rounds_played || 0,
        archived_at: admin.firestore.FieldValue.serverTimestamp(),
      },
    });

    // Reset user state (does NOT clear unlocked_rewards)
    resets.push({
      ref: doc.ref,
      data: {
        challenge_progress: {},
        season_rounds_played: 0,
      },
    });
  }

  // Batch write archives (creates)
  for (let i = 0; i < archives.length; i += 450) {
    const batch = db.batch();
    archives.slice(i, i + 450).forEach(({ ref, data }) => batch.set(ref, data));
    await batch.commit();
  }

  // Batch write resets (updates)
  for (let i = 0; i < resets.length; i += 450) {
    const batch = db.batch();
    resets.slice(i, i + 450).forEach(({ ref, data }) => batch.update(ref, data));
    await batch.commit();
  }

  // Reset metadata counter for the new season
  await db.collection('metadata').doc('season_stats').set(
    { active_user_count: 0 },
    { merge: true },
  );

  console.log(
    `[challengeSeasonReset] Done: archived ${archives.length} users, ` +
    `reset ${resets.length} users for season ${endingSeasonId}`,
  );

  return { archived: archives.length, seasonId: endingSeasonId };
}

// ── Exports ─────────────────────────────────────────────────────────────────

module.exports = {
  challengeSeasonResetHandler,
};
