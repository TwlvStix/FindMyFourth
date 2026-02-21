/**
 * sync.js
 * Keeps denormalized collections in sync with the source of truth.
 *
 * TWO RESPONSIBILITIES:
 *
 * 1. player_rounds — A flattened, player-centric view of round participation.
 *    Enables fast trajectory queries like "show me all of Player X's rounds"
 *    without traversing nested subcollections.
 *
 * 2. BigQuery export — Marks flat event log entries as exported and
 *    provides a batch export function for Phase 3.
 */

const admin = require("firebase-admin");
const db = admin.firestore();
const { logEvent } = require("./utils");

// ─────────────────────────────────────────────
// SYNC PLAYER_ROUNDS
// ─────────────────────────────────────────────

/**
 * Upserts a denormalized player_rounds document.
 *
 * This should be called:
 *   - After a participant is added to a round
 *   - After a status change (completion, cancellation, no-show)
 *   - After feedback is submitted
 *   - After behavioral labels are backfilled
 *
 * The document ID is {playerId}_{roundId} for uniqueness.
 *
 * This is NOT the source of truth — it's a materialized view.
 * The subcollections under rounds/ remain authoritative.
 *
 * @param {string} roundId
 * @param {string} playerId
 * @returns {Promise<void>}
 */
async function syncPlayerRound(roundId, playerId) {
  const docId = `${playerId}_${roundId}`;

  // Gather data from multiple sources
  const [roundDoc, participantDoc, feedbackDoc] = await Promise.all([
    db.collection("rounds").doc(roundId).get(),
    db.collection("rounds").doc(roundId).collection("participants").doc(playerId).get(),
    db.collection("rounds").doc(roundId).collection("feedback").doc(playerId).get(),
  ]);

  if (!roundDoc.exists || !participantDoc.exists) {
    console.warn(`Cannot sync player_round: round or participant not found (${roundId}, ${playerId})`);
    return;
  }

  const round = roundDoc.data();
  const participant = participantDoc.data();
  const feedback = feedbackDoc.exists ? feedbackDoc.data() : null;

  // Get co-player IDs
  const participantsSnapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("participants")
    .get();

  const coPlayerIds = participantsSnapshot.docs
    .map((doc) => doc.data().player_id)
    .filter((id) => id !== playerId);

  // Get average vibe score for this player in this round
  const pairwiseSnapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("pairwiseMatches")
    .get();

  let avgVibeScore = null;
  if (!pairwiseSnapshot.empty) {
    const relevantPairs = pairwiseSnapshot.docs
      .map((doc) => doc.data())
      .filter(
        (pair) =>
          pair.player_a_id === playerId || pair.player_b_id === playerId
      );

    if (relevantPairs.length > 0) {
      const totalVibe = relevantPairs.reduce(
        (sum, pair) => sum + (pair.vibe_match_score || 0),
        0
      );
      avgVibeScore = parseFloat((totalVibe / relevantPairs.length).toFixed(4));
    }
  }

  const playerRoundData = {
    player_id: playerId,
    round_id: roundId,

    // Round context
    tee_time: round.tee_time,
    course_id: round.course_id,
    match_source: round.match_source,
    algorithm_version: round.algorithm_version,
    group_size: round.group_size,
    is_weekend: round.is_weekend,
    time_of_day_bucket: round.time_of_day_bucket,

    // Participant context
    role: participant.role,
    participation_status: participant.participation_status,
    co_player_ids: coPlayerIds,
    handicap_at_booking: participant.handicap_at_booking,
    days_since_last_round: participant.days_since_last_round,
    is_returning_after_gap: participant.is_returning_after_gap,

    // Cancellation signals
    cancelled_after_seeing_group: participant.cancelled_after_seeing_group || null,
    cancellation_reason: participant.cancellation_reason || null,

    // Match quality
    avg_vibe_score_in_group: avgVibeScore,

    // Feedback (self-reported)
    self_reported_rating: feedback?.rating || null,
    play_again_self_report: feedback?.play_again_self_report || null,
    feedback_delay_hours: feedback?.feedback_delay_hours || null,

    // Feedback (behavioral)
    actually_played_again_any: feedback?.actually_played_again_any || null,
    actually_played_again_same_players: feedback?.actually_played_again_same_players || null,
    days_until_next_round: feedback?.days_until_next_round || null,

    // Metadata
    created_at: participant.created_at,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("player_rounds").doc(docId).set(playerRoundData, { merge: true });
}

/**
 * Syncs ALL participants in a round to player_rounds.
 * Useful after round completion or feedback backfill.
 *
 * @param {string} roundId
 * @returns {Promise<number>} Number of player_round docs synced
 */
async function syncAllPlayerRounds(roundId) {
  const participantsSnapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("participants")
    .get();

  let count = 0;
  for (const doc of participantsSnapshot.docs) {
    await syncPlayerRound(roundId, doc.data().player_id);
    count++;
  }

  return count;
}

// ─────────────────────────────────────────────
// BIGQUERY EXPORT (Phase 3)
// ─────────────────────────────────────────────

/**
 * Exports un-exported events from the flat event log.
 *
 * In Phase 3, replace the console.log with actual BigQuery inserts.
 * For now, this marks events as exported so you can track what's been processed.
 *
 * @param {number} batchSize - Number of events to export per run (default: 500)
 * @returns {Promise<Object>} { exported: number, errors: number }
 */
async function exportEventsToBigQuery(batchSize = 500) {
  const results = { exported: 0, errors: 0 };

  const eventsSnapshot = await db
    .collection("round_events")
    .where("exported_to_bq", "==", false)
    .orderBy("created_at", "asc")
    .limit(batchSize)
    .get();

  if (eventsSnapshot.empty) {
    console.log("No new events to export.");
    return results;
  }

  const batch = db.batch();
  const eventsToExport = [];

  for (const doc of eventsSnapshot.docs) {
    const eventData = doc.data();

    // ── PHASE 3: Replace this block with actual BigQuery insert ──
    // Example:
    // await bigquery.dataset('behavioral').table('round_events').insert([{
    //   event_type: eventData.event_type,
    //   round_id: eventData.round_id,
    //   player_id: eventData.player_id,
    //   player_b_id: eventData.player_b_id,
    //   algorithm_version: eventData.algorithm_version,
    //   payload: JSON.stringify(eventData.payload),
    //   event_timestamp: eventData.created_at?.toDate?.().toISOString(),
    // }]);
    eventsToExport.push({
      id: doc.id,
      ...eventData,
    });

    // Mark as exported
    batch.update(doc.ref, { exported_to_bq: true });
    results.exported++;
  }

  try {
    // In Phase 3, wrap the BigQuery insert + Firestore update in error handling
    // so you don't mark events as exported if the BQ insert fails.
    await batch.commit();
    console.log(`Exported ${results.exported} events (marked in Firestore).`);
    console.log("Phase 3: Replace console.log with BigQuery insert.");
  } catch (error) {
    console.error("Export batch commit failed:", error);
    results.errors = results.exported;
    results.exported = 0;
  }

  return results;
}

/**
 * Exports player_rounds to BigQuery for ML training.
 * This is the primary training dataset — one row per player per round
 * with all features and labels flattened.
 *
 * @param {number} batchSize
 * @returns {Promise<number>} Number of rows exported
 */
async function exportPlayerRoundsToBigQuery(batchSize = 500) {
  // ── PHASE 3: Implement this ──
  // Query player_rounds, transform to BQ schema, insert.
  //
  // Suggested BQ table schema:
  //   player_id STRING
  //   round_id STRING
  //   tee_time TIMESTAMP
  //   course_id STRING
  //   match_source STRING
  //   algorithm_version STRING
  //   group_size INTEGER
  //   is_weekend BOOLEAN
  //   role STRING
  //   participation_status STRING
  //   handicap_at_booking FLOAT
  //   days_since_last_round INTEGER
  //   is_returning_after_gap BOOLEAN
  //   avg_vibe_score_in_group FLOAT
  //   cancelled_after_seeing_group BOOLEAN
  //   self_reported_rating INTEGER
  //   play_again_self_report BOOLEAN
  //   feedback_delay_hours FLOAT
  //   actually_played_again_any BOOLEAN
  //   actually_played_again_same_players BOOLEAN
  //   days_until_next_round INTEGER

  console.log("Phase 3: Implement BigQuery export for player_rounds.");
  return 0;
}

module.exports = {
  syncPlayerRound,
  syncAllPlayerRounds,
  exportEventsToBigQuery,
  exportPlayerRoundsToBigQuery,
};
