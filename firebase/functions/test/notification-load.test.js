/**
 * Notification System Load Test — Session 13
 *
 * Tests the Trust System notification infrastructure under peak Saturday load:
 *   - 500 games in a 2-hour window
 *   - ~1,500 users with 1-2 devices each
 *   - Burst onGameConfirmed() → host check-in (80%) → rating notifications
 *
 * Measures:
 *   - P50/P95/P99 latency for each hook
 *   - Error rate
 *   - Firestore read/write costs
 *   - Cloud Tasks creation throughput
 *
 * Success Criteria:
 *   - P99 latency < 5 seconds
 *   - Error rate < 1%
 *
 * Cloud Functions 2nd Gen Configuration (for production):
 *   maxInstances: 100
 *   concurrency: 10
 *   timeoutSeconds: 60
 *   memory: '512MiB'
 *
 * Usage:
 *   # Small run (validation)
 *   node test/notification-load-test.js --small
 *
 *   # Full load test (500 games)
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json node test/notification-load-test.js
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────

const isSmallRun = process.env.NOTIF_LOAD_TEST_SMALL === 'true' || process.argv.includes('--small');

const CONFIG = {
  // Scale: SMALL=50 games, LARGE=500 games
  TOTAL_GAMES: isSmallRun ? 50 : 500,
  USERS_PER_GAME_AVG: 3.5,  // Average 3-4 players per game
  DEVICES_PER_USER: { MIN: 1, MAX: 2 },

  // 2-hour window for tee times
  TEE_TIME_WINDOW_MS: 2 * 60 * 60 * 1000,

  // Simulation rates
  HOST_CHECKIN_RATE: 0.80,       // 80% of hosts check in
  PLAYER_PRESENT_RATE: 0.90,     // 90% of players marked present

  // Performance thresholds
  P99_THRESHOLD_MS: 5000,        // < 5 seconds
  ERROR_RATE_THRESHOLD: 0.01,    // < 1%

  // Test marker for cleanup
  TEST_PREFIX: 'NOTIF_LOADTEST_',

  // Firestore operation costs (USD per million)
  COSTS: {
    READ: 0.06,
    WRITE: 0.18,
    DELETE: 0.02,
  },

  // Concurrency control
  BATCH_SIZE: 10,                // Parallel operations per batch
  SETTLE_DELAY_MS: 500,          // Pause between phases

  // Cloud Functions 2nd Gen config (informational — applied at deploy time)
  CF_GEN2: {
    maxInstances: 100,
    concurrency: 10,
    timeoutSeconds: 60,
    memory: '512MiB',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// MODULE-LEVEL MOCK STATE
// ─────────────────────────────────────────────────────────────────────────────

let mockDb;
let mockCreateTask;
let mockDeleteTask;
let mockFcmSend;
let mockIdCounter = 0;

// ─────────────────────────────────────────────────────────────────────────────
// MOCKS (before any require)
// ─────────────────────────────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  function serverTimestamp() {
    return Object.assign(new Date(), { toMillis() { return this.getTime(); } });
  }
  function fromDate(d) {
    return { _ts: d, toMillis: () => d.getTime() };
  }

  function mockFirestoreFn() { return mockDb; }
  mockFirestoreFn.FieldValue = { serverTimestamp };
  mockFirestoreFn.Timestamp = { fromDate };

  return {
    firestore: mockFirestoreFn,
    messaging: () => ({ send: (...args) => mockFcmSend(...args) }),
  };
});

jest.mock('@google-cloud/tasks', () => {
  function MockCloudTasksClient() {}
  MockCloudTasksClient.prototype.createTask = (...args) => mockCreateTask(...args);
  MockCloudTasksClient.prototype.deleteTask = (...args) => mockDeleteTask(...args);
  MockCloudTasksClient.prototype.queuePath = (p, l, q) =>
    `projects/${p}/locations/${l}/queues/${q}`;
  return { CloudTasksClient: MockCloudTasksClient };
});

jest.mock('firebase-functions', () => ({
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTS (after mocks)
// ─────────────────────────────────────────────────────────────────────────────

const {
  onGameConfirmed,
  onHostCheckinCompleted,
} = require('../notifications/trust/hooks');
const { _resetTasksClient } = require('../notifications/trust/scheduler');

// ─────────────────────────────────────────────────────────────────────────────
// IN-MEMORY FIRESTORE MOCK WITH COST TRACKING
// ─────────────────────────────────────────────────────────────────────────────

function toMs(v) {
  if (v instanceof Date) return v.getTime();
  if (v && typeof v.toMillis === 'function') return v.toMillis();
  return Number(v);
}

function createInMemoryDb(costTracker) {
  const store = new Map();

  function getOrCreateCol(colPath) {
    if (!store.has(colPath)) store.set(colPath, new Map());
    return store.get(colPath);
  }

  function makeDocRef(colPath, docId) {
    return {
      id: docId,
      path: `${colPath}/${docId}`,

      async set(data) {
        getOrCreateCol(colPath).set(docId, { ...data });
        costTracker.writes++;
      },

      async get() {
        const col = store.get(colPath);
        const data = col && col.get(docId);
        costTracker.reads++;
        return {
          exists: data !== undefined,
          id: docId,
          data: () => (data ? { ...data } : {}),
          ref: makeDocRef(colPath, docId),
        };
      },

      async update(updates) {
        const col = getOrCreateCol(colPath);
        const existing = col.get(docId) || {};
        col.set(docId, { ...existing, ...updates });
        costTracker.writes++;
      },

      async delete() {
        const col = store.get(colPath);
        if (col) col.delete(docId);
        costTracker.deletes++;
      },

      collection(subColName) {
        return makeCollectionRef(`${colPath}/${docId}/${subColName}`);
      },
    };
  }

  function makeCollectionRef(colPath, filters = []) {
    return {
      doc(id) {
        const docId = id !== undefined ? id : `auto_${++mockIdCounter}`;
        return makeDocRef(colPath, docId);
      },

      async add(data) {
        const docId = `auto_${++mockIdCounter}`;
        const docRef = makeDocRef(colPath, docId);
        await docRef.set(data);
        return docRef;
      },

      where(field, op, value) {
        return makeCollectionRef(colPath, [...filters, { field, op, value }]);
      },

      orderBy() { return this; },

      async get() {
        const col = store.get(colPath) || new Map();
        let entries = [...col.entries()];
        costTracker.reads += entries.length || 1;

        for (const { field, op, value } of filters) {
          entries = entries.filter(([, data]) => {
            const fieldVal = data[field];
            if (op === '==') return fieldVal === value;
            if (op === '<') return toMs(fieldVal) < toMs(value);
            if (op === '>') return toMs(fieldVal) > toMs(value);
            return true;
          });
        }

        const docs = entries.map(([docId, data]) => ({
          id: docId,
          exists: true,
          data: () => ({ ...data }),
          ref: makeDocRef(colPath, docId),
        }));

        return { docs, empty: docs.length === 0, size: docs.length };
      },
    };
  }

  return {
    collection(colName) {
      return makeCollectionRef(colName);
    },
    collectionGroup() {
      return {
        where() { return this; },
        async get() {
          costTracker.reads++;
          return { docs: [] };
        },
      };
    },
    // Expose store for verification
    _store: store,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// METRICS COLLECTION
// ─────────────────────────────────────────────────────────────────────────────

const metrics = {
  operations: [],
  errors: [],
  firestoreOps: { reads: 0, writes: 0, deletes: 0 },
  cloudTasksCreated: 0,
  cloudTasksCancelled: 0,
  fcmCalls: 0,
  startTime: null,
  endTime: null,
};

function trackOperation(name, startTime, success = true, error = null) {
  const duration = Date.now() - startTime;
  metrics.operations.push({
    name,
    duration,
    success,
    timestamp: Date.now(),
    error: error ? error.message : null,
  });
  if (!success && error) {
    metrics.errors.push({ operation: name, error: error.message, timestamp: Date.now() });
  }
  return { duration, success };
}

function calculatePercentiles(operationType) {
  const durations = metrics.operations
    .filter(op => op.name === operationType && op.success)
    .map(op => op.duration)
    .sort((a, b) => a - b);

  if (durations.length === 0) return { P50: 0, P95: 0, P99: 0, avg: 0, count: 0 };

  return {
    P50: durations[Math.floor(durations.length * 0.50)] || 0,
    P95: durations[Math.floor(durations.length * 0.95)] || 0,
    P99: durations[Math.floor(durations.length * 0.99)] || 0,
    avg: Math.round(durations.reduce((a, b) => a + b, 0) / durations.length),
    count: durations.length,
  };
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

function generateFcmToken(userId, deviceIndex) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const random = Array.from({ length: 100 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `${CONFIG.TEST_PREFIX}${random}:${userId}:${deviceIndex}`;
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 1: SEED USERS WITH DEVICES
// ─────────────────────────────────────────────────────────────────────────────

async function seedUsers(db, count) {
  console.log(`\n[Phase 1] Seeding ${count} users with 1-2 devices each...`);
  const startTime = Date.now();

  for (let i = 0; i < count; i++) {
    const userId = generateUserId(i);

    // User document with notification preferences
    await db.collection('users').doc(userId).set({
      display_name: `Load Test User ${i}`,
      notification_prefs: {
        push_enabled: true,
        trust_categories: { post_round: true, trust_alerts: true, badges: true },
        quiet_hours: { enabled: false },
      },
      test_marker: CONFIG.TEST_PREFIX,
    });

    // 1-2 devices per user
    const numDevices = CONFIG.DEVICES_PER_USER.MIN +
      Math.floor(Math.random() * (CONFIG.DEVICES_PER_USER.MAX - CONFIG.DEVICES_PER_USER.MIN + 1));

    for (let d = 0; d < numDevices; d++) {
      await db.collection('users').doc(userId)
        .collection('devices').doc(`device_${d}`)
        .set({
          fcmToken: generateFcmToken(userId, d),
          platform: d === 0 ? 'ios' : 'android',
          lastSeenAt: new Date(),
        });
    }

    if ((i + 1) % 100 === 0 || i === count - 1) {
      console.log(`  Seeded ${i + 1}/${count} users`);
    }
  }

  const { duration } = trackOperation('seedUsers', startTime);
  console.log(`  ✓ Seeded ${count} users in ${duration}ms`);
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 2: SEED GAMES WITH PARTICIPANTS
// ─────────────────────────────────────────────────────────────────────────────

async function seedGames(db, gameCount, userCount) {
  console.log(`\n[Phase 2] Seeding ${gameCount} games with participants...`);
  const startTime = Date.now();

  const baseTeeTime = new Date(Date.now() - 5 * 60 * 60 * 1000); // 5h ago for T+5h trigger
  const games = [];

  for (let g = 0; g < gameCount; g++) {
    const gameId = generateGameId(g);

    // 3-4 players per game
    const numPlayers = 3 + Math.floor(Math.random() * 2);
    const playerIndices = new Set();
    while (playerIndices.size < numPlayers) {
      playerIndices.add(Math.floor(Math.random() * userCount));
    }
    const playerUserIds = [...playerIndices].map(i => generateUserId(i));
    const hostUserId = playerUserIds[0];

    // Spread tee times across 2-hour window
    const teeTimeOffset = (g / gameCount) * CONFIG.TEE_TIME_WINDOW_MS;
    const teeTime = new Date(baseTeeTime.getTime() + teeTimeOffset);
    const gameDate = teeTime.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    // Game document
    await db.collection('games').doc(gameId).set({
      hostCheckedIn: false,
      course_play: `Load Test Course ${g % 10}`,
      date: teeTime,
      test_marker: CONFIG.TEST_PREFIX,
    });

    games.push({
      gameId,
      hostUserId,
      playerUserIds,
      teeTime: teeTime.toISOString(),
      courseName: `Load Test Course ${g % 10}`,
      gameDate,
    });

    if ((g + 1) % 50 === 0 || g === gameCount - 1) {
      console.log(`  Seeded ${g + 1}/${gameCount} games`);
    }
  }

  const { duration } = trackOperation('seedGames', startTime);
  console.log(`  ✓ Seeded ${gameCount} games in ${duration}ms`);

  return games;
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 3: BURST onGameConfirmed()
// ─────────────────────────────────────────────────────────────────────────────

async function burstGameConfirmed(games, db) {
  console.log(`\n[Phase 3] Calling onGameConfirmed() for ${games.length} games...`);
  const phaseStart = Date.now();

  let successCount = 0;
  let errorCount = 0;

  // Process in parallel batches
  for (let i = 0; i < games.length; i += CONFIG.BATCH_SIZE) {
    const batch = games.slice(i, i + CONFIG.BATCH_SIZE);

    await Promise.all(batch.map(async (game) => {
      const opStart = Date.now();
      try {
        await onGameConfirmed(
          game.gameId,
          game.teeTime,
          game.hostUserId,
          game.playerUserIds,
          game.courseName,
          game.gameDate,
          db,
        );
        trackOperation('onGameConfirmed', opStart, true);
        successCount++;
      } catch (error) {
        trackOperation('onGameConfirmed', opStart, false, error);
        errorCount++;
      }
    }));

    if ((i + CONFIG.BATCH_SIZE) % 50 === 0 || i + CONFIG.BATCH_SIZE >= games.length) {
      console.log(`  Processed ${Math.min(i + CONFIG.BATCH_SIZE, games.length)}/${games.length} games`);
    }
  }

  const phaseDuration = Date.now() - phaseStart;
  console.log(`  ✓ onGameConfirmed: ${successCount} success, ${errorCount} errors in ${phaseDuration}ms`);
  console.log(`    Cloud Tasks created: ${metrics.cloudTasksCreated}`);

  return { successCount, errorCount };
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 4: BURST onHostCheckinCompleted() (80% of games)
// ─────────────────────────────────────────────────────────────────────────────

async function burstHostCheckin(games, db) {
  const checkinGames = games.filter(() => Math.random() < CONFIG.HOST_CHECKIN_RATE);
  console.log(`\n[Phase 4] Calling onHostCheckinCompleted() for ${checkinGames.length} games (${Math.round(CONFIG.HOST_CHECKIN_RATE * 100)}%)...`);
  const phaseStart = Date.now();

  let successCount = 0;
  let errorCount = 0;
  const checkedInGames = [];

  for (let i = 0; i < checkinGames.length; i += CONFIG.BATCH_SIZE) {
    const batch = checkinGames.slice(i, i + CONFIG.BATCH_SIZE);

    await Promise.all(batch.map(async (game) => {
      const opStart = Date.now();
      try {
        // Filter to present players (90%)
        const presentPlayers = game.playerUserIds.filter(() => Math.random() < CONFIG.PLAYER_PRESENT_RATE);

        await onHostCheckinCompleted(
          game.gameId,
          game.hostUserId,
          presentPlayers,
          game.courseName,
          db,
        );

        trackOperation('onHostCheckinCompleted', opStart, true);
        successCount++;
        checkedInGames.push({ ...game, presentPlayers });
      } catch (error) {
        trackOperation('onHostCheckinCompleted', opStart, false, error);
        errorCount++;
      }
    }));

    if ((i + CONFIG.BATCH_SIZE) % 50 === 0 || i + CONFIG.BATCH_SIZE >= checkinGames.length) {
      console.log(`  Processed ${Math.min(i + CONFIG.BATCH_SIZE, checkinGames.length)}/${checkinGames.length} check-ins`);
    }
  }

  const phaseDuration = Date.now() - phaseStart;
  console.log(`  ✓ onHostCheckinCompleted: ${successCount} success, ${errorCount} errors in ${phaseDuration}ms`);
  console.log(`    Jobs cancelled: ${metrics.cloudTasksCancelled}`);
  console.log(`    Rating jobs scheduled: ${metrics.cloudTasksCreated - (games.length * 4 + games.reduce((acc, g) => acc + g.playerUserIds.length - 1, 0))}`);

  return { successCount, errorCount, checkedInGames };
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE 5: VERIFY DOCUMENT COUNTS
// ─────────────────────────────────────────────────────────────────────────────

async function verifyDocuments(db) {
  console.log('\n[Phase 5] Verifying Firestore document counts...');

  const collections = ['users', 'games', 'scheduledNotifications', 'notificationLog'];
  const counts = {};

  for (const colName of collections) {
    const snap = await db.collection(colName).get();
    counts[colName] = snap.size;
    console.log(`  ${colName}: ${snap.size} documents`);
  }

  return counts;
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORT GENERATION
// ─────────────────────────────────────────────────────────────────────────────

function generateReport() {
  console.log('\n' + '='.repeat(80));
  console.log('NOTIFICATION SYSTEM LOAD TEST REPORT');
  console.log('='.repeat(80));

  const totalDuration = metrics.endTime - metrics.startTime;
  const durationSec = (totalDuration / 1000).toFixed(2);

  console.log(`\nTest Duration: ${durationSec}s`);
  console.log(`Total Operations: ${metrics.operations.length}`);
  console.log(`Total Errors: ${metrics.errors.length}`);

  // Latency metrics
  console.log('\n--- LATENCY METRICS ---');
  const operationTypes = ['onGameConfirmed', 'onHostCheckinCompleted'];
  let allPassed = true;

  for (const opType of operationTypes) {
    const stats = calculatePercentiles(opType);
    if (stats.count === 0) continue;

    const ops = metrics.operations.filter(op => op.name === opType);
    const errorRate = ops.length > 0 ? ops.filter(op => !op.success).length / ops.length : 0;

    console.log(`\n${opType}:`);
    console.log(`  Count:      ${stats.count}`);
    console.log(`  Average:    ${stats.avg}ms`);
    console.log(`  P50:        ${stats.P50}ms`);
    console.log(`  P95:        ${stats.P95}ms`);
    console.log(`  P99:        ${stats.P99}ms`);
    console.log(`  Error Rate: ${(errorRate * 100).toFixed(2)}%`);

    const p99Passed = stats.P99 < CONFIG.P99_THRESHOLD_MS;
    const errorPassed = errorRate < CONFIG.ERROR_RATE_THRESHOLD;
    const opPassed = p99Passed && errorPassed;

    console.log(`  P99 < ${CONFIG.P99_THRESHOLD_MS}ms: ${p99Passed ? '✓ PASS' : '✗ FAIL'}`);
    console.log(`  Errors < ${CONFIG.ERROR_RATE_THRESHOLD * 100}%: ${errorPassed ? '✓ PASS' : '✗ FAIL'}`);

    if (!opPassed) allPassed = false;
  }

  // Cloud Tasks & FCM
  console.log('\n--- EXTERNAL SERVICE CALLS ---');
  console.log(`  Cloud Tasks Created:   ${metrics.cloudTasksCreated}`);
  console.log(`  Cloud Tasks Cancelled: ${metrics.cloudTasksCancelled}`);
  console.log(`  FCM Calls:             ${metrics.fcmCalls}`);

  // Firestore costs
  console.log('\n--- FIRESTORE COSTS ---');
  const { reads, writes, deletes } = metrics.firestoreOps;
  const readCost = (reads / 1_000_000) * CONFIG.COSTS.READ;
  const writeCost = (writes / 1_000_000) * CONFIG.COSTS.WRITE;
  const deleteCost = (deletes / 1_000_000) * CONFIG.COSTS.DELETE;
  const totalCost = readCost + writeCost + deleteCost;

  console.log(`  Reads:   ${reads.toLocaleString()} ($${readCost.toFixed(4)})`);
  console.log(`  Writes:  ${writes.toLocaleString()} ($${writeCost.toFixed(4)})`);
  console.log(`  Deletes: ${deletes.toLocaleString()} ($${deleteCost.toFixed(4)})`);
  console.log(`  Total:   $${totalCost.toFixed(4)}`);

  // Throughput
  console.log('\n--- THROUGHPUT ---');
  const gamesPerSecond = CONFIG.TOTAL_GAMES / (totalDuration / 1000);
  console.log(`  Games/second: ${gamesPerSecond.toFixed(2)}`);
  console.log(`  Notifications/second: ${(metrics.cloudTasksCreated / (totalDuration / 1000)).toFixed(2)}`);

  // Cloud Functions 2nd Gen Config
  console.log('\n--- CLOUD FUNCTIONS 2ND GEN CONFIG ---');
  console.log(`  maxInstances: ${CONFIG.CF_GEN2.maxInstances}`);
  console.log(`  concurrency:  ${CONFIG.CF_GEN2.concurrency}`);
  console.log(`  timeout:      ${CONFIG.CF_GEN2.timeoutSeconds}s`);
  console.log(`  memory:       ${CONFIG.CF_GEN2.memory}`);

  // Top errors
  if (metrics.errors.length > 0) {
    console.log('\n--- TOP ERRORS ---');
    const errorCounts = {};
    for (const err of metrics.errors) {
      const key = `${err.operation}: ${err.error}`;
      errorCounts[key] = (errorCounts[key] || 0) + 1;
    }
    const sorted = Object.entries(errorCounts).sort((a, b) => b[1] - a[1]).slice(0, 5);
    for (const [error, count] of sorted) {
      console.log(`  ${count}x ${error}`);
    }
  }

  // Overall result
  console.log('\n' + '='.repeat(80));
  console.log(`OVERALL RESULT: ${allPassed ? '✓ PASS' : '✗ FAIL'}`);
  console.log('='.repeat(80));

  // Save JSON report
  const report = {
    timestamp: new Date().toISOString(),
    config: {
      totalGames: CONFIG.TOTAL_GAMES,
      hostCheckinRate: CONFIG.HOST_CHECKIN_RATE,
      p99Threshold: CONFIG.P99_THRESHOLD_MS,
      errorRateThreshold: CONFIG.ERROR_RATE_THRESHOLD,
      cfGen2: CONFIG.CF_GEN2,
    },
    duration: {
      totalMs: totalDuration,
      totalSec: parseFloat(durationSec),
    },
    operations: {
      total: metrics.operations.length,
      errors: metrics.errors.length,
    },
    latency: {},
    externalCalls: {
      cloudTasksCreated: metrics.cloudTasksCreated,
      cloudTasksCancelled: metrics.cloudTasksCancelled,
      fcmCalls: metrics.fcmCalls,
    },
    firestoreCosts: {
      reads,
      writes,
      deletes,
      readCostUsd: readCost,
      writeCostUsd: writeCost,
      deleteCostUsd: deleteCost,
      totalCostUsd: totalCost,
    },
    throughput: {
      gamesPerSecond: gamesPerSecond,
      notificationsPerSecond: metrics.cloudTasksCreated / (totalDuration / 1000),
    },
    passed: allPassed,
  };

  for (const opType of operationTypes) {
    report.latency[opType] = calculatePercentiles(opType);
  }

  const reportPath = path.join(__dirname, 'notification-load.report.json');
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`\nDetailed report: ${reportPath}`);

  return allPassed;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN TEST
// ─────────────────────────────────────────────────────────────────────────────

describe('Notification System Load Test', () => {
  let taskIdCounter = 0;

  beforeAll(() => {
    console.log('='.repeat(80));
    console.log('NOTIFICATION SYSTEM LOAD TEST — Session 13');
    console.log(isSmallRun ? 'Mode: SMALL (validation run)' : 'Mode: FULL (500 games)');
    console.log('='.repeat(80));

    console.log('\nConfiguration:');
    console.log(`  Games:            ${CONFIG.TOTAL_GAMES}`);
    console.log(`  Users (approx):   ~${Math.ceil(CONFIG.TOTAL_GAMES * CONFIG.USERS_PER_GAME_AVG / 1.5)}`);
    console.log(`  Devices per user: ${CONFIG.DEVICES_PER_USER.MIN}-${CONFIG.DEVICES_PER_USER.MAX}`);
    console.log(`  Host check-in:    ${CONFIG.HOST_CHECKIN_RATE * 100}%`);
    console.log(`\nThresholds:`);
    console.log(`  P99 latency:      < ${CONFIG.P99_THRESHOLD_MS}ms`);
    console.log(`  Error rate:       < ${CONFIG.ERROR_RATE_THRESHOLD * 100}%`);
  });

  beforeEach(() => {
    jest.clearAllMocks();
    _resetTasksClient();

    mockIdCounter = 0;
    taskIdCounter = 0;

    // Reset metrics
    metrics.operations = [];
    metrics.errors = [];
    metrics.firestoreOps = { reads: 0, writes: 0, deletes: 0 };
    metrics.cloudTasksCreated = 0;
    metrics.cloudTasksCancelled = 0;
    metrics.fcmCalls = 0;
    metrics.startTime = null;
    metrics.endTime = null;

    // Create fresh in-memory db with cost tracking
    mockDb = createInMemoryDb(metrics.firestoreOps);

    // Mock Cloud Tasks
    mockCreateTask = jest.fn().mockImplementation(async () => {
      metrics.cloudTasksCreated++;
      return [{ name: `projects/test/tasks/task_${++taskIdCounter}` }];
    });

    mockDeleteTask = jest.fn().mockImplementation(async () => {
      metrics.cloudTasksCancelled++;
      return [{}];
    });

    // Mock FCM (will be called during immediate notifications)
    mockFcmSend = jest.fn().mockImplementation(async () => {
      metrics.fcmCalls++;
      return 'mock_message_id';
    });

    // Re-wire Cloud Tasks prototype
    const { CloudTasksClient } = require('@google-cloud/tasks');
    CloudTasksClient.prototype.createTask = (...args) => mockCreateTask(...args);
    CloudTasksClient.prototype.deleteTask = (...args) => mockDeleteTask(...args);
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  test('Full load test: 500 games, 80% check-in, P99 < 5s, errors < 1%', async () => {
    metrics.startTime = Date.now();

    // Phase 1: Seed users
    const userCount = Math.ceil(CONFIG.TOTAL_GAMES * CONFIG.USERS_PER_GAME_AVG / 1.5);
    await seedUsers(mockDb, userCount);

    // Phase 2: Seed games
    const games = await seedGames(mockDb, CONFIG.TOTAL_GAMES, userCount);

    // Brief settle
    await new Promise(r => setTimeout(r, CONFIG.SETTLE_DELAY_MS));

    // Phase 3: Burst onGameConfirmed
    const confirmedResult = await burstGameConfirmed(games, mockDb);
    expect(confirmedResult.errorCount).toBeLessThan(games.length * CONFIG.ERROR_RATE_THRESHOLD);

    // Brief settle
    await new Promise(r => setTimeout(r, CONFIG.SETTLE_DELAY_MS));

    // Phase 4: Burst onHostCheckinCompleted
    const checkinResult = await burstHostCheckin(games, mockDb);
    expect(checkinResult.errorCount).toBeLessThan(checkinResult.successCount * CONFIG.ERROR_RATE_THRESHOLD);

    // Phase 5: Verify documents
    await verifyDocuments(mockDb);

    metrics.endTime = Date.now();

    // Generate report
    const passed = generateReport();

    // Assertions
    const confirmStats = calculatePercentiles('onGameConfirmed');
    const checkinStats = calculatePercentiles('onHostCheckinCompleted');

    expect(confirmStats.P99).toBeLessThan(CONFIG.P99_THRESHOLD_MS);
    expect(checkinStats.P99).toBeLessThan(CONFIG.P99_THRESHOLD_MS);

    const totalOps = metrics.operations.length;
    const totalErrors = metrics.errors.length;
    const errorRate = totalOps > 0 ? totalErrors / totalOps : 0;
    expect(errorRate).toBeLessThan(CONFIG.ERROR_RATE_THRESHOLD);

    // Expected Cloud Tasks: 4 per game (confirm) + rating jobs (after checkin)
    // Each confirm: 3 host jobs + (players-1) fallback jobs
    const expectedConfirmTasks = games.reduce((acc, g) => acc + 3 + (g.playerUserIds.length - 1), 0);
    expect(metrics.cloudTasksCreated).toBeGreaterThanOrEqual(expectedConfirmTasks);

    expect(passed).toBe(true);
  }, 300000); // 5 minute timeout for large test
});
