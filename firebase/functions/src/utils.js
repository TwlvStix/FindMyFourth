/**
 * utils.js
 * Shared utilities for the behavioral dataset backend.
 * Canonical pair logic, temporal features, constants, and validation.
 */

const admin = require("firebase-admin");
const db = admin.firestore();

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────

const ALGORITHM_VERSION = "v1.0.0";

const MATCH_SOURCES = ["algorithm", "friend_invite", "open_join", "manual"];

const TIME_OF_DAY_BUCKETS = {
  morning: { start: 5, end: 11 },    // 5:00 AM – 11:59 AM
  afternoon: { start: 12, end: 16 }, // 12:00 PM – 4:59 PM
  twilight: { start: 17, end: 20 },  // 5:00 PM – 8:59 PM
};

const PARTICIPATION_STATUSES = [
  "invited",
  "confirmed",
  "checked_in",
  "completed",
  "declined",
  "cancelled",
  "no_show",
  "early_departure",
];

const CANCELLATION_REASONS = [
  "schedule_conflict",
  "weather",
  "group_composition",
  "other",
];

const FEEDBACK_SOURCES = ["push_notification", "in_app_prompt", "spontaneous"];

// How many days to wait before computing behavioral labels
const BEHAVIORAL_BACKFILL_WINDOW_DAYS = 30;

// ─────────────────────────────────────────────
// CANONICAL PAIR LOGIC
// ─────────────────────────────────────────────

/**
 * Returns a deterministic document ID for a player pair.
 * Always orders lexicographically so A_B and B_A produce the same key.
 *
 * @param {string} idA - First player ID
 * @param {string} idB - Second player ID
 * @returns {string} Canonical pair ID (e.g., "uid_alice_uid_charlie")
 */
function canonicalPairId(idA, idB) {
  if (!idA || !idB) throw new Error("Both player IDs are required");
  if (idA === idB) throw new Error("Cannot create a pair with the same player");
  return idA < idB ? `${idA}_${idB}` : `${idB}_${idA}`;
}

/**
 * Returns an object with player_a_id and player_b_id in canonical order.
 *
 * @param {string} idA - First player ID
 * @param {string} idB - Second player ID
 * @returns {{ player_a_id: string, player_b_id: string }}
 */
function canonicalPair(idA, idB) {
  return idA < idB
    ? { player_a_id: idA, player_b_id: idB }
    : { player_a_id: idB, player_b_id: idA };
}

/**
 * Generates all unique pairs from an array of player IDs.
 * Returns canonical pairs — no duplicates, deterministic order.
 *
 * @param {string[]} playerIds - Array of player IDs in the group
 * @returns {Array<{ pair_id: string, player_a_id: string, player_b_id: string }>}
 */
function generateAllPairs(playerIds) {
  const pairs = [];
  for (let i = 0; i < playerIds.length; i++) {
    for (let j = i + 1; j < playerIds.length; j++) {
      const pair = canonicalPair(playerIds[i], playerIds[j]);
      pairs.push({
        pair_id: canonicalPairId(playerIds[i], playerIds[j]),
        ...pair,
      });
    }
  }
  return pairs;
}

// ─────────────────────────────────────────────
// TIME-OF-DAY BUCKET
// ─────────────────────────────────────────────

/**
 * Determines the time-of-day bucket from a timestamp.
 *
 * @param {Date} date
 * @returns {string} "morning" | "afternoon" | "twilight" | "other"
 */
function getTimeOfDayBucket(date) {
  const hour = date.getHours();
  for (const [bucket, range] of Object.entries(TIME_OF_DAY_BUCKETS)) {
    if (hour >= range.start && hour <= range.end) return bucket;
  }
  return "other";
}

/**
 * Returns whether a date falls on a weekend (Saturday or Sunday).
 *
 * @param {Date} date
 * @returns {boolean}
 */
function isWeekend(date) {
  const day = date.getDay();
  return day === 0 || day === 6;
}

/**
 * Calculates the number of days between two dates, rounded down.
 *
 * @param {Date} earlier
 * @param {Date} later
 * @returns {number}
 */
function daysBetween(earlier, later) {
  return Math.floor((later.getTime() - earlier.getTime()) / (1000 * 60 * 60 * 24));
}

// ─────────────────────────────────────────────
// TEMPORAL FEATURE COMPUTATION
// ─────────────────────────────────────────────

