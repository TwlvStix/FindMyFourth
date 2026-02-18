/**
 * Trust Profile — Stage 5
 *
 * Computes and writes trust profile fields to the users doc after each
 * round verification or no-show finalization.
 *
 * Exports:
 *   updateTrustProfile  - Callable: recalculates and writes trust fields for a user
 *   getMyStanding       - Callable: returns full standing data for "Your Standing" screen
 *
 * Internal helpers (exported for testing):
 *   _updateTrustProfileHandler(db, uid)
 *   _computeWeightedRounds(db, uid)
 *   _computeShowUpRate(db, uid)
 *   _computeCancellationRate(db, uid, windowMs)
 *   _computeWarningFlag(db, uid)
 *   _computeGamesHosted(db, uid)
 *   _computeBadgeLevel(weightedRounds, uniqueCoPlayers, gamesHosted, cancellationRate)
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/** Rolling window for cancellation warning detection (90 days). */
const WARNING_WINDOW_MS = 90 * 24 * 60 * 60 * 1000;

/** Rolling window for badge cancellation rate (6 months). */
const CANCEL_RATE_WINDOW_MS = 180 * 24 * 60 * 60 * 1000;

/** Minimum verified rounds before show_up_rate is displayed. */
const SHOW_UP_RATE_MIN_ROUNDS = 5;

/**
 * Badge tier definitions, ordered highest → lowest.
 * _computeBadgeLevel iterates top-to-bottom and returns the first match.
 *
 * maxCancelRate: null means no cancellation rate requirement for that tier.
 */
