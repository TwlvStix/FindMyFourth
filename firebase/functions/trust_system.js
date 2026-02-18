/**
 * Trust System Cloud Functions — Stage 1 & 2
 *
 * Stage 1 exports:
 *   calculateCancellationTier  - pure helper (also exported for seed script)
 *   recordCancellation         - callable: writes CancellationRecord with computed tier
 *   validateGameAppUserCount   - callable: validates min 2 app users
 *   onGameCreate               - Firestore trigger: enforces min 2 app users on game creation
 *
 * Stage 2 exports:
 *   recordStrike               - internal helper: writes a strike document and returns it
 *   checkLateCancelPattern     - internal helper: checks 3-in-90-days late cancel window
 *   getActiveStrikeCount       - internal helper: counts non-expired strikes
 *   getRestrictionForStrikes   - pure helper: maps strike count → restriction info
 *   checkPlayerRestriction     - callable: returns a player's current restriction status
 *   markGhostNoShow            - callable: marks a ghost no-show, writes 2 strikes immediately
 *
 * Tier logic (mirrors Dart CancellationRecord.tier):
 *   36+ hours before tee time  → 'early'
 *   12-36 hours before         → 'late'
 *   under 12 hours             → 'day_of'
 *
 * Strike rules (spec §5.1–5.2):
 *   3 late cancels in rolling 90 days  → 1 strike
 *   1 day-of cancel                    → 1 strike immediately
 *   1 ghost no-show                    → 2 strikes immediately
 *   early cancels                      → never generate strikes
 *
 * Restriction ladder (active strikes, rolling 6-month window):
 *   1 strike  → private warning, no restriction
 *   2 strikes → 24-hour cooldown on joining new games
 *   3 strikes → 7-day restriction (cannot join or create)
 *   4 strikes → 30-day restriction (account flagged for review)
 *   5+        → suspension (manual review required)
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// admin is already initialized by index.js before this module is required.
const firestore = admin.firestore;

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/** Rolling window for late-cancel pattern detection (milliseconds). */
const LATE_CANCEL_WINDOW_MS = 90 * 24 * 60 * 60 * 1000; // 90 days

/** Strikes older than this are expired and don't count toward active total. */
const STRIKE_EXPIRY_MS = 180 * 24 * 60 * 60 * 1000; // ~6 months (180 days)

/** Number of late cancels in LATE_CANCEL_WINDOW_MS that triggers 1 strike. */
const LATE_CANCEL_STRIKE_THRESHOLD = 3;

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 1 — CANCELLATION TIER
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Pure tier calculation helper. No side effects.
 *
 * @param {number} cancelledAtMs - epoch ms of cancellation time
 * @param {number} teeTimeMs     - epoch ms of tee time
 * @returns {{ tier: string, hoursBeforeTeeTime: number }}
 */
function calculateCancellationTier(cancelledAtMs, teeTimeMs) {
  const diffMs = teeTimeMs - cancelledAtMs; // positive = cancelled before tee time
  const hoursBeforeTeeTime = diffMs / (1000 * 60 * 60);
  let tier;
  if (hoursBeforeTeeTime >= 36) {
    tier = "early";
  } else if (hoursBeforeTeeTime >= 12) {
    tier = "late";
  } else {
    tier = "day_of";
  }
  return { tier, hoursBeforeTeeTime };
}

/**
 * Callable: recordCancellation
 *
 * Records a cancellation for a player leaving a game. Computes the tier
 * based on how far in advance of tee time the cancellation happens and
 * writes a cancellation_records document.
 *
 * After writing, if the tier is 'day_of', immediately issues 1 strike.
 * If the tier is 'late', checks for the 3-in-90-days pattern and issues
 * 1 strike if the threshold is reached.
 * Early cancels never generate strikes.
 *
 * Expected payload: { gameId: string, userId: string }
 * Returns: {
 *   success: true,
 *   recordId: string,
 *   tier: string,
 *   hoursBeforeTeeTime: number,
 *   strikeIssued: boolean,
 *   strikeId: string|null,
 *   activeStrikeCount: number,
 *   restriction: object
 * }
 */
