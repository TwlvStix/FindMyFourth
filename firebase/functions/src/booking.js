/**
 * booking.js
 * Handles round creation and participant joining.
 *
 * LIFECYCLE:
 * 1. Host creates a round → createRound()
 * 2. Players join → addParticipant()
 * 3. When group is full or host finalizes → finalizeGroup()
 *
 * All snapshots are taken AT BOOKING TIME. This is critical.
 * Never reference live profile data in historical records.
 */

const admin = require("firebase-admin");
const db = admin.firestore();
const {
  ALGORITHM_VERSION,
  MATCH_SOURCES,
  getTimeOfDayBucket,
  isWeekend,
  daysBetween,
  computeTemporalFeatures,
  logEvent,
  validateRequired,
  validateEnum,
} = require("./utils");

/**
 * Computes age in years from a Firestore Timestamp or Date.
 * Returns null if dateOfBirth is missing.
 */
function computeAge(dateOfBirth) {
  if (!dateOfBirth) return null;
  const dob = dateOfBirth.toDate ? dateOfBirth.toDate() : new Date(dateOfBirth);
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const monthDiff = today.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

// ─────────────────────────────────────────────
// CREATE ROUND
// ─────────────────────────────────────────────

/**
 * Creates a new round document with all context fields.
 * Called when the host initiates a new game.
 *
 * @param {Object} params
 * @param {string} params.game_type - Type of game (e.g., "stroke_play", "match_play")
 * @param {Object} params.game_settings - Game-specific settings
 * @param {Date|string} params.tee_time - Scheduled tee time
 * @param {string} params.course_id - Course identifier
 * @param {Object|null} params.weather_snapshot - Weather at booking time
 * @param {string} params.host_player_id - Host's player ID
 * @param {string} params.match_source - How this group was assembled
 * @param {number} params.group_size - Expected number of players (2–4)
 * @returns {Promise<string>} The new round ID
 */
async function createRound({
  game_type,
  game_settings = {},
  tee_time,
  course_id,
  weather_snapshot = null,
  host_player_id,
  match_source,
  group_size,
}) {
  // Validate inputs
  validateRequired(
    { game_type, tee_time, course_id, host_player_id, match_source, group_size },
    ["game_type", "tee_time", "course_id", "host_player_id", "match_source", "group_size"]
  );
  validateEnum(match_source, MATCH_SOURCES, "match_source");

  if (group_size < 2 || group_size > 4) {
    throw new Error("group_size must be between 2 and 4");
  }

  const teeTimeDate = tee_time instanceof Date ? tee_time : new Date(tee_time);
  const now = new Date();

  const roundData = {
    game_type,
    game_settings,
    tee_time: admin.firestore.Timestamp.fromDate(teeTimeDate),
    course_id,
    weather_snapshot,
    host_player_id,
    booking_timestamp: admin.firestore.FieldValue.serverTimestamp(),

    // New fields from the fixes
    group_size,
    time_of_day_bucket: getTimeOfDayBucket(teeTimeDate),
    match_source,
    algorithm_version: match_source === "algorithm" ? ALGORITHM_VERSION : null,
    days_booked_in_advance: daysBetween(now, teeTimeDate),
    is_weekend: isWeekend(teeTimeDate),
    round_status: "scheduled",

    // Track when the group roster becomes visible to players
    group_finalized_at: null,

    // Metadata
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  const roundRef = await db.collection("rounds").add(roundData);

  // Log the event
  await logEvent({
    event_type: "round_created",
    round_id: roundRef.id,
    player_id: host_player_id,
    algorithm_version: roundData.algorithm_version,
    payload: {
      game_type,
      course_id,
      match_source,
      group_size,
    },
  });

  // Automatically add the host as the first participant
  await addParticipant({
    round_id: roundRef.id,
    player_id: host_player_id,
    role: "host",
  });

  return roundRef.id;
}

// ─────────────────────────────────────────────
// ADD PARTICIPANT
// ─────────────────────────────────────────────

/**
 * Adds a player to a round with a full snapshot of their state at booking time.
 *
 * CRITICAL: This function snapshots profile data. It reads the player's
 * CURRENT profile and copies values into the participant document.
 * These values are never updated — they represent the state at booking time.
 *
 * @param {Object} params
 * @param {string} params.round_id - Round to join
 * @param {string} params.player_id - Player joining
 * @param {string} params.role - "host" or "joined"
 * @returns {Promise<void>}
 */
async function addParticipant({ round_id, player_id, role = "joined" }) {
  validateRequired({ round_id, player_id }, ["round_id", "player_id"]);
  validateEnum(role, ["host", "joined"], "role");

  // Read the player's CURRENT profile (we'll snapshot it)
  const profileDoc = await db.collection("users").doc(player_id).get();
  if (!profileDoc.exists) {
    throw new Error(`Player ${player_id} not found`);
  }
  const profile = profileDoc.data();

  // Compute temporal features at this moment
  const temporalFeatures = await computeTemporalFeatures(player_id);

  const participantData = {
    round_id,
    player_id,
    role,

    // ── Snapshots from live profile (copied, not referenced) ──
    handicap_at_booking: profile.handicap ?? null,
    vibe_preferences_at_booking: profile.vibe_profile ?? {},
    experience_level_snapshot: profile.badge_level ?? "unknown",
    gender_at_booking: profile.gender ?? null,
    age_at_booking: computeAge(profile.date_of_birth),

    // ── Temporal features (computed at booking time) ──
    days_since_last_round: temporalFeatures.days_since_last_round,
    rounds_in_last_30_days: temporalFeatures.rounds_in_last_30_days,
    rounds_in_last_7_days: temporalFeatures.rounds_in_last_7_days,
    active_round_streak: temporalFeatures.active_round_streak,
    lifetime_round_count: temporalFeatures.lifetime_round_count,
    is_returning_after_gap: temporalFeatures.is_returning_after_gap,

    // ── Participation lifecycle ──
    participation_status: role === "host" ? "confirmed" : "invited",
    status_history: [
      {
        status: role === "host" ? "confirmed" : "invited",
        timestamp: new Date().toISOString(),
      },
    ],
    cancelled_after_seeing_group: null,
    cancellation_reason: null,

    // ── Metadata ──
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db
    .collection("rounds")
    .doc(round_id)
    .collection("participants")
    .doc(player_id)
    .set(participantData);

  // Log the event
  await logEvent({
    event_type: "player_joined",
    round_id,
    player_id,
    payload: {
      role,
      handicap_at_booking: participantData.handicap_at_booking,
      experience_level_snapshot: participantData.experience_level_snapshot,
      gender_at_booking: participantData.gender_at_booking,
      age_at_booking: participantData.age_at_booking,
      days_since_last_round: temporalFeatures.days_since_last_round,
    },
  });
}

// ─────────────────────────────────────────────
// FINALIZE GROUP
// ─────────────────────────────────────────────

/**
 * Called when the group roster is complete and visible to all players.
 * This is the point at which pairwise match scores should be generated.
 *
 * Marks the round's group_finalized_at timestamp, which is used later
 * to determine if a cancellation happened AFTER the player saw the group.
 *
 * @param {string} roundId - Round to finalize
 * @returns {Promise<string[]>} Array of participant player IDs
 */
async function finalizeGroup(roundId) {
  // Update the round with finalization timestamp
  await db.collection("rounds").doc(roundId).update({
    group_finalized_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Get all participants
  const participantsSnapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("participants")
    .get();

  const playerIds = participantsSnapshot.docs.map((doc) => doc.data().player_id);

  await logEvent({
    event_type: "group_finalized",
    round_id: roundId,
    payload: { player_ids: playerIds, group_size: playerIds.length },
  });

  return playerIds;
}

module.exports = {
  createRound,
  addParticipant,
  finalizeGroup,
};
