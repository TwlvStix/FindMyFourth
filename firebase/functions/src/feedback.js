/**
 * feedback.js
 * Handles self-reported feedback and behavioral label backfilling.
 *
 * TWO SIGNAL TYPES:
 *
 * 1. Self-reported (immediate): Player submits "play again?" and rating
 *    after a round. Available right away but noisy — people say yes to be polite.
 *
 * 2. Behavioral (delayed): Did the player ACTUALLY play again with the same
 *    people within 30 days? Computed by a scheduled backfill job.
 *    This is your strongest training label.
 *
 * Use self-reported labels for early model training when you don't have enough
 * behavioral data. Transition to behavioral labels as your dataset grows.
 */

const admin = require("firebase-admin");
const db = admin.firestore();
const {
  FEEDBACK_SOURCES,
  BEHAVIORAL_BACKFILL_WINDOW_DAYS,
  daysBetween,
  logEvent,
  validateRequired,
  validateEnum,
} = require("./utils");

// ─────────────────────────────────────────────
// SUBMIT FEEDBACK (Self-Reported)
// ─────────────────────────────────────────────

/**
 * Records a player's self-reported feedback after a round.
 *
 * @param {Object} params
 * @param {string} params.round_id
 * @param {string} params.player_id
 * @param {boolean|null} params.play_again - "Would you play with this group again?"
 * @param {number|null} params.rating - 1–5 satisfaction rating
 * @param {string|null} params.text_feedback - Optional free text
 * @param {string} params.feedback_source - How the feedback was collected
 * @param {number} params.prompt_attempt_count - How many nudges before they responded
 * @returns {Promise<void>}
 */