const recordCancellation = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const { gameId, userId } = data || {};

    if (typeof gameId !== "string" || gameId.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid gameId is required."
      );
    }
    if (typeof userId !== "string" || userId.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid userId is required."
      );
    }
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Authenticated user does not match provided userId."
      );
    }

    try {
      const db = admin.firestore();
      const gameRef = db.collection("games").doc(gameId);
      const gameSnapshot = await gameRef.get();

      if (!gameSnapshot.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          `Game ${gameId} not found.`
        );
      }

      const gameData = gameSnapshot.data();

      // Tee time is the 'date' field on the game document (a Firestore Timestamp).
      const teeTimeTs = gameData.date;
      if (!teeTimeTs || typeof teeTimeTs.toMillis !== "function") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Game does not have a valid tee time (date field)."
        );
      }

      const cancelledAtMs = Date.now();
      const teeTimeMs = teeTimeTs.toMillis();
      const { tier, hoursBeforeTeeTime } = calculateCancellationTier(
        cancelledAtMs,
        teeTimeMs
      );

      const playerRef = db.collection("users").doc(userId);
      const gameType =
        typeof gameData.game_type === "string" ? gameData.game_type : "";

      const recordData = {
        player_ref: playerRef,
        game_ref: gameRef,
        cancelled_at: admin.firestore.Timestamp.fromMillis(cancelledAtMs),
        tee_time: teeTimeTs, // copy of game's tee time at cancellation
        hours_before_tee_time: hoursBeforeTeeTime,
        tier: tier,
        game_type: gameType,
        is_ghost: false,
      };

      const docRef = await db.collection("cancellation_records").add(recordData);

      console.log(
        `recordCancellation: wrote ${docRef.id} for user ${userId}, ` +
          `game ${gameId}, tier=${tier}, hours=${hoursBeforeTeeTime.toFixed(2)}`
      );

      // ── Strike logic ──────────────────────────────────────────────────────
      let strikeIssued = false;
      let strikeId = null;

      if (tier === "day_of") {
        // Day-of cancel → 1 strike immediately
        const strike = await recordStrike(db, {
          playerRef,
          gameRef,
          reason: "day_of_cancel",
          cancellationRecordId: docRef.id,
          nowMs: cancelledAtMs,
        });
        strikeIssued = true;
        strikeId = strike.id;
        console.log(
          `recordCancellation: issued strike ${strike.id} (day_of_cancel) for user ${userId}`
        );
      } else if (tier === "late") {
        // Late cancel → check 3-in-90-days pattern
        const patternStrike = await checkLateCancelPattern(db, {
          playerRef,
          gameRef,
          cancellationRecordId: docRef.id,
          nowMs: cancelledAtMs,
        });
        if (patternStrike) {
          strikeIssued = true;
          strikeId = patternStrike.id;
          console.log(
            `recordCancellation: issued strike ${patternStrike.id} (late_cancel_pattern) for user ${userId}`
          );
        }
      }
      // Early cancels: no strike logic

      // ── Return current restriction state ─────────────────────────────────
      const activeCount = await getActiveStrikeCount(db, playerRef, cancelledAtMs);
      const restriction = getRestrictionForStrikes(activeCount);

      return {
        success: true,
        recordId: docRef.id,
        tier,
        hoursBeforeTeeTime,
        strikeIssued,
        strikeId,
        activeStrikeCount: activeCount,
        restriction,
      };
    } catch (error) {
      console.error("recordCancellation failed:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        `Failed to record cancellation: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 2 — STRIKE SYSTEM
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Pure function: maps an active strike count to a restriction descriptor.
 *
 * Returns an object with:
 *   level:       'none' | 'warning' | 'cooldown' | 'restricted' | 'suspended'
 *   strikeCount: number passed in
 *   message:     human-readable description
 *   durationMs:  null for none/warning/suspended, duration in ms for timed restrictions
 *   requiresManualReview: boolean — true only for suspension
 *
 * @param {number} activeStrikes
 * @returns {{ level: string, strikeCount: number, message: string, durationMs: number|null, requiresManualReview: boolean }}
 */
function getRestrictionForStrikes(activeStrikes) {
  if (activeStrikes <= 0) {
    return {
      level: "none",
      strikeCount: activeStrikes,
      message: "No active strikes. Account in good standing.",
      durationMs: null,
      requiresManualReview: false,
    };
  }
  if (activeStrikes === 1) {
    return {
      level: "warning",
      strikeCount: 1,
      message: "1 active strike. Private warning — no restrictions on joining games.",
      durationMs: null,
      requiresManualReview: false,
    };
  }
  if (activeStrikes === 2) {
    return {
      level: "cooldown",
      strikeCount: 2,
      message: "2 active strikes. 24-hour cooldown before joining new games.",
      durationMs: 24 * 60 * 60 * 1000, // 24 hours
      requiresManualReview: false,
    };
  }
  if (activeStrikes === 3) {
    return {
      level: "restricted",
      strikeCount: 3,
      message: "3 active strikes. Restricted for 7 days — cannot join or create games.",
      durationMs: 7 * 24 * 60 * 60 * 1000, // 7 days
      requiresManualReview: false,
    };
  }
  if (activeStrikes === 4) {
    return {
      level: "restricted",
      strikeCount: 4,
      message: "4 active strikes. Restricted for 30 days. Account flagged for team review.",
      durationMs: 30 * 24 * 60 * 60 * 1000, // 30 days
      requiresManualReview: true,
    };
  }
  // 5+
  return {
    level: "suspended",
    strikeCount: activeStrikes,
    message: `${activeStrikes} active strikes. Account suspended. Manual review required before reinstatement.`,
    durationMs: null,
    requiresManualReview: true,
  };
}

/**
 * Writes a single strike document to the `strikes` collection.
 *
 * Strike document fields:
 *   player_ref         - DocumentReference to the user
 *   game_ref           - DocumentReference to the game that triggered this
 *   reason             - 'day_of_cancel' | 'late_cancel_pattern' | 'ghost_no_show'
 *   created_at         - Firestore Timestamp
 *   expires_at         - Firestore Timestamp (6 months from created_at)
 *   cancellation_record_id - string | null (the cancellation_records doc ID, if applicable)
 *   is_expired         - boolean (false at write time; updated by expiry sweep or query-time check)
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {{ playerRef, gameRef, reason: string, cancellationRecordId: string|null, nowMs: number }} opts
 * @returns {Promise<FirebaseFirestore.DocumentReference>}
 */
async function recordStrike(db, { playerRef, gameRef, reason, cancellationRecordId, nowMs }) {
  const expiresAtMs = nowMs + STRIKE_EXPIRY_MS;
  const strikeData = {
    player_ref: playerRef,
    game_ref: gameRef,
    reason: reason,
    created_at: admin.firestore.Timestamp.fromMillis(nowMs),
    expires_at: admin.firestore.Timestamp.fromMillis(expiresAtMs),
    cancellation_record_id: cancellationRecordId || null,
    is_expired: false,
  };
  const ref = await db.collection("strikes").add(strikeData);
  return ref;
}

/**
 * Counts non-expired strikes for a player at a given point in time.
 *
 * A strike is active if its expires_at > nowMs.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {FirebaseFirestore.DocumentReference} playerRef
 * @param {number} nowMs
 * @returns {Promise<number>}
 */
async function getActiveStrikeCount(db, playerRef, nowMs) {
  const expiryThreshold = admin.firestore.Timestamp.fromMillis(nowMs);
  const snapshot = await db
    .collection("strikes")
    .where("player_ref", "==", playerRef)
    .where("expires_at", ">", expiryThreshold)
    .get();
  return snapshot.size;
}

/**
 * Checks whether the player has accumulated 3+ late cancels within the
 * rolling 90-day window ending at nowMs. If so, writes 1 strike for the
 * 'late_cancel_pattern' reason and returns the strike DocumentReference.
 * Returns null if the threshold has not been met.
 *
 * The 90-day window looks at ALL late cancels (including the one just written)
 * that have cancelled_at >= (nowMs - LATE_CANCEL_WINDOW_MS).
 *
 * To prevent double-issuing, we also check whether a 'late_cancel_pattern'
 * strike already exists for this exact batch of 3 cancels. We do this by
 * querying for any late_cancel_pattern strike created within the same 90-day
 * window. If one already exists (i.e., a prior batch already triggered a
 * strike), we only issue a new strike if the current count has crossed another
 * multiple of LATE_CANCEL_STRIKE_THRESHOLD beyond those already covered.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {{ playerRef, gameRef, cancellationRecordId: string, nowMs: number }} opts
 * @returns {Promise<FirebaseFirestore.DocumentReference|null>}
 */
async function checkLateCancelPattern(db, { playerRef, gameRef, cancellationRecordId, nowMs }) {
  const windowStartMs = nowMs - LATE_CANCEL_WINDOW_MS;
  const windowStartTs = admin.firestore.Timestamp.fromMillis(windowStartMs);
  const nowTs = admin.firestore.Timestamp.fromMillis(nowMs);

  // Count late cancels in the 90-day window.
  const lateCancelsSnap = await db
    .collection("cancellation_records")
    .where("player_ref", "==", playerRef)
    .where("tier", "==", "late")
    .where("cancelled_at", ">=", windowStartTs)
    .where("cancelled_at", "<=", nowTs)
    .get();

  const lateCancelCount = lateCancelsSnap.size;

  if (lateCancelCount < LATE_CANCEL_STRIKE_THRESHOLD) {
    return null; // Not enough late cancels yet
  }

  // Count existing late_cancel_pattern strikes in the same 90-day window
  // to handle repeat offenses (every 3 late cancels = 1 more strike).
  const existingPatternStrikesSnap = await db
    .collection("strikes")
    .where("player_ref", "==", playerRef)
    .where("reason", "==", "late_cancel_pattern")
    .where("created_at", ">=", windowStartTs)
    .where("created_at", "<=", nowTs)
    .get();

  const existingPatternStrikes = existingPatternStrikesSnap.size;
  const strikesEarned = Math.floor(lateCancelCount / LATE_CANCEL_STRIKE_THRESHOLD);

  if (strikesEarned <= existingPatternStrikes) {
    return null; // Already issued the appropriate number of strikes
  }

  // Issue 1 new strike for the latest batch of 3.
  const strike = await recordStrike(db, {
    playerRef,
    gameRef,
    reason: "late_cancel_pattern",
    cancellationRecordId,
    nowMs,
  });

  return strike;
}

/**
 * Callable: checkPlayerRestriction
 *
 * Returns the caller's current active strike count and restriction status.
 * Always operates on the authenticated user's own data (no userId param needed —
 * users cannot query other players' strike data).
 *
 * Returns: {
 *   userId: string,
 *   activeStrikeCount: number,
 *   restriction: {
 *     level: string,
 *     strikeCount: number,
 *     message: string,
 *     durationMs: number|null,
 *     requiresManualReview: boolean
 *   },
 *   isRestricted: boolean,        // true if level is not 'none' or 'warning'
 *   restrictionEndsAt: string|null, // ISO timestamp of when restriction lifts, or null
 *   strikes: Array<{              // Active strikes detail
 *     id: string,
 *     reason: string,
 *     createdAt: string,
 *     expiresAt: string,
 *     gameId: string|null
 *   }>
 * }
 */
const checkPlayerRestriction = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const userId = context.auth.uid;

    try {
      const db = admin.firestore();
      const playerRef = db.collection("users").doc(userId);
      const nowMs = Date.now();
      const expiryThreshold = admin.firestore.Timestamp.fromMillis(nowMs);

      // Fetch all active (non-expired) strikes for this player.
      const strikesSnap = await db
        .collection("strikes")
        .where("player_ref", "==", playerRef)
        .where("expires_at", ">", expiryThreshold)
        .orderBy("expires_at", "asc") // Oldest expiry first
        .get();

      const activeStrikeCount = strikesSnap.size;
      const restriction = getRestrictionForStrikes(activeStrikeCount);

      // Determine if the player is currently restricted and when the restriction lifts.
      // The restriction period is measured from the most recently created active strike.
      let isRestricted = false;
      let restrictionEndsAt = null;

      if (restriction.level !== "none" && restriction.level !== "warning" && restriction.level !== "suspended") {
        // Timed restriction: find the most recently created active strike.
        const strikesByCreation = strikesSnap.docs.sort((a, b) =>
          b.data().created_at.toMillis() - a.data().created_at.toMillis()
        );
        if (strikesByCreation.length > 0) {
          const mostRecentCreatedAtMs = strikesByCreation[0].data().created_at.toMillis();
          const restrictionEndMs = mostRecentCreatedAtMs + restriction.durationMs;
          if (restrictionEndMs > nowMs) {
            isRestricted = true;
            restrictionEndsAt = new Date(restrictionEndMs).toISOString();
          }
        }
      } else if (restriction.level === "suspended") {
        isRestricted = true;
        restrictionEndsAt = null; // Manual review — no automatic end
      }

      // Build strikes detail array for the player's "Your Standing" view.
      const strikesDetail = strikesSnap.docs.map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          reason: d.reason,
          createdAt: d.created_at.toDate().toISOString(),
          expiresAt: d.expires_at.toDate().toISOString(),
          gameId: d.game_ref ? d.game_ref.id : null,
        };
      });

      console.log(
        `checkPlayerRestriction: user ${userId} has ${activeStrikeCount} active strike(s), ` +
          `level=${restriction.level}, isRestricted=${isRestricted}`
      );

      return {
        userId,
        activeStrikeCount,
        restriction,
        isRestricted,
        restrictionEndsAt,
        strikes: strikesDetail,
      };
    } catch (error) {
      console.error("checkPlayerRestriction failed:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        `Failed to check player restriction: ${error.message}`
      );
    }
  });

