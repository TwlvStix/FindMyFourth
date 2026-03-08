/**
 * lifecycle.js
 * Manages the participation status state machine.
 *
 * STATUS FLOW:
 *   invited → confirmed → checked_in → completed
 *                ↘ declined
 *                ↘ cancelled     (after confirming, before tee time)
 *                ↘ no_show       (confirmed but didn't check in)
 *                ↘ early_departure (checked in but left before round end)
 *
 * Every transition is timestamped in status_history.
 * Cancellations after seeing the group roster are flagged — this is
 * one of the strongest negative signals in the dataset.
 */

const admin = require("firebase-admin");
const db = admin.firestore();
const {
  PARTICIPATION_STATUSES,
  CANCELLATION_REASONS,
  logEvent,
  validateRequired,
  validateEnum,
} = require("./utils");

// Valid transitions — prevents illegal state changes
const VALID_TRANSITIONS = {
  invited: ["confirmed", "declined"],
  confirmed: ["checked_in", "cancelled", "no_show"],
  checked_in: ["completed", "early_departure"],
  // Terminal states — no transitions out
  completed: [],
  declined: [],
  cancelled: [],
  no_show: [],
  early_departure: [],
};

// ─────────────────────────────────────────────
// UPDATE PARTICIPATION STATUS
// ─────────────────────────────────────────────

/**
 * Transitions a participant to a new status.
 * Validates the transition is legal, appends to status_history,
 * and flags cancellations that happened after seeing the group.
 *
 * @param {Object} params
 * @param {string} params.round_id
 * @param {string} params.player_id
 * @param {string} params.new_status - Target status
 * @param {string|null} params.cancellation_reason - Required if new_status is "cancelled"
 * @returns {Promise<Object>} Updated participant data
 */
