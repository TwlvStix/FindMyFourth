/**
 * Load Test Script for Trust System — Session 13
 *
 * Exercises REAL production entry points:
 *   - _onGameStatusToPlayedHandler() → creates round_jobs, round_records, schedules Trust notifications
 *   - _submitHostCheckinHandler()    → calls onHostCheckinCompleted, sends no-show notifications
 *   - _submitPeerRatingsHandler()    → creates pair_ratings, records verification signals
 *
 * Configuration:
 *   SMALL:  50 games, ~100 users (first run, validation)
 *   LARGE:  500 games, ~1500 users (peak Saturday morning simulation)
 *
 * Success Criteria:
 *   - P99 latency < 5 seconds
 *   - Error rate < 1%
 *   - Firestore read/write costs measured
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node test/load-test.js
 */

'use strict';

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Import the raw handlers we're testing
const confirmationFlow = require('../confirmation_flow');

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────

const CONFIG = {
  // SMALL config for first run
  TOTAL_GAMES: 50,
  USERS_PER_GAME_AVG: 3,
  DEVICES_PER_USER_AVG: 1.5,

  // Burst simulation
  HOST_CHECKIN_RATE: 0.80,      // 80% of hosts confirm
  PLAYER_PRESENT_RATE: 0.85,    // 85% of players marked present
  RATING_COMPLETION_RATE: 0.75, // 75% of present players submit ratings

  // Performance thresholds
  P99_THRESHOLD_MS: 5000,
  ERROR_RATE_THRESHOLD: 0.01,

  // Test marker for cleanup
  TEST_PREFIX: 'LOADTEST_',

  // Firestore operation costs (per million)
  COSTS: {
    READ: 0.06,
    WRITE: 0.18,
    DELETE: 0.02,
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// METRICS COLLECTION
// ─────────────────────────────────────────────────────────────────────────────

const metrics = {
  operations: [],
  errors: [],
  firestoreOps: { reads: 0, writes: 0, deletes: 0 },
  startTime: null,
  endTime: null,
  documentCounts: {},
};

function trackOperation(name, startTime, success = true, error = null) {
  const endTime = Date.now();
  const duration = endTime - startTime;

  metrics.operations.push({
    name,
    duration,
    success,
    timestamp: endTime,
    error: error ? error.message : null,
  });

  if (!success && error) {
    metrics.errors.push({
      operation: name,
      error: error.message,
      timestamp: endTime,
    });
  }

  return { duration, success };
}

// ─────────────────────────────────────────────────────────────────────────────
// TEST DATA GENERATORS
// ─────────────────────────────────────────────────────────────────────────────

function generateUserId(index) {
  return `${CONFIG.TEST_PREFIX}user_${String(index).padStart(4, '0')}`;
}

function generateGameId(index) {
  return `${CONFIG.TEST_PREFIX}game_${String(index).padStart(4, '0')}`;
}

function generateVibeProfile() {
  return {
    prefs: {
      drinking: { value: Math.floor(Math.random() * 5), dealbreaker: false, is_default: false },
      music: { value: Math.floor(Math.random() * 5), dealbreaker: false, is_default: false },
      pace: { value: Math.floor(Math.random() * 5), dealbreaker: false, is_default: false },
      money: { value: Math.floor(Math.random() * 5), dealbreaker: false, is_default: false },
      chat: { value: Math.floor(Math.random() * 5), dealbreaker: false, is_default: false },
      competitive: { value: Math.floor(Math.random() * 5), dealbreaker: false, is_default: false },
    },
  };
}

function generateFCMToken(userId, deviceIndex) {
  // Fake token format — FCM sends will fail, which is expected
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const random = Array.from({ length: 140 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `${CONFIG.TEST_PREFIX}${random}:${userId}:${deviceIndex}`;
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 1: CREATE TEST USERS
// ─────────────────────────────────────────────────────────────────────────────

async function createTestUsers(count) {
  console.log(`\n[Phase 1] Creating ${count} test users...`);
  const startTime = Date.now();

  const batchSize = 400; // Stay under 500 limit with subcollection writes
  let created = 0;

  for (let i = 0; i < count; i += batchSize) {
    const batch = db.batch();
    const batchEnd = Math.min(i + batchSize, count);

    for (let j = i; j < batchEnd; j++) {
      const userId = generateUserId(j);
      const userRef = db.collection('users').doc(userId);

      // User document
      batch.set(userRef, {
        display_name: `Load Test User ${j}`,
        first_name: 'Load',
        last_name: `User${j}`,
        email: `${userId}@loadtest.local`,
        handicap: Math.floor(Math.random() * 36),
        vibe_profile: generateVibeProfile(),
        notification_prefs: {
          push_enabled: true,
          trust_categories: {
            post_round: true,
            trust_alerts: true,
            badges: true,
          },
          quiet_hours: { enabled: false },
          game_alerts: { enabled: true },
        },
        test_marker: CONFIG.TEST_PREFIX,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      metrics.firestoreOps.writes++;

      // Add 1-2 FCM tokens per user
      const numDevices = Math.random() < 0.5 ? 1 : 2;
      for (let d = 0; d < numDevices; d++) {
        const tokenRef = userRef.collection('fcm_tokens').doc(`device_${d}`);
        batch.set(tokenRef, {
          fcm_token: generateFCMToken(userId, d),
          device_type: d === 0 ? 'ios' : 'android',
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        metrics.firestoreOps.writes++;
      }
    }

    await batch.commit();
    created += (batchEnd - i);

    if (created % 100 === 0 || created === count) {
      console.log(`  Created ${created}/${count} users`);
    }
  }

  const { duration } = trackOperation('createTestUsers', startTime, true);
  console.log(`  ✓ Created ${count} users in ${duration}ms`);

  return count;
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 2: CREATE TEST GAMES + PARTICIPANTS
// ─────────────────────────────────────────────────────────────────────────────

async function createTestGames(gameCount, userCount) {
  console.log(`\n[Phase 2] Creating ${gameCount} test games with participants...`);
  const startTime = Date.now();

  const games = [];

  // Tee time in the past (5 hours ago) so T+5h notification is "now"
  const baseTeeTime = new Date(Date.now() - 5 * 60 * 60 * 1000);

  for (let g = 0; g < gameCount; g++) {
    const gameId = generateGameId(g);
    const gameRef = db.collection('games').doc(gameId);

    // Select 3-4 random users for this game
    const numPlayers = 3 + Math.floor(Math.random() * 2); // 3 or 4
    const playerIndices = [];
    while (playerIndices.length < numPlayers) {
      const idx = Math.floor(Math.random() * userCount);
      if (!playerIndices.includes(idx)) {
        playerIndices.push(idx);
      }
    }

    const playerUserIds = playerIndices.map(i => generateUserId(i));
    const hostUserId = playerUserIds[0];

    // Spread tee times across 2-hour window
    const teeTimeOffset = (g / gameCount) * 2 * 60 * 60 * 1000;
    const teeTime = new Date(baseTeeTime.getTime() + teeTimeOffset);

    // Create game document with status 'filled' (will transition to 'played')
    const gameData = {
      status: 'filled',
      date: admin.firestore.Timestamp.fromDate(teeTime),
      course_play: `Load Test Course ${g % 5}`,
      courseRef: db.collection('courses').doc(`course_${g % 5}`),
      game_type: ['stroke_play', 'match_play', 'stableford'][g % 3],
      style_game: ['money', 'for_fun', 'competitive'][g % 3],
      rules_setting: ['competitive', 'casual'][g % 2],
      userRef: db.collection('users').doc(hostUserId),
      host_ref: db.collection('users').doc(hostUserId),
      joined_players: playerUserIds.map(uid => db.collection('users').doc(uid)),
      max_players: 4,
      isCancelled: false,
      test_marker: CONFIG.TEST_PREFIX,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await gameRef.set(gameData);
    metrics.firestoreOps.writes++;

    // Create game_participants with profile_snapshots (mimics onGameParticipantJoin)
    const participantsBatch = db.batch();
    const vibeScores = {}; // uid -> { otherUid -> score }

    for (const uid of playerUserIds) {
      vibeScores[uid] = {};
      for (const otherUid of playerUserIds) {
        if (otherUid !== uid) {
          vibeScores[uid][otherUid] = {
            finalScorePercent: 50 + Math.floor(Math.random() * 50),
            recommendation: 'Recommended',
            confidence: 'medium',
            hasHardConflict: false,
          };
        }
      }
    }

    for (let p = 0; p < playerUserIds.length; p++) {
      const uid = playerUserIds[p];
      const participantRef = db.collection('game_participants').doc(`${gameId}_${uid}`);

      participantsBatch.set(participantRef, {
        user_ref: db.collection('users').doc(uid),
        game_ref: gameRef,
        role: p === 0 ? 'host' : 'player',
        status: 'joined',
        profile_snapshot: {
          uid,
          display_name: `Load Test User ${playerIndices[p]}`,
          photo_url: '',
          handicap: Math.floor(Math.random() * 36),
          role: p === 0 ? 'host' : 'player',
          snapshotted_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        vibe_scores_with_others: vibeScores[uid],
        test_marker: CONFIG.TEST_PREFIX,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      metrics.firestoreOps.writes++;
    }

    await participantsBatch.commit();

    games.push({
      gameId,
      gameRef,
      hostUserId,
      playerUserIds,
      teeTime,
      gameData,
    });

    if ((g + 1) % 10 === 0 || g === gameCount - 1) {
      console.log(`  Created ${g + 1}/${gameCount} games`);
    }
  }

  const { duration } = trackOperation('createTestGames', startTime, true);
  console.log(`  ✓ Created ${gameCount} games in ${duration}ms`);

  return games;
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 3: BURST onGameStatusToPlayed
// ─────────────────────────────────────────────────────────────────────────────

async function burstGameStatusToPlayed(games) {
  console.log(`\n[Phase 3] Calling _onGameStatusToPlayedHandler() for ${games.length} games...`);

  let successCount = 0;
  let errorCount = 0;
  const latencies = [];

  // Process in parallel batches of 10
  const batchSize = 10;

  for (let i = 0; i < games.length; i += batchSize) {
    const batch = games.slice(i, i + batchSize);

    const results = await Promise.allSettled(batch.map(async (game) => {
      const startTime = Date.now();

      try {
        // Simulate Firestore change object for onUpdate trigger
        const beforeData = { ...game.gameData, status: 'filled' };
        const afterData = { ...game.gameData, status: 'played' };

        const mockChange = {
          before: {
            data: () => beforeData,
            ref: game.gameRef,
          },
          after: {
            data: () => afterData,
            ref: game.gameRef,
          },
        };

        const mockContext = {
          params: { gameId: game.gameId },
        };

        // Call the actual handler
        await confirmationFlow._onGameStatusToPlayedHandler(mockChange, mockContext, db);

        const { duration } = trackOperation('onGameStatusToPlayed', startTime, true);
        latencies.push(duration);
        return { success: true, duration };
      } catch (error) {
        trackOperation('onGameStatusToPlayed', startTime, false, error);
        return { success: false, error: error.message };
      }
    }));

    for (const result of results) {
      if (result.status === 'fulfilled' && result.value.success) {
        successCount++;
      } else {
        errorCount++;
      }
    }

    if ((i + batchSize) % 20 === 0 || i + batchSize >= games.length) {
      console.log(`  Processed ${Math.min(i + batchSize, games.length)}/${games.length} games`);
    }
  }

  const avgLatency = latencies.length > 0 ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length) : 0;
  console.log(`  ✓ onGameStatusToPlayed: ${successCount} success, ${errorCount} errors, avg ${avgLatency}ms`);

  return { successCount, errorCount };
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 4: BURST submitHostCheckin
// ─────────────────────────────────────────────────────────────────────────────

async function burstHostCheckin(games) {
  console.log(`\n[Phase 4] Calling _submitHostCheckinHandler() for ${Math.floor(games.length * CONFIG.HOST_CHECKIN_RATE)} games (80%)...`);

  // Select 80% of games for host check-in
  const checkInGames = games.filter(() => Math.random() < CONFIG.HOST_CHECKIN_RATE);

  let successCount = 0;
  let errorCount = 0;
  const latencies = [];
  const checkedInGames = [];

  const batchSize = 10;

  for (let i = 0; i < checkInGames.length; i += batchSize) {
    const batch = checkInGames.slice(i, i + batchSize);

    const results = await Promise.allSettled(batch.map(async (game) => {
      const startTime = Date.now();

      try {
        // Build attendance map — 85% present, 15% no-show
        const attendance = {};
        for (const uid of game.playerUserIds) {
          attendance[uid] = Math.random() < CONFIG.PLAYER_PRESENT_RATE;
        }

        const mockData = {
          gameId: game.gameId,
          attendance,
        };

        const mockContext = {
          auth: { uid: game.hostUserId },
        };

        // Call the actual handler
        await confirmationFlow._submitHostCheckinHandler(mockData, mockContext, db);

        const { duration } = trackOperation('submitHostCheckin', startTime, true);
        latencies.push(duration);

        // Track which players are present for ratings phase
        const presentPlayers = game.playerUserIds.filter(uid => attendance[uid]);
        checkedInGames.push({ ...game, presentPlayers });

        return { success: true, duration };
      } catch (error) {
        trackOperation('submitHostCheckin', startTime, false, error);
        return { success: false, error: error.message };
      }
    }));

    for (const result of results) {
      if (result.status === 'fulfilled' && result.value.success) {
        successCount++;
      } else {
        errorCount++;
      }
    }

    if ((i + batchSize) % 20 === 0 || i + batchSize >= checkInGames.length) {
      console.log(`  Processed ${Math.min(i + batchSize, checkInGames.length)}/${checkInGames.length} check-ins`);
    }
  }

  const avgLatency = latencies.length > 0 ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length) : 0;
  console.log(`  ✓ submitHostCheckin: ${successCount} success, ${errorCount} errors, avg ${avgLatency}ms`);

  return { successCount, errorCount, checkedInGames };
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 5: BURST submitPeerRatings
// ─────────────────────────────────────────────────────────────────────────────

async function burstPeerRatings(checkedInGames) {
  console.log(`\n[Phase 5] Calling _submitPeerRatingsHandler() for present players...`);

  let totalRatings = 0;
  let successCount = 0;
  let errorCount = 0;
  const latencies = [];

  for (const game of checkedInGames) {
    // Each present player who completes ratings (75%)
    const ratersWhoSubmit = game.presentPlayers.filter(() => Math.random() < CONFIG.RATING_COMPLETION_RATE);

    for (const raterUid of ratersWhoSubmit) {
      const startTime = Date.now();

      try {
        // Rate all other present players
        const ratings = {};
        for (const ratedUid of game.presentPlayers) {
          if (ratedUid !== raterUid) {
            ratings[ratedUid] = Math.random() < 0.85; // 85% would play again
          }
        }

        const mockData = {
          gameId: game.gameId,
          ratings,
        };

        const mockContext = {
          auth: { uid: raterUid },
        };

        await confirmationFlow._submitPeerRatingsHandler(mockData, mockContext, db);

        const { duration } = trackOperation('submitPeerRatings', startTime, true);
        latencies.push(duration);
        totalRatings += Object.keys(ratings).length;
        successCount++;
      } catch (error) {
        trackOperation('submitPeerRatings', startTime, false, error);
        errorCount++;
      }
    }
  }

  const avgLatency = latencies.length > 0 ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length) : 0;
  console.log(`  ✓ submitPeerRatings: ${successCount} success, ${errorCount} errors, ${totalRatings} ratings, avg ${avgLatency}ms`);

  return { successCount, errorCount, totalRatings };
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 6: VERIFY DOCUMENT COUNTS
// ─────────────────────────────────────────────────────────────────────────────

async function verifyDocumentCounts() {
  console.log('\n[Phase 6] Verifying Firestore document counts...');

  const collections = ['round_jobs', 'round_records', 'pair_ratings', 'scheduledNotifications'];

  for (const collection of collections) {
    try {
      // Query for test documents
      let query;
      if (collection === 'scheduledNotifications') {
        // scheduledNotifications use sourceId starting with LOADTEST_
        query = db.collection(collection)
          .where('sourceId', '>=', CONFIG.TEST_PREFIX)
          .where('sourceId', '<', CONFIG.TEST_PREFIX + '\uf8ff');
      } else {
        // Other collections have test_marker or game_ref starting with LOADTEST_
        const snapshot = await db.collection(collection).limit(1000).get();
        let count = 0;
        snapshot.forEach(doc => {
          const data = doc.data();
          const gameRef = data.game_ref;
          if (gameRef && gameRef.id && gameRef.id.startsWith(CONFIG.TEST_PREFIX)) {
            count++;
          }
        });
        metrics.documentCounts[collection] = count;
        metrics.firestoreOps.reads += snapshot.size;
        console.log(`  ${collection}: ${count} documents`);
        continue;
      }

      const snapshot = await query.get();
      metrics.documentCounts[collection] = snapshot.size;
      metrics.firestoreOps.reads += snapshot.size;
      console.log(`  ${collection}: ${snapshot.size} documents`);
    } catch (error) {
      console.log(`  ${collection}: error counting - ${error.message}`);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 7: CLEANUP
// ─────────────────────────────────────────────────────────────────────────────

async function cleanup() {
  console.log('\n[Phase 7] Cleaning up test data...');

  const collections = [
    { name: 'users', queryField: null, hasSubcollections: ['fcm_tokens'] },
    { name: 'games', queryField: 'test_marker' },
    { name: 'game_participants', queryField: 'test_marker' },
    { name: 'round_jobs', queryField: null, useGameRef: true },
    { name: 'round_records', queryField: null, useGameRef: true },
    { name: 'pair_ratings', queryField: null, useGameRef: true },
    { name: 'scheduledNotifications', queryField: 'sourceId', prefixQuery: true },
    { name: 'notificationLog', queryField: null, useRecipient: true },
  ];

  let totalDeleted = 0;

  for (const col of collections) {
    try {
      let snapshot;

      if (col.queryField === 'test_marker') {
        snapshot = await db.collection(col.name)
          .where('test_marker', '==', CONFIG.TEST_PREFIX)
          .limit(500)
          .get();
      } else if (col.prefixQuery) {
        snapshot = await db.collection(col.name)
          .where(col.queryField, '>=', CONFIG.TEST_PREFIX)
          .where(col.queryField, '<', CONFIG.TEST_PREFIX + '\uf8ff')
          .limit(500)
          .get();
      } else if (col.name === 'users') {
        // Query by document ID prefix
        snapshot = await db.collection(col.name)
          .where(admin.firestore.FieldPath.documentId(), '>=', CONFIG.TEST_PREFIX)
          .where(admin.firestore.FieldPath.documentId(), '<', CONFIG.TEST_PREFIX + '\uf8ff')
          .limit(500)
          .get();
      } else {
        // For round_jobs and round_records, we need to check game_ref
        snapshot = await db.collection(col.name).limit(500).get();
      }

      if (snapshot.empty) {
        console.log(`  ${col.name}: 0 documents to delete`);
        continue;
      }

      // Filter documents that belong to our test
      const docsToDelete = [];
      for (const doc of snapshot.docs) {
        const data = doc.data();

        if (col.useGameRef) {
          const gameRef = data.game_ref;
          if (gameRef && gameRef.id && gameRef.id.startsWith(CONFIG.TEST_PREFIX)) {
            docsToDelete.push(doc);
          }
        } else if (col.useRecipient) {
          const recipientId = data.recipientUserId;
          if (recipientId && recipientId.startsWith(CONFIG.TEST_PREFIX)) {
            docsToDelete.push(doc);
          }
        } else {
          docsToDelete.push(doc);
        }
      }

      if (docsToDelete.length === 0) {
        console.log(`  ${col.name}: 0 documents to delete`);
        continue;
      }

      // Delete in batches
      const batchSize = 400;
      for (let i = 0; i < docsToDelete.length; i += batchSize) {
        const batch = db.batch();
        const batchDocs = docsToDelete.slice(i, i + batchSize);

        for (const doc of batchDocs) {
          // Delete subcollections first if any
          if (col.hasSubcollections) {
            for (const subCol of col.hasSubcollections) {
              const subSnapshot = await doc.ref.collection(subCol).get();
              for (const subDoc of subSnapshot.docs) {
                batch.delete(subDoc.ref);
                metrics.firestoreOps.deletes++;
              }
            }
          }

          batch.delete(doc.ref);
          metrics.firestoreOps.deletes++;
        }

        await batch.commit();
        totalDeleted += batchDocs.length;
      }

      console.log(`  ${col.name}: deleted ${docsToDelete.length} documents`);

    } catch (error) {
      console.log(`  ${col.name}: error - ${error.message}`);
    }
  }

  console.log(`  ✓ Cleanup complete: ${totalDeleted} documents deleted`);
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORT GENERATION
// ─────────────────────────────────────────────────────────────────────────────

function calculatePercentiles(operations, operationType) {
  const durations = operations
    .filter(op => op.name === operationType && op.success)
    .map(op => op.duration)
    .sort((a, b) => a - b);

  if (durations.length === 0) return { P50: 0, P95: 0, P99: 0 };

  return {
    P50: durations[Math.floor(durations.length * 0.50)] || 0,
    P95: durations[Math.floor(durations.length * 0.95)] || 0,
    P99: durations[Math.floor(durations.length * 0.99)] || 0,
  };
}

function estimateFirestoreCosts() {
  const { reads, writes, deletes } = metrics.firestoreOps;
  return {
    reads,
    writes,
    deletes,
    readCost: (reads / 1000000) * CONFIG.COSTS.READ,
    writeCost: (writes / 1000000) * CONFIG.COSTS.WRITE,
    deleteCost: (deletes / 1000000) * CONFIG.COSTS.DELETE,
    totalCost: ((reads / 1000000) * CONFIG.COSTS.READ) +
               ((writes / 1000000) * CONFIG.COSTS.WRITE) +
               ((deletes / 1000000) * CONFIG.COSTS.DELETE),
  };
}

function generateReport() {
  console.log('\n' + '='.repeat(80));
  console.log('LOAD TEST REPORT — Trust System Session 13');
  console.log('='.repeat(80));

  const duration = metrics.endTime - metrics.startTime;
  const durationMinutes = (duration / 1000 / 60).toFixed(2);

  console.log(`\nTest Duration: ${durationMinutes} minutes`);
  console.log(`Total Operations: ${metrics.operations.length}`);
  console.log(`Total Errors: ${metrics.errors.length}`);

  // Latency metrics by operation type
  console.log('\n--- LATENCY METRICS ---');
  const operationTypes = ['onGameStatusToPlayed', 'submitHostCheckin', 'submitPeerRatings'];

  let allPassed = true;

  for (const opType of operationTypes) {
    const ops = metrics.operations.filter(op => op.name === opType);
    if (ops.length === 0) continue;

    const percentiles = calculatePercentiles(metrics.operations, opType);
    const successOps = ops.filter(op => op.success);
    const errorRate = ops.length > 0 ? (ops.length - successOps.length) / ops.length : 0;

    console.log(`\n${opType}:`);
    console.log(`  Count: ${ops.length} (${successOps.length} success)`);
    console.log(`  P50: ${percentiles.P50}ms`);
    console.log(`  P95: ${percentiles.P95}ms`);
    console.log(`  P99: ${percentiles.P99}ms`);
    console.log(`  Error Rate: ${(errorRate * 100).toFixed(2)}%`);

    const p99Passed = percentiles.P99 < CONFIG.P99_THRESHOLD_MS;
    const errorPassed = errorRate < CONFIG.ERROR_RATE_THRESHOLD;
    const opPassed = p99Passed && errorPassed;

    console.log(`  Status: ${opPassed ? '✓ PASS' : '✗ FAIL'}`);
    if (!opPassed) allPassed = false;
  }

  // Document counts
  console.log('\n--- DOCUMENT COUNTS ---');
  for (const [collection, count] of Object.entries(metrics.documentCounts)) {
    console.log(`  ${collection}: ${count}`);
  }

  // Firestore costs
  console.log('\n--- FIRESTORE COSTS ---');
  const costs = estimateFirestoreCosts();
  console.log(`  Reads: ${costs.reads.toLocaleString()} ($${costs.readCost.toFixed(4)})`);
  console.log(`  Writes: ${costs.writes.toLocaleString()} ($${costs.writeCost.toFixed(4)})`);
  console.log(`  Deletes: ${costs.deletes.toLocaleString()} ($${costs.deleteCost.toFixed(4)})`);
  console.log(`  Total Cost: $${costs.totalCost.toFixed(4)}`);

  // Top errors
  if (metrics.errors.length > 0) {
    console.log('\n--- TOP ERRORS ---');
    const errorCounts = {};
    for (const error of metrics.errors) {
      const key = `${error.operation}: ${error.error}`;
      errorCounts[key] = (errorCounts[key] || 0) + 1;
    }
    const sortedErrors = Object.entries(errorCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5);
    for (const [error, count] of sortedErrors) {
      console.log(`  ${count}x ${error}`);
    }
  }

  // Overall result
  console.log('\n' + '='.repeat(80));
  console.log(`OVERALL RESULT: ${allPassed ? '✓ PASS' : '✗ FAIL'}`);
  console.log('='.repeat(80));

  // Save report to file
  const reportPath = path.join(__dirname, 'load-test-report.json');
  const report = {
    timestamp: new Date().toISOString(),
    config: CONFIG,
    duration,
    durationMinutes,
    operationCounts: {
      total: metrics.operations.length,
      errors: metrics.errors.length,
    },
    latencyByOperation: {},
    documentCounts: metrics.documentCounts,
    firestoreCosts: costs,
    passed: allPassed,
  };

  for (const opType of operationTypes) {
    report.latencyByOperation[opType] = calculatePercentiles(metrics.operations, opType);
  }

  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`\nDetailed report saved to: ${reportPath}`);

  return allPassed;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

async function runLoadTest() {
  console.log('='.repeat(80));
  console.log('TRUST SYSTEM LOAD TEST — Session 13');
  console.log('Saturday Morning Peak Validation');
  console.log('='.repeat(80));

  console.log(`\nConfiguration:`);
  console.log(`  Games: ${CONFIG.TOTAL_GAMES}`);
  console.log(`  Users per Game: ~${CONFIG.USERS_PER_GAME_AVG}`);
  console.log(`  Total Users: ~${Math.ceil(CONFIG.TOTAL_GAMES * CONFIG.USERS_PER_GAME_AVG / 1.5)}`);
  console.log(`  Host Check-in Rate: ${CONFIG.HOST_CHECKIN_RATE * 100}%`);
  console.log(`  Player Present Rate: ${CONFIG.PLAYER_PRESENT_RATE * 100}%`);
  console.log(`  Rating Completion Rate: ${CONFIG.RATING_COMPLETION_RATE * 100}%`);
  console.log(`\nThresholds:`);
  console.log(`  P99 Latency: < ${CONFIG.P99_THRESHOLD_MS}ms`);
  console.log(`  Error Rate: < ${CONFIG.ERROR_RATE_THRESHOLD * 100}%`);
  console.log('\nNote: FCM sends will fail (fake tokens) — expected. Measuring pipeline throughput.\n');

  metrics.startTime = Date.now();

  try {
    // Phase 1: Create test users
    const userCount = Math.ceil(CONFIG.TOTAL_GAMES * CONFIG.USERS_PER_GAME_AVG / 1.5);
    await createTestUsers(userCount);

    // Phase 2: Create test games + participants
    const games = await createTestGames(CONFIG.TOTAL_GAMES, userCount);

    // Phase 3: Burst onGameStatusToPlayed
    await burstGameStatusToPlayed(games);

    // Brief pause to let Firestore settle
    console.log('\n  Waiting 2s for Firestore to settle...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Phase 4: Burst submitHostCheckin
    const { checkedInGames } = await burstHostCheckin(games);

    // Brief pause
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Phase 5: Burst submitPeerRatings
    await burstPeerRatings(checkedInGames);

    // Phase 6: Verify document counts
    await verifyDocumentCounts();

    metrics.endTime = Date.now();

    // Generate report
    const passed = generateReport();

    // Phase 7: Cleanup
    await cleanup();

    // Reset Cloud Tasks client to avoid hanging connections
    confirmationFlow._resetTasksClient();

    process.exit(passed ? 0 : 1);

  } catch (error) {
    console.error('\n✗ Load test failed:', error);
    metrics.endTime = Date.now();
    generateReport();

    try {
      await cleanup();
    } catch (cleanupError) {
      console.error('Cleanup failed:', cleanupError.message);
    }

    confirmationFlow._resetTasksClient();
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  runLoadTest().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = { runLoadTest, CONFIG, metrics };
