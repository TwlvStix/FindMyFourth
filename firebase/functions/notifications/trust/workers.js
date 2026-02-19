'use strict';

/**
 * Trust System Background Workers
 *
 * Scheduled job handlers — plain async functions wired to Cloud Scheduler
 * in index.js via functions.pubsub.schedule().onRun().
 *
 * Public API:
 *   trustTokenHygieneHandler(db?)         — daily 3am UTC
 *     Deletes stale device documents (lastSeenAt older than 90 days).
 *
 *   trustQuietHoursCleanupHandler(db?)    — every 15 minutes
 *     Safety net: re-dispatches notificationLog entries that are stuck in
 *     quiet_held status past their releaseAt time. Cloud Tasks normally
 *     handles quiet hours releases; this catches anything that slipped through.
 */

const admin = require('firebase-admin');
const functions = require('firebase-functions');
const { routeNotification } = require('./router');

// ── Constants ─────────────────────────────────────────────────────────────────

const STALE_DEVICE_DAYS    = 90;
const STUCK_THRESHOLD_MS   = 5 * 60 * 1000;   // 5 minutes
const FIRESTORE_BATCH_LIMIT = 500;

// ── trustTokenHygieneHandler ──────────────────────────────────────────────────

/**
 * Finds device documents with lastSeenAt older than 90 days and deletes them.
 * Runs in batches of up to 500 to respect Firestore batch limits.
 *
 * Requires a COLLECTION_GROUP index on devices.lastSeenAt.
 *
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ scanned: number, deleted: number, cutoff: string }>}
 */
async function trustTokenHygieneHandler(db) {
  if (!db) db = admin.firestore();

  const cutoff = new Date(Date.now() - STALE_DEVICE_DAYS * 24 * 60 * 60 * 1000);
  const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

  const snap = await db
    .collectionGroup('devices')
    .where('lastSeenAt', '<', cutoffTs)
    .get();

  const docs = snap.docs;
  let deleted = 0;

  // Delete in batches of FIRESTORE_BATCH_LIMIT
  for (let i = 0; i < docs.length; i += FIRESTORE_BATCH_LIMIT) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + FIRESTORE_BATCH_LIMIT);
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }

  const summary = { scanned: docs.length, deleted, cutoff: cutoff.toISOString() };
  functions.logger.info('trustTokenHygieneJob', summary);
  return summary;
}

// ── trustQuietHoursCleanupHandler ─────────────────────────────────────────────

/**
 * Safety net for quiet_held notifications that were not released by Cloud Tasks.
 * Queries notificationLog for entries stuck in quiet_held status where
 * releaseAt is more than 5 minutes in the past, then re-dispatches each one
 * via routeNotification with quietHoursBypass: true.
 *
 * Processed entries are marked quiet_held_released to prevent re-processing.
 * Errors on individual re-dispatches are logged but do not abort the run.
 *
 * Requires the composite index on notificationLog[status ASC, releaseAt ASC].
 *
 * @param {FirebaseFirestore.Firestore} [db]
 * @returns {Promise<{ found: number, requeued: number, errors: number }>}
 */
async function trustQuietHoursCleanupHandler(db) {
  if (!db) db = admin.firestore();

  const staleThreshold = new Date(Date.now() - STUCK_THRESHOLD_MS);
  const staleTs = admin.firestore.Timestamp.fromDate(staleThreshold);

  const snap = await db
    .collection('notificationLog')
    .where('status', '==', 'quiet_held')
    .where('releaseAt', '<', staleTs)
    .get();

  const docs = snap.docs;
  let requeued = 0;
  let errors = 0;

  for (const doc of docs) {
    const data = doc.data();
    const event = data.event;

    if (!event) {
      // Pre-feature doc — no event payload stored; skip.
      functions.logger.warn('trustQuietHoursCleanup', { message: `no event payload on doc ${doc.id}, skipping`, docId: doc.id });
      errors += 1;
      continue;
    }

    try {
      await routeNotification({ ...event, quietHoursBypass: true }, db);
      await doc.ref.update({ status: 'quiet_held_released' });
      requeued += 1;
    } catch (err) {
      functions.logger.error('trustQuietHoursCleanup', { message: `failed to re-dispatch doc ${doc.id}`, docId: doc.id, error: err.message });
      errors += 1;
    }
  }

  const summary = { found: docs.length, requeued, errors };
  functions.logger.info('trustQuietHoursCleanup', summary);
  return summary;
}

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  trustTokenHygieneHandler,
  trustQuietHoursCleanupHandler,
};
