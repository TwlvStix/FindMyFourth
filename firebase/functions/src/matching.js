/**
 * matching.js
 * Generates and stores pairwise match predictions.
 *
 * Called after finalizeGroup() when the roster is locked.
 * Stores what the algorithm PREDICTED before the round happens.
 * This is the "what we thought would happen" half of the learning loop.
 *
 * IMPORTANT: The actual matching/scoring logic (computeVibeScore, etc.)
 * is a placeholder here. Replace it with your real algorithm.
 * The data storage structure is the point of this file.
 */

const admin = require("firebase-admin");
const db = admin.firestore();
const {
  ALGORITHM_VERSION,
  canonicalPairId,
  canonicalPair,
  generateAllPairs,
  logEvent,
} = require("./utils");

// ─────────────────────────────────────────────
// PLACEHOLDER: YOUR MATCHING ALGORITHM
// ─────────────────────────────────────────────

/**
 * REPLACE THIS with your actual vibe/compatibility scoring logic.
 *
 * This function should take two player snapshots and return a
 * compatibility score and the weights used to compute it.
 *
 * @param {Object} playerA - Participant snapshot for player A
 * @param {Object} playerB - Participant snapshot for player B
 * @returns {{ vibe_match_score: number, predicted_compatibility: number, weighting_factors: Object }}
 */
function computeMatchScore(playerA, playerB) {
  // ── PLACEHOLDER LOGIC ──
  // Replace this entire function with your real algorithm.
  // The return shape is what matters for the data layer.

  const handicapDiff = Math.abs(
    (playerA.handicap_at_booking || 20) - (playerB.handicap_at_booking || 20)
  );
  const handicapScore = Math.max(0, 1 - handicapDiff / 30);

  // Placeholder vibe score — your algorithm goes here
  const vibeScore = 0.5 + Math.random() * 0.5; // Replace with real logic

  const weights = {
    handicap_weight: 0.3,
    vibe_weight: 0.4,
    experience_weight: 0.2,
    recency_weight: 0.1,
  };

  const predicted = (
    handicapScore * weights.handicap_weight +
    vibeScore * weights.vibe_weight +
    0.5 * weights.experience_weight + // placeholder
    0.5 * weights.recency_weight      // placeholder
  );

  return {
    vibe_match_score: parseFloat(vibeScore.toFixed(4)),
    predicted_compatibility: parseFloat(predicted.toFixed(4)),
    weighting_factors: weights,
  };
}

// ─────────────────────────────────────────────
// GENERATE PAIRWISE MATCHES
// ─────────────────────────────────────────────

/**
 * Generates pairwise match documents for all player combinations in a round.
 * Uses canonical pair IDs to prevent duplicate/reversed entries.
 *
 * Call this AFTER finalizeGroup() and BEFORE the round starts.
 *
 * For a 4-player group, this creates 6 pairwise documents:
 *   A-B, A-C, A-D, B-C, B-D, C-D
 *
 * @param {string} roundId - The round to generate pairs for
 * @returns {Promise<number>} Number of pairwise documents created
 */
async function generatePairwiseMatches(roundId) {
  // Fetch all participants for this round
  const participantsSnapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("participants")
    .get();

  if (participantsSnapshot.empty) {
    throw new Error(`No participants found for round ${roundId}`);
  }

  // Build a map of player_id → participant snapshot
  const participantMap = {};
  participantsSnapshot.docs.forEach((doc) => {
    const data = doc.data();
    participantMap[data.player_id] = data;
  });

  const playerIds = Object.keys(participantMap);

  if (playerIds.length < 2) {
    throw new Error("Need at least 2 participants to generate pairs");
  }

  // Generate all unique pairs with canonical ordering
  const pairs = generateAllPairs(playerIds);

  // Use a batched write for atomicity
  const batch = db.batch();
  const pairwiseCollection = db
    .collection("rounds")
    .doc(roundId)
    .collection("pairwiseMatches");

  for (const pair of pairs) {
    const playerA = participantMap[pair.player_a_id];
    const playerB = participantMap[pair.player_b_id];

    // Compute match prediction using your algorithm
    const matchResult = computeMatchScore(playerA, playerB);

    const pairDoc = {
      player_a_id: pair.player_a_id,
      player_b_id: pair.player_b_id,
      round_id: roundId,

      // Algorithm prediction (the "what we predicted" signal)
      vibe_match_score: matchResult.vibe_match_score,
      predicted_compatibility: matchResult.predicted_compatibility,
      weighting_factors: matchResult.weighting_factors,

      // Algorithm metadata
      algorithm_version: ALGORITHM_VERSION,

      // Timestamp
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Use canonical pair ID as the document ID
    const docRef = pairwiseCollection.doc(pair.pair_id);
    batch.set(docRef, pairDoc);
  }

  await batch.commit();

  // Log events for each pair
  for (const pair of pairs) {
    const playerA = participantMap[pair.player_a_id];
    const playerB = participantMap[pair.player_b_id];
    const matchResult = computeMatchScore(playerA, playerB);

    await logEvent({
      event_type: "pair_scored",
      round_id: roundId,
      player_id: pair.player_a_id,
      player_b_id: pair.player_b_id,
      algorithm_version: ALGORITHM_VERSION,
      payload: {
        vibe_match_score: matchResult.vibe_match_score,
        predicted_compatibility: matchResult.predicted_compatibility,
      },
    });
  }

  return pairs.length;
}

// ─────────────────────────────────────────────
// QUERY HELPERS
// ─────────────────────────────────────────────

/**
 * Retrieves the pairwise match data for two specific players in a round.
 * Always uses canonical ordering, so caller doesn't need to worry about order.
 *
 * @param {string} roundId
 * @param {string} playerIdA
 * @param {string} playerIdB
 * @returns {Promise<Object|null>} The pairwise match document data, or null
 */
async function getPairwiseMatch(roundId, playerIdA, playerIdB) {
  const pairId = canonicalPairId(playerIdA, playerIdB);
  const doc = await db
    .collection("rounds")
    .doc(roundId)
    .collection("pairwiseMatches")
    .doc(pairId)
    .get();

  return doc.exists ? doc.data() : null;
}

/**
 * Retrieves all pairwise matches for a specific round.
 *
 * @param {string} roundId
 * @returns {Promise<Object[]>} Array of pairwise match documents
 */
async function getAllPairwiseMatches(roundId) {
  const snapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("pairwiseMatches")
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

module.exports = {
  generatePairwiseMatches,
  getPairwiseMatch,
  getAllPairwiseMatches,
  computeMatchScore, // Exported for testing; replace internals with real algorithm
};