const BADGE_TIERS = [
  { level: "anchor",    minWeighted: 50, minUnique: 20, minHosted: 10, maxCancelRate: 0.10 },
  { level: "starter",   minWeighted: 25, minUnique: 10, minHosted:  3, maxCancelRate: null },
  { level: "regular",   minWeighted: 10, minUnique:  5, minHosted:  0, maxCancelRate: 0.15 },
  { level: "confirmed", minWeighted:  3, minUnique:  2, minHosted:  0, maxCancelRate: null },
  { level: "new",       minWeighted:  0, minUnique:  0, minHosted:  0, maxCancelRate: null },
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: _computeWeightedRounds
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Reads users/{uid}/partner_plays/* and sums weighted round credits.
 *
 * Weighting rule per unique co-player (play_count = n):
 *   rounds 1-3  → 1.0x each  (tier1 = min(n, 3))
 *   rounds 4-6  → 0.5x each  (tier2 = max(0, min(n-3, 3)))
 *   rounds 7+   → 0.25x each (tier3 = max(0, n-6))
 *
 * Example: played with Alice 8 times:
 *   3×1.0 + 3×0.5 + 2×0.25 = 3 + 1.5 + 0.5 = 5.0
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @returns {Promise<{ weightedRounds: number, uniqueCoPlayerCount: number }>}
 */
async function _computeWeightedRounds(db, uid) {
  const partnerPlaysSnap = await db
    .collection("users")
    .doc(uid)
    .collection("partner_plays")
    .get();

  let weightedRounds = 0;
  const uniqueCoPlayerCount = partnerPlaysSnap.size;

  for (const doc of partnerPlaysSnap.docs) {
    const playCount =
      typeof doc.data().play_count === "number" ? doc.data().play_count : 0;

    const tier1 = Math.min(playCount, 3);
    const tier2 = Math.max(0, Math.min(playCount - 3, 3));
    const tier3 = Math.max(0, playCount - 6);

    weightedRounds += tier1 * 1.0 + tier2 * 0.5 + tier3 * 0.25;
  }

  return { weightedRounds, uniqueCoPlayerCount };
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: _computeShowUpRate
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Computes show-up rate.
 *
 * Only day_of cancels (tier='day_of', is_ghost=false) and ghost no-shows
 * (is_ghost=true) count as no-shows. Late and early cancels are excluded.
 *
 * Formula: attended / (attended + noShows)
 *   attended  = verified_round_count (set by confirmation_flow._finalizeRoundVerification;
 *               only present players receive the increment)
 *   noShows   = day_of_cancel_records + ghost_records (all time, not windowed)
 *
 * Returns null showUpRate if total commitments < SHOW_UP_RATE_MIN_ROUNDS.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @returns {Promise<{ showUpRate: number|null, denominator: number }>}
 */
async function _computeShowUpRate(db, uid) {
  const playerRef = db.collection("users").doc(uid);

  // Count day_of cancels (non-ghost)
  const dayOfSnap = await db
    .collection("cancellation_records")
    .where("player_ref", "==", playerRef)
    .where("tier", "==", "day_of")
    .where("is_ghost", "==", false)
    .get();

  // Count ghost no-shows
  const ghostSnap = await db
    .collection("cancellation_records")
    .where("player_ref", "==", playerRef)
    .where("is_ghost", "==", true)
    .get();

  const noShowCount = dayOfSnap.size + ghostSnap.size;

  // Read verified_round_count from user doc
  const userSnap = await db.collection("users").doc(uid).get();
  const verifiedRounds = userSnap.exists
    ? castToInt(userSnap.data().verified_round_count)
    : 0;

  const denominator = verifiedRounds + noShowCount;

  if (denominator < SHOW_UP_RATE_MIN_ROUNDS) {
    return { showUpRate: null, denominator };
  }

  const showUpRate = verifiedRounds / denominator;
  return { showUpRate, denominator };
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: _computeCancellationRate
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Computes cancellation rate over a rolling window for badge eligibility.
 *
 * Formula: badCancels / (attendedInWindow + badCancels)
 * Where:
 *   badCancels      = late + day_of + ghost cancels in window
 *   early cancels   = excluded from BOTH numerator and denominator
 *   attendedInWindow = verified rounds in window where uid was present
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @param {number} windowMs - rolling window in milliseconds
 * @returns {Promise<{ cancellationRate: number, numerator: number, denominator: number }>}
 */
async function _computeCancellationRate(db, uid, windowMs) {
  const playerRef = db.collection("users").doc(uid);
  const cutoffMs = Date.now() - windowMs;
  const cutoffTs = admin.firestore.Timestamp.fromMillis(cutoffMs);

  // Fetch all cancellation records in the window for this player
  const cancelSnap = await db
    .collection("cancellation_records")
    .where("player_ref", "==", playerRef)
    .where("cancelled_at", ">=", cutoffTs)
    .get();

  let badCancels = 0;
  for (const doc of cancelSnap.docs) {
    const d = doc.data();
    const tier = d.tier || "";
    const isGhost = d.is_ghost === true;
    // early cancels are excluded from both numerator and denominator
    if (isGhost || tier === "late" || tier === "day_of") {
      badCancels++;
    }
  }

  // Count attended rounds in window: query verified round_records by tee_time range,
  // then check participant_snapshots and attendance_records for this uid
  const roundsSnap = await db
    .collection("round_records")
    .where("tee_time", ">=", cutoffTs)
    .where("verification_status", "==", "verified")
    .get();

  let attendedInWindow = 0;
  for (const doc of roundsSnap.docs) {
    const data = doc.data();
    const attendanceRecords = data.attendance_records || {};
    const participantSnapshots = Array.isArray(data.participant_snapshots)
      ? data.participant_snapshots
      : [];

    const isParticipant = participantSnapshots.some(
      (s) => s && s.uid === uid
    );
    if (!isParticipant) continue;

    // Any status other than no_show counts as attended
    if (attendanceRecords[uid] !== "no_show") {
      attendedInWindow++;
    }
  }

  const denominator = attendedInWindow + badCancels;
  if (denominator === 0) {
    return { cancellationRate: 0, numerator: 0, denominator: 0 };
  }

  const cancellationRate = badCancels / denominator;
  return { cancellationRate, numerator: badCancels, denominator };
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: _computeWarningFlag
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Returns warning flag if player has 2+ late/day_of/ghost cancellations
 * in a rolling 90-day window.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @returns {Promise<{ hasWarning: boolean, warningCount: number }>}
 */
async function _computeWarningFlag(db, uid) {
  const playerRef = db.collection("users").doc(uid);
  const cutoffMs = Date.now() - WARNING_WINDOW_MS;
  const cutoffTs = admin.firestore.Timestamp.fromMillis(cutoffMs);

  const cancelSnap = await db
    .collection("cancellation_records")
    .where("player_ref", "==", playerRef)
    .where("cancelled_at", ">=", cutoffTs)
    .get();

  let warningCount = 0;
  for (const doc of cancelSnap.docs) {
    const d = doc.data();
    const tier = d.tier || "";
    const isGhost = d.is_ghost === true;
    if (isGhost || tier === "late" || tier === "day_of") {
      warningCount++;
    }
  }

  return {
    hasWarning: warningCount >= 2,
    warningCount,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: _computeGamesHosted
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Counts verified games hosted by this user (games where userRef == uid
 * and status == 'played').
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @returns {Promise<{ gamesHosted: number }>}
 */
async function _computeGamesHosted(db, uid) {
  const userRef = db.collection("users").doc(uid);
  const gamesSnap = await db
    .collection("games")
    .where("userRef", "==", userRef)
    .where("status", "==", "played")
    .get();
  return { gamesHosted: gamesSnap.size };
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: _computeBadgeLevel
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Pure function: determines badge level from computed metrics.
 * Iterates BADGE_TIERS from highest to lowest and returns the first match.
 *
 * @param {number} weightedRounds
 * @param {number} uniqueCoPlayers
 * @param {number} gamesHosted
 * @param {number} cancellationRate  - 0.0 to 1.0
 * @returns {string}  badge level
 */
function _computeBadgeLevel(weightedRounds, uniqueCoPlayers, gamesHosted, cancellationRate) {
  for (const tier of BADGE_TIERS) {
    if (weightedRounds < tier.minWeighted) continue;
    if (uniqueCoPlayers < tier.minUnique) continue;
    if (gamesHosted < tier.minHosted) continue;
    if (tier.maxCancelRate !== null && cancellationRate > tier.maxCancelRate) continue;
    return tier.level;
  }
  return "new"; // unreachable — 'new' tier always matches
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL UTILITY
// ─────────────────────────────────────────────────────────────────────────────

function castToInt(value) {
  if (typeof value === "number") return Math.floor(value);
  if (typeof value === "string") {
    const n = parseInt(value, 10);
    return isNaN(n) ? 0 : n;
  }
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// CORE ORCHESTRATOR: _updateTrustProfileHandler
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Recomputes all trust profile fields for a user and writes them atomically.
 *
 * Called internally by:
 *   - confirmation_flow._finalizeRoundVerification (for present players)
 *   - confirmation_flow._closeConfirmationWindow (for no-show players)
 *
 * Idempotent. Safe to call multiple times.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @returns {Promise<object>} computed metrics
 */
async function _updateTrustProfileHandler(db, uid) {
  // Run all five computations in parallel for performance
  const [
    weightedResult,
    showUpResult,
    cancelRateResult,
    warningResult,
    gamesHostedResult,
  ] = await Promise.all([
    _computeWeightedRounds(db, uid),
    _computeShowUpRate(db, uid),
    _computeCancellationRate(db, uid, CANCEL_RATE_WINDOW_MS),
    _computeWarningFlag(db, uid),
    _computeGamesHosted(db, uid),
  ]);

  const { weightedRounds, uniqueCoPlayerCount } = weightedResult;
  const { showUpRate, denominator: showUpDenominator } = showUpResult;
  const { cancellationRate } = cancelRateResult;
  const { hasWarning, warningCount } = warningResult;
  const { gamesHosted } = gamesHostedResult;

  const badgeLevel = _computeBadgeLevel(
    weightedRounds,
    uniqueCoPlayerCount,
    gamesHosted,
    cancellationRate
  );

  // Build unique_co_players array from partner_plays subcollection doc IDs
  // (Re-reads, but partner_plays was already read in _computeWeightedRounds above.
  // Acceptable since this is a background update and partner_plays is small.)
  const partnerPlaysSnap = await db
    .collection("users")
    .doc(uid)
    .collection("partner_plays")
    .get();
  const uniqueCoPlayersArray = partnerPlaysSnap.docs.map((d) => d.id);

  const updateData = {
    weighted_rounds: weightedRounds,
    badge_level: badgeLevel,
    cancellation_rate: cancellationRate,
    cancellation_warning: hasWarning,
    cancellation_warning_count: warningCount,
    unique_co_players: uniqueCoPlayersArray,
    games_hosted: gamesHosted,
    show_up_rate_denominator: showUpDenominator,
    trust_profile_updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (showUpRate !== null) {
    updateData.show_up_rate = showUpRate;
  } else {
    // Remove the field if the user no longer has enough rounds (edge case)
    updateData.show_up_rate = admin.firestore.FieldValue.delete();
  }

  await db.collection("users").doc(uid).update(updateData);

  console.log(
    `_updateTrustProfileHandler: updated trust profile for user ${uid}. ` +
      `badge=${badgeLevel}, weighted=${weightedRounds.toFixed(2)}, ` +
      `showUpRate=${showUpRate !== null ? (showUpRate * 100).toFixed(1) + "%" : "N/A"}, ` +
      `cancelRate=${(cancellationRate * 100).toFixed(1)}%, ` +
      `warning=${hasWarning} (${warningCount}), hosted=${gamesHosted}`
  );

  return {
    badgeLevel,
    weightedRounds,
    showUpRate,
    cancellationRate,
    hasWarning,
    warningCount,
    gamesHosted,
    uniqueCoPlayerCount,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE: updateTrustProfile
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: updateTrustProfile
 *
 * Triggers a full trust profile recalculation for a user.
 * Can be called by a user to refresh their own profile, or internally
 * from the backend (no auth context for internal calls).
 *
 * Input:  { userId: string }
 * Auth:   Must match userId, OR no auth context (internal backend call)
 * Returns: { success: true, ...computed metrics }
 */
const updateTrustProfile = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    const { userId } = data || {};

    if (!userId || typeof userId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required."
      );
    }

    // Allow the user themselves, or unauthenticated internal backend calls
    if (context.auth && context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You can only update your own trust profile."
      );
    }

    try {
      const result = await _updateTrustProfileHandler(db, userId);
      return { success: true, ...result };
    } catch (error) {
      console.error(`updateTrustProfile failed for ${userId}:`, error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to update trust profile: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE: getMyStanding
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: getMyStanding
 *
 * Returns the full private standing data for the "Your Standing" screen.
 * Computes all rates fresh (not from cached user doc fields).
 *
 * Input:  { userId: string }
 * Auth:   Required. Must match userId.
 *
 * Returns: {
 *   strikes:                Array<{ id, reason, gameRef, expiresAt, createdAt }>
 *   activeStrikeCount:      number
 *   nextThreshold:          { strikes, restriction, strikesNeeded } | null
 *   showUpRate:             number | null
 *   showUpRateDenominator:  number
 *   cancellationRate:       number
 *   cancellationRateNumerator:   number
 *   cancellationRateDenominator: number
 *   weightedRounds:         number
 *   currentBadge:           string
 *   nextBadge:              string | null
 *   nextBadgeRequirements:  object | null
 *   uniqueCoPlayers:        number
 *   gamesHosted:            number
 *   warningCount:           number
 * }
 */
const getMyStanding = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 120, memory: "256MB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const { userId } = data || {};
    if (!userId || typeof userId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required."
      );
    }
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You can only view your own standing."
      );
    }

    const db = admin.firestore();
    const playerRef = db.collection("users").doc(userId);
    const nowMs = Date.now();
    const expiryThreshold = admin.firestore.Timestamp.fromMillis(nowMs);

    // ── Fetch active (non-expired) strikes ────────────────────────────────
    const strikesSnap = await db
      .collection("strikes")
      .where("player_ref", "==", playerRef)
      .where("expires_at", ">", expiryThreshold)
      .orderBy("expires_at", "asc")
      .get();

    const strikes = strikesSnap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        reason: d.reason || "",
        gameRef: d.game_ref ? d.game_ref.path : null,
        expiresAt: d.expires_at ? d.expires_at.toMillis() : null,
        createdAt: d.created_at ? d.created_at.toMillis() : null,
      };
    });

    const activeStrikeCount = strikes.length;

    // ── Next restriction threshold ────────────────────────────────────────
    const RESTRICTION_THRESHOLDS = [
      { strikes: 1, restriction: "Private warning — no restrictions yet" },
      { strikes: 2, restriction: "24-hour cooldown on joining new games" },
      { strikes: 3, restriction: "7-day restriction (cannot join or create)" },
      { strikes: 4, restriction: "30-day restriction (account flagged for review)" },
      { strikes: 5, restriction: "Account suspension — manual review required" },
    ];

    let nextThreshold = null;
    for (const entry of RESTRICTION_THRESHOLDS) {
      if (activeStrikeCount < entry.strikes) {
        nextThreshold = {
          strikes: entry.strikes,
          restriction: entry.restriction,
          strikesNeeded: entry.strikes - activeStrikeCount,
        };
        break;
      }
    }

    // ── Recompute all rates fresh ─────────────────────────────────────────
    const [
      showUpResult,
      cancelRateResult,
      warningResult,
      weightedResult,
      gamesHostedResult,
    ] = await Promise.all([
      _computeShowUpRate(db, userId),
      _computeCancellationRate(db, userId, CANCEL_RATE_WINDOW_MS),
      _computeWarningFlag(db, userId),
      _computeWeightedRounds(db, userId),
      _computeGamesHosted(db, userId),
    ]);

    const { showUpRate, denominator: showUpDenominator } = showUpResult;
    const {
      cancellationRate,
      numerator: cancelNumerator,
      denominator: cancelDenominator,
    } = cancelRateResult;
    const { warningCount } = warningResult;
    const { weightedRounds, uniqueCoPlayerCount } = weightedResult;
    const { gamesHosted } = gamesHostedResult;

    // ── Current and next badge ────────────────────────────────────────────
    const currentBadge = _computeBadgeLevel(
      weightedRounds,
      uniqueCoPlayerCount,
      gamesHosted,
      cancellationRate
    );

    // BADGE_TIERS is ordered highest → lowest; find index of current badge
    const currentTierIndex = BADGE_TIERS.findIndex(
      (t) => t.level === currentBadge
    );

    let nextBadge = null;
    let nextBadgeRequirements = null;
    if (currentTierIndex > 0) {
      // The tier above current (one index lower in the array = harder tier)
      const nextTier = BADGE_TIERS[currentTierIndex - 1];
      nextBadge = nextTier.level;
      nextBadgeRequirements = {
        minWeightedRounds: nextTier.minWeighted,
        minUniquePlayers: nextTier.minUnique,
        minHosted: nextTier.minHosted,
        maxCancelRate: nextTier.maxCancelRate,
        currentWeightedRounds: weightedRounds,
        currentUniquePlayers: uniqueCoPlayerCount,
        currentHosted: gamesHosted,
        currentCancelRate: cancellationRate,
        weightedRoundsNeeded: Math.max(0, nextTier.minWeighted - weightedRounds),
        uniquePlayersNeeded: Math.max(0, nextTier.minUnique - uniqueCoPlayerCount),
        hostedNeeded: Math.max(0, nextTier.minHosted - gamesHosted),
      };
    }

    return {
      strikes,
      activeStrikeCount,
      nextThreshold,
      showUpRate,
      showUpRateDenominator: showUpDenominator,
      cancellationRate,
      cancellationRateNumerator: cancelNumerator,
      cancellationRateDenominator: cancelDenominator,
      weightedRounds,
      currentBadge,
      nextBadge,
      nextBadgeRequirements,
      uniqueCoPlayers: uniqueCoPlayerCount,
      gamesHosted,
      warningCount,
    };
  });

// ─────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────────

module.exports = {
  updateTrustProfile,
  getMyStanding,

  // Internal helpers exported for unit testing
  _updateTrustProfileHandler,
  _computeWeightedRounds,
  _computeShowUpRate,
  _computeCancellationRate,
  _computeWarningFlag,
  _computeGamesHosted,
  _computeBadgeLevel,
};
