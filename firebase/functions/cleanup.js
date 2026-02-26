/**
 * Cleanup module for expired cancelled games.
 *
 * Provides a nightly scheduled function that permanently deletes
 * cancelled games that have passed their expiration threshold:
 * - Scheduled games: deleted after the scheduled date passes
 * - Flexible games: deleted after the cancellation date passes
 */

const admin = require("firebase-admin");

/**
 * Handler for cleaning up expired cancelled games.
 *
 * Deletion rules:
 * - Scheduled games: isCancelled=true AND date < today
 * - Flexible games: isCancelled=true AND cancelled_at < today
 *
 * Also deletes the game_participants subcollection for each game.
 *
 * @returns {Object} Summary of cleanup results
 */
async function cleanupCancelledGamesHandler() {
  const db = admin.firestore();

  // Start of today (midnight) in the function's timezone
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayTimestamp = admin.firestore.Timestamp.fromDate(today);

  console.log(`[cleanupCancelledGames] Starting cleanup. Deleting games expired before ${today.toISOString()}`);

  // Query 1: Cancelled scheduled games where game date < today
  const scheduledQuery = db.collection("games")
    .where("isCancelled", "==", true)
    .where("schedule_type", "==", "scheduled")
    .where("date", "<", todayTimestamp);

  // Query 2: Cancelled flexible games where cancelled_at < today
  const flexibleQuery = db.collection("games")
    .where("isCancelled", "==", true)
    .where("schedule_type", "==", "flexible")
    .where("cancelled_at", "<", todayTimestamp);

  const [scheduledGames, flexibleGames] = await Promise.all([
    scheduledQuery.get(),
    flexibleQuery.get(),
  ]);

  const allGames = [...scheduledGames.docs, ...flexibleGames.docs];

  if (allGames.length === 0) {
    console.log("[cleanupCancelledGames] No cancelled games to clean up");
    return {
      deleted: 0,
      errors: 0,
      scheduledCount: 0,
      flexibleCount: 0,
    };
  }

  console.log(
    `[cleanupCancelledGames] Found ${allGames.length} cancelled games to delete ` +
    `(${scheduledGames.size} scheduled, ${flexibleGames.size} flexible)`
  );

  let deleted = 0;
  let errors = 0;

  for (const gameDoc of allGames) {
    try {
      // Delete subcollection (game_participants) first
      const participants = await gameDoc.ref.collection("game_participants").get();

      const batch = db.batch();
      participants.docs.forEach((doc) => batch.delete(doc.ref));
      batch.delete(gameDoc.ref);

      await batch.commit();
      deleted++;

      console.log(
        `[cleanupCancelledGames] Deleted game ${gameDoc.id} (${participants.size} participants)`
      );
    } catch (error) {
      errors++;
      console.error(`[cleanupCancelledGames] Failed to delete game ${gameDoc.id}:`, error);
    }
  }

  const summary = {
    deleted,
    errors,
    scheduledCount: scheduledGames.size,
    flexibleCount: flexibleGames.size,
  };

  console.log(`[cleanupCancelledGames] Cleanup complete:`, summary);
  return summary;
}

module.exports = {
  cleanupCancelledGamesHandler,
};
