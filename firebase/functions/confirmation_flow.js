/**
 * Confirmation Flow Cloud Functions — Stage 3
 *
 * This module handles the post-round confirmation flow that fires after
 * each game's tee time, collecting host attendance confirmation and
 * peer ratings from all app users.
 *
 * Flow timeline (relative to tee time T):
 *   T+0h  → Game status transitions to 'played' (auto-sweep)
 *            onGameStatusToPlayed creates round_jobs + initial round_records doc
 *   T+5h  → processConfirmationJobs sends host check-in notification
 *   Host confirms → submitHostCheckin updates attendance, triggers no-show strikes,
 *                   schedules peer rating notifications for T+30min later
 *   T+5h30m → peer rating notifications sent to all present app users
 *   T+24h → if host has not responded: 24h reminder to host + fallback to all app users
 *   T+48h → window closed; no more submissions accepted
 *
 * Stage 0 prerequisite (also in this module):
 *   onGameParticipantJoin → writes profile_snapshot + vibe_scores_with_others
 *   onto each game_participants doc at join time. This data is later copied
 *   (never recomputed) into the round_records doc.
 *
 * Exports:
 *   onGameParticipantJoin  - Firestore trigger: captures snapshot + vibe scores at join time
 *   onGameStatusToPlayed   - Firestore trigger: creates round_jobs + round_records
 *   processConfirmationJobs - Scheduled: sweeps pending jobs every 15 min
 *   submitHostCheckin      - Callable: host submits attendance confirmation
 *   submitPeerRatings      - Callable: app user submits play-again ratings
 *   submitFallbackConfirmation - Callable: fallback "did you play?" response
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const trustProfile = require("./trust_profile");
const streaks = require("./streaks");
const { routeNotification } = require('./notifications/trust/router');
const { onGameConfirmed, onHostCheckinCompleted, onGameCancelled } = require('./notifications/trust/hooks');
const { onJoinRequestExpired } = require('./join_request_notifications');
const { randomUUID } = require('crypto');
const { CloudTasksClient } = require('@google-cloud/tasks');

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const HOST_NOTIFY_OFFSET_MS = 5 * 60 * 60 * 1000;        // 5 hours
const PEER_NOTIFY_OFFSET_MS = 30 * 60 * 1000;            // 30 min after host confirms
const REMINDER_OFFSET_MS = 24 * 60 * 60 * 1000;          // 24 hours
const CLOSE_OFFSET_MS = 48 * 60 * 60 * 1000;             // 48 hours

// Pre-game confirmation timing (partial games only)
const PRE_GAME_CHECK_OFFSET_MS = 45 * 60 * 1000;         // 45 minutes before tee time
const PRE_GAME_TIMEOUT_MS = 20 * 60 * 1000;              // 20 minutes to respond

const PROJECT = process.env.GCLOUD_PROJECT || 'find-my-fourth';
const LOCATION = 'us-west2';
const QUEUE_NAME = 'trust-notification-scheduler';

/** Vibe categories used for server-side pair scoring at join time. */
const VIBE_CATEGORIES = ["drinking", "music", "pace", "money", "chat", "competitive"];

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 0 — PARTICIPANT JOIN: SNAPSHOT + VIBE SCORES
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for onGameParticipantJoin.
 * Accepts the Firestore snapshot, context, and an injected db instance.
 * Exported directly so unit tests can call it without Firebase wrappers.
 */
async function _onGameParticipantJoinHandler(snapshot, context, db) {
  const data = snapshot.data();

  // Skip guest entries (no user_ref)
  const userRef = data.user_ref;
  if (!userRef || typeof userRef.id !== "string" || userRef.id.length === 0) {
    console.log(
      `onGameParticipantJoin: skipping guest entry ${context.params.participantId}`
    );
    return;
  }

  const gameRef = data.game_ref;
  if (!gameRef) {
    console.warn(
      `onGameParticipantJoin: participant ${context.params.participantId} has no game_ref`
    );
    return;
  }

  try {
    // ── 1. Fetch joining user profile ─────────────────────────────────────
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      console.warn(
        `onGameParticipantJoin: user ${userRef.id} not found, skipping snapshot`
      );
      return;
    }
    const userData = userSnap.data();

    // ── 2. Build profile snapshot ─────────────────────────────────────────
    const displayName = _getUserDisplayName(userData);
    const profileSnapshot = {
      uid: userRef.id,
      display_name: displayName,
      photo_url: typeof userData.photo_url === "string" ? userData.photo_url : "",
      handicap: typeof userData.handicap === "number" ? userData.handicap : 0,
      role: typeof data.role === "string" ? data.role : "player",
      snapshotted_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // ── 3. Fetch all other app user participants in this game ─────────────
    const otherParticipantsSnap = await db
      .collection("game_participants")
      .where("game_ref", "==", gameRef)
      .where("status", "==", "joined")
      .get();

    // Collect other app users (exclude self, exclude guests)
    const otherParticipantDocs = otherParticipantsSnap.docs.filter((doc) => {
      const d = doc.data();
      return (
        doc.id !== context.params.participantId &&
        d.user_ref &&
        typeof d.user_ref.id === "string" &&
        d.user_ref.id.length > 0
      );
    });

    // ── 4. Compute vibe scores with each other participant ────────────────
    const joiningVibeProfile = _extractVibeProfile(userData);
    const vibeScoresWithOthers = {};

    // Fetch all other user profiles in parallel
    let fetchSuccessCount = 0;
    let fetchFailureCount = 0;
    const otherUserFetches = otherParticipantDocs.map(async (doc) => {
      const otherData = doc.data();
      const otherUserRef = otherData.user_ref;
      try {
        const otherUserSnap = await otherUserRef.get();
        if (!otherUserSnap.exists) {
          fetchFailureCount++;
          return null;
        }
        fetchSuccessCount++;
        return {
          participantDoc: doc,
          otherUserId: otherUserRef.id,
          otherUserData: otherUserSnap.data(),
          otherParticipantRef: doc.ref,
        };
      } catch (err) {
        fetchFailureCount++;
        console.error(
          `onGameParticipantJoin: could not fetch user ${otherUserRef.id}: ${err.message}`
        );
        return null;
      }
    });

    const otherUserResults = await Promise.all(otherUserFetches);
    const otherUsers = otherUserResults.filter(Boolean);

    // Log fetch outcome summary
    const totalAttempted = otherParticipantDocs.length;
    if (totalAttempted > 0 && fetchSuccessCount === 0) {
      console.error(
        `onGameParticipantJoin: ALL user fetches failed (0/${totalAttempted}) for game ${gameRef.id}`
      );
    } else if (fetchFailureCount > 0) {
      console.warn(
        `onGameParticipantJoin: partial user fetch failure (${fetchSuccessCount}/${totalAttempted} succeeded) for game ${gameRef.id}`
      );
    }

    // Score each pair and collect updates for the other participants
    const otherParticipantUpdates = [];

    for (const other of otherUsers) {
      const otherVibeProfile = _extractVibeProfile(other.otherUserData);
      const score = _computeVibeScore(joiningVibeProfile, otherVibeProfile);

      // Score keyed by the other user's UID
      vibeScoresWithOthers[other.otherUserId] = score;

      // Schedule an update on the other participant's doc to add back this score
      otherParticipantUpdates.push({
        ref: other.otherParticipantRef,
        userId: userRef.id,
        score,
      });
    }

    // ── 5. Write snapshot + vibe scores onto this participant doc ─────────
    // Determine vibe score status for observability
    const totalAttemptedPeers = otherParticipantDocs.length;
    let vibeScoreStatus;
    if (totalAttemptedPeers === 0) {
      vibeScoreStatus = 'no_peers';
    } else if (fetchFailureCount === 0) {
      vibeScoreStatus = 'complete';
    } else if (fetchSuccessCount > 0) {
      vibeScoreStatus = 'partial';
    } else {
      vibeScoreStatus = 'failed';
    }

    await snapshot.ref.update({
      profile_snapshot: profileSnapshot,
      vibe_scores_with_others: vibeScoresWithOthers,
      vibe_score_status: vibeScoreStatus,
      vibe_score_peer_count: fetchSuccessCount,
      vibe_score_attempted_count: totalAttemptedPeers,
    });

    // ── 6. Update each other participant's vibe_scores_with_others ────────
    if (otherParticipantUpdates.length > 0) {
      const batch = db.batch();
      for (const update of otherParticipantUpdates) {
        batch.update(update.ref, {
          [`vibe_scores_with_others.${update.userId}`]: update.score,
        });
      }
      await batch.commit();
    }

    console.log(
      `onGameParticipantJoin: wrote snapshot + vibe scores for user ${userRef.id} ` +
        `in game ${gameRef.id} (${otherParticipantUpdates.length} peer(s) updated)`
    );
  } catch (error) {
    // Never block the join flow — log with structured data and write status
    console.error(
      `onGameParticipantJoin: non-fatal error for participant ${context.params.participantId}`,
      {
        gameId: data.game_ref ? data.game_ref.id : 'unknown',
        userId: userRef ? userRef.id : 'unknown',
        error: error.message,
        stack: error.stack,
      }
    );

    // Best-effort: write error status to participant doc for observability
    try {
      await snapshot.ref.update({
        vibe_score_status: 'error',
      });
    } catch (_) {
      // Ignore — we're already in the error handler
    }
  }
}

/**
 * Firestore trigger: onGameParticipantJoin
 *
 * Fires when a new game_participants document is created.
 * This is the ONLY place profile snapshots and vibe match scores are computed.
 * The confirmation flow copies this data — it never recomputes it.
 */
const onGameParticipantJoin = functions
  .region("us-west2")
  .firestore.document("game_participants/{participantId}")
  .onCreate(async (snapshot, context) => {
    return _onGameParticipantJoinHandler(snapshot, context, admin.firestore());
  });

// ─────────────────────────────────────────────────────────────────────────────
// GAME STATUS TRANSITION — onGameStatusToFilled
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for onGameStatusToFilled.
 *
 * NOTE: Tee-time Cloud Task scheduling is now handled by onGameCreated for ALL games.
 * This trigger only handles the edge case where a game fills AFTER tee time has passed,
 * flipping the status to 'played' immediately.
 *
 * This trigger fires on EVERY games/{gameId} update. It guards with
 * status checks so it only runs when a game transitions TO 'filled'.
 */
