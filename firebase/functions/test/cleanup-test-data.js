/**
 * Cleanup Script for Load Test Data
 *
 * Deletes all documents created by load-test.js with the LOADTEST_ prefix.
 * Safe to run multiple times - only deletes test data.
 *
 * Usage:
 *   cd firebase/functions
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node test/cleanup-test-data.js
 */

'use strict';

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin with explicit service account
if (!admin.apps.length) {
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    path.join(__dirname, '..', 'service-account.json');

  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });

  console.log(`Initialized with project: ${serviceAccount.project_id}`);
}

const db = admin.firestore();
const PREFIX = 'LOADTEST_';
const USERNAME_PREFIX = 'Load Test User';

// Collections to clean up
const COLLECTIONS = [
  // Primary test data (query by document ID prefix)
  { name: 'users', queryById: true, prefix: PREFIX, subcollections: ['fcm_tokens'] },
  { name: 'games', queryById: true, prefix: PREFIX },
  { name: 'usernames', queryById: true, prefix: USERNAME_PREFIX },

  // Secondary data (query by test_marker field)
  { name: 'game_participants', queryByField: 'test_marker' },

  // Trust system data (query by game_ref prefix)
  { name: 'round_jobs', queryByGameRef: true },
  { name: 'round_records', queryByGameRef: true },
  { name: 'pair_ratings', queryByGameRef: true },

  // Notifications (query by sourceId or recipientUserId prefix)
  { name: 'scheduledNotifications', queryByField: 'sourceId', prefixQuery: true },
  { name: 'notificationLog', queryByField: 'recipientUserId', prefixQuery: true },
];

async function deleteSubcollections(docRef, subcollections) {
  for (const subCol of subcollections) {
    const subSnapshot = await docRef.collection(subCol).get();
    if (subSnapshot.empty) continue;

    const batch = db.batch();
    subSnapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }
}

async function deleteCollection(config) {
  const { name, queryById, queryByField, queryByGameRef, prefixQuery, subcollections, prefix } = config;
  const queryPrefix = prefix || PREFIX;

  let totalDeleted = 0;
  let hasMore = true;

  while (hasMore) {
    let snapshot;

    try {
      if (queryById) {
        // Query by document ID prefix
        snapshot = await db.collection(name)
          .where(admin.firestore.FieldPath.documentId(), '>=', queryPrefix)
          .where(admin.firestore.FieldPath.documentId(), '<', queryPrefix + '\uf8ff')
          .limit(400)
          .get();
      } else if (queryByField && prefixQuery) {
        // Query by field value prefix
        snapshot = await db.collection(name)
          .where(queryByField, '>=', PREFIX)
          .where(queryByField, '<', PREFIX + '\uf8ff')
          .limit(400)
          .get();
      } else if (queryByField) {
        // Query by exact field match
        snapshot = await db.collection(name)
          .where(queryByField, '==', PREFIX)
          .limit(400)
          .get();
      } else if (queryByGameRef) {
        // Need to fetch and filter manually by game_ref
        snapshot = await db.collection(name).limit(500).get();
        const testDocs = snapshot.docs.filter(doc => {
          const data = doc.data();
          const gameRef = data.game_ref;
          return gameRef && gameRef.id && gameRef.id.startsWith(PREFIX);
        });

        if (testDocs.length === 0) {
          hasMore = false;
          continue;
        }

        // Delete filtered docs
        const batch = db.batch();
        testDocs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        totalDeleted += testDocs.length;

        // Check if we might have more
        hasMore = snapshot.size === 500;
        continue;
      } else {
        hasMore = false;
        continue;
      }

      if (snapshot.empty) {
        hasMore = false;
        continue;
      }

      // Delete subcollections first if needed
      if (subcollections) {
        for (const doc of snapshot.docs) {
          await deleteSubcollections(doc.ref, subcollections);
        }
      }

      // Delete documents in batch
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();

      totalDeleted += snapshot.size;
      hasMore = snapshot.size === 400; // If we got a full batch, there might be more

    } catch (error) {
      console.error(`  Error in ${name}: ${error.message}`);
      hasMore = false;
    }
  }

  return totalDeleted;
}

async function runCleanup() {
  console.log('='.repeat(60));
  console.log('LOAD TEST DATA CLEANUP');
  console.log('='.repeat(60));
  console.log(`\nDefault prefix: ${PREFIX}`);
  console.log(`Username prefix: ${USERNAME_PREFIX}\n`);

  let grandTotal = 0;

  for (const config of COLLECTIONS) {
    const usedPrefix = config.prefix || PREFIX;
    process.stdout.write(`${config.name} (prefix: "${usedPrefix}"): `);
    const deleted = await deleteCollection(config);
    console.log(`${deleted} documents deleted`);
    grandTotal += deleted;
  }

  console.log('\n' + '='.repeat(60));
  console.log(`TOTAL: ${grandTotal} documents deleted`);
  console.log('='.repeat(60));

  process.exit(0);
}

// Run cleanup
runCleanup().catch(error => {
  console.error('Cleanup failed:', error);
  process.exit(1);
});
