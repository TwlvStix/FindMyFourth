'use strict';

/**
 * Trust System Notification Scheduler
 *
 * Manages deferred notifications via Cloud Tasks.
 *
 * Public API:
 *   scheduleJob(event, db?)                    → jobId
 *   cancelJob(jobId, db?)                      → { cancelled: boolean }
 *   cancelGameJobs(gameId, db?)                → { count: number }
 *   processScheduledTrustNotificationHandler   → Express-compatible HTTP handler
 *
 * The event object passed to scheduleJob extends the standard TrustEvent with:
 *   scheduleTime   {string|Date}  When to deliver — ISO string or Date
 *   conditionCheck {string}       'always' | 'host_not_checked_in'
 *
 * Queue config: trust-notification-scheduler
 *   - Target: processScheduledTrustNotification HTTP function (OIDC auth)
 *   - Retries handled by Cloud Tasks (3 retries, 10s–300s backoff)
 */

const admin = require('firebase-admin');
const { CloudTasksClient } = require('@google-cloud/tasks');
const { routeNotification } = require('./router');

// ── Constants ─────────────────────────────────────────────────────────────────

const PROJECT   = process.env.GCLOUD_PROJECT || 'find-my-fourth';
const LOCATION  = 'us-west2';
const QUEUE_NAME = 'trust-notification-scheduler';
const RECEIVER_URL = `https://${LOCATION}-${PROJECT}.cloudfunctions.net/processScheduledTrustNotification`;
const SCHEDULED_NOTIFICATIONS = 'scheduledNotifications';

// ── CloudTasksClient singleton ─────────────────────────────────────────────────

let _tasksClient = null;

/** Returns the shared CloudTasksClient, creating it on first call. */
function getTasksClient() {
  if (!_tasksClient) _tasksClient = new CloudTasksClient();
  return _tasksClient;
}

// ── scheduleJob ───────────────────────────────────────────────────────────────

/**
 * Schedules a future Trust System notification via Cloud Tasks.
 *
 * @param {{
 *   eventId:         string,
 *   eventType:       string,
 *   recipientUserId: string,
 *   sourceId:        string,
 *   data:            Record<string, string>,
 *   scheduleTime:    string|Date,   // when to deliver
 *   conditionCheck?: string,        // 'always' (default) | 'host_not_checked_in'
 *   isReminder?:     boolean,
 *   quietHoursBypass?: boolean,
 * }} event
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<string>} jobId
 */
async function scheduleJob(event, db) {
  if (!db) db = admin.firestore();
  const client = getTasksClient();

  // Use eventId as the doc ID for deterministic idempotency.
  // If the same eventId is scheduled twice (crash-retry), the Firestore doc
  // and Cloud Task name will collide, preventing duplicates.
  const jobId  = event.eventId;
  const docRef = db.collection(SCHEDULED_NOTIFICATIONS).doc(jobId);

  const queuePath         = client.queuePath(PROJECT, LOCATION, QUEUE_NAME);
  const scheduleTimeMs    = new Date(event.scheduleTime).getTime();
  const scheduleTimeSeconds = Math.floor(scheduleTimeMs / 1000);

  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url: RECEIVER_URL,
      headers: { 'Content-Type': 'application/json' },
      body: Buffer.from(JSON.stringify({ jobId, event })).toString('base64'),
      oidcToken: {
        serviceAccountEmail: `${PROJECT}@appspot.gserviceaccount.com`,
      },
    },
    scheduleTime: { seconds: scheduleTimeSeconds },
    // Deterministic task name prevents duplicate Cloud Tasks on retry
    name: `${queuePath}/tasks/${jobId}`,
  };

  let taskName;
  try {
    const [createdTask] = await client.createTask({ parent: queuePath, task });
    taskName = createdTask.name;
  } catch (err) {
    // gRPC ALREADY_EXISTS (code 6) — task was already created; treat as success
    if (err.code === 6) {
      console.log(`[Scheduler] Task ${jobId} already exists, treating as success`);
      taskName = `${queuePath}/tasks/${jobId}`;
    } else {
      throw err;
    }
  }

  // Write tracking doc. Uses set() which is idempotent — if the doc already
  // exists from a previous attempt, it gets overwritten with the same data.
  await docRef.set({
    jobId,
    taskName,
    eventType:       event.eventType,
    recipientUserId: event.recipientUserId,
    sourceId:        event.sourceId,
    // gameId mirrors sourceId — used by the [gameId, status] composite index
    // for cancelGameJobs queries.
    gameId:          event.sourceId,
    status:          'PENDING',
    scheduleTime:    admin.firestore.Timestamp.fromDate(new Date(event.scheduleTime)),
    createdAt:       admin.firestore.FieldValue.serverTimestamp(),
    event,
  });

  return jobId;
}

// ── cancelJob ─────────────────────────────────────────────────────────────────

/**
 * Cancels a pending scheduled notification. Idempotent — safe to call multiple
 * times or on already-CANCELLED / EXECUTED jobs.
 *
 * @param {string} jobId
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ cancelled: boolean }>}
 */