async function _onGameStatusToFilledHandler(change, context, db) {
  const before = change.before.data();
  const after = change.after.data();

  // Only fire on transition TO 'filled'
  if (after.status !== 'filled' || before.status === 'filled') return;

  // Don't flip if cancelled
  if (after.isCancelled === true) return;

  const gameId = context.params.gameId;
  const teeTimeTs = after.date;

  if (!teeTimeTs || typeof teeTimeTs.toMillis !== 'function') {
    console.warn(`onGameStatusToFilled: game ${gameId} has no valid tee time, skipping`);
    return;
  }

  const teeTimeMs = teeTimeTs.toMillis();

  // If tee time is already in the past, flip immediately
  // (Tee-time scheduling is handled by onGameCreated, but this catches
  // games that fill after the scheduled task already ran)
  if (teeTimeMs <= Date.now()) {
    await change.after.ref.update({ status: 'played' });
    console.log(`onGameStatusToFilled: game ${gameId} tee time already passed, flipped to played immediately`);
    return;
  }

  // No scheduling needed — onGameCreated already scheduled the tee-time task
  console.log(`onGameStatusToFilled: game ${gameId} filled, tee-time task already scheduled by onGameCreated`);
}

const onGameStatusToFilled = functions
  .region('us-west2')
  .firestore.document('games/{gameId}')
  .onUpdate(async (change, context) => {
    return _onGameStatusToFilledHandler(change, context, admin.firestore());
  });

// ─────────────────────────────────────────────────────────────────────────────
// GAME CREATION — onGameCreated
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for onGameCreated.
 * Schedules a Cloud Task at tee time to transition the game to 'played'.
 *
 * This ensures ALL games (not just filled ones) get their status updated
 * and post-game notifications scheduled when tee time arrives.
 */
async function _onGameCreatedHandler(snapshot, context, db) {
  const gameData = snapshot.data();
  const gameId = context.params.gameId;
  const teeTimeTs = gameData.date;

  if (!teeTimeTs || typeof teeTimeTs.toMillis !== 'function') {
    console.warn(`onGameCreated: game ${gameId} has no valid tee time, skipping`);
    return;
  }

  const teeTimeMs = teeTimeTs.toMillis();

  // If tee time already passed, flip immediately
  if (teeTimeMs <= Date.now()) {
    await snapshot.ref.update({ status: 'played' });
    console.log(`onGameCreated: game ${gameId} tee time already passed, flipped to played`);
    return;
  }

  // Schedule Cloud Task at tee time
  try {
    const taskName = await _scheduleCloudTask(
      'processScheduledGameStatusChange',
      { gameId },
      new Date(teeTimeMs)
    );
    console.log(`onGameCreated: scheduled status change for game ${gameId} at tee time (task: ${taskName})`);
  } catch (err) {
    console.error(`onGameCreated: failed to schedule task for game ${gameId}:`, err);
  }

  // Schedule pre-game check at T-45min for partial game confirmation flow
  // Only schedule if tee time is > 45 min away
  const preCheckTime = teeTimeMs - PRE_GAME_CHECK_OFFSET_MS;
  if (preCheckTime > Date.now()) {
    try {
      await _scheduleCloudTask(
        'processScheduledPreGameCheck',
        { gameId },
        new Date(preCheckTime)
      );
      console.log(`onGameCreated: scheduled pre-game check for game ${gameId} at T-45min`);
    } catch (err) {
      // Non-fatal: pre-game check is optional enhancement
      console.warn(`onGameCreated: failed to schedule pre-game check for game ${gameId}:`, err);
    }
  }
}

const onGameCreated = functions
  .region('us-west2')
  .firestore.document('games/{gameId}')
  .onCreate(async (snapshot, context) => {
    return _onGameCreatedHandler(snapshot, context, admin.firestore());
  });

// ─────────────────────────────────────────────────────────────────────────────
// HTTP HANDLER — processScheduledGameStatusChange
// ─────────────────────────────────────────────────────────────────────────────

/**
 * HTTP handler: processScheduledGameStatusChange
 * Called by Cloud Tasks at tee time to transition a game from 'filled' to 'played'.
 */
