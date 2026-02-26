'use strict';

/**
 * Session 12 — Trust System Integration Tests
 *
 * Tests multiple real modules working together end-to-end:
 *   hooks → scheduler → router → fcm-sender → template-engine → event-registry
 *
 * Only the two true external boundaries are mocked:
 *   - admin.messaging().send()        (FCM endpoint)
 *   - CloudTasksClient                (Cloud Tasks endpoint)
 *
 * admin.firestore() returns a shared stateful in-memory mock db so all modules
 * (including preferences-service which calls admin.firestore() with no db arg)
 * read from and write to the same in-memory store.
 */

// ── Module-level mock state (must be declared before jest.mock() calls) ───────
//
// Variables accessed inside jest.mock() factory functions must be prefixed with
// "mock" (case-insensitive) — Jest's module factory scope restriction.

let mockSharedDb;   // reassigned in beforeEach; closed over by admin mock
let mockFcmSend;    // reassigned in beforeEach
let mockCreateTask; // reassigned in beforeEach
let mockDeleteTask; // reassigned in beforeEach
let mockIdCounter = 0; // auto-ID counter; reset in beforeEach

// ── Mocks ─────────────────────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  // serverTimestamp returns a real Date with .toMillis() so the workers cleanup
  // query where('releaseAt', '<', staleTs) works with real Date comparison.
  function serverTimestamp() {
    return Object.assign(new Date(), { toMillis() { return this.getTime(); } });
  }
  function fromDate(d) { return { _ts: d, toMillis: () => d.getTime() }; }

  // Closes over mockSharedDb — reassigned in beforeEach, so every call gets the
  // current test's in-memory db (including preferences-service which has no db injection).
  // "mock"-prefixed variables are allowed inside jest.mock() factory scope.
  function mockFirestoreFn() { return mockSharedDb; }
  mockFirestoreFn.FieldValue = { serverTimestamp };
  mockFirestoreFn.Timestamp  = { fromDate };

  return {
    firestore: mockFirestoreFn,
    messaging: () => ({ send: (...args) => mockFcmSend(...args) }),
  };
});

jest.mock('@google-cloud/tasks', () => {
  function MockCloudTasksClient() {}
  MockCloudTasksClient.prototype.createTask = (...args) => mockCreateTask(...args);
  MockCloudTasksClient.prototype.deleteTask = (...args) => mockDeleteTask(...args);
  MockCloudTasksClient.prototype.queuePath  = (p, l, q) =>
    `projects/${p}/locations/${l}/queues/${q}`;
  return { CloudTasksClient: MockCloudTasksClient };
});