/**
 * Callable: markGhostNoShow
 *
 * Called by a host (or scheduled function) to mark a player as a ghost
 * no-show after the tee time has passed without communication.
 *
 * Writes a cancellation_records document with is_ghost=true, then
 * immediately issues 2 strikes for the 'ghost_no_show' reason.
 *
 * Expected payload: { gameId: string, targetUserId: string }
 * The caller must be the game host.
 *
 * Returns: {
 *   success: true,
 *   cancellationRecordId: string,
 *   strikeIds: [string, string],
 *   activeStrikeCount: number,
 *   restriction: object
 * }
 */
const markGhostNoShow = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const { gameId, targetUserId } = data || {};

    if (typeof gameId !== "string" || gameId.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid gameId is required."
      );
    }
    if (typeof targetUserId !== "string" || targetUserId.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid targetUserId is required."
      );
    }

    try {
      const db = admin.firestore();
      const gameRef = db.collection("games").doc(gameId);
      const gameSnapshot = await gameRef.get();

      if (!gameSnapshot.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          `Game ${gameId} not found.`
        );
      }

      const gameData = gameSnapshot.data();

      // Verify the caller is the game host.
      const hostRef = gameData.host_ref;
      const callerIsHost =
        hostRef &&
        typeof hostRef.id === "string" &&
        hostRef.id === context.auth.uid;

      if (!callerIsHost) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only the game host can mark ghost no-shows."
        );
      }

      // Verify the tee time has passed (must be after tee time to mark a ghost).
      const teeTimeTs = gameData.date;
      if (!teeTimeTs || typeof teeTimeTs.toMillis !== "function") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Game does not have a valid tee time (date field)."
        );
      }

      const nowMs = Date.now();
      const teeTimeMs = teeTimeTs.toMillis();

      if (nowMs < teeTimeMs) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Cannot mark a ghost no-show before the tee time has passed."
        );
      }

      const targetPlayerRef = db.collection("users").doc(targetUserId);
      const gameType =
        typeof gameData.game_type === "string" ? gameData.game_type : "";

      // Write the cancellation record as a ghost.
      const ghostRecordData = {
        player_ref: targetPlayerRef,
        game_ref: gameRef,
        cancelled_at: admin.firestore.Timestamp.fromMillis(nowMs),
        tee_time: teeTimeTs,
        hours_before_tee_time: 0, // Ghost: did not cancel before tee time
        tier: "day_of",           // Treat as worst tier for metrics
        game_type: gameType,
        is_ghost: true,
      };

      const cancellationRef = await db.collection("cancellation_records").add(ghostRecordData);

      // Issue 2 strikes immediately for ghost no-show.
      const [strike1, strike2] = await Promise.all([
        recordStrike(db, {
          playerRef: targetPlayerRef,
          gameRef,
          reason: "ghost_no_show",
          cancellationRecordId: cancellationRef.id,
          nowMs,
        }),
        recordStrike(db, {
          playerRef: targetPlayerRef,
          gameRef,
          reason: "ghost_no_show",
          cancellationRecordId: cancellationRef.id,
          nowMs,
        }),
      ]);

      console.log(
        `markGhostNoShow: wrote ghost record ${cancellationRef.id} and ` +
          `strikes ${strike1.id}, ${strike2.id} for user ${targetUserId}, game ${gameId}`
      );

      const activeCount = await getActiveStrikeCount(db, targetPlayerRef, nowMs);
      const restriction = getRestrictionForStrikes(activeCount);

      return {
        success: true,
        cancellationRecordId: cancellationRef.id,
        strikeIds: [strike1.id, strike2.id],
        activeStrikeCount: activeCount,
        restriction,
      };
    } catch (error) {
      console.error("markGhostNoShow failed:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        `Failed to mark ghost no-show: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 1 — GAME CREATION VALIDATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: validateGameAppUserCount
 *
 * Client-side validation callable used before game creation to confirm
 * the proposed participant list has at least 2 app users (non-guests).
 *
 * Expected payload: { participantUids: string[] }
 * Returns: { valid: true, appUserCount: number }
 * Throws invalid-argument if count < 2.
 */
const validateGameAppUserCount = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const participantUids = data && data.participantUids;
    if (!Array.isArray(participantUids)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "participantUids must be an array of user ID strings."
      );
    }

    const appUserCount = participantUids.filter(
      (uid) => typeof uid === "string" && uid.length > 0
    ).length;

    if (appUserCount < 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `A game requires at least 2 app users. Got ${appUserCount}.`
      );
    }

    return { valid: true, appUserCount };
  });