async function _processScheduledGameStatusChangeHandler(req, res, db = null) {
  if (!db) db = admin.firestore();
  const { gameId } = req.body;

  if (!gameId) {
    return res.status(400).send('Missing gameId');
  }

  try {
    const gameRef = db.collection('games').doc(gameId);
    const gameSnap = await gameRef.get();

    if (!gameSnap.exists) {
      console.warn(`processScheduledGameStatusChange: game ${gameId} not found`);
      return res.status(200).send('NOT_FOUND');
    }

    const gameData = gameSnap.data();

    // Only flip if still 'active', 'open', or 'filled' (not already 'played' or 'cancelled')
    if (gameData.status !== 'filled' && gameData.status !== 'open' && gameData.status !== 'active') {
      console.log(`processScheduledGameStatusChange: game ${gameId} is ${gameData.status}, not active/open/filled — skipping`);
      return res.status(200).send('SKIPPED');
    }

    if (gameData.isCancelled === true) {
      console.log(`processScheduledGameStatusChange: game ${gameId} is cancelled — skipping`);
      return res.status(200).send('CANCELLED');
    }

    // Check if game was cancelled via pre-game confirmation flow
    if (gameData.hostConfirmation === 'cancelled') {
      console.log(`processScheduledGameStatusChange: game ${gameId} was cancelled by host via pre-game confirmation — skipping`);
      return res.status(200).send('CANCELLED_BY_HOST');
    }

    await gameRef.update({ status: 'played' });
    console.log(`processScheduledGameStatusChange: flipped game ${gameId} to played`);

    // This triggers onGameStatusToPlayed, which creates round_jobs/round_records
    // and calls onGameConfirmed for notification scheduling

    return res.status(200).send('OK');
  } catch (err) {
    console.error(`processScheduledGameStatusChange: error for game ${gameId}:`, err);
    return res.status(500).send('ERROR');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP HANDLER — processScheduledWindowClose
// ─────────────────────────────────────────────────────────────────────────────

/**
 * HTTP handler: processScheduledWindowClose
 * Called by Cloud Tasks at T+48h to close the confirmation window.
 */
async function _processScheduledWindowCloseHandler(req, res, db = null) {
  if (!db) db = admin.firestore();
  const { jobId, gameId } = req.body;

  if (!jobId) {
    return res.status(400).send('Missing jobId');
  }

  try {
    const jobRef = db.collection('round_jobs').doc(jobId);
    const jobSnap = await jobRef.get();

    if (!jobSnap.exists) {
      console.warn(`processScheduledWindowClose: job ${jobId} not found`);
      return res.status(200).send('NOT_FOUND');
    }

    const job = jobSnap.data();

    // Already closed — idempotent
    if (job.closed_at) {
      console.log(`processScheduledWindowClose: job ${jobId} already closed`);
      return res.status(200).send('ALREADY_CLOSED');
    }

    const nowTs = admin.firestore.Timestamp.now();
    await _closeConfirmationWindow(db, jobRef, job, nowTs);

    console.log(`processScheduledWindowClose: closed window for job ${jobId} (game ${gameId})`);
    return res.status(200).send('OK');
  } catch (err) {
    console.error(`processScheduledWindowClose: error for job ${jobId}:`, err);
    return res.status(500).send('ERROR');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP HANDLERS — PRE-GAME CONFIRMATION (PARTIAL GAMES ONLY)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * HTTP handler: processScheduledPreGameCheck
 * Called by Cloud Tasks at T-45min for games that were partial at creation time.
 * Checks if game is still partial and sends host confirmation request.
 */
async function _processScheduledPreGameCheckHandler(req, res, db = null) {
  if (!db) db = admin.firestore();
  const { gameId } = req.body;

  if (!gameId) {
    return res.status(400).send('Missing gameId');
  }

  try {
    const gameRef = db.collection('games').doc(gameId);
    const gameSnap = await gameRef.get();

    if (!gameSnap.exists) {
      console.warn(`processScheduledPreGameCheck: game ${gameId} not found`);
      return res.status(200).send('NOT_FOUND');
    }

    const gameData = gameSnap.data();

    // Skip if game is full, cancelled, or already played
    if (gameData.status === 'filled' || gameData.status === 'played' || gameData.isCancelled === true) {
      console.log(`processScheduledPreGameCheck: game ${gameId} is ${gameData.status}${gameData.isCancelled ? ' (cancelled)' : ''}, skipping`);
      return res.status(200).send('SKIPPED_FULL_OR_CANCELLED');
    }

    // Check if game is partial (2+ players but not full)
    const joinedPlayers = Array.isArray(gameData.joined_players) ? gameData.joined_players : [];
    const maxPlayers = typeof gameData.max_players === 'number' ? gameData.max_players : 4;

    if (joinedPlayers.length < 2) {
      console.log(`processScheduledPreGameCheck: game ${gameId} has ${joinedPlayers.length} player(s), skipping (need 2+)`);
      return res.status(200).send('SKIPPED_TOO_FEW_PLAYERS');
    }

    if (joinedPlayers.length >= maxPlayers) {
      console.log(`processScheduledPreGameCheck: game ${gameId} is full (${joinedPlayers.length}/${maxPlayers}), skipping`);
      return res.status(200).send('SKIPPED_FULL');
    }

    // Game is partial - send pre-game confirmation request
    const hostRef = gameData.userRef || gameData.host_ref;
    if (!hostRef) {
      console.warn(`processScheduledPreGameCheck: game ${gameId} has no host ref`);
      return res.status(200).send('NO_HOST');
    }

    // Set hostConfirmation to pending
    await gameRef.update({ hostConfirmation: 'pending' });

    // Send notification to host
    const courseName = typeof gameData.course_play === 'string' ? gameData.course_play : 'your course';
    const gameDate = _formatGameDate(gameData.date);

    try {
      await routeNotification({
        eventId:         randomUUID(),
        eventType:       'host_pre_game_confirm',
        recipientUserId: hostRef.id,
        sourceId:        gameId,
        data:            { course_name: courseName, game_date: gameDate, game_id: gameId },
      }, db);
    } catch (err) {
      console.error(`processScheduledPreGameCheck: failed to send notification for game ${gameId}:`, err);
    }

    // Schedule timeout task for 20 minutes from now
    try {
      await _scheduleCloudTask(
        'processScheduledPreGameTimeout',
        { gameId },
        new Date(Date.now() + PRE_GAME_TIMEOUT_MS)
      );
      console.log(`processScheduledPreGameCheck: scheduled timeout for game ${gameId} in 20 min`);
    } catch (err) {
      console.error(`processScheduledPreGameCheck: failed to schedule timeout for game ${gameId}:`, err);
    }

    console.log(`processScheduledPreGameCheck: sent pre-game confirmation request for partial game ${gameId} (${joinedPlayers.length}/${maxPlayers} players)`);
    return res.status(200).send('OK');
  } catch (err) {
    console.error(`processScheduledPreGameCheck: error for game ${gameId}:`, err);
    return res.status(500).send('ERROR');
  }
}

/**
 * HTTP handler: processScheduledPreGameTimeout
 * Called by Cloud Tasks 20 minutes after pre-game check if host hasn't responded.
 * Auto-proceeds by setting hostConfirmation to 'timeout'.
 */
async function _processScheduledPreGameTimeoutHandler(req, res, db = null) {
  if (!db) db = admin.firestore();
  const { gameId } = req.body;

  if (!gameId) {
    return res.status(400).send('Missing gameId');
  }

  try {
    const gameRef = db.collection('games').doc(gameId);
    const gameSnap = await gameRef.get();

    if (!gameSnap.exists) {
      console.warn(`processScheduledPreGameTimeout: game ${gameId} not found`);
      return res.status(200).send('NOT_FOUND');
    }

    const gameData = gameSnap.data();

    // Only update if still pending (host hasn't responded)
    if (gameData.hostConfirmation === 'pending') {
      await gameRef.update({ hostConfirmation: 'timeout' });
      console.log(`processScheduledPreGameTimeout: auto-proceeded game ${gameId} (no host response)`);
    } else {
      console.log(`processScheduledPreGameTimeout: game ${gameId} already has hostConfirmation=${gameData.hostConfirmation}, skipping`);
    }

    return res.status(200).send('OK');
  } catch (err) {
    console.error(`processScheduledPreGameTimeout: error for game ${gameId}:`, err);
    return res.status(500).send('ERROR');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE — submitPreGameConfirmation
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for submitPreGameConfirmation.
 * Accepts data, context, and an injected db instance.
 *
 * Input: {
 *   gameId: string,
 *   confirmed: boolean  // true = game is on, false = cancel game
 * }
 */
async function _submitPreGameConfirmationHandler(data, context, db) {
  const HttpsError = functions.https.HttpsError;

  if (!context.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const { gameId, confirmed } = data || {};
  if (typeof gameId !== 'string' || gameId.length === 0) {
    throw new HttpsError('invalid-argument', 'A valid gameId is required.');
  }
  if (typeof confirmed !== 'boolean') {
    throw new HttpsError('invalid-argument', 'confirmed must be a boolean.');
  }

  const gameRef = db.collection('games').doc(gameId);
  const gameSnap = await gameRef.get();

  if (!gameSnap.exists) {
    throw new HttpsError('not-found', `Game ${gameId} not found.`);
  }

  const gameData = gameSnap.data();

  // Verify caller is the host
  const hostRef = gameData.userRef || gameData.host_ref;
  if (!hostRef || hostRef.id !== context.auth.uid) {
    throw new HttpsError('permission-denied', 'Only the game host can confirm.');
  }

  // Guard: only accept if status is pending
  if (gameData.hostConfirmation !== 'pending') {
    console.log(`submitPreGameConfirmation: game ${gameId} already has hostConfirmation=${gameData.hostConfirmation}`);
    return { success: true, status: gameData.hostConfirmation, alreadyHandled: true };
  }

  if (confirmed) {
    // Host confirms - game continues
    await gameRef.update({ hostConfirmation: 'confirmed' });
    console.log(`submitPreGameConfirmation: host ${context.auth.uid} confirmed game ${gameId}`);
    return { success: true, status: 'confirmed' };
  } else {
    // Host cancels - cancel game and notify players
    await gameRef.update({
      hostConfirmation: 'cancelled',
      status: 'cancelled',
      isCancelled: true,
      cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get all players to notify (exclude host)
    const joinedPlayers = Array.isArray(gameData.joined_players) ? gameData.joined_players : [];
    const playerUserIds = joinedPlayers
      .filter(ref => ref && typeof ref.id === 'string')
      .map(ref => ref.id)
      .filter(uid => uid !== context.auth.uid);

    const courseName = typeof gameData.course_play === 'string' ? gameData.course_play : 'your course';
    const gameDate = _formatGameDate(gameData.date);

    // Cancel all pending scheduled tasks and notify players
    try {
      await onGameCancelled(gameId, playerUserIds, courseName, gameDate, db);
    } catch (err) {
      console.error(`submitPreGameConfirmation: failed to send cancellation notifications for game ${gameId}:`, err);
    }

    console.log(`submitPreGameConfirmation: host ${context.auth.uid} cancelled game ${gameId}, notified ${playerUserIds.length} player(s)`);
    return { success: true, status: 'cancelled' };
  }
}

/**
 * Callable: submitPreGameConfirmation
 */
const submitPreGameConfirmation = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    try {
      return await _submitPreGameConfirmationHandler(data, context, db);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError(
        'internal',
        `Failed to submit pre-game confirmation: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 3 MAIN TRIGGER — onGameStatusToPlayed
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for onGameStatusToPlayed.
 * Accepts the Firestore change, context, and an injected db instance.
 */
async function _onGameStatusToPlayedHandler(change, context, db) {
  const before = change.before.data();
  const after = change.after.data();

  // Only fire on the transition to 'played'
  if (after.status !== "played" || before.status === "played") {
    return;
  }

  const gameId = context.params.gameId;
  const gameRef = change.after.ref;

  try {
    // ── 0. Idempotency guard ──────────────────────────────────────────────
    const existingJobSnap = await db.collection("round_jobs")
      .where("game_ref", "==", gameRef)
      .limit(1)
      .get();

    let resumeMode = false;
    let existingJobRef = null;

    if (!existingJobSnap.empty) {
      const existingJob = existingJobSnap.docs[0].data();
      existingJobRef = existingJobSnap.docs[0].ref;
      if (existingJob.processing_state === "ready") {
        console.log(`onGameStatusToPlayed: already completed for game ${gameId}`);
        return;
      }
      // If processing_state is "initializing", the previous run crashed mid-way.
      // The batch wrote docs but post-batch steps may not have run.
      // Fall through to re-run post-batch steps only.
      console.warn(`onGameStatusToPlayed: resuming incomplete processing for game ${gameId}`);
      resumeMode = true;
    }

    const teeTimeTs = after.date;
    if (!teeTimeTs || typeof teeTimeTs.toMillis !== "function") {
      console.warn(
        `onGameStatusToPlayed: game ${gameId} has no valid tee time, skipping`
      );
      return;
    }

    const teeTimeMs = teeTimeTs.toMillis();
    const now = admin.firestore.Timestamp.now();

    // Resolve host ref — the game uses userRef for the creator/host
    const hostRef = after.userRef || after.host_ref || null;
    if (!hostRef) {
      console.warn(`onGameStatusToPlayed: game ${gameId} has no host ref`);
      return;
    }

    // Collect app user refs from joined_players
    const joinedPlayers = Array.isArray(after.joined_players)
      ? after.joined_players
      : [];
    const appUserRefs = joinedPlayers.filter(
      (entry) =>
        entry &&
        typeof entry === "object" &&
        typeof entry.id === "string" &&
        entry.id.length > 0
    );

    const courseName =
      typeof after.course_play === "string" ? after.course_play : "your course";

    // ── 1–2. Create round_jobs + round_records (skip if resuming) ────────
    let jobRef;

    if (!resumeMode) {
      const jobData = {
        game_ref: gameRef,
        round_ref: null, // filled in when round_records doc is created below
        tee_time: teeTimeTs,
        status: "pending",
        processing_state: "initializing",
        host_ref: hostRef,
        app_user_refs: appUserRefs,
        course_name: courseName,

        // Step tracking for crash-resume idempotency
        steps_completed: {
          streaks_pending: false,
          trust_notifications_scheduled: false,
          window_close_scheduled: false,
          join_requests_expired: false,
        },

        // Milestone timestamps
        scheduled_host_notify_at: admin.firestore.Timestamp.fromMillis(
          teeTimeMs + HOST_NOTIFY_OFFSET_MS
        ),
        scheduled_peer_notify_at: null, // set when host confirms
        scheduled_reminder_at: admin.firestore.Timestamp.fromMillis(
          teeTimeMs + REMINDER_OFFSET_MS
        ),
        scheduled_close_at: admin.firestore.Timestamp.fromMillis(
          teeTimeMs + CLOSE_OFFSET_MS
        ),

        // Event timestamps (null until reached)
        host_notified_at: null,
        host_confirmed_at: null,
        peer_notified_at: null,
        reminder_sent_at: null,
        closed_at: null,
        created_at: now,
      };

      const { participantSnapshots, vibeMatchScores } =
        await _buildRoundRecordData(db, gameId, appUserRefs);

      const gameSettings = _snapshotGameSettings(after);

      const roundData = {
        game_ref: gameRef,
        course_ref: after.courseRef || null,
        tee_time: teeTimeTs,
        game_type: typeof after.game_type === "string" ? after.game_type : "",
        game_settings: gameSettings,
        participant_snapshots: participantSnapshots,
        vibe_match_scores: vibeMatchScores,
        verification_status: "pending",
        // Stage 4: verification signal tracking
        verification_signals: {},       // uid → true
        verification_signal_count: 0,
        verified_at: null,
        // Stage 4: dispute resolution (no-shows are pending until window closes or resolved)
        pending_no_shows: {},           // uid → { recorded_at, notified_at }
        host_check_in_at: null,
        host_confirmation_data: null,
        attendance_records: {},
        confirmed_player_refs: [],
        created_at: now,
      };

      // Write both docs in a batch
      const batch = db.batch();
      jobRef = db.collection("round_jobs").doc();
      const roundRef = db.collection("round_records").doc();

      batch.set(jobRef, jobData);
      batch.set(roundRef, roundData);

      // Back-link the round_ref on the job
      batch.update(jobRef, { round_ref: roundRef });

      await batch.commit();
    } else {
      jobRef = existingJobRef;
    }

    // In resume mode, read which steps already completed
    let stepsCompleted = {
      streaks_pending: false,
      trust_notifications_scheduled: false,
      window_close_scheduled: false,
      join_requests_expired: false,
    };
    if (resumeMode) {
      const existingJobData = (await jobRef.get()).data();
      stepsCompleted = existingJobData.steps_completed || stepsCompleted;
    }

    // ── 3. Mark round as pending for streak tracking (non-fatal) ────────
    if (!stepsCompleted.streaks_pending) {
      try {
        const streakPlayerIds = appUserRefs.map(ref => ref.id);
        await streaks.onRoundPending(db, gameId, teeTimeTs, streakPlayerIds, after);
      } catch (err) {
        // Non-fatal: streak tracking shouldn't block confirmation flow
        console.warn(`onGameStatusToPlayed: streak pending failed for game ${gameId}:`, err);
      }
      // Mark complete even on failure to avoid re-runs of non-fatal step
      await jobRef.update({ 'steps_completed.streaks_pending': true });
    }

    // ── 4. Schedule Trust System notification tasks (critical) ───────────
    if (!stepsCompleted.trust_notifications_scheduled) {
      const playerUserIds = appUserRefs.map(ref => ref.id);
      const gameDate = _formatGameDate(teeTimeTs);

      await onGameConfirmed(
        gameId,
        new Date(teeTimeMs),   // teeTime as Date
        hostRef.id,            // hostUserId
        playerUserIds,         // all player user IDs including host
        courseName,            // course name string
        gameDate,              // formatted date string
        db
      );
      await jobRef.update({ 'steps_completed.trust_notifications_scheduled': true });
      console.log(`onGameStatusToPlayed: scheduled Trust System notifications for game ${gameId}`);
    }

    // ── 5. Schedule T+48h window close (critical) ────────────────────────
    if (!stepsCompleted.window_close_scheduled) {
      const closeAt = new Date(teeTimeMs + CLOSE_OFFSET_MS);
      await _scheduleCloudTask(
        'processScheduledWindowClose',
        { jobId: jobRef.id, gameId },
        closeAt,
        `window-close-${gameId}`
      );
      await jobRef.update({ 'steps_completed.window_close_scheduled': true });
      console.log(`onGameStatusToPlayed: scheduled window close for game ${gameId} at T+48h`);
    }

    // ── 6. Expire any pending join requests ─────────────────────────────
    if (!stepsCompleted.join_requests_expired) {
      await _expirePendingJoinRequests(db, gameId, gameRef, courseName);
      await jobRef.update({ 'steps_completed.join_requests_expired': true });
    }

    // ── 7. Mark processing complete ─────────────────────────────────────
    await jobRef.update({ processing_state: "ready" });

    console.log(
      `onGameStatusToPlayed: created round_jobs/${jobRef.id} for game ${gameId}`
    );
  } catch (error) {
    console.error(`onGameStatusToPlayed failed for game ${gameId}:`, error);
    throw error;  // Let Cloud Functions retry
  }
}

/**
 * Firestore trigger: onGameStatusToPlayed
 *
 * Fires when a game document transitions to status='played'.
 * Creates:
 *   1. A round_jobs document with all scheduled milestone timestamps
 *   2. An initial round_records document with participant snapshots and vibe scores
 */
const onGameStatusToPlayed = functions
  .region("us-west2")
  .firestore.document("games/{gameId}")
  .onUpdate(async (change, context) => {
    return _onGameStatusToPlayedHandler(change, context, admin.firestore());
  });

// ─────────────────────────────────────────────────────────────────────────────
// GAME STATUS TRANSITION — onGameStatusToCancelled
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for onGameStatusToCancelled.
 *
 * This trigger fires when a game's status transitions TO 'cancelled'.
 * It cancels all pending Cloud Tasks for the game and notifies players.
 *
 * This is important when hosts cancel a game from 'played' status via the UI,
 * ensuring the Trust System notification pipeline is halted.
 */
async function _onGameStatusToCancelledHandler(change, context, db) {
  const before = change.before.data();
  const after = change.after.data();

  // Only fire on transition TO 'cancelled'
  if (after.status !== 'cancelled' || before.status === 'cancelled') {
    return;
  }

  // Also guard against isCancelled being true before
  if (before.isCancelled === true) {
    return;
  }

  const gameId = context.params.gameId;

  console.log(`onGameStatusToCancelled: game ${gameId} was cancelled`);

  try {
    // Get all joined players from game_participants subcollection
    const participantsSnap = await change.after.ref
      .collection('game_participants')
      .get();

    // Extract user IDs (excluding the host)
    const hostRef = after.userRef || after.host_ref || null;
    const hostId = hostRef ? hostRef.id : null;

    const playerUserIds = participantsSnap.docs
      .map(doc => {
        const userRef = doc.data().user_ref;
        return userRef && typeof userRef.id === 'string' ? userRef.id : null;
      })
      .filter(uid => uid && uid !== hostId);

    // Extract course name and format game date
    const courseName = typeof after.course_play === 'string'
      ? after.course_play
      : 'Unknown course';

    const teeTimeTs = after.date;
    let gameDate = '';
    if (teeTimeTs && typeof teeTimeTs.toDate === 'function') {
      const date = teeTimeTs.toDate();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      gameDate = `${months[date.getMonth()]} ${date.getDate()}`;
    }

    // Cancel scheduled tasks and notify players via the hook
    const result = await onGameCancelled(gameId, playerUserIds, courseName, gameDate, db);

    console.log(
      `onGameStatusToCancelled: game ${gameId} — cancelled ${result.cancelledCount} tasks, ` +
      `notified ${result.notifyResults.length} players`
    );
  } catch (error) {
    console.error(`onGameStatusToCancelled: error processing game ${gameId}:`, error);
    // Don't rethrow - this is a best-effort notification
  }
}

const onGameStatusToCancelled = functions
  .region("us-west2")
  .firestore.document("games/{gameId}")
  .onUpdate(async (change, context) => {
    return _onGameStatusToCancelledHandler(change, context, admin.firestore());
  });

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE — submitHostCheckin
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for submitHostCheckin.
 * Accepts data, context, and an injected db instance.
 * Exported directly so unit tests can call it without Firebase wrappers.
 *
 * Input: {
 *   gameId: string,
 *   attendance: {
 *     [uid]: boolean,         // true=present, false=no_show (for app users)
 *     [guestName]: boolean    // true=present, false=no_show (for guests)
 *   }
 * }
 */
async function _submitHostCheckinHandler(data, context, db) {
  const HttpsError = functions.https.HttpsError;

  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { gameId, attendance } = data || {};
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "A valid gameId is required.");
  }
  if (!attendance || typeof attendance !== "object") {
    throw new HttpsError(
      "invalid-argument",
      "attendance must be an object mapping uid/guestName to boolean."
    );
  }

  const gameRef = db.collection("games").doc(gameId);

  const gameSnap = await gameRef.get();
  if (!gameSnap.exists) {
    throw new HttpsError("not-found", `Game ${gameId} not found.`);
  }

  const gameData = gameSnap.data();

  // Verify caller is the host
  const hostRef = gameData.userRef || gameData.host_ref;
  if (!hostRef || hostRef.id !== context.auth.uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the game host can submit attendance."
    );
  }

  // Find the round_jobs doc for this game
  const jobsSnap = await db
    .collection("round_jobs")
    .where("game_ref", "==", gameRef)
    .limit(1)
    .get();

  if (jobsSnap.empty) {
    throw new HttpsError(
      "not-found",
      "No confirmation job found for this game."
    );
  }

  const jobDoc = jobsSnap.docs[0];
  const job = jobDoc.data();

  // Guard: window must be open
  if (job.closed_at) {
    throw new HttpsError(
      "failed-precondition",
      "The confirmation window for this game has closed (48h limit)."
    );
  }

  // Guard: idempotent — already confirmed
  if (job.host_confirmed_at) {
    return { success: true, pendingNoShows: {} };
  }

  const nowMs = Date.now();
  const nowTs = admin.firestore.Timestamp.fromMillis(nowMs);

  // ── Build attendance_records ──────────────────────────────────────────
  const attendanceRecords = {};
  for (const [key, isPresent] of Object.entries(attendance)) {
    attendanceRecords[key] = isPresent ? "present" : "no_show";
  }

  // ── Identify no-show app users (guests excluded — no accounts) ────────
  const joinedPlayers = Array.isArray(gameData.joined_players)
    ? gameData.joined_players
    : [];

  const noShowAppUserIds = [];
  for (const [key, isPresent] of Object.entries(attendance)) {
    if (isPresent) continue;
    const isAppUser = joinedPlayers.some(
      (entry) =>
        entry &&
        typeof entry === "object" &&
        typeof entry.id === "string" &&
        entry.id === key
    );
    if (isAppUser) {
      noShowAppUserIds.push(key);
    }
  }

  // ── Find the round_records doc ────────────────────────────────────────
  const roundRef = job.round_ref;

  // ── Read current round_records (needed for signal deduplication) ──────
  let roundData = {};
  if (roundRef) {
    try {
      const roundSnap = await roundRef.get();
      if (roundSnap.exists) roundData = roundSnap.data();
    } catch (err) {
      console.warn("submitHostCheckin: could not read round_records:", err);
    }
  }

  // ── Stage 4: write pending_no_shows + send dispute notifications ──────
  // Strikes are NOT issued immediately. They remain pending until:
  //   - another player's peer ratings confirm the no-show was present (auto-resolved), OR
  //   - the 48h window closes with no corroboration (converted to active strikes)
  const pendingNoShowsUpdate = {};
  for (const uid of noShowAppUserIds) {
    pendingNoShowsUpdate[`pending_no_shows.${uid}`] = {
      recorded_at: nowTs,
      notified_at: null,
    };
    // Update game_participants status
    await _updateParticipantStatus(db, gameRef, uid, "no_show");
  }

  // ── Stage 4: record host as a verification signal ─────────────────────
  const hostUid = context.auth.uid;
  const { newCount: signalCount } = await _recordVerificationSignal(
    db, roundRef, roundData, hostUid
  );

  // ── Update round_records with host confirmation data ──────────────────
  const hostConfirmationData = {
    confirmed_by: hostUid,
    confirmed_at: nowTs,
    attendance: attendanceRecords,
  };

  const roundUpdate = {
    attendance_records: attendanceRecords,
    host_check_in_at: nowTs,
    host_confirmation_data: hostConfirmationData,
    ...pendingNoShowsUpdate,
  };

  // ── Update round_jobs ─────────────────────────────────────────────────
  const peerNotifyAt = admin.firestore.Timestamp.fromMillis(
    nowMs + PEER_NOTIFY_OFFSET_MS
  );

  const jobUpdate = {
    status: "host_confirmed",
    host_confirmed_at: nowTs,
    scheduled_peer_notify_at: peerNotifyAt,
  };

  // Batch round_records + round_jobs updates
  const batch = db.batch();
  if (roundRef) {
    batch.update(roundRef, roundUpdate);
  }
  batch.update(jobDoc.ref, jobUpdate);
  await batch.commit();

  // ── Trust System: cancel pending notification tasks + schedule ratings ──
  const appUserRefs = Array.isArray(job.app_user_refs) ? job.app_user_refs : [];
  const courseName = job.course_name || "your course";
  try {
    await onHostCheckinCompleted(
      gameId,
      context.auth.uid,                          // hostUserId
      appUserRefs.map(ref => ref.id),            // all playerUserIds
      courseName,                                // course name
      db
    );
    console.log(`submitHostCheckin: scheduled Trust System rating notifications for game ${gameId}`);
  } catch (err) {
    console.error(`submitHostCheckin: failed to schedule rating notifications:`, err);
  }

  // ── Send dispute notifications to flagged players ─────────────────────
  const gameDate = _formatGameDate(job.tee_time);
  for (const uid of noShowAppUserIds) {
    try {
      await routeNotification({
        eventId: randomUUID(),
        eventType: 'no_show_flagged',
        recipientUserId: uid,
        sourceId: uid,
        data: {
          course_name: courseName,
          date: gameDate,
        },
      }, db);
      // Record notified_at
      if (roundRef) {
        await roundRef.update({
          [`pending_no_shows.${uid}.notified_at`]: nowTs,
        });
      }
    } catch (err) {
      console.warn(`submitHostCheckin: failed to send no-show notification to ${uid}:`, err);
    }
  }

  // ── Stage 4: check for early verification (2+ signals already) ────────
  if (signalCount >= 2 && roundRef) {
    // Refresh round data (may have changed from pending_no_shows writes above)
    try {
      const freshRoundSnap = await roundRef.get();
      const freshRoundData = freshRoundSnap.exists ? freshRoundSnap.data() : roundData;
      await _finalizeRoundVerification(db, roundRef, freshRoundData, gameRef);
    } catch (err) {
      console.warn("submitHostCheckin: _finalizeRoundVerification error:", err);
    }
  }

  console.log(
    `submitHostCheckin: host ${hostUid} confirmed attendance for game ${gameId}. ` +
      `Pending no-shows: ${noShowAppUserIds.join(", ") || "none"}. ` +
      `Verification signals: ${signalCount}`
  );

  return { success: true, pendingNoShows: noShowAppUserIds };
}

/**
 * Callable: submitHostCheckin
 */
const submitHostCheckin = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    try {
      return await _submitHostCheckinHandler(data, context, db);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError(
        "internal",
        `Failed to submit host check-in: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE — submitPeerRatings
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for submitPeerRatings.
 * Accepts data, context, and an injected db instance.
 */
async function _submitPeerRatingsHandler(data, context, db) {
  const HttpsError = functions.https.HttpsError;

  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { gameId, ratings } = data || {};
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "A valid gameId is required.");
  }
  if (!ratings || typeof ratings !== "object") {
    throw new HttpsError(
      "invalid-argument",
      "ratings must be an object mapping uid to boolean."
    );
  }

  const gameRef = db.collection("games").doc(gameId);
  const raterRef = db.collection("users").doc(context.auth.uid);

  const gameSnap = await gameRef.get();
  if (!gameSnap.exists) {
    throw new HttpsError("not-found", `Game ${gameId} not found.`);
  }
  const gameData = gameSnap.data();

  // Verify caller is an app user in this game
  const joinedPlayers = Array.isArray(gameData.joined_players)
    ? gameData.joined_players
    : [];
  const isParticipant = joinedPlayers.some(
    (entry) =>
      entry &&
      typeof entry === "object" &&
      typeof entry.id === "string" &&
      entry.id === context.auth.uid
  );
  if (!isParticipant) {
    throw new HttpsError(
      "permission-denied",
      "You are not a participant in this game."
    );
  }

  // Find round_jobs doc
  const jobsSnap = await db
    .collection("round_jobs")
    .where("game_ref", "==", gameRef)
    .limit(1)
    .get();

  if (jobsSnap.empty) {
    throw new HttpsError("not-found", "No confirmation job found for this game.");
  }

  const job = jobsSnap.docs[0].data();

  // Guard: window open
  if (job.closed_at) {
    throw new HttpsError(
      "failed-precondition",
      "The confirmation window for this game has closed (48h limit)."
    );
  }

  // Guard: host must have confirmed first
  if (!job.host_confirmed_at) {
    throw new HttpsError(
      "failed-precondition",
      "The host has not yet confirmed attendance. Please try again later."
    );
  }

  // Guard: rater must be marked present
  const roundRef = job.round_ref;
  if (roundRef) {
    const roundSnap = await roundRef.get();
    if (roundSnap.exists) {
      const attendanceRecords = roundSnap.data().attendance_records || {};
      const raterStatus = attendanceRecords[context.auth.uid];
      if (raterStatus === "no_show") {
        throw new HttpsError(
          "failed-precondition",
          "You were marked as a no-show and cannot submit ratings."
        );
      }
    }
  }

  // Idempotency: check for existing ratings by this rater for this game
  const existingRatingsSnap = await db
    .collection("pair_ratings")
    .where("rater_ref", "==", raterRef)
    .where("game_ref", "==", gameRef)
    .limit(1)
    .get();

  if (!existingRatingsSnap.empty) {
    return { success: true, ratingsWritten: 0, alreadySubmitted: true };
  }

  // Write one pair_ratings doc per ratee
  const gameType =
    typeof gameData.game_type === "string" ? gameData.game_type : "";
  const nowTs = admin.firestore.Timestamp.now();
  const batch = db.batch();
  let ratingsWritten = 0;

  for (const [ratedUserId, wouldPlayAgain] of Object.entries(ratings)) {
    if (typeof wouldPlayAgain !== "boolean") continue;
    if (ratedUserId === context.auth.uid) continue; // can't rate yourself

    const ratedRef = db.collection("users").doc(ratedUserId);
    const ratingData = {
      rater_ref: raterRef,
      rated_ref: ratedRef,
      game_ref: gameRef,
      round_ref: roundRef || null,
      would_play_again: wouldPlayAgain,
      rated_at: nowTs,
      game_type: gameType,
    };
    batch.set(db.collection("pair_ratings").doc(), ratingData);
    ratingsWritten++;
  }

  if (ratingsWritten > 0) {
    await batch.commit();
  }

  // ── Stage 4: record rater as a verification signal ────────────────────
  // Read current round_records to check signals + pending_no_shows
  let roundDataForStage4 = {};
  if (roundRef) {
    try {
      const roundSnap = await roundRef.get();
      if (roundSnap.exists) roundDataForStage4 = roundSnap.data();
    } catch (err) {
      console.warn("submitPeerRatings: could not read round_records for Stage 4:", err);
    }
  }

  const { newCount: signalCount } = await _recordVerificationSignal(
    db, roundRef, roundDataForStage4, context.auth.uid
  );

  // ── Stage 4: dispute resolution — resolve pending no-shows the rater rated ──
  // Only resolves if the rater explicitly submitted a rating for the disputed player.
  // A rating entry for that uid (any value) proves the rater interacted with them → they were present.
  const pendingNoShows = roundDataForStage4.pending_no_shows || {};
  const pendingNoShowUids = Object.keys(pendingNoShows);

  if (pendingNoShowUids.length > 0 && roundRef) {
    const courseName = typeof gameData.course_play === 'string' ? gameData.course_play : 'your course';
    const gameDate = _formatGameDate(gameData.date);

    for (const noShowUid of pendingNoShowUids) {
      if (noShowUid === context.auth.uid) continue; // can't self-resolve
      // Check if rater submitted a rating (any value) for this no-show player
      if (Object.prototype.hasOwnProperty.call(ratings, noShowUid)) {
        await _resolvePendingNoShow(db, roundRef, noShowUid, context.auth.uid, courseName, gameDate);
      }
    }
  }

  // ── Stage 4: check for early verification ────────────────────────────
  if (signalCount >= 2 && roundRef) {
    try {
      const freshRoundSnap = await roundRef.get();
      const freshRoundData = freshRoundSnap.exists ? freshRoundSnap.data() : roundDataForStage4;
      await _finalizeRoundVerification(db, roundRef, freshRoundData, gameRef);
    } catch (err) {
      console.warn("submitPeerRatings: _finalizeRoundVerification error:", err);
    }
  }

  console.log(
    `submitPeerRatings: user ${context.auth.uid} submitted ${ratingsWritten} rating(s) for game ${gameId}. ` +
      `Verification signals: ${signalCount}`
  );

  return { success: true, ratingsWritten };
}

/**
 * Callable: submitPeerRatings
 */
const submitPeerRatings = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    try {
      return await _submitPeerRatingsHandler(data, context, db);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError(
        "internal",
        `Failed to submit peer ratings: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// CALLABLE — submitFallbackConfirmation
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Raw handler for submitFallbackConfirmation.
 * Accepts data, context, and an injected db instance.
 */
async function _submitFallbackConfirmationHandler(data, context, db) {
  const HttpsError = functions.https.HttpsError;

  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const { gameId, didPlay } = data || {};
  if (typeof gameId !== "string" || gameId.length === 0) {
    throw new HttpsError("invalid-argument", "A valid gameId is required.");
  }
  if (typeof didPlay !== "boolean") {
    throw new HttpsError("invalid-argument", "didPlay must be a boolean.");
  }

  const gameRef = db.collection("games").doc(gameId);

  // Find round_jobs doc
  const jobsSnap = await db
    .collection("round_jobs")
    .where("game_ref", "==", gameRef)
    .limit(1)
    .get();

  if (jobsSnap.empty) {
    throw new HttpsError("not-found", "No confirmation job found for this game.");
  }

  const job = jobsSnap.docs[0].data();

  // Guard: window open
  if (job.closed_at) {
    throw new HttpsError(
      "failed-precondition",
      "The confirmation window for this game has closed (48h limit)."
    );
  }

  if (!didPlay) {
    console.log(
      `submitFallbackConfirmation: user ${context.auth.uid} said they did NOT play in game ${gameId}`
    );
    return { success: true };
  }

  // Add user to confirmed_player_refs
  const userRef = db.collection("users").doc(context.auth.uid);
  const roundRef = job.round_ref;

  // Read round_records for Stage 4 signal tracking
  let roundData = {};
  if (roundRef) {
    try {
      const roundSnap = await roundRef.get();
      if (roundSnap.exists) roundData = roundSnap.data();
    } catch (err) {
      console.warn("submitFallbackConfirmation: could not read round_records:", err);
    }
  }

  if (roundRef) {
    await roundRef.update({
      confirmed_player_refs: admin.firestore.FieldValue.arrayUnion(userRef),
    });
  }

  // ── Stage 4: record respondent as a verification signal ───────────────
  // Fallback confirmations count as signals — this is the only path to
  // verification when the host never submits a check-in.
  // NOTE: fallback does NOT resolve pending no-shows. It only proves the
  // respondent was present, not any other player.
  const { newCount: signalCount } = await _recordVerificationSignal(
    db, roundRef, roundData, context.auth.uid
  );

  // ── Stage 4: check for early verification ─────────────────────────────
  if (signalCount >= 2 && roundRef) {
    try {
      const freshRoundSnap = await roundRef.get();
      const freshRoundData = freshRoundSnap.exists ? freshRoundSnap.data() : roundData;
      await _finalizeRoundVerification(db, roundRef, freshRoundData, gameRef);
    } catch (err) {
      console.warn("submitFallbackConfirmation: _finalizeRoundVerification error:", err);
    }
  }

  console.log(
    `submitFallbackConfirmation: user ${context.auth.uid} confirmed they played in game ${gameId}. ` +
      `Verification signals: ${signalCount}`
  );

  return { success: true };
}

/**
 * Callable: submitFallbackConfirmation
 */
const submitFallbackConfirmation = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    const db = admin.firestore();
    try {
      return await _submitFallbackConfirmationHandler(data, context, db);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError(
        "internal",
        `Failed to submit fallback confirmation: ${error.message}`
      );
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 4 HELPERS — VERIFICATION ENGINE & DISPUTE RESOLUTION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Records a verification signal from a distinct app user.
 *
 * Signals:
 *   - Host submitting check-in
 *   - Any player submitting play-again ratings (1 signal per player)
 *   - Any player submitting fallback confirmation (didPlay=true)
 *
 * Deduplication: if the uid has already signaled, count is NOT incremented.
 *
 * Returns: { newCount, alreadySignaled }
 */
async function _recordVerificationSignal(db, roundRef, roundData, signalUid) {
  const existingSignals = roundData.verification_signals || {};
  if (existingSignals[signalUid] === true) {
    return { newCount: roundData.verification_signal_count || 0, alreadySignaled: true };
  }

  await roundRef.update({
    [`verification_signals.${signalUid}`]: true,
    verification_signal_count: admin.firestore.FieldValue.increment(1),
  });

  const newCount = (roundData.verification_signal_count || 0) + 1;
  return { newCount, alreadySignaled: false };
}

/**
 * Removes a single entry from round_records.pending_no_shows.
 * Called when another app user's play-again rating confirms the disputed player was present.
 * Does NOT issue or remove any strike docs — the pending state is simply discarded.
 */
async function _resolvePendingNoShow(db, roundRef, noShowUid, resolvedBy, courseName, gameDate) {
  await roundRef.update({
    [`pending_no_shows.${noShowUid}`]: admin.firestore.FieldValue.delete(),
  });
  console.log(
    `_resolvePendingNoShow: pending no-show for ${noShowUid} auto-resolved ` +
      `(peer ${resolvedBy} submitted a rating for them)`
  );

  // ── Notify player their dispute was resolved ────────────────────────
  try {
    await routeNotification({
      eventId: randomUUID(),
      eventType: 'dispute_resolved',
      recipientUserId: noShowUid,
      sourceId: noShowUid,
      data: {
        course_name: courseName || '',
        date: gameDate || '',
      },
    }, db);
  } catch (err) {
    console.warn(`_resolvePendingNoShow: failed to send dispute_resolved to ${noShowUid}:`, err);
  }
}

/**
 * Finalizes a round as verified.
 *
 * Actions:
 *   1. Sets verification_status = 'verified', verified_at = now on round_records
 *   2. Increments verified_round_count on each present app user's users doc
 *   3. Writes/updates partner_plays subcollection entries for all present-user pairs
 *
 * Idempotent: skips if round_records.verification_status is already 'verified'.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {FirebaseFirestore.DocumentReference} roundRef
 * @param {Object} roundData  - current round_records data (used for attendance + participant info)
 * @param {FirebaseFirestore.DocumentReference} gameRef
 */
async function _finalizeRoundVerification(db, roundRef, roundData, gameRef) {
  if (roundData.verification_status === "verified") {
    // Already finalized — idempotent guard
    return;
  }

  const nowTs = admin.firestore.Timestamp.now();

  // ── 1. Determine which app users are present ──────────────────────────────
  const attendanceRecords = roundData.attendance_records || {};
  const participantSnapshots = Array.isArray(roundData.participant_snapshots)
    ? roundData.participant_snapshots
    : [];

  // Build list of present uids from attendance_records
  // Any uid not explicitly marked 'no_show' is considered present
  const presentUids = participantSnapshots
    .map((s) => (s && typeof s.uid === "string" ? s.uid : null))
    .filter((uid) => uid !== null && attendanceRecords[uid] !== "no_show");

  // ── 2. Require at least 2 app users for verification ──────────────────────
  if (presentUids.length < 2) {
    await roundRef.update({
      verification_status: "failed",
      verification_failed_at: nowTs,
      verification_failure_reason: "insufficient_app_users",
    });
    console.log(
      `_finalizeRoundVerification: round ${roundRef.id} failed verification - ` +
        `only ${presentUids.length} present app user(s), minimum is 2`
    );
    return;
  }

  // ── 3. Mark round as verified ─────────────────────────────────────────────
  await roundRef.update({
    verification_status: "verified",
    verified_at: nowTs,
  });

  // ── 4. Increment verified_round_count for each present user ───────────────
  // Write to stats/counters subcollection to avoid contention on the main user doc
  const userCountBatch = db.batch();
  for (const uid of presentUids) {
    const countersRef = db.collection("users").doc(uid).collection("stats").doc("counters");
    userCountBatch.set(countersRef, {
      verified_round_count: admin.firestore.FieldValue.increment(1),
    }, { merge: true });
  }
  await userCountBatch.commit();

  // ── 5. Write partner_plays entries for all present-user pairs ─────────────
  const partnerBatch = db.batch();
  for (let i = 0; i < presentUids.length; i++) {
    for (let j = i + 1; j < presentUids.length; j++) {
      const uidA = presentUids[i];
      const uidB = presentUids[j];

      // users/{uidA}/partner_plays/{uidB}
      const refAB = db
        .collection("users")
        .doc(uidA)
        .collection("partner_plays")
        .doc(uidB);
      partnerBatch.set(
        refAB,
        {
          play_count: admin.firestore.FieldValue.increment(1),
          last_played_at: nowTs,
          game_refs: admin.firestore.FieldValue.arrayUnion(gameRef),
        },
        { merge: true }
      );

      // Mirror: users/{uidB}/partner_plays/{uidA}
      const refBA = db
        .collection("users")
        .doc(uidB)
        .collection("partner_plays")
        .doc(uidA);
      partnerBatch.set(
        refBA,
        {
          play_count: admin.firestore.FieldValue.increment(1),
          last_played_at: nowTs,
          game_refs: admin.firestore.FieldValue.arrayUnion(gameRef),
        },
        { merge: true }
      );
    }
  }
  await partnerBatch.commit();

  console.log(
    `_finalizeRoundVerification: round ${roundRef.id} verified. ` +
      `Present users: ${presentUids.length}. ` +
      `Partner pairs updated: ${(presentUids.length * (presentUids.length - 1)) / 2}`
  );

  // ── 6. Stage 5: update trust profiles for all present users ───────────────
  const trustUpdates = presentUids.map((uid) =>
    trustProfile._updateTrustProfileHandler(db, uid).catch((err) =>
      console.warn(
        `_finalizeRoundVerification: trust profile update failed for ${uid}:`, err
      )
    )
  );
  await Promise.all(trustUpdates);

  // ── 7. Stage 6: update streak tracking for verified round ─────────────────
  try {
    const teeTime = roundData.tee_time;
    await streaks.onRoundVerified(db, gameRef, teeTime, presentUids);
    await streaks.clearPendingForAllParticipants(db, gameRef, teeTime);
  } catch (err) {
    // Non-fatal: streak tracking shouldn't block verification flow
    console.warn(
      `_finalizeRoundVerification: streak verification failed for round ${roundRef.id}:`, err
    );
  }
}

/**
 * Evaluates and sets the final verification status at T+48h window close.
 *
 * Called by _closeConfirmationWindow after converting pending no-shows.
 * If the round is not already verified, checks signal count:
 *   - >= 2 signals → verified (calls _finalizeRoundVerification)
 *   - < 2 signals  → failed
 *
 * 'expired' is set by the existing logic when host never confirmed;
 * this function only runs after that check.
 */
async function _evaluateFinalVerificationStatus(db, roundRef, gameRef) {
  let roundData;
  try {
    const roundSnap = await roundRef.get();
    if (!roundSnap.exists) return;
    roundData = roundSnap.data();
  } catch (err) {
    console.warn(`_evaluateFinalVerificationStatus: could not read round ${roundRef.id}:`, err);
    return;
  }

  // Already resolved by early verification or expired branch
  if (
    roundData.verification_status === "verified" ||
    roundData.verification_status === "expired"
  ) {
    return;
  }

  const signalCount = roundData.verification_signal_count || 0;

  if (signalCount >= 2) {
    await _finalizeRoundVerification(db, roundRef, roundData, gameRef);
  } else {
    await roundRef.update({ verification_status: "failed" });
    console.log(
      `_evaluateFinalVerificationStatus: round ${roundRef.id} failed verification ` +
        `(only ${signalCount} signal(s) received)`
    );
  }
}

/**
 * Reads game_participants for a game and returns:
 *   participantSnapshots: array of profile snapshots (from profile_snapshot field)
 *   vibeMatchScores: map of "uid1:uid2" → score object (from vibe_scores_with_others)
 *
 * Never computes vibe scores — only copies from game_participants.
 * If profile_snapshot or vibe scores are missing, logs a warning and omits.
 */
async function _buildRoundRecordData(db, gameId, appUserRefs) {
  const gameRef = db.collection("games").doc(gameId);
  const participantsSnap = await db
    .collection("game_participants")
    .where("game_ref", "==", gameRef)
    .where("status", "==", "joined")
    .get();

  const participantSnapshots = [];
  const vibeScoresRaw = {}; // uid → { otherUid → score }

  for (const doc of participantsSnap.docs) {
    const d = doc.data();

    // Collect profile snapshot
    if (d.profile_snapshot && typeof d.profile_snapshot === "object") {
      participantSnapshots.push(d.profile_snapshot);
    } else if (d.user_ref) {
      // Snapshot missing — log and omit (do not fetch live)
      console.warn(
        `_buildRoundRecordData: missing profile_snapshot for participant ${doc.id} in game ${gameId}`
      );
    }

    // Collect vibe scores for app users only
    const userRef = d.user_ref;
    if (!userRef || typeof userRef.id !== "string") continue;
    const uid = userRef.id;

    if (d.vibe_scores_with_others && typeof d.vibe_scores_with_others === "object") {
      vibeScoresRaw[uid] = d.vibe_scores_with_others;
    } else {
      console.warn(
        `_buildRoundRecordData: missing vibe_scores_with_others for user ${uid} in game ${gameId}`
      );
    }
  }

  // Flatten vibe scores into pair keys "uid1:uid2" (sorted, so each pair appears once)
  const vibeMatchScores = {};
  const processedPairs = new Set();

  for (const [uid, scores] of Object.entries(vibeScoresRaw)) {
    for (const [otherUid, score] of Object.entries(scores)) {
      const pairKey = [uid, otherUid].sort().join(":");
      if (!processedPairs.has(pairKey)) {
        processedPairs.add(pairKey);
        vibeMatchScores[pairKey] = score;
      }
    }
  }

  return { participantSnapshots, vibeMatchScores };
}

/**
 * Returns a snapshot map of game settings at booking time.
 */
function _snapshotGameSettings(gameData) {
  return {
    style_game: gameData.style_game || gameData.styleGame || "",
    game_type: gameData.game_type || gameData.gameType || "",
    rules_setting: gameData.rules_setting || gameData.rulesSetting || "",
    scoring: typeof gameData.scoring === "string" ? gameData.scoring : "",
    max_players: typeof gameData.max_players === "number" ? gameData.max_players : 0,
    course_play: typeof gameData.course_play === "string" ? gameData.course_play : "",
    member_discount: gameData.member_discount === true,
  };
}

/**
 * Handles the strike logic for a no-show player.
 *
 * Checks cancellation_records:
 *   - If a prior cancellation record exists for this game → strike already issued → no action
 *   - If no record → ghost no-show → write cancellation record + 2 strikes
 *
 * Returns { strikeIds, activeStrikeCount } or null if no action taken.
 */
async function _handleNoShowStrike(db, gameId, targetUserId, gameData, gameRef, nowMs) {
  const targetPlayerRef = db.collection("users").doc(targetUserId);

  // Check for existing cancellation record for this game
  const existingCancelSnap = await db
    .collection("cancellation_records")
    .where("player_ref", "==", targetPlayerRef)
    .where("game_ref", "==", gameRef)
    .where("is_ghost", "==", false)
    .limit(1)
    .get();

  if (!existingCancelSnap.empty) {
    // Player cancelled before tee time — strike already issued by recordCancellation
    console.log(
      `_handleNoShowStrike: user ${targetUserId} already has a cancellation record for game ${gameId}, no additional strike`
    );
    return null;
  }

  // Ghost no-show: write cancellation record + 2 strikes
  const teeTimeTs = gameData.date;
  const gameType = typeof gameData.game_type === "string" ? gameData.game_type : "";

  const ghostRecordData = {
    player_ref: targetPlayerRef,
    game_ref: gameRef,
    cancelled_at: admin.firestore.Timestamp.fromMillis(nowMs),
    tee_time: teeTimeTs,
    hours_before_tee_time: 0,
    tier: "day_of",
    game_type: gameType,
    is_ghost: true,
  };

  const cancellationRef = await db.collection("cancellation_records").add(ghostRecordData);

  // Issue 2 strikes (ghost_no_show)
  const STRIKE_EXPIRY_MS = 180 * 24 * 60 * 60 * 1000; // 6 months, matches trust_system.js
  const expiresAtMs = nowMs + STRIKE_EXPIRY_MS;
  const strikeBase = {
    player_ref: targetPlayerRef,
    game_ref: gameRef,
    reason: "ghost_no_show",
    created_at: admin.firestore.Timestamp.fromMillis(nowMs),
    expires_at: admin.firestore.Timestamp.fromMillis(expiresAtMs),
    cancellation_record_id: cancellationRef.id,
    is_expired: false,
  };

  const [strike1Ref, strike2Ref] = await Promise.all([
    db.collection("strikes").add(strikeBase),
    db.collection("strikes").add(strikeBase),
  ]);

  // ── Notify player of strike ─────────────────────────────────────────
  try {
    await routeNotification({
      eventId: randomUUID(),
      eventType: 'strike_issued',
      recipientUserId: targetUserId,
      sourceId: targetUserId,
      data: {
        reason: 'ghost_no_show',
      },
    }, db);
  } catch (err) {
    console.warn(`_handleNoShowStrike: failed to send strike notification to ${targetUserId}:`, err);
  }

  // Count active strikes
  const expiryThreshold = admin.firestore.Timestamp.fromMillis(nowMs);
  const activeStrikesSnap = await db
    .collection("strikes")
    .where("player_ref", "==", targetPlayerRef)
    .where("expires_at", ">", expiryThreshold)
    .get();

  const activeStrikeCount = activeStrikesSnap.size;

  console.log(
    `_handleNoShowStrike: ghost no-show for user ${targetUserId} in game ${gameId}. ` +
      `Strikes: ${strike1Ref.id}, ${strike2Ref.id}. Active: ${activeStrikeCount}`
  );

  return {
    strikeIds: [strike1Ref.id, strike2Ref.id],
    activeStrikeCount,
  };
}

/**
 * Updates the status field on a game_participants doc for a specific user.
 */
async function _updateParticipantStatus(db, gameRef, userId, status) {
  try {
    const snap = await db
      .collection("game_participants")
      .where("game_ref", "==", gameRef)
      .where("user_ref", "==", db.collection("users").doc(userId))
      .limit(1)
      .get();

    if (!snap.empty) {
      await snap.docs[0].ref.update({ status });
    }
  } catch (err) {
    console.warn(`_updateParticipantStatus: could not update status for user ${userId}:`, err);
  }
}

/**
 * Closes the confirmation window at hour 48.
 * No more submissions accepted after this point.
 *
 * Stage 4 additions:
 *   1. Converts any remaining pending_no_shows to active strikes (ghost_no_show × 2)
 *   2. Evaluates and sets the final verification_status
 */
async function _closeConfirmationWindow(db, jobRef, job, nowTs) {
  const roundRef = job.round_ref;
  const gameRef = job.game_ref;
  const nowMs = nowTs.toMillis();

  // ── Close the job ─────────────────────────────────────────────────────
  await jobRef.update({
    status: "closed",
    closed_at: nowTs,
  });

  if (!roundRef) {
    console.log(
      `_closeConfirmationWindow: closed job ${jobRef.id} (no round_ref)`
    );
    return;
  }

  // ── Read round_records ────────────────────────────────────────────────
  let roundData = {};
  try {
    const roundSnap = await roundRef.get();
    if (roundSnap.exists) roundData = roundSnap.data();
  } catch (err) {
    console.warn(`_closeConfirmationWindow: could not read round_records ${roundRef.id}:`, err);
  }

  // ── If host never confirmed → mark as expired (existing behavior) ─────
  if (!job.host_confirmed_at) {
    // Still evaluate verification status in case fallback signals reached 2
    // before the window closed; if not, mark expired.
    const signalCount = roundData.verification_signal_count || 0;
    if (signalCount < 2) {
      await roundRef.update({ verification_status: "expired" });
      console.log(
        `_closeConfirmationWindow: closed job ${jobRef.id} for game ${gameRef ? gameRef.id : "unknown"} — expired (no host confirmation)`
      );
      return;
    }
    // Fall through: host didn't confirm but we have 2+ fallback signals → verify
  }

  // ── Stage 4: convert remaining pending_no_shows to active strikes ─────
  const pendingNoShows = roundData.pending_no_shows || {};
  const pendingUids = Object.keys(pendingNoShows);

  if (pendingUids.length > 0 && gameRef) {
    // Fetch game data once for _handleNoShowStrike
    let gameData = {};
    try {
      const gameSnap = await gameRef.get();
      if (gameSnap.exists) gameData = gameSnap.data();
    } catch (err) {
      console.warn(`_closeConfirmationWindow: could not fetch game data for strikes:`, err);
    }

    const gameId = gameRef.id;
    for (const uid of pendingUids) {
      try {
        await _handleNoShowStrike(db, gameId, uid, gameData, gameRef, nowMs);
        console.log(
          `_closeConfirmationWindow: pending no-show for ${uid} converted to active strike`
        );
      } catch (err) {
        console.error(
          `_closeConfirmationWindow: failed to issue strike for ${uid}:`, err
        );
      }
    }
  }

  // ── Stage 4: evaluate final verification status ───────────────────────
  if (gameRef) {
    await _evaluateFinalVerificationStatus(db, roundRef, gameRef);
  }

  console.log(
    `_closeConfirmationWindow: closed job ${jobRef.id} for game ${gameRef ? gameRef.id : "unknown"}. ` +
      `Converted ${pendingUids.length} pending no-show(s) to active strikes.`
  );

  // ── Stage 5: update trust profiles for no-show players ───────────────────
  // present players are handled by _finalizeRoundVerification above;
  // no-show players need updates because they just received strikes
  if (pendingUids.length > 0) {
    const noShowTrustUpdates = pendingUids.map((uid) =>
      trustProfile._updateTrustProfileHandler(db, uid).catch((err) =>
        console.warn(
          `_closeConfirmationWindow: trust profile update failed for no-show ${uid}:`, err
        )
      )
    );
    await Promise.all(noShowTrustUpdates);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOIN REQUEST EXPIRATION
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Expires all pending join requests for a game when it transitions to 'played'.
 * Called from _onGameStatusToPlayedHandler after creating round_jobs/round_records.
 *
 * Queries games/{gameId}/join_requests where status == 'pending',
 * batch updates all to status = 'expired' with expired_at timestamp,
 * and notifies each affected player.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} gameId
 * @param {FirebaseFirestore.DocumentReference} gameRef
 * @param {string} gameName - Name of the game for notifications
 */
async function _expirePendingJoinRequests(db, gameId, gameRef, gameName) {
  try {
    const pendingRequestsSnap = await db
      .collection('games')
      .doc(gameId)
      .collection('join_requests')
      .where('status', '==', 'pending')
      .get();

    if (pendingRequestsSnap.empty) {
      return; // No pending requests to expire
    }

    const nowTs = admin.firestore.Timestamp.now();
    const batch = db.batch();
    const affectedPlayers = [];

    for (const doc of pendingRequestsSnap.docs) {
      const data = doc.data();
      batch.update(doc.ref, {
        status: 'expired',
        expired_at: nowTs,
      });

      // Collect player info for notifications
      const playerRef = data.player_ref;
      if (playerRef && typeof playerRef.id === 'string') {
        affectedPlayers.push({
          userId: playerRef.id,
          requestId: doc.id,
        });
      }
    }

    await batch.commit();

    // Send notifications to affected players (non-blocking)
    for (const player of affectedPlayers) {
      try {
        await onJoinRequestExpired(player.userId, gameId, gameName, db);
      } catch (err) {
        console.warn(
          `_expirePendingJoinRequests: failed to notify player ${player.userId}:`, err
        );
      }
    }

    console.log(
      `_expirePendingJoinRequests: expired ${affectedPlayers.length} pending request(s) for game ${gameId}`
    );
  } catch (err) {
    // Non-fatal: log and continue
    console.error(
      `_expirePendingJoinRequests: error for game ${gameId}:`, err
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIBE SCORING (server-side, join-time only)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Extracts the vibe profile from a user document's raw data.
 * Returns a map of category → { value, dealbreaker }.
 */
function _extractVibeProfile(userData) {
  const vibeProfileRaw = userData.vibe_profile;
  if (!vibeProfileRaw || typeof vibeProfileRaw !== "object") {
    return {};
  }

  const prefs = vibeProfileRaw.prefs;
  if (!prefs || typeof prefs !== "object") {
    return {};
  }

  const profile = {};
  for (const category of VIBE_CATEGORIES) {
    const pref = prefs[category];
    if (pref && typeof pref === "object") {
      profile[category] = {
        value: typeof pref.value === "number" ? pref.value : 2.5,
        dealbreaker: pref.dealbreaker === true,
        threshold: typeof pref.dealbreaker_threshold === "number" ? pref.dealbreaker_threshold : 2,
        isDefault: pref.is_default !== false,
      };
    }
  }
  return profile;
}

/**
 * Computes a simplified pairwise vibe score between two users.
 *
 * Returns: {
 *   finalScorePercent: number (0-100),
 *   recommendation: 'Recommended' | 'Caution' | 'NotRecommended',
 *   confidence: 'high' | 'medium' | 'low',
 *   hasHardConflict: boolean
 * }
 */
function _computeVibeScore(profileA, profileB) {
  const categoriesA = Object.keys(profileA);
  const categoriesB = Object.keys(profileB);
  const sharedCategories = categoriesA.filter((c) => categoriesB.includes(c));

  if (sharedCategories.length === 0) {
    return {
      finalScorePercent: 50,
      recommendation: "Caution",
      confidence: "low",
      hasHardConflict: false,
    };
  }

  let totalScore = 0;
  let hasHardConflict = false;
  let defaultCount = 0;

  for (const category of sharedCategories) {
    const a = profileA[category];
    const b = profileB[category];

    if (a.isDefault || b.isDefault) defaultCount++;

    const distance = Math.abs(a.value - b.value); // 0-5 scale

    // Check dealbreaker (hard conflict)
    if (a.dealbreaker && distance > a.threshold) {
      hasHardConflict = true;
    }
    if (b.dealbreaker && distance > b.threshold) {
      hasHardConflict = true;
    }

    // Category match: 1.0 = identical, 0.0 = max distance (5)
    const categoryMatch = Math.max(0, 1 - distance / 5);
    totalScore += categoryMatch;
  }

  const baseScore = totalScore / sharedCategories.length; // 0-1
  const finalScorePercent = hasHardConflict
    ? Math.min(baseScore * 100 * 0.4, 30) // hard cap at 30% with conflict
    : Math.round(baseScore * 100);

  let recommendation;
  if (hasHardConflict || finalScorePercent < 40) {
    recommendation = "NotRecommended";
  } else if (finalScorePercent < 65) {
    recommendation = "Caution";
  } else {
    recommendation = "Recommended";
  }

  const defaultRatio = defaultCount / (sharedCategories.length * 2);
  let confidence;
  if (defaultRatio < 0.25) {
    confidence = "high";
  } else if (defaultRatio < 0.6) {
    confidence = "medium";
  } else {
    confidence = "low";
  }

  return { finalScorePercent, recommendation, confidence, hasHardConflict };
}

/**
 * Returns a display name for a user, preferring display_name over first+last.
 */
function _getUserDisplayName(userData) {
  if (!userData) return "";
  const displayName = userData.display_name;
  if (typeof displayName === "string" && displayName.trim().length > 0) {
    return displayName.trim();
  }
  const first = typeof userData.first_name === "string" ? userData.first_name.trim() : "";
  const last = typeof userData.last_name === "string" ? userData.last_name.trim() : "";
  return `${first} ${last}`.trim();
}

/**
 * Formats a Firestore Timestamp into a short date string for notification templates.
 * e.g., Timestamp for 2026-02-18 → "Feb 18"
 */
function _formatGameDate(teeTimeTs) {
  if (!teeTimeTs || typeof teeTimeTs.toDate !== 'function') return '';
  const d = teeTimeTs.toDate();
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' });
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOUD TASKS SCHEDULING
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Schedules a Cloud Task to call an HTTP function at a specific time.
 * Used for game status transitions and window close — NOT for notifications
 * (those go through the Trust System scheduler).
 */
let _tasksClient = null;
function _getTasksClient() {
  if (!_tasksClient) _tasksClient = new CloudTasksClient();
  return _tasksClient;
}

// Exported for test teardown
function _resetTasksClient() { _tasksClient = null; }

async function _scheduleCloudTask(functionName, payload, scheduleTime, taskId) {
  const client = _getTasksClient();
  const queuePath = client.queuePath(PROJECT, LOCATION, QUEUE_NAME);
  const url = `https://${LOCATION}-${PROJECT}.cloudfunctions.net/${functionName}`;

  const scheduleTimeMs = new Date(scheduleTime).getTime();

  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify(payload)).toString('base64'),
      oidcToken: {
        serviceAccountEmail: `${PROJECT}@appspot.gserviceaccount.com`,
      },
    },
    scheduleTime: {
      seconds: Math.floor(scheduleTimeMs / 1000),
    },
  };

  // Use deterministic task name if provided (enables idempotent retries)
  if (taskId) {
    task.name = `${queuePath}/tasks/${taskId}`;
  }

  try {
    const [createdTask] = await client.createTask({ parent: queuePath, task });
    return createdTask.name;
  } catch (err) {
    // gRPC ALREADY_EXISTS (code 6) — task was already created; treat as success
    if (err.code === 6) {
      console.log(`_scheduleCloudTask: task ${taskId} already exists, treating as success`);
      return `${queuePath}/tasks/${taskId}`;
    }
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────────

module.exports = {
  // Firebase Functions exports (wrapped triggers/callables)
  onGameParticipantJoin,
  onGameStatusToFilled,
  onGameCreated,
  onGameStatusToPlayed,
  onGameStatusToCancelled,
  submitHostCheckin,
  submitPeerRatings,
  submitFallbackConfirmation,
  submitPreGameConfirmation,

  // Raw handler functions — exported for unit testing (bypass Firebase wrappers)
  // Tests call these directly with (data, context, mockDb)
  _onGameParticipantJoinHandler,
  _onGameStatusToFilledHandler,
  _onGameCreatedHandler,
  _onGameStatusToCancelledHandler,
  _processScheduledGameStatusChangeHandler,
  _processScheduledWindowCloseHandler,
  _processScheduledPreGameCheckHandler,
  _processScheduledPreGameTimeoutHandler,
  _onGameStatusToPlayedHandler,
  _submitHostCheckinHandler,
  _submitPeerRatingsHandler,
  _submitFallbackConfirmationHandler,
  _submitPreGameConfirmationHandler,

  // Other internal helpers exported for testing
  _handleNoShowStrike,
  _buildRoundRecordData,
  _snapshotGameSettings,
  _extractVibeProfile,
  _computeVibeScore,
  _getUserDisplayName,
  _formatGameDate,
  _resetTasksClient,
  _closeConfirmationWindow,

  // Stage 4 helpers exported for testing
  _recordVerificationSignal,
  _resolvePendingNoShow,
  _finalizeRoundVerification,
  _evaluateFinalVerificationStatus,

  // Vibe floor join request helpers exported for testing
  _expirePendingJoinRequests,
};