async function updateParticipationStatus({
  round_id,
  player_id,
  new_status,
  cancellation_reason = null,
}) {
  validateRequired({ round_id, player_id, new_status }, [
    "round_id",
    "player_id",
    "new_status",
  ]);
  validateEnum(new_status, PARTICIPATION_STATUSES, "new_status");

  if (new_status === "cancelled" && cancellation_reason) {
    validateEnum(cancellation_reason, CANCELLATION_REASONS, "cancellation_reason");
  }

  const participantRef = db
    .collection("rounds")
    .doc(round_id)
    .collection("participants")
    .doc(player_id);

  const roundRef = db.collection("rounds").doc(round_id);

  // Run in a transaction to prevent race conditions
  const result = await db.runTransaction(async (transaction) => {
    const participantDoc = await transaction.get(participantRef);
    if (!participantDoc.exists) {
      throw new Error(
        `Participant ${player_id} not found in round ${round_id}`
      );
    }

    const currentData = participantDoc.data();
    const currentStatus = currentData.participation_status;

    // Validate transition
    const allowed = VALID_TRANSITIONS[currentStatus];
    if (!allowed || !allowed.includes(new_status)) {
      throw new Error(
        `Invalid transition: ${currentStatus} → ${new_status}. ` +
        `Allowed transitions from "${currentStatus}": ${(allowed || []).join(", ") || "none (terminal state)"}`
      );
    }

    const now = new Date();
    const statusEntry = {
      status: new_status,
      timestamp: now.toISOString(),
    };

    // Determine if cancellation happened after seeing the group
    let cancelledAfterSeeingGroup = null;
    if (new_status === "cancelled") {
      const roundDoc = await transaction.get(roundRef);
      const roundData = roundDoc.data();

      if (roundData.group_finalized_at) {
        const finalizedAt = roundData.group_finalized_at.toDate
          ? roundData.group_finalized_at.toDate()
          : new Date(roundData.group_finalized_at);
        cancelledAfterSeeingGroup = now > finalizedAt;
      } else {
        cancelledAfterSeeingGroup = false;
      }
    }

    const updateData = {
      participation_status: new_status,
      status_history: admin.firestore.FieldValue.arrayUnion(statusEntry),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (new_status === "cancelled") {
      updateData.cancelled_after_seeing_group = cancelledAfterSeeingGroup;
      updateData.cancellation_reason = cancellation_reason;
    }

    transaction.update(participantRef, updateData);

    return {
      player_id,
      round_id,
      previous_status: currentStatus,
      new_status,
      cancelled_after_seeing_group: cancelledAfterSeeingGroup,
      cancellation_reason,
    };
  });

  // Log the status change event
  await logEvent({
    event_type: "status_change",
    round_id,
    player_id,
    payload: {
      previous_status: result.previous_status,
      new_status: result.new_status,
      cancelled_after_seeing_group: result.cancelled_after_seeing_group,
      cancellation_reason: result.cancellation_reason,
    },
  });

  return result;
}

// ─────────────────────────────────────────────
// CONVENIENCE METHODS
// ─────────────────────────────────────────────

/** Confirm an invited player. */
async function confirmParticipant(round_id, player_id) {
  return updateParticipationStatus({ round_id, player_id, new_status: "confirmed" });
}

/** Decline an invitation. */
async function declineParticipant(round_id, player_id) {
  return updateParticipationStatus({ round_id, player_id, new_status: "declined" });
}

/** Cancel a confirmed participant. */
async function cancelParticipant(round_id, player_id, cancellation_reason = "other") {
  return updateParticipationStatus({
    round_id,
    player_id,
    new_status: "cancelled",
    cancellation_reason,
  });
}

/** Check in a confirmed participant at the course. */
async function checkInParticipant(round_id, player_id) {
  return updateParticipationStatus({ round_id, player_id, new_status: "checked_in" });
}

/** Mark a participant as having completed the round. */
async function completeParticipant(round_id, player_id) {
  return updateParticipationStatus({ round_id, player_id, new_status: "completed" });
}

/** Mark a confirmed participant as a no-show. */
async function markNoShow(round_id, player_id) {
  return updateParticipationStatus({ round_id, player_id, new_status: "no_show" });
}

/** Mark a checked-in participant as having left early. */
async function markEarlyDeparture(round_id, player_id) {
  return updateParticipationStatus({ round_id, player_id, new_status: "early_departure" });
}

// ─────────────────────────────────────────────
// COMPLETE ROUND
// ─────────────────────────────────────────────

/**
 * Marks the round as completed and transitions all checked-in participants
 * to "completed" status. Also detects no-shows (confirmed but not checked in).
 *
 * Call this when the round ends.
 *
 * @param {string} roundId
 * @returns {Promise<Object>} Summary of completions and no-shows
 */
async function completeRound(roundId) {
  const participantsSnapshot = await db
    .collection("rounds")
    .doc(roundId)
    .collection("participants")
    .get();

  const results = { completed: [], no_shows: [] };
  const now = new Date();
  const batch = db.batch();

  for (const doc of participantsSnapshot.docs) {
    const data = doc.data();
    const playerId = data.player_id;

    if (data.participation_status === "checked_in") {
      batch.update(doc.ref, {
        participation_status: "completed",
        status_history: admin.firestore.FieldValue.arrayUnion({
          status: "completed",
          timestamp: now.toISOString(),
        }),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      results.completed.push(playerId);
    } else if (data.participation_status === "confirmed") {
      // Confirmed but never checked in = no-show
      batch.update(doc.ref, {
        participation_status: "no_show",
        status_history: admin.firestore.FieldValue.arrayUnion({
          status: "no_show",
          timestamp: now.toISOString(),
        }),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      results.no_shows.push(playerId);
    }
    // Other statuses (declined, cancelled) are already terminal — skip
  }

  // Update the round status in the same batch
  const roundRef = db.collection("rounds").doc(roundId);
  batch.update(roundRef, {
    round_status: "completed",
    completed_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  // Log events in parallel after commit
  const logPromises = [];

  for (const playerId of results.completed) {
    logPromises.push(logEvent({
      event_type: "status_change",
      round_id: roundId,
      player_id: playerId,
      payload: {
        previous_status: "checked_in",
        new_status: "completed",
        cancelled_after_seeing_group: null,
        cancellation_reason: null,
      },
    }));
  }

  for (const playerId of results.no_shows) {
    logPromises.push(logEvent({
      event_type: "status_change",
      round_id: roundId,
      player_id: playerId,
      payload: {
        previous_status: "confirmed",
        new_status: "no_show",
        cancelled_after_seeing_group: null,
        cancellation_reason: null,
      },
    }));
  }

  logPromises.push(logEvent({
    event_type: "round_completed",
    round_id: roundId,
    payload: {
      completed_players: results.completed,
      no_show_players: results.no_shows,
    },
  }));

  await Promise.all(logPromises);

  return results;
}

// ─────────────────────────────────────────────
// DETECT NO-SHOWS (Scheduled)
// ─────────────────────────────────────────────

/**
 * Scans for rounds past their tee time where participants are still
 * "confirmed" (never checked in). Marks them as no-shows.
 *
 * Run this as a scheduled Cloud Function, e.g., every hour.
 *
 * @param {number} graceMinutes - Minutes past tee time before marking no-show (default: 60)
 * @returns {Promise<Object[]>} Array of { round_id, player_id } no-shows detected
 */
async function detectNoShows(graceMinutes = 60) {
  const cutoff = new Date(Date.now() - graceMinutes * 60 * 1000);

  // Find rounds that are past tee time + grace period and still scheduled/in_progress
  const roundsSnapshot = await db
    .collection("rounds")
    .where("round_status", "in", ["scheduled", "in_progress"])
    .where("tee_time", "<", admin.firestore.Timestamp.fromDate(cutoff))
    .get();

  const noShows = [];

  for (const roundDoc of roundsSnapshot.docs) {
    const roundId = roundDoc.id;
    const participantsSnapshot = await db
      .collection("rounds")
      .doc(roundId)
      .collection("participants")
      .where("participation_status", "==", "confirmed")
      .get();

    for (const pDoc of participantsSnapshot.docs) {
      const playerId = pDoc.data().player_id;
      await markNoShow(roundId, playerId);
      noShows.push({ round_id: roundId, player_id: playerId });
    }
  }

  return noShows;
}

module.exports = {
  updateParticipationStatus,
  confirmParticipant,
  declineParticipant,
  cancelParticipant,
  checkInParticipant,
  completeParticipant,
  markNoShow,
  markEarlyDeparture,
  completeRound,
  detectNoShows,
  VALID_TRANSITIONS,
};
