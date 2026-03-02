/**
 * Cleanup module for expired cancelled games and chats.
 *
 * Provides scheduled functions that permanently delete:
 * - Cancelled games that have passed their expiration threshold
 * - Chats scheduled for deletion (deletesAt <= now)
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

/**
 * Handler for cleaning up chats scheduled for deletion.
 *
 * Queries chats where deletesAt <= now and deletes them along with
 * their messages subcollection.
 *
 * This is triggered when a game is cancelled - the chat is marked
 * with deletesAt = cancellation_date + 3 days.
 *
 * @returns {Object} Summary of cleanup results
 */
async function cleanupScheduledChatsHandler() {
  const db = admin.firestore();

  const now = admin.firestore.Timestamp.now();

  console.log(`[cleanupScheduledChats] Starting cleanup. Deleting chats with deletesAt <= ${now.toDate().toISOString()}`);

  // Query chats scheduled for deletion
  const chatsQuery = db.collection("chats")
    .where("deletesAt", "<=", now);

  const chatsSnapshot = await chatsQuery.get();

  if (chatsSnapshot.empty) {
    console.log("[cleanupScheduledChats] No chats to clean up");
    return {
      deleted: 0,
      errors: 0,
      messagesDeleted: 0,
    };
  }

  console.log(`[cleanupScheduledChats] Found ${chatsSnapshot.size} chats to delete`);

  let deleted = 0;
  let errors = 0;
  let messagesDeleted = 0;

  for (const chatDoc of chatsSnapshot.docs) {
    try {
      // Delete messages subcollection first (in batches of 500)
      const messagesRef = chatDoc.ref.collection("messages");
      let messagesSnapshot = await messagesRef.limit(500).get();

      while (!messagesSnapshot.empty) {
        const batch = db.batch();
        messagesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        messagesDeleted += messagesSnapshot.size;
        messagesSnapshot = await messagesRef.limit(500).get();
      }

      // Delete chatRefs for all members
      const chatData = chatDoc.data();
      const memberIds = chatData.memberIds || [];

      if (memberIds.length > 0) {
        const batch = db.batch();
        for (const memberId of memberIds) {
          const chatRefDoc = db.collection("users").doc(memberId).collection("chatRefs").doc(chatDoc.id);
          batch.delete(chatRefDoc);
        }
        await batch.commit();
      }

      // Delete the chat document itself
      await chatDoc.ref.delete();
      deleted++;

      console.log(
        `[cleanupScheduledChats] Deleted chat ${chatDoc.id} (${memberIds.length} members)`
      );
    } catch (error) {
      errors++;
      console.error(`[cleanupScheduledChats] Failed to delete chat ${chatDoc.id}:`, error);
    }
  }

  const summary = {
    deleted,
    errors,
    messagesDeleted,
  };

  console.log(`[cleanupScheduledChats] Cleanup complete:`, summary);
  return summary;
}

module.exports = {
  cleanupCancelledGamesHandler,
  cleanupScheduledChatsHandler,
};