/**
 * Firestore trigger: onGameCreate
 *
 * Server-side safety net. Validates that a newly created game has at least
 * 2 app users in joined_players. If not, marks the game cancelled with a
 * reason field rather than deleting it (preserves auditability).
 *
 * Clients should call validateGameAppUserCount before creating a game.
 * This trigger catches any direct Firestore writes that bypass the callable.
 *
 * NOTE: Does not interfere with other onCreate triggers on games/{gameId}
 * (e.g. syncGameChatMembers) — Firestore runs them independently.
 */
const onGameCreate = functions
  .region("us-west2")
  .firestore.document("games/{gameId}")
  .onCreate(async (snapshot, context) => {
    const gameData = snapshot.data();
    const joinedPlayers = Array.isArray(gameData.joined_players)
      ? gameData.joined_players
      : [];

    // Count app users: entries that are DocumentReferences (duck-typed) or path strings.
    // admin.firestore.DocumentReference is not reliably accessible in the Functions
    // emulator runtime — use duck typing instead.
    const appUserCount = joinedPlayers.filter((entry) => {
      if (!entry) return false;
      if (typeof entry === "object" && typeof entry.id === "string" && entry.id.length > 0) return true;
      // Firestore path strings like "users/abc123"
      if (typeof entry === "string" && entry.includes("/")) return true;
      return false;
    }).length;

    if (appUserCount < 2) {
      console.warn(
        `onGameCreate: game ${context.params.gameId} has only ` +
          `${appUserCount} app user(s) in joined_players. Minimum is 2. Cancelling.`
      );
      await snapshot.ref.update({
        status: "cancelled",
        isCancelled: true,
        cancellation_reason: "insufficient_app_users",
      });
    }
  });

module.exports = {
  // Stage 1
  calculateCancellationTier,
  recordCancellation,
  validateGameAppUserCount,
  onGameCreate,
  // Stage 2 — callables
  checkPlayerRestriction,
  markGhostNoShow,
  // Stage 2 — internal helpers (exported for testing)
  recordStrike,
  checkLateCancelPattern,
  getActiveStrikeCount,
  getRestrictionForStrikes,
  LATE_CANCEL_WINDOW_MS,
  STRIKE_EXPIRY_MS,
  LATE_CANCEL_STRIKE_THRESHOLD,
};
