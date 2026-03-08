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

  const BATCH_SIZE = 500;
  let deleted = 0;
  let errors = 0;
  let scheduledCount = 0;
  let flexibleCount = 0;
  let hasMore = true;

  while (hasMore) {
    const [scheduledGames, flexibleGames] = await Promise.all([
      db.collection("games")
        .where("isCancelled", "==", true)
        .where("schedule_type", "==", "scheduled")
        .where("date", "<", todayTimestamp)
        .limit(BATCH_SIZE)
        .get(),
      db.collection("games")
        .where("isCancelled", "==", true)
        .where("schedule_type", "==", "flexible")
        .where("cancelled_at", "<", todayTimestamp)
        .limit(BATCH_SIZE)
        .get(),
    ]);

    const allGames = [...scheduledGames.docs, ...flexibleGames.docs];
    if (allGames.length === 0) break;

    scheduledCount += scheduledGames.size;
    flexibleCount += flexibleGames.size;

    console.log(
      `[cleanupCancelledGames] Processing batch of ${allGames.length} games ` +
      `(${scheduledGames.size} scheduled, ${flexibleGames.size} flexible)`
    );

    // Phase 1: Parallel reads — fetch all participant subcollections concurrently
    const participantResults = await Promise.all(
      allGames.map(async (gameDoc) => {
        try {
          const participants = await gameDoc.ref.collection("game_participants").get();
          return { gameDoc, participants, error: null };
        } catch (error) {
          return { gameDoc, participants: null, error };
        }
      })
    );

    // Phase 2: Accumulate deletes into shared batches, flush at 450-op threshold
    const FLUSH_THRESHOLD = 450;
    let batch = db.batch();
    let opsInBatch = 0;
    let gamesInBatch = 0;

    for (const { gameDoc, participants, error: readError } of participantResults) {
      if (readError) {
        errors++;
        console.error(`[cleanupCancelledGames] Failed to read participants for game ${gameDoc.id}:`, readError);
        continue;
      }

      const opsForThisGame = participants.size + 1; // participants + game doc

      // Flush if adding this game would exceed threshold
      if (opsInBatch > 0 && opsInBatch + opsForThisGame > FLUSH_THRESHOLD) {
        try {
          await batch.commit();
          deleted += gamesInBatch;
        } catch (commitError) {
          errors += gamesInBatch;
          console.error(`[cleanupCancelledGames] Batch commit failed (${gamesInBatch} games):`, commitError);
        }
        batch = db.batch();
        opsInBatch = 0;
        gamesInBatch = 0;
      }

      participants.docs.forEach((doc) => batch.delete(doc.ref));
      batch.delete(gameDoc.ref);
      opsInBatch += opsForThisGame;
      gamesInBatch++;
    }

    // Flush remaining
    if (opsInBatch > 0) {
      try {
        await batch.commit();
        deleted += gamesInBatch;
      } catch (commitError) {
        errors += gamesInBatch;
        console.error(`[cleanupCancelledGames] Final batch commit failed (${gamesInBatch} games):`, commitError);
      }
    }

    // Deleted docs won't reappear — no cursor needed
    hasMore = scheduledGames.size === BATCH_SIZE || flexibleGames.size === BATCH_SIZE;
  }

  const summary = {
    deleted,
    errors,
    scheduledCount,
    flexibleCount,
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

  const BATCH_SIZE = 500;
  let deleted = 0;
  let errors = 0;
  let messagesDeleted = 0;
  let hasMore = true;

  while (hasMore) {
    // Query chats scheduled for deletion (paginated via deletion)
    const chatsSnapshot = await db.collection("chats")
      .where("deletesAt", "<=", now)
      .limit(BATCH_SIZE)
      .get();

    if (chatsSnapshot.empty) break;

    console.log(`[cleanupScheduledChats] Processing batch of ${chatsSnapshot.size} chats`);

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

    // Deleted docs won't reappear — no cursor needed
    hasMore = chatsSnapshot.size === BATCH_SIZE;
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