async function cancelJob(jobId, db) {
  if (!db) db = admin.firestore();
  const client = getTasksClient();

  const docRef = db.collection(SCHEDULED_NOTIFICATIONS).doc(jobId);
  const snap   = await docRef.get();

  if (!snap.exists || snap.data().status !== 'PENDING') {
    return { cancelled: false };
  }

  const taskName = snap.data().taskName;
  try {
    await client.deleteTask({ name: taskName });
  } catch (err) {
    // gRPC NOT_FOUND (code 5) — task already executed or was deleted; safe to ignore.
    if (err.code !== 5) throw err;
  }

  await docRef.update({
    status:      'CANCELLED',
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { cancelled: true };
}

// ── cancelGameJobs ────────────────────────────────────────────────────────────

/**
 * Cancels all PENDING scheduled notifications for a given gameId.
 * Uses the [gameId ASC, status ASC] composite index in firestore.indexes.json.
 *
 * @param {string} gameId
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ count: number }>}
 */
async function cancelGameJobs(gameId, db) {
  if (!db) db = admin.firestore();
  const client = getTasksClient();

  const snap = await db.collection(SCHEDULED_NOTIFICATIONS)
    .where('gameId', '==', gameId)
    .where('status', '==', 'PENDING')
    .get();

  if (snap.empty) return { count: 0 };

  await Promise.all(snap.docs.map(async (doc) => {
    const taskName = doc.data().taskName;
    try {
      await client.deleteTask({ name: taskName });
    } catch (err) {
      if (err.code !== 5) throw err;
    }
    await doc.ref.update({
      status:      'CANCELLED',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }));

  return { count: snap.docs.length };
}

// ── HTTP receiver ─────────────────────────────────────────────────────────────

/**
 * HTTP handler for the processScheduledTrustNotification Cloud Function.
 *
 * Cloud Tasks delivers the task payload here. The function is protected by
 * OIDC at the platform level — no manual token validation required.
 *
 * Returns 200 for all non-error outcomes (including cancelled/skipped jobs)
 * so Cloud Tasks does not retry unnecessarily.
 *
 * @param {import('express').Request}  req
 * @param {import('express').Response} res
 */
async function processScheduledTrustNotificationHandler(req, res) {
  const db = admin.firestore();

  // 1. Parse payload
  const { jobId, event } = req.body || {};
  if (!jobId || !event) {
    console.error('[Scheduler] Missing jobId or event in request body');
    return res.status(400).send('Missing jobId or event');
  }

  // 2. Read tracking doc
  const docRef = db.collection(SCHEDULED_NOTIFICATIONS).doc(jobId);
  const snap   = await docRef.get();

  if (!snap.exists) {
    console.warn(`[Scheduler] Tracking doc not found for jobId ${jobId}`);
    return res.status(200).send('NOT_FOUND');
  }

  // 3. If CANCELLED → 200 no-op (Cloud Tasks won't retry)
  if (snap.data().status === 'CANCELLED') {
    console.log(`[Scheduler] Job ${jobId} is CANCELLED — skipping`);
    return res.status(200).send('CANCELLED');
  }

  // 4. Evaluate conditionCheck
  const conditionCheck = event.conditionCheck || 'always';

  if (conditionCheck === 'host_not_checked_in') {
    const gameSnap = await db.collection('games').doc(event.sourceId).get();
    if (gameSnap.exists) {
      const gameData = gameSnap.data();
      // NOTE: `hostCheckedIn` is a placeholder field name. Update to the real
      // game document field once the host check-in write is implemented.
      // If the field name is wrong the check silently passes and delivers the
      // notification, which is the safer failure mode (false positive over
      // false negative).
      if (gameData.hostCheckedIn === true) {
        console.log(`[Scheduler] Job ${jobId} condition not met (host checked in) — cancelling`);
        await docRef.update({
          status:      'CANCELLED',
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.status(200).send('CONDITION_NOT_MET');
      }
    }
  }

  if (conditionCheck === 'flexible_game_still_active') {
    const gameSnap = await db.collection('games').doc(event.sourceId).get();
    if (gameSnap.exists) {
      const gameData = gameSnap.data();
      // Game must still be flexible (not confirmed) with 2+ players
      const isStillFlexible = gameData.schedule_type === 'flexible';
      const hasEnoughPlayers = (gameData.joined_players?.length || 0) >= 2;
      const isNotCancelled = gameData.status !== 'cancelled';

      if (!isStillFlexible || !hasEnoughPlayers || !isNotCancelled) {
        console.log(`[Scheduler] Job ${jobId} condition not met (flexible=${isStillFlexible}, players=${hasEnoughPlayers}, notCancelled=${isNotCancelled}) — cancelling`);
        await docRef.update({
          status:      'CANCELLED',
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.status(200).send('CONDITION_NOT_MET');
      }
    }
  }
  // conditionCheck === 'always' falls through to delivery

  // 5. Route notification through the full pipeline
  // Flexible nudge events have their own handler with built-in condition re-checking
  const FLEXIBLE_NUDGE_EVENT_TYPES = ['flexible_nudge_soft', 'flexible_nudge_urgent'];
  if (FLEXIBLE_NUDGE_EVENT_TYPES.includes(event.eventType)) {
    // Late require to avoid circular dependency (flexible_nudge imports from scheduler)
    const { processFlexibleNudge } = require('../flexible_nudge');
    await processFlexibleNudge(event, db);
  } else {
    await routeNotification(event, db);
  }

  // 6. Mark executed
  await docRef.update({
    status:      'EXECUTED',
    executedAt:  admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[Scheduler] Job ${jobId} executed — eventType=${event.eventType}`);
  return res.status(200).send('OK');
}

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  scheduleJob,
  cancelJob,
  cancelGameJobs,
  processScheduledTrustNotificationHandler,
  getTasksClient,
  // Exported for testing only
  _resetTasksClient: () => { _tasksClient = null; },
};