/**
 * Computes temporal features for a player at booking time.
 * Queries their participation history and derives engagement metrics.
 *
 * IMPORTANT: Call this at booking time and snapshot the results.
 * Do NOT recompute later — the whole point is to capture the state
 * at the moment the decision was made.
 *
 * @param {string} playerId
 * @returns {Promise<Object>} Temporal feature snapshot
 */
async function computeTemporalFeatures(playerId) {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  // Query all completed/checked-in participations for this player
  const historySnapshot = await db
    .collectionGroup("participants")
    .where("player_id", "==", playerId)
    .where("participation_status", "in", ["completed", "checked_in"])
    .orderBy("created_at", "desc")
    .get();

  const rounds = historySnapshot.docs.map((doc) => ({
    ...doc.data(),
    created_at: doc.data().created_at?.toDate?.() || new Date(doc.data().created_at),
  }));

  const lastRound = rounds.length > 0 ? rounds[0] : null;

  const roundsInLast30 = rounds.filter((r) => r.created_at > thirtyDaysAgo).length;
  const roundsInLast7 = rounds.filter((r) => r.created_at > sevenDaysAgo).length;

  const daysSinceLast = lastRound ? daysBetween(lastRound.created_at, now) : null;

  // Compute active streak: consecutive weeks with at least one round
  // Starting from the most recent week, going backwards
  let streak = 0;
  if (rounds.length > 0) {
    let weekStart = new Date(now);
    weekStart.setHours(0, 0, 0, 0);
    weekStart.setDate(weekStart.getDate() - weekStart.getDay()); // Start of current week

    let checking = true;
    while (checking) {
      const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);
      const hasRoundThisWeek = rounds.some(
        (r) => r.created_at >= weekStart && r.created_at < weekEnd
      );
      if (hasRoundThisWeek) {
        streak++;
        weekStart = new Date(weekStart.getTime() - 7 * 24 * 60 * 60 * 1000);
      } else {
        checking = false;
      }
    }
  }

  return {
    days_since_last_round: daysSinceLast,
    rounds_in_last_30_days: roundsInLast30,
    rounds_in_last_7_days: roundsInLast7,
    active_round_streak: streak,
    lifetime_round_count: rounds.length,
    is_returning_after_gap: daysSinceLast !== null && daysSinceLast > 30,
  };
}

// ─────────────────────────────────────────────
// FLAT EVENT LOGGING
// ─────────────────────────────────────────────

/**
 * Writes an append-only event to the flat event log.
 * Used for easy BigQuery export later.
 *
 * @param {Object} params
 * @param {string} params.event_type - Type of event
 * @param {string} params.round_id - Associated round ID
 * @param {string|null} params.player_id - Primary player ID
 * @param {string|null} params.player_b_id - Secondary player ID (for pairwise events)
 * @param {string|null} params.algorithm_version - Algorithm version if applicable
 * @param {Object} params.payload - Event-specific data
 */
async function logEvent({ event_type, round_id, player_id = null, player_b_id = null, algorithm_version = null, payload = {} }) {
  await db.collection("round_events").add({
    event_type,
    round_id,
    player_id,
    player_b_id,
    algorithm_version,
    payload,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    exported_to_bq: false,
  });
}

// ─────────────────────────────────────────────
// VALIDATION HELPERS
// ─────────────────────────────────────────────

/**
 * Validates that required fields exist and are non-null.
 *
 * @param {Object} data - Object to validate
 * @param {string[]} requiredFields - List of required field names
 * @throws {Error} If any required field is missing
 */
function validateRequired(data, requiredFields) {
  const missing = requiredFields.filter(
    (field) => data[field] === undefined || data[field] === null
  );
  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(", ")}`);
  }
}

/**
 * Validates that a value is one of an allowed set.
 *
 * @param {string} value
 * @param {string[]} allowed
 * @param {string} fieldName
 * @throws {Error} If value is not in the allowed set
 */
function validateEnum(value, allowed, fieldName) {
  if (!allowed.includes(value)) {
    throw new Error(
      `Invalid ${fieldName}: "${value}". Must be one of: ${allowed.join(", ")}`
    );
  }
}

module.exports = {
  ALGORITHM_VERSION,
  MATCH_SOURCES,
  TIME_OF_DAY_BUCKETS,
  PARTICIPATION_STATUSES,
  CANCELLATION_REASONS,
  FEEDBACK_SOURCES,
  BEHAVIORAL_BACKFILL_WINDOW_DAYS,
  canonicalPairId,
  canonicalPair,
  generateAllPairs,
  getTimeOfDayBucket,
  isWeekend,
  daysBetween,
  computeTemporalFeatures,
  logEvent,
  validateRequired,
  validateEnum,
};