async function submitFeedback({
  round_id,
  player_id,
  play_again = null,
  rating = null,
  text_feedback = null,
  feedback_source = "in_app_prompt",
  prompt_attempt_count = 1,
}) {
  validateRequired({ round_id, player_id }, ["round_id", "player_id"]);
  validateEnum(feedback_source, FEEDBACK_SOURCES, "feedback_source");

  if (rating !== null && (rating < 1 || rating > 5)) {
    throw new Error("Rating must be between 1 and 5");
  }

  // Get the round's completion time to calculate feedback delay
  const roundDoc = await db.collection("rounds").doc(round_id).get();
  if (!roundDoc.exists) {
    throw new Error(`Round ${round_id} not found`);
  }
  const roundData = roundDoc.data();

  // Calculate delay between round end and feedback submission
  const now = new Date();
  let feedbackDelayHours = null;
  if (roundData.completed_at) {
    const completedAt = roundData.completed_at.toDate
      ? roundData.completed_at.toDate()
      : new Date(roundData.completed_at);
    feedbackDelayHours = parseFloat(
      ((now.getTime() - completedAt.getTime()) / (1000 * 60 * 60)).toFixed(2)
    );
  }

  const feedbackData = {
    round_id,
    player_id,

    // ── Self-reported signals ──
    play_again_self_report: play_again,
    rating,
    optional_text_feedback: text_feedback,

    // ── Contextual signals ──
    feedback_timestamp: admin.firestore.FieldValue.serverTimestamp(),
    feedback_source,
    was_solicited: feedback_source !== "spontaneous",
    feedback_delay_hours: feedbackDelayHours,
    prompt_attempt_count,

    // ── Behavioral signals (backfilled later) ──
    actually_played_again_any: null,
    actually_played_again_same_players: null,
    days_until_next_round: null,
    next_round_id: null,
    behavioral_label_computed_at: null,

    // ── Metadata ──
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db
    .collection("rounds")
    .doc(round_id)
    .collection("feedback")
    .doc(player_id)
    .set(feedbackData, { merge: true });

  // Log the event
  await logEvent({
    event_type: "feedback_submitted",
    round_id,
    player_id,
    payload: {
      play_again_self_report: play_again,
      rating,
      feedback_source,
      feedback_delay_hours: feedbackDelayHours,
    },
  });
}

// ─────────────────────────────────────────────
// BEHAVIORAL BACKFILL (Scheduled Job)
// ─────────────────────────────────────────────

/**
 * Backfills behavioral labels for feedback documents.
 *
 * For each feedback doc without a behavioral label (or with a stale one),
 * this checks whether the player actually booked another round — and
 * specifically whether they played again with any of the SAME co-players.
 *
 * Run this as a scheduled Cloud Function (daily or weekly).
 *
 * LOGIC:
 * - Look at feedback docs where behavioral_label_computed_at is null
 * - For each, find the player's subsequent rounds within the backfill window
 * - Check for co-player overlap
 * - Write the behavioral labels back
 *
 * @returns {Promise<Object>} Summary: { processed, labeled, skipped }
 */
async function runBehavioralBackfill() {
  const now = new Date();
  const results = { processed: 0, labeled: 0, skipped: 0 };

  // Find feedback docs that need behavioral labels
  // These are docs where:
  //   1. behavioral_label_computed_at is null (never computed)
  //   2. The round happened at least BEHAVIORAL_BACKFILL_WINDOW_DAYS ago
  //      (so we've given the player enough time to rebook)
  const cutoffDate = new Date(
    now.getTime() - BEHAVIORAL_BACKFILL_WINDOW_DAYS * 24 * 60 * 60 * 1000
  );

  // Query all feedback docs that haven't been backfilled yet
  const feedbackSnapshot = await db
    .collectionGroup("feedback")
    .where("behavioral_label_computed_at", "==", null)
    .get();

  for (const feedbackDoc of feedbackSnapshot.docs) {
    results.processed++;

    const feedback = feedbackDoc.data();
    const roundId = feedback.round_id;
    const playerId = feedback.player_id;

    // Get the round to check its completion date
    const roundDoc = await db.collection("rounds").doc(roundId).get();
    if (!roundDoc.exists) {
      results.skipped++;
      continue;
    }

    const roundData = roundDoc.data();
    const completedAt = roundData.completed_at?.toDate?.()
      || (roundData.completed_at ? new Date(roundData.completed_at) : null);

    if (!completedAt) {
      results.skipped++;
      continue;
    }

    // Only backfill if enough time has passed since the round
    if (completedAt > cutoffDate) {
      results.skipped++;
      continue; // Too recent — wait for the full window
    }

    // Find who was in this round (co-players)
    const participantsSnapshot = await db
      .collection("rounds")
      .doc(roundId)
      .collection("participants")
      .where("participation_status", "==", "completed")
      .get();

    const coPlayerIds = participantsSnapshot.docs
      .map((doc) => doc.data().player_id)
      .filter((id) => id !== playerId);

    // Find this player's subsequent rounds within the backfill window
    const windowEnd = new Date(
      completedAt.getTime() + BEHAVIORAL_BACKFILL_WINDOW_DAYS * 24 * 60 * 60 * 1000
    );

    const subsequentRoundsSnapshot = await db
      .collectionGroup("participants")
      .where("player_id", "==", playerId)
      .where("participation_status", "==", "completed")
      .where("created_at", ">", admin.firestore.Timestamp.fromDate(completedAt))
      .where("created_at", "<", admin.firestore.Timestamp.fromDate(windowEnd))
      .get();

    let playedAgainAny = false;
    let playedAgainSamePlayers = false;
    let daysUntilNextRound = null;
    let nextRoundId = null;

    if (!subsequentRoundsSnapshot.empty) {
      playedAgainAny = true;

      // Find the earliest next round
      const subsequentRounds = subsequentRoundsSnapshot.docs
        .map((doc) => ({
          ...doc.data(),
          created_at_date: doc.data().created_at?.toDate?.()
            || new Date(doc.data().created_at),
        }))
        .sort((a, b) => a.created_at_date - b.created_at_date);

      const firstNext = subsequentRounds[0];
      nextRoundId = firstNext.round_id;
      daysUntilNextRound = daysBetween(completedAt, firstNext.created_at_date);

      // Check each subsequent round for co-player overlap
      for (const nextParticipation of subsequentRounds) {
        const nextRoundParticipants = await db
          .collection("rounds")
          .doc(nextParticipation.round_id)
          .collection("participants")
          .where("participation_status", "==", "completed")
          .get();

        const nextRoundPlayerIds = nextRoundParticipants.docs.map(
          (doc) => doc.data().player_id
        );

        const overlap = coPlayerIds.filter((id) =>
          nextRoundPlayerIds.includes(id)
        );

        if (overlap.length > 0) {
          playedAgainSamePlayers = true;
          // Use this round as the "next" if it has overlap
          nextRoundId = nextParticipation.round_id;
          daysUntilNextRound = daysBetween(
            completedAt,
            nextParticipation.created_at_date
          );
          break; // Found overlap, no need to keep looking
        }
      }
    }

    // Write behavioral labels back to the feedback doc
    await feedbackDoc.ref.update({
      actually_played_again_any: playedAgainAny,
      actually_played_again_same_players: playedAgainSamePlayers,
      days_until_next_round: daysUntilNextRound,
      next_round_id: nextRoundId,
      behavioral_label_computed_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log the backfill event
    await logEvent({
      event_type: "behavioral_label_updated",
      round_id: roundId,
      player_id: playerId,
      payload: {
        actually_played_again_any: playedAgainAny,
        actually_played_again_same_players: playedAgainSamePlayers,
        days_until_next_round: daysUntilNextRound,
      },
    });

    results.labeled++;
  }

  console.log(
    `Behavioral backfill complete: ${results.processed} processed, ` +
    `${results.labeled} labeled, ${results.skipped} skipped`
  );

  return results;
}

module.exports = {
  submitFeedback,
  runBehavioralBackfill,
};