jest.mock('firebase-functions', () => ({
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// ── Imports (after all jest.mock() calls) ─────────────────────────────────────

const { onGameConfirmed, onGameCancelled } = require('../notifications/trust/hooks');
const {
  processScheduledTrustNotificationHandler,
  _resetTasksClient,
} = require('../notifications/trust/scheduler');
const { routeNotification } = require('../notifications/trust/router');
const { trustQuietHoursCleanupHandler } = require('../notifications/trust/workers');

// ── In-memory Firestore mock ──────────────────────────────────────────────────

/**
 * Normalises a field value to milliseconds for < / > comparisons.
 * Handles: real Date, Timestamp-like { toMillis() }, or plain number.
 */
function toMs(v) {
  if (v instanceof Date)                         return v.getTime();
  if (v && typeof v.toMillis === 'function')     return v.toMillis();
  return Number(v);
}

/**
 * Creates a fresh stateful in-memory Firestore mock.
 *
 * Store layout:
 *   Map< collectionPath: string, Map< docId: string, data: object > >
 *
 * Collection paths are flat strings, e.g.:
 *   'notificationLog'
 *   'users'
 *   'users/u1/notifications'
 *   'users/u1/devices'
 *   'scheduledNotifications'
 *   'games'
 */
function createInMemoryDb() {
  const store = new Map(); // colPath → Map<docId, data>

  function getOrCreateCol(colPath) {
    if (!store.has(colPath)) store.set(colPath, new Map());
    return store.get(colPath);
  }

  function makeDocRef(colPath, docId) {
    return {
      id: docId,

      async set(data) {
        getOrCreateCol(colPath).set(docId, Object.assign({}, data));
      },

      async get() {
        const col  = store.get(colPath);
        const data = col && col.get(docId);
        return {
          exists: data !== undefined,
          id:     docId,
          data:   () => (data ? Object.assign({}, data) : {}),
          ref:    makeDocRef(colPath, docId),
        };
      },

      async update(updates) {
        const col      = getOrCreateCol(colPath);
        const existing = col.get(docId) || {};
        col.set(docId, Object.assign({}, existing, updates));
      },

      async delete() {
        const col = store.get(colPath);
        if (col) col.delete(docId);
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
        const docId  = `auto_${++mockIdCounter}`;
        const docRef = makeDocRef(colPath, docId);
        await docRef.set(data);
        return docRef;
      },

      // Returns a NEW CollectionRef with the additional filter appended.
      // This prevents cross-chain filter contamination.
      where(field, op, value) {
        return makeCollectionRef(colPath, [...filters, { field, op, value }]);
      },

      // No-op for in-memory — Map preserves insertion order.
      orderBy() { return this; },

      async get() {
        const col     = store.get(colPath) || new Map();
        let entries   = [...col.entries()]; // [[docId, data], ...]

        for (const { field, op, value } of filters) {
          entries = entries.filter(([, data]) => {
            const fieldVal = data[field];
            if (op === '==') return fieldVal === value;
            if (op === '<')  return toMs(fieldVal) < toMs(value);
            if (op === '>')  return toMs(fieldVal) > toMs(value);
            return true;
          });
        }

        const docs = entries.map(([docId, data]) => ({
          id:     docId,
          exists: true,
          data:   () => Object.assign({}, data),
          ref:    makeDocRef(colPath, docId),
        }));

        return { docs, empty: docs.length === 0 };
      },
    };
  }

  return {
    collection(colName) {
      return makeCollectionRef(colName);
    },
    // Stub — trustTokenHygieneHandler uses collectionGroup('devices').
    // Not exercised in these 12 scenarios.
    collectionGroup() {
      return {
        where() { return this; },
        async get() { return { docs: [] }; },
      };
    },
  };
}

// ── Fixture helpers ───────────────────────────────────────────────────────────

/**
 * Seeds users/{userId} with a notification_prefs map.
 * Field names are snake_case matching what Firestore stores (preferences-service.js).
 */
async function makeUserWithPrefs(db, userId, prefsOverrides = {}) {
  const notification_prefs = Object.assign(
    {
      push_enabled:     true,
      trust_categories: { post_round: true, trust_alerts: true, badges: true },
      quiet_hours:      { enabled: false, start: '22:00', end: '07:00' },
    },
    prefsOverrides,
  );
  await db.collection('users').doc(userId).set({ notification_prefs });
}

/** Seeds users/{userId}/devices/{deviceId}. */
async function makeDevice(db, userId, deviceId, token, platform = 'ios') {
  await db
    .collection('users').doc(userId)
    .collection('devices').doc(deviceId)
    .set({ fcmToken: token, platform, lastSeenAt: new Date() });
}

/** Seeds games/{gameId}. */
async function makeGame(db, gameId, data = {}) {
  await db.collection('games').doc(gameId).set({ hostCheckedIn: false, ...data });
}

/** Fake Express res for HTTP handler tests. */
function makeFakeRes() {
  const res = { _status: null, _body: null };
  res.status = function (s) { this._status = s; return this; };
  res.send   = function (b) { this._body   = b; return this; };
  return res;
}

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  _resetTasksClient(); // reset singleton in scheduler.js

  mockIdCounter = 0;
  mockSharedDb  = createInMemoryDb();

  mockFcmSend    = jest.fn().mockResolvedValue('fcm_msg_id_001');
  mockCreateTask = jest.fn().mockResolvedValue([{ name: 'projects/x/tasks/t_001' }]);
  mockDeleteTask = jest.fn().mockResolvedValue([{}]);

  // Re-wire prototype methods — clearAllMocks() does not restore these.
  const { CloudTasksClient } = require('@google-cloud/tasks');
  CloudTasksClient.prototype.createTask = (...args) => mockCreateTask(...args);
  CloudTasksClient.prototype.deleteTask = (...args) => mockDeleteTask(...args);
  CloudTasksClient.prototype.queuePath  = (p, l, q) =>
    `projects/${p}/locations/${l}/queues/${q}`;
});

afterEach(() => {
  jest.useRealTimers();
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 1 — Happy path game flow
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 1 — Happy path: onGameConfirmed + scheduled host_checkin_due delivery', () => {
  const GAME_ID   = 'game_sc1';
  const HOST_ID   = 'user_host_sc1';
  const PLAYER_1  = 'user_p1_sc1';
  const TEE_TIME  = '2026-04-01T14:00:00.000Z';
  const COURSE    = 'Pebble Beach';
  const GAME_DATE = 'Apr 1';

  test('onGameConfirmed writes 4 PENDING tracking docs and calls Cloud Tasks 4x', async () => {
    await makeUserWithPrefs(mockSharedDb, HOST_ID);
    await makeDevice(mockSharedDb, HOST_ID, 'dev_host_sc1', 'tok_host_sc1', 'ios');
    await makeGame(mockSharedDb, GAME_ID);

    const result = await onGameConfirmed(
      GAME_ID, TEE_TIME, HOST_ID, [HOST_ID, PLAYER_1], COURSE, GAME_DATE, mockSharedDb,
    );

    expect(mockCreateTask).toHaveBeenCalledTimes(4);

    const snap = await mockSharedDb.collection('scheduledNotifications').get();
    expect(snap.docs).toHaveLength(4);
    expect(snap.docs.every((d) => d.data().status === 'PENDING')).toBe(true);

    expect(result).toHaveProperty('hostCheckinJobId');
    expect(result).toHaveProperty('hostCheckinReminderJobId');
    expect(result).toHaveProperty('hostFallbackJobId');
    expect(result.playerFallbackJobIds).toHaveProperty(PLAYER_1);
  });

  test('processScheduledTrustNotificationHandler delivers host_checkin_due (conditionCheck=always)', async () => {
    await makeUserWithPrefs(mockSharedDb, HOST_ID);
    await makeDevice(mockSharedDb, HOST_ID, 'dev_host_sc1', 'tok_host_sc1', 'ios');
    await makeGame(mockSharedDb, GAME_ID);

    const jobResult = await onGameConfirmed(
      GAME_ID, TEE_TIME, HOST_ID, [HOST_ID, PLAYER_1], COURSE, GAME_DATE, mockSharedDb,
    );
    const jobId = jobResult.hostCheckinJobId;

    // Read the stored event from the tracking doc
    const trackingSnap = await mockSharedDb.collection('scheduledNotifications').doc(jobId).get();
    const event = trackingSnap.data().event;
    expect(event.conditionCheck).toBe('always');

    const res = makeFakeRes();
    await processScheduledTrustNotificationHandler({ body: { jobId, event } }, res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');

    const updatedSnap = await mockSharedDb.collection('scheduledNotifications').doc(jobId).get();
    expect(updatedSnap.data().status).toBe('EXECUTED');

    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    const notifSnap = await mockSharedDb
      .collection('users').doc(HOST_ID)
      .collection('notifications').get();
    expect(notifSnap.docs).toHaveLength(1);
    expect(notifSnap.docs[0].data().type).toBe('host_checkin_due');

    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(1);
    expect(logSnap.docs[0].data().eventType).toBe('host_checkin_due');
    expect(logSnap.docs[0].data().recipientUserId).toBe(HOST_ID);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 2 — Fallback flow (host never checks in)
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 2 — Fallback flow: host never checks in → fallback jobs fire', () => {
  const GAME_ID   = 'game_sc2';
  const HOST_ID   = 'user_host_sc2';
  const PLAYER_1  = 'user_p1_sc2';
  const TEE_TIME  = '2026-04-02T14:00:00.000Z';
  const COURSE    = 'Augusta National';
  const GAME_DATE = 'Apr 2';

  test('host_checkin_fallback and player_fallback_confirm both deliver when hostCheckedIn=false', async () => {
    await makeUserWithPrefs(mockSharedDb, HOST_ID);
    await makeDevice(mockSharedDb, HOST_ID, 'dev_host_sc2', 'tok_host_sc2', 'android');
    await makeUserWithPrefs(mockSharedDb, PLAYER_1);
    await makeDevice(mockSharedDb, PLAYER_1, 'dev_p1_sc2', 'tok_p1_sc2', 'ios');
    await makeGame(mockSharedDb, GAME_ID, { hostCheckedIn: false });

    const jobResult = await onGameConfirmed(
      GAME_ID, TEE_TIME, HOST_ID, [HOST_ID, PLAYER_1], COURSE, GAME_DATE, mockSharedDb,
    );

    // Fire host fallback — conditionCheck=host_not_checked_in, game has hostCheckedIn=false
    const fallbackJobId = jobResult.hostFallbackJobId;
    const fSnap = await mockSharedDb.collection('scheduledNotifications').doc(fallbackJobId).get();
    const fEvent = fSnap.data().event;
    expect(fEvent.conditionCheck).toBe('host_not_checked_in');

    const res1 = makeFakeRes();
    await processScheduledTrustNotificationHandler({ body: { jobId: fallbackJobId, event: fEvent } }, res1);
    expect(res1._status).toBe(200);
    expect(res1._body).toBe('OK');
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    mockFcmSend.mockClear();

    // Fire player fallback
    const playerFallbackJobId = jobResult.playerFallbackJobIds[PLAYER_1];
    const pSnap = await mockSharedDb.collection('scheduledNotifications').doc(playerFallbackJobId).get();
    const pEvent = pSnap.data().event;

    const res2 = makeFakeRes();
    await processScheduledTrustNotificationHandler({ body: { jobId: playerFallbackJobId, event: pEvent } }, res2);
    expect(res2._status).toBe(200);
    expect(res2._body).toBe('OK');
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    // 2 total sent entries across both deliveries
    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(2);

    const eventTypes = logSnap.docs.map((d) => d.data().eventType).sort();
    expect(eventTypes).toEqual(['host_checkin_fallback', 'player_fallback_confirm'].sort());
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 3 — Condition skip (host already checked in)
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 3 — Condition skip: host checked in before reminder fires', () => {
  const GAME_ID  = 'game_sc3';
  const HOST_ID  = 'user_host_sc3';
  const PLAYER_1 = 'user_p1_sc3';

  test('host_checkin_due reminder skipped and tracking doc CANCELLED when hostCheckedIn=true', async () => {
    await makeUserWithPrefs(mockSharedDb, HOST_ID);
    await makeDevice(mockSharedDb, HOST_ID, 'dev_host_sc3', 'tok_host_sc3', 'ios');
    await makeGame(mockSharedDb, GAME_ID, { hostCheckedIn: true });

    const jobResult = await onGameConfirmed(
      GAME_ID, '2026-04-03T14:00:00.000Z', HOST_ID,
      [HOST_ID, PLAYER_1], 'Torrey Pines', 'Apr 3', mockSharedDb,
    );

    const reminderJobId = jobResult.hostCheckinReminderJobId;
    const rSnap = await mockSharedDb.collection('scheduledNotifications').doc(reminderJobId).get();
    const rEvent = rSnap.data().event;
    expect(rEvent.conditionCheck).toBe('host_not_checked_in');

    const res = makeFakeRes();
    await processScheduledTrustNotificationHandler({ body: { jobId: reminderJobId, event: rEvent } }, res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('CONDITION_NOT_MET');

    // Tracking doc is now CANCELLED (not EXECUTED)
    const updatedSnap = await mockSharedDb.collection('scheduledNotifications').doc(reminderJobId).get();
    expect(updatedSnap.data().status).toBe('CANCELLED');

    // Condition check happens before routeNotification — FCM and in-app not touched
    expect(mockFcmSend).not.toHaveBeenCalled();

    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(0);

    const notifSnap = await mockSharedDb
      .collection('users').doc(HOST_ID)
      .collection('notifications').get();
    expect(notifSnap.docs).toHaveLength(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 4 — Game cancellation cascade
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 4 — Game cancellation cascade: all jobs cancelled, players notified immediately', () => {
  const GAME_ID   = 'game_sc4';
  const HOST_ID   = 'user_host_sc4';
  const PLAYER_1  = 'user_p1_sc4';
  const PLAYER_2  = 'user_p2_sc4';
  const TEE_TIME  = '2026-04-04T14:00:00.000Z';
  const COURSE    = 'Shinnecock Hills';
  const GAME_DATE = 'Apr 4';

  test('onGameCancelled cancels all 5 scheduled jobs and notifies 2 players', async () => {
    await makeUserWithPrefs(mockSharedDb, HOST_ID);
    await makeDevice(mockSharedDb, HOST_ID, 'dev_h_sc4', 'tok_h_sc4', 'ios');
    await makeUserWithPrefs(mockSharedDb, PLAYER_1);
    await makeDevice(mockSharedDb, PLAYER_1, 'dev_p1_sc4', 'tok_p1_sc4', 'ios');
    await makeUserWithPrefs(mockSharedDb, PLAYER_2);
    await makeDevice(mockSharedDb, PLAYER_2, 'dev_p2_sc4', 'tok_p2_sc4', 'android');
    await makeGame(mockSharedDb, GAME_ID);

    // 3 players → 3 host jobs + 2 player fallbacks = 5 total
    await onGameConfirmed(
      GAME_ID, TEE_TIME, HOST_ID, [HOST_ID, PLAYER_1, PLAYER_2], COURSE, GAME_DATE, mockSharedDb,
    );

    const beforeSnap = await mockSharedDb.collection('scheduledNotifications')
      .where('status', '==', 'PENDING').get();
    expect(beforeSnap.docs).toHaveLength(5);

    await onGameCancelled(GAME_ID, [PLAYER_1, PLAYER_2], COURSE, GAME_DATE, mockSharedDb);

    // All 5 tracking docs now CANCELLED
    const allSnap = await mockSharedDb.collection('scheduledNotifications').get();
    expect(allSnap.docs).toHaveLength(5);
    const cancelledCount = allSnap.docs.filter((d) => d.data().status === 'CANCELLED').length;
    expect(cancelledCount).toBe(5);

    // FCM called once per notified player (host not in playerUserIds)
    expect(mockFcmSend).toHaveBeenCalledTimes(2);

    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(2);

    const recipients = logSnap.docs.map((d) => d.data().recipientUserId).sort();
    expect(recipients).toEqual([PLAYER_1, PLAYER_2].sort());
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 5 — Dedup (same event routed twice)
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 5 — Dedup: second identical routeNotification call is dropped', () => {
  const USER_ID = 'user_dedup_sc5';

  test('second call with same eventType+sourceId+recipientUserId returns deduped; FCM called only once', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID);
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc5', 'tok_sc5', 'ios');

    const event = {
      eventId:         'evt_sc5_001',
      eventType:       'badge_earned',
      recipientUserId: USER_ID,
      sourceId:        USER_ID, // user-scoped sourceId for badge events
      data:            { badge_name: 'Verified Regular', rounds_count: '10', unique_players: '8' },
      isReminder:      false,
    };

    const result1 = await routeNotification(event, mockSharedDb);
    expect(result1.result).toBe('sent');
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    // Same event, different eventId — dedup keys on (eventType, sourceId, recipientUserId, status=sent)
    const result2 = await routeNotification({ ...event, eventId: 'evt_sc5_002' }, mockSharedDb);
    expect(result2.result).toBe('deduped');

    // FCM total stays at 1
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    const logSnap = await mockSharedDb.collection('notificationLog').get();
    expect(logSnap.docs).toHaveLength(2);

    const statuses = logSnap.docs.map((d) => d.data().status).sort();
    expect(statuses).toEqual(['deduped', 'sent'].sort());
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 6 — Delivery cap
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 6 — Delivery cap: third host_checkin_due delivery dropped (maxDeliveries=2)', () => {
  const USER_ID = 'user_cap_sc6';
  const GAME_ID = 'game_cap_sc6';

  test('third delivery returns cap_reached; in-app not written', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID);
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc6', 'tok_sc6', 'ios');

    // Pre-seed 2 sent entries with timestamps 25h ago so they are:
    //   - OUTSIDE the 24h dedup window   (dedup check skips them)
    //   - COUNTED by the cap check       (cap looks at all sent entries regardless of age)
    const oldTs = Object.assign(
      new Date(Date.now() - 25 * 60 * 60 * 1000),
      { toMillis() { return this.getTime(); } },
    );
    await mockSharedDb.collection('notificationLog').add({
      eventType: 'host_checkin_due', sourceId: GAME_ID, recipientUserId: USER_ID,
      status: 'sent', timestamp: oldTs,
    });
    await mockSharedDb.collection('notificationLog').add({
      eventType: 'host_checkin_due', sourceId: GAME_ID, recipientUserId: USER_ID,
      status: 'sent', timestamp: oldTs,
    });

    const result = await routeNotification(
      {
        eventId:         'evt_sc6_003',
        eventType:       'host_checkin_due',
        recipientUserId: USER_ID,
        sourceId:        GAME_ID,
        data:            { course_name: 'Pebble Beach', game_id: GAME_ID, hours_remaining: '0' },
        isReminder:      false,
      },
      mockSharedDb,
    );

    expect(result.result).toBe('cap_reached');
    expect(mockFcmSend).not.toHaveBeenCalled();

    // In-app NOT written (cap check is Step 2; in-app write is Step 5)
    const notifSnap = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('notifications').get();
    expect(notifSnap.docs).toHaveLength(0);

    // 2 old sent + 1 cap_reached
    const logSnap = await mockSharedDb.collection('notificationLog').get();
    expect(logSnap.docs).toHaveLength(3);
    const capEntry = logSnap.docs.find((d) => d.data().status === 'cap_reached');
    expect(capEntry).toBeDefined();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 7 — Quiet hours: held then released by cleanup handler
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 7 — Quiet hours: notification held then released by trustQuietHoursCleanupHandler', () => {
  const USER_ID = 'user_quiet_sc7';

  test('badge_earned held at 23:30; cleanup handler at 07:06 re-dispatches and writes in-app', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID, {
      quiet_hours: { enabled: true, start: '22:00', end: '07:00' },
    });
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc7', 'tok_sc7', 'ios');

    // 23:30 UTC — inside 22:00–07:00 quiet window
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-18T23:30:00Z'));

    const event = {
      eventId:         'evt_sc7_001',
      eventType:       'badge_earned',
      recipientUserId: USER_ID,
      sourceId:        USER_ID,
      data:            { badge_name: 'Verified Regular', rounds_count: '10', unique_players: '8' },
      isReminder:      false,
    };

    const result = await routeNotification(event, mockSharedDb);

    expect(result.result).toBe('quiet_held');
    // releaseAt should be 07:00 on the next day (2026-02-19)
    expect(result.releaseAt).toBeInstanceOf(Date);
    expect(result.releaseAt.toISOString()).toBe('2026-02-19T07:00:00.000Z');

    expect(mockFcmSend).not.toHaveBeenCalled();

    // In-app NOT written during hold (in-app write is Step 5, after quiet hours gate Step 4)
    const notifSnapBefore = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('notifications').get();
    expect(notifSnapBefore.docs).toHaveLength(0);

    // notificationLog has the quiet_held entry with releaseAt and event
    const heldSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'quiet_held').get();
    expect(heldSnap.docs).toHaveLength(1);
    const heldData = heldSnap.docs[0].data();
    expect(heldData.releaseAt).toBeInstanceOf(Date);
    expect(heldData.event).toBeDefined();
    expect(heldData.event.eventType).toBe('badge_earned');

    // Advance time past releaseAt + 5min threshold (cleanup stale threshold = 5 min)
    jest.setSystemTime(new Date('2026-02-19T07:06:00Z'));

    const cleanupResult = await trustQuietHoursCleanupHandler(mockSharedDb);

    expect(cleanupResult.found).toBe(1);
    expect(cleanupResult.requeued).toBe(1);
    expect(cleanupResult.errors).toBe(0);

    // FCM called by re-dispatched routeNotification
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    // quiet_held entry now marked quiet_held_released
    const releasedSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'quiet_held_released').get();
    expect(releasedSnap.docs).toHaveLength(1);

    // In-app now written (re-dispatched event passes all gates with quietHoursBypass=true)
    const notifSnapAfter = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('notifications').get();
    expect(notifSnapAfter.docs).toHaveLength(1);
    expect(notifSnapAfter.docs[0].data().type).toBe('badge_earned');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 8 — CRITICAL priority overrides quiet hours
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 8 — CRITICAL priority overrides quiet hours', () => {
  const USER_ID = 'user_critical_sc8';

  test('restriction_started (CRITICAL priority) delivers at 23:30 despite quiet hours', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID, {
      quiet_hours: { enabled: true, start: '22:00', end: '07:00' },
    });
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc8', 'tok_sc8', 'ios');

    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-18T23:30:00Z'));

    // restriction_started: CRITICAL priority + CRITICAL_BYPASS_TYPE
    const result = await routeNotification(
      {
        eventId:         'evt_sc8_001',
        eventType:       'restriction_started',
        recipientUserId: USER_ID,
        sourceId:        USER_ID,
        data:            { duration: '7 days' },
        isReminder:      false,
      },
      mockSharedDb,
    );

    expect(result.result).toBe('sent');
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    const notifSnap = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('notifications').get();
    expect(notifSnap.docs).toHaveLength(1);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 9 — CRITICAL_BYPASS_TYPE ignores category preference
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 9 — CRITICAL_BYPASS_TYPE: cooldown_started delivers even when trustAlerts=false', () => {
  const USER_ID = 'user_bypass_sc9';

  test('cooldown_started delivers with trustAlerts disabled; CRITICAL_BYPASS skips category pref', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID, {
      trust_categories: { post_round: true, trust_alerts: false, badges: true },
    });
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc9', 'tok_sc9', 'android');

    // cooldown_started: CRITICAL_BYPASS_TYPE (skips prefs), HIGH priority (not CRITICAL)
    const result = await routeNotification(
      {
        eventId:         'evt_sc9_001',
        eventType:       'cooldown_started',
        recipientUserId: USER_ID,
        sourceId:        USER_ID,
        data:            {},
        isReminder:      false,
      },
      mockSharedDb,
    );

    expect(result.result).toBe('sent');
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(1);
    expect(logSnap.docs[0].data().eventType).toBe('cooldown_started');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 10 — pushEnabled=false drops everything (before in-app write)
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 10 — pushEnabled=false: non-critical event dropped before in-app write', () => {
  const USER_ID = 'user_disabled_sc10';

  test('badge_earned returns preference_disabled; no FCM, no in-app notification', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID, {
      push_enabled: false,
    });
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc10', 'tok_sc10', 'ios');

    const result = await routeNotification(
      {
        eventId:         'evt_sc10_001',
        eventType:       'badge_earned',
        recipientUserId: USER_ID,
        sourceId:        USER_ID,
        data:            { badge_name: 'Gold', rounds_count: '5', unique_players: '8' },
        isReminder:      false,
      },
      mockSharedDb,
    );

    expect(result.result).toBe('preference_disabled');
    expect(mockFcmSend).not.toHaveBeenCalled();

    // In-app NOT written — pref check is Step 3, in-app write is Step 5
    const notifSnap = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('notifications').get();
    expect(notifSnap.docs).toHaveLength(0);

    const logSnap = await mockSharedDb.collection('notificationLog').get();
    expect(logSnap.docs).toHaveLength(1);
    expect(logSnap.docs[0].data().status).toBe('preference_disabled');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 11 — Token invalidation causes device doc deletion
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 11 — Token invalidation: device doc deleted; result=sent with sentCount=0', () => {
  const USER_ID = 'user_token_sc11';

  test('invalid token causes device deletion; pipeline result is still "sent"', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID);
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc11', 'tok_sc11', 'ios');

    // token_invalid: no retry (fcm-sender returns immediately after first failure)
    mockFcmSend = jest.fn().mockRejectedValue(
      Object.assign(new Error('invalid token'), {
        code: 'messaging/invalid-registration-token',
      }),
    );

    const result = await routeNotification(
      {
        eventId:         'evt_sc11_001',
        eventType:       'badge_earned',
        recipientUserId: USER_ID,
        sourceId:        USER_ID,
        data:            { badge_name: 'Gold', rounds_count: '5', unique_players: '8' },
        isReminder:      false,
      },
      mockSharedDb,
    );

    // router.js:355 always returns result:'sent' after fan-out regardless of device outcomes
    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(0); // 0 successful sends

    // token_invalid → no retry → only 1 FCM call
    expect(mockFcmSend).toHaveBeenCalledTimes(1);

    // Device doc deleted from users/{uid}/devices
    const devicesSnap = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('devices').get();
    expect(devicesSnap.docs).toHaveLength(0);

    // notificationLog sent entry records the token-invalid device result
    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(1);
    const deviceResults = logSnap.docs[0].data().deviceResults;
    expect(deviceResults).toHaveLength(1);
    expect(deviceResults[0].success).toBe(false);
    expect(deviceResults[0].deviceId).toBe('dev_sc11');
    // router.js:326-330 maps sendResults to {deviceId, success, errorCode} only —
    // tokenInvalid is used internally for device deletion but not stored in deviceResults.
    expect(deviceResults[0].errorCode).toBe('messaging/invalid-registration-token');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Scenario 12 — In-app always written even when push fails (server_error)
// ─────────────────────────────────────────────────────────────────────────────

describe('Scenario 12 — In-app written even when push fails (server_error); device NOT deleted', () => {
  const USER_ID = 'user_serverr_sc12';

  test('server_error FCM failure: in-app written, device kept, result=sent sentCount=0', async () => {
    await makeUserWithPrefs(mockSharedDb, USER_ID);
    await makeDevice(mockSharedDb, USER_ID, 'dev_sc12', 'tok_sc12', 'android');

    // server_error → fcm-sender retries 5 total times (1 initial + 4 retries)
    // The router passes baseDelayMs=0 so retries resolve immediately.
    mockFcmSend = jest.fn().mockRejectedValue(
      Object.assign(new Error('server unavailable'), {
        code: 'messaging/server-unavailable',
      }),
    );

    const result = await routeNotification(
      {
        eventId:         'evt_sc12_001',
        eventType:       'badge_earned',
        recipientUserId: USER_ID,
        sourceId:        USER_ID,
        data:            { badge_name: 'Silver', rounds_count: '5', unique_players: '5' },
        isReminder:      false,
      },
      mockSharedDb,
    );

    // router.js:355 always returns result:'sent' after fan-out
    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(0);
    expect(result.inAppWritten).toBe(true);

    // server_error → 5 total FCM calls (1 initial attempt + 4 retries with baseDelayMs=0)
    expect(mockFcmSend).toHaveBeenCalledTimes(5);

    // In-app written at Step 5 (before the FCM fan-out at Steps 7–8)
    const notifSnap = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('notifications').get();
    expect(notifSnap.docs).toHaveLength(1);
    expect(notifSnap.docs[0].data().type).toBe('badge_earned');

    // Device NOT deleted — server_error is not tokenInvalid
    const devicesSnap = await mockSharedDb
      .collection('users').doc(USER_ID)
      .collection('devices').get();
    expect(devicesSnap.docs).toHaveLength(1);

    // notificationLog sent entry records the server-error device result
    const logSnap = await mockSharedDb.collection('notificationLog')
      .where('status', '==', 'sent').get();
    expect(logSnap.docs).toHaveLength(1);
    const dr = logSnap.docs[0].data().deviceResults;
    expect(dr[0].success).toBe(false);
    expect(dr[0].errorCode).toBe('messaging/server-unavailable');
    expect(dr[0].tokenInvalid).toBeUndefined();
  });
});
