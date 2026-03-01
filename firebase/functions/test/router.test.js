'use strict';

/**
 * Trust System Notification Router — Unit Tests
 *
 * Covers all pipeline branches:
 *   Step 1 — Dedup
 *   Step 2 — Delivery cap
 *   Step 3 — Preference check (pushEnabled, trustCategories, game_alerts, social_alerts, critical bypass)
 *   Step 4 — Quiet hours (overnight windows, CRITICAL priority bypass, imminent cancellation, quietHoursBypass)
 *   Step 5 — In-app notification (always written past gates; never written on drops)
 *   Step 6 — Device token resolution (no devices, missing token, single device)
 *   Step 7+8 — Push payload + fan-out (multi-device, partial failure)
 *   Step 9 — Post-send (token invalidation, device deletion, sentCount)
 *   Pure helpers — isInQuietWindow, computeReleaseAt, isImminentGameCancellation
 *
 * Run: npx jest test/router.test.js --verbose
 */

// ── Shared mock state — must be declared before jest.mock() factories ────────
// mockDb is reassigned per-test inside beforeEach so every test starts fresh.
let mockDb;
let logAddSpy;
let notifAddSpy;
let deviceDeleteSpy;

// ── firebase-admin mock ───────────────────────────────────────────────────────
// The router uses admin.firestore() (callable → returns mockDb) AND
// admin.firestore.FieldValue.serverTimestamp() (static property).
// Both must be satisfied by the same mock object.
jest.mock('firebase-admin', () => {
  const serverTimestamp = jest.fn(() => ({ _sentinel: 'SERVER_TIMESTAMP' }));
  function mockFirestoreFn() { return mockDb; }
  mockFirestoreFn.FieldValue = { serverTimestamp };
  return { firestore: mockFirestoreFn };
});

// ── Dependency mocks ──────────────────────────────────────────────────────────
jest.mock('../notifications/trust/preferences-service', () => ({
  getUserPreferences: jest.fn(),
}));
jest.mock('../notifications/trust/fcm-sender', () => ({
  send: jest.fn(),
}));
jest.mock('../notifications/trust/template-engine', () => ({
  buildPushPayload:      jest.fn(),
  buildInAppNotification: jest.fn(),
}));
jest.mock('../notifications/trust/scheduler', () => ({
  scheduleJob: jest.fn(),
}));

// ── Module under test ─────────────────────────────────────────────────────────
const {
  routeNotification,
  isInQuietWindow,
  isActiveDay,
  computeReleaseAt,
  isImminentGameCancellation,
} = require('../notifications/trust/router');

const { getUserPreferences }                    = require('../notifications/trust/preferences-service');
const { send }                                  = require('../notifications/trust/fcm-sender');
const { buildPushPayload, buildInAppNotification } = require('../notifications/trust/template-engine');
const { scheduleJob }                           = require('../notifications/trust/scheduler');

// ── Test fixtures ─────────────────────────────────────────────────────────────

function makeEvent(overrides = {}) {
  return Object.assign({
    eventId:         'evt_001',
    eventType:       'badge_earned',
    recipientUserId: 'user_abc',
    sourceId:        'game_g1',
    data:            { badge_name: 'Gold', rounds_count: '5', unique_players: '8' },
    isReminder:      false,
    quietHoursBypass: false,
  }, overrides);
}

function makePrefs(overrides = {}) {
  return Object.assign({
    pushEnabled: true,
    trustCategories: { postRound: true, trustAlerts: true, badges: true },
    quietHours: { enabled: false, start: '22:00', end: '07:00' },
  }, overrides);
}

const MOCK_PAYLOAD = {
  title: 'Test Title', body: 'Test body',
  deepLink: 'findmyfourth://badges',
  eventType: 'badge_earned', eventId: 'evt_001',
  priority: 'HIGH', threadId: 'badges', androidChannelId: 'important',
};

const MOCK_IN_APP_DOC = {
  type: 'badge_earned', title: 'Test Title', body: 'Test body',
  read: false,
  createdAt: { _sentinel: 'SERVER_TIMESTAMP' },
  data: { gameId: null, gameRef: null, eventId: 'evt_001', eventType: 'badge_earned' },
};

/** A Firestore doc stub with a toMillis()-compatible timestamp. */
function makeSentDoc(offsetMs = 0) {
  const ms = Date.now() - offsetMs;
  return {
    data: () => ({
      status:    'sent',
      timestamp: { toMillis: () => ms },
    }),
  };
}

const DEVICE_1 = { id: 'dev_1', data: () => ({ fcmToken: 'tok_abc', platform: 'ios' }) };
const DEVICE_2 = { id: 'dev_2', data: () => ({ fcmToken: 'tok_def', platform: 'android' }) };

const SEND_SUCCESS = (deviceId) => ({ success: true,  deviceId, latencyMs: 10 });
const SEND_FAIL_INVALID = (deviceId) => ({
  success: false, deviceId, tokenInvalid: true,
  errorCode: 'messaging/invalid-registration-token', latencyMs: 5,
});
const SEND_FAIL_OTHER = (deviceId) => ({
  success: false, deviceId, errorCode: 'messaging/server-unavailable', latencyMs: 5,
});

// ── Mock DB builder ───────────────────────────────────────────────────────────

/**
 * Builds a minimal mockDb that satisfies all Firestore interaction patterns
 * used by routeNotification. Injected as the `db` parameter.
 *
 * Routing:
 *   db.collection('notificationLog').where(...).orderBy(...).get() → logDocs
 *   db.collection('notificationLog').add(...)                      → logAddSpy
 *   db.collection('users').doc(uid).get()                         → userDoc
 *   db.collection('users').doc(uid).collection('notifications').add() → notifAddSpy
 *   db.collection('users').doc(uid).collection('devices').get()   → deviceDocs
 *   db.collection('users').doc(uid).collection('devices').doc(id).delete() → deviceDeleteSpy
 */
function makeMockDb({
  logDocs      = [],
  userDocData  = null,   // raw Firestore data for users/{uid}.get()
  deviceDocs   = [DEVICE_1],
} = {}) {
  logAddSpy        = jest.fn().mockResolvedValue({ id: 'log_id_1' });
  notifAddSpy      = jest.fn().mockResolvedValue({ id: 'notif_id_1' });
  deviceDeleteSpy  = jest.fn().mockResolvedValue(undefined);

  // Chainable query builder for notificationLog
  function makeLogQuery() {
    const q = {
      where:   () => q,
      orderBy: () => q,
      get:     jest.fn().mockResolvedValue({ docs: logDocs }),
    };
    return q;
  }

  // Sub-collection factory for users/{uid}/...
  function makeUserSubCol(subColName) {
    return {
      add: subColName === 'notifications'
        ? notifAddSpy
        : jest.fn().mockResolvedValue({ id: 'other_id' }),
      get: jest.fn().mockResolvedValue({ docs: deviceDocs }),
      doc: (docId) => ({
        delete: () => deviceDeleteSpy(docId),
      }),
    };
  }

  // User doc
  function makeUserDoc() {
    const exists = userDocData !== null;
    return {
      exists,
      data: () => (exists ? userDocData : {}),
    };
  }

  const db = {
    collection: (colName) => {
      if (colName === 'notificationLog') {
        const logQ = makeLogQuery();
        return Object.assign(logQ, { add: logAddSpy });
      }
      if (colName === 'users') {
        return {
          doc: () => ({
            get:        jest.fn().mockResolvedValue(makeUserDoc()),
            collection: (subCol) => makeUserSubCol(subCol),
          }),
        };
      }
      throw new Error(`Unexpected collection: ${colName}`);
    },
  };

  return db;
}

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();

  // Default: all prefs enabled, no quiet hours, single valid device
  getUserPreferences.mockResolvedValue(makePrefs());
  buildPushPayload.mockReturnValue(MOCK_PAYLOAD);
  buildInAppNotification.mockReturnValue(MOCK_IN_APP_DOC);
  send.mockResolvedValue(SEND_SUCCESS('dev_1'));
  scheduleJob.mockResolvedValue('mock_job_id');

  mockDb = makeMockDb({ logDocs: [], deviceDocs: [DEVICE_1] });
});

afterEach(() => {
  jest.useRealTimers();
});

// ════════════════════════════════════════════════════════════════════════════
// Step 1 — Dedup
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 1: Dedup', () => {

  test('dedup hit (within 24h): returns deduped, no in-app written, log entry added', async () => {
    mockDb = makeMockDb({ logDocs: [makeSentDoc(1000)] }); // 1 second ago

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result).toEqual({ result: 'deduped' });
    expect(logAddSpy).toHaveBeenCalledTimes(1);
    expect(logAddSpy.mock.calls[0][0].status).toBe('deduped');
    expect(buildInAppNotification).not.toHaveBeenCalled();
    expect(send).not.toHaveBeenCalled();
  });

  test('sent entry older than 24h does NOT trigger dedup', async () => {
    mockDb = makeMockDb({ logDocs: [makeSentDoc(25 * 60 * 60 * 1000)] }); // 25h ago

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).not.toBe('deduped');
  });

  test('no prior sends: passes dedup check', async () => {
    mockDb = makeMockDb({ logDocs: [] });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).not.toBe('deduped');
    expect(result.result).not.toBe('cap_reached');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Step 2 — Delivery cap
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 2: Delivery cap', () => {

  test('host_checkin_due (maxDeliveries=2) with 2 prior sends: cap_reached', async () => {
    // Both docs are older than 24h so dedup does not fire, but cap check sees count=2
    const oldDoc = makeSentDoc(25 * 60 * 60 * 1000);
    mockDb = makeMockDb({ logDocs: [oldDoc, oldDoc] });

    const result = await routeNotification(
      makeEvent({ eventType: 'host_checkin_due', data: { course_name: 'Pebble Beach' } }),
      mockDb,
    );

    expect(result).toEqual({ result: 'cap_reached' });
    expect(logAddSpy.mock.calls[0][0].status).toBe('cap_reached');
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('1 prior send for maxDeliveries=2: passes cap check', async () => {
    mockDb = makeMockDb({ logDocs: [makeSentDoc(25 * 60 * 60 * 1000)] });

    const result = await routeNotification(
      makeEvent({ eventType: 'host_checkin_due', data: { course_name: 'Pebble Beach' } }),
      mockDb,
    );

    expect(result.result).not.toBe('cap_reached');
  });

  test('0 prior sends: passes cap check', async () => {
    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).not.toBe('cap_reached');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Step 3 — Preference check
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 3: pushEnabled master toggle', () => {

  test('pushEnabled=false, non-critical event: preference_disabled, no in-app', async () => {
    getUserPreferences.mockResolvedValue(makePrefs({ pushEnabled: false }));

    const result = await routeNotification(makeEvent({ eventType: 'badge_earned' }), mockDb);

    expect(result).toEqual({ result: 'preference_disabled' });
    expect(logAddSpy.mock.calls[0][0].status).toBe('preference_disabled');
    expect(buildInAppNotification).not.toHaveBeenCalled();
    expect(send).not.toHaveBeenCalled();
  });

  test('pushEnabled=false, cooldown_started (CRITICAL_BYPASS): proceeds through pipeline', async () => {
    getUserPreferences.mockResolvedValue(makePrefs({ pushEnabled: false }));

    const result = await routeNotification(
      makeEvent({ eventType: 'cooldown_started', data: {} }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('pushEnabled=false, restriction_started (CRITICAL_BYPASS): proceeds', async () => {
    getUserPreferences.mockResolvedValue(makePrefs({ pushEnabled: false }));

    const result = await routeNotification(
      makeEvent({ eventType: 'restriction_started', data: { duration: '7 days' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

  test('pushEnabled=false, suspension_started (CRITICAL_BYPASS): proceeds', async () => {
    getUserPreferences.mockResolvedValue(makePrefs({ pushEnabled: false }));

    const result = await routeNotification(
      makeEvent({ eventType: 'suspension_started', data: {} }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

});

describe('routeNotification — Step 3: trustCategories check', () => {

  test('trustCategories.badges=false, badge_earned: preference_disabled', async () => {
    getUserPreferences.mockResolvedValue(
      makePrefs({ trustCategories: { postRound: true, trustAlerts: true, badges: false } }),
    );

    const result = await routeNotification(makeEvent({ eventType: 'badge_earned' }), mockDb);

    expect(result.result).toBe('preference_disabled');
  });

  test('trustCategories.postRound=false, host_checkin_due: preference_disabled', async () => {
    getUserPreferences.mockResolvedValue(
      makePrefs({ trustCategories: { postRound: false, trustAlerts: true, badges: true } }),
    );

    const result = await routeNotification(
      makeEvent({ eventType: 'host_checkin_due', data: { course_name: 'Pebble Beach' } }),
      mockDb,
    );

    expect(result.result).toBe('preference_disabled');
  });

  test('trustCategories.trustAlerts=false, no_show_flagged (HIGH, non-bypass): preference_disabled', async () => {
    getUserPreferences.mockResolvedValue(
      makePrefs({ trustCategories: { postRound: true, trustAlerts: false, badges: true } }),
    );

    const result = await routeNotification(
      makeEvent({ eventType: 'no_show_flagged', data: { course_name: 'X', date: 'June 1' } }),
      mockDb,
    );

    expect(result.result).toBe('preference_disabled');
  });

  test('trustCategories.trustAlerts=false, cooldown_started (CRITICAL_BYPASS): category check skipped', async () => {
    getUserPreferences.mockResolvedValue(
      makePrefs({ trustCategories: { postRound: false, trustAlerts: false, badges: false } }),
    );

    const result = await routeNotification(
      makeEvent({ eventType: 'cooldown_started', data: {} }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

});

describe('routeNotification — Step 3: game_alerts check', () => {

  function makeUserDocWith(gameAlertsEnabled) {
    return {
      notification_prefs: {
        push_enabled: true,
        game_alerts:  { enabled: gameAlertsEnabled },
      },
    };
  }

  test('game_spot_opened, game_alerts.enabled=true: proceeds (trustCategories irrelevant)', async () => {
    // Even if all trustCategories are disabled, game_spot_opened uses game_alerts
    getUserPreferences.mockResolvedValue(
      makePrefs({ trustCategories: { postRound: false, trustAlerts: false, badges: false } }),
    );
    mockDb = makeMockDb({
      userDocData: makeUserDocWith(true),
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'game_spot_opened', data: { game_date: 'Sat', course_name: 'X', spots_remaining: '1', game_id: 'g1' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('game_spot_opened, game_alerts.enabled=false: preference_disabled', async () => {
    mockDb = makeMockDb({ userDocData: makeUserDocWith(false), deviceDocs: [DEVICE_1] });

    const result = await routeNotification(
      makeEvent({ eventType: 'game_spot_opened', data: { game_date: 'Sat', course_name: 'X', spots_remaining: '1', game_id: 'g1' } }),
      mockDb,
    );

    expect(result.result).toBe('preference_disabled');
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('game_cancelled, game_alerts.enabled=false: preference_disabled', async () => {
    mockDb = makeMockDb({ userDocData: makeUserDocWith(false), deviceDocs: [DEVICE_1] });

    const result = await routeNotification(
      makeEvent({ eventType: 'game_cancelled', data: { game_date: 'Sun', course_name: 'X', game_id: 'g1' } }),
      mockDb,
    );

    expect(result.result).toBe('preference_disabled');
  });

  test('game_spot_opened, game_alerts field absent: defaults to enabled (not dropped)', async () => {
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { push_enabled: true } }, // no game_alerts field
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'game_spot_opened', data: { game_date: 'Sat', course_name: 'X', spots_remaining: '1', game_id: 'g1' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

});

describe('routeNotification — Step 3: social_alerts check', () => {

  function makeUserDocWithSocialAlerts(socialAlertsEnabled) {
    return {
      notification_prefs: {
        push_enabled: true,
        social_alerts: { enabled: socialAlertsEnabled },
      },
    };
  }

  test('friend_request_received, social_alerts.enabled=true: proceeds (trustCategories irrelevant)', async () => {
    // Even if all trustCategories are disabled, friend_request_received uses social_alerts
    getUserPreferences.mockResolvedValue(
      makePrefs({ trustCategories: { postRound: false, trustAlerts: false, badges: false } }),
    );
    mockDb = makeMockDb({
      userDocData: makeUserDocWithSocialAlerts(true),
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_received', data: { sender_name: 'Alice', sender_id: 'user_123' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('friend_request_received, social_alerts.enabled=false: preference_disabled', async () => {
    mockDb = makeMockDb({ userDocData: makeUserDocWithSocialAlerts(false), deviceDocs: [DEVICE_1] });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_received', data: { sender_name: 'Alice', sender_id: 'user_123' } }),
      mockDb,
    );

    expect(result.result).toBe('preference_disabled');
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('friend_request_accepted, social_alerts.enabled=true: proceeds', async () => {
    mockDb = makeMockDb({
      userDocData: makeUserDocWithSocialAlerts(true),
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_accepted', data: { acceptor_name: 'Bob', acceptor_id: 'user_456' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('friend_request_accepted, social_alerts.enabled=false: preference_disabled', async () => {
    mockDb = makeMockDb({ userDocData: makeUserDocWithSocialAlerts(false), deviceDocs: [DEVICE_1] });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_accepted', data: { acceptor_name: 'Bob', acceptor_id: 'user_456' } }),
      mockDb,
    );

    expect(result.result).toBe('preference_disabled');
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('friend_request_received, social_alerts field absent: defaults to enabled (not dropped)', async () => {
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { push_enabled: true } }, // no social_alerts field
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_received', data: { sender_name: 'Alice', sender_id: 'user_123' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

  test('friend_request_accepted, social_alerts field absent: defaults to enabled', async () => {
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { push_enabled: true } }, // no social_alerts field
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_accepted', data: { acceptor_name: 'Bob', acceptor_id: 'user_456' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

  test('friend_request_received, user doc does not exist: defaults to enabled', async () => {
    mockDb = makeMockDb({
      userDocData: null, // user doc doesn't exist
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'friend_request_received', data: { sender_name: 'Alice', sender_id: 'user_123' } }),
      mockDb,
    );

    expect(result.result).not.toBe('preference_disabled');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Step 4 — Quiet hours
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 4: Quiet hours', () => {

  function enableQuietHours(start = '22:00', end = '07:00') {
    getUserPreferences.mockResolvedValue(
      makePrefs({ quietHours: { enabled: true, start, end } }),
    );
  }

  test('in quiet window (23:00 Vancouver, 22:00–07:00): quiet_held, schedules Cloud Task, no in-app, log has releaseAt and jobId', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours('22:00', '07:00');
    mockDb = makeMockDb({ logDocs: [], deviceDocs: [DEVICE_1] });

    const result = await routeNotification(makeEvent({ eventType: 'badge_earned' }), mockDb);

    expect(result.result).toBe('quiet_held');
    expect(result.releaseAt).toBeInstanceOf(Date);
    expect(result.releaseAt.toISOString()).toBe('2026-02-19T15:00:00.000Z');
    expect(result.jobId).toBe('mock_job_id');
    expect(scheduleJob).toHaveBeenCalledTimes(1);
    expect(scheduleJob).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: 'badge_earned',
        scheduleTime: expect.any(Date),
        quietHoursBypass: true,
        conditionCheck: 'always',
      }),
      mockDb,
    );
    expect(logAddSpy.mock.calls[0][0].status).toBe('quiet_held');
    expect(logAddSpy.mock.calls[0][0].releaseAt).toBeInstanceOf(Date);
    expect(logAddSpy.mock.calls[0][0].jobId).toBe('mock_job_id');
    expect(buildInAppNotification).not.toHaveBeenCalled();
    expect(send).not.toHaveBeenCalled();
  });

  test('in quiet window, CRITICAL priority (strike_issued): bypasses quiet hours, proceeds', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();
    mockDb = makeMockDb({ logDocs: [], deviceDocs: [DEVICE_1] });

    const result = await routeNotification(
      makeEvent({ eventType: 'strike_issued', data: { reason: 'confirmed no-show' } }),
      mockDb,
    );

    // strike_issued is CRITICAL priority per event registry → bypasses quiet hours
    expect(result.result).not.toBe('quiet_held');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('in quiet window, cooldown_started (HIGH priority, in CRITICAL_BYPASS but not CRITICAL priority): held', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();
    mockDb = makeMockDb({ logDocs: [], deviceDocs: [DEVICE_1] });

    const result = await routeNotification(
      makeEvent({ eventType: 'cooldown_started', data: {} }),
      mockDb,
    );

    // cooldown_started bypasses preferences, but it is HIGH priority → does NOT bypass quiet hours
    expect(result.result).toBe('quiet_held');
    expect(result.jobId).toBe('mock_job_id');
    expect(scheduleJob).toHaveBeenCalledTimes(1);
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('in quiet window, game_cancelled with imminent game_start_iso (within 4h): proceeds', async () => {
    jest.useFakeTimers();
    // Quiet window 22:00–07:00, current time 23:00 Vancouver. releaseAt = 2026-02-19T15:00Z
    // Game starts at 17:00 UTC same day = 2h after releaseAt → within 4h
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { game_alerts: { enabled: true } } },
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({
        eventType: 'game_cancelled',
        data: { game_date: 'Wed', course_name: 'X', game_id: 'g1', game_start_iso: '2026-02-19T17:00:00Z' },
      }),
      mockDb,
    );

    expect(result.result).not.toBe('quiet_held');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('in quiet window, game_cancelled with game_start_iso > 4h after releaseAt: held', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { game_alerts: { enabled: true } } },
      deviceDocs: [DEVICE_1],
    });

    // Game starts 23:00 UTC = 8h after releaseAt (15:00) → outside 4h window
    const result = await routeNotification(
      makeEvent({
        eventType: 'game_cancelled',
        data: { game_date: 'Wed', course_name: 'X', game_id: 'g1', game_start_iso: '2026-02-19T23:00:00Z' },
      }),
      mockDb,
    );

    expect(result.result).toBe('quiet_held');
    expect(result.jobId).toBe('mock_job_id');
    expect(scheduleJob).toHaveBeenCalledTimes(1);
  });

  test('in quiet window, game_cancelled with no game_start_iso: held (safe default)', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { game_alerts: { enabled: true } } },
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'game_cancelled', data: { game_date: 'Wed', course_name: 'X', game_id: 'g1' } }),
      mockDb,
    );

    expect(result.result).toBe('quiet_held');
    expect(result.jobId).toBe('mock_job_id');
    expect(scheduleJob).toHaveBeenCalledTimes(1);
  });

  test('in quiet window, game_cancelled with unparseable game_start_iso: held', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();
    mockDb = makeMockDb({
      userDocData: { notification_prefs: { game_alerts: { enabled: true } } },
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(
      makeEvent({ eventType: 'game_cancelled', data: { game_date: 'Wed', course_name: 'X', game_id: 'g1', game_start_iso: 'not-a-date' } }),
      mockDb,
    );

    expect(result.result).toBe('quiet_held');
    expect(result.jobId).toBe('mock_job_id');
    expect(scheduleJob).toHaveBeenCalledTimes(1);
  });

  test('quietHoursBypass=true: skips quiet hours entirely', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours();

    const result = await routeNotification(
      makeEvent({ quietHoursBypass: true }),
      mockDb,
    );

    expect(result.result).not.toBe('quiet_held');
    expect(buildInAppNotification).toHaveBeenCalled();
  });

  test('quietHours.enabled=false: not held even during window time', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    getUserPreferences.mockResolvedValue(
      makePrefs({ quietHours: { enabled: false, start: '22:00', end: '07:00' } }),
    );

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).not.toBe('quiet_held');
  });

  test('overnight window (22:00–07:00), time=01:00: held', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T09:00:00Z'));
    enableQuietHours('22:00', '07:00');

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).toBe('quiet_held');
    expect(result.jobId).toBe('mock_job_id');
    expect(scheduleJob).toHaveBeenCalledTimes(1);
  });

  test('overnight window (22:00–07:00), time=12:00: NOT held', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-18T20:00:00Z'));
    enableQuietHours('22:00', '07:00');

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).not.toBe('quiet_held');
  });

  test('quiet hours active_days excludes today: quiet hours are skipped', async () => {
    jest.useFakeTimers();
    // 2026-02-19T07:00Z = Wednesday 23:00 Vancouver, but active_days=[4] means Thursday only.
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    enableQuietHours('22:00', '07:00');
    mockDb = makeMockDb({
      userDocData: {
        notification_prefs: {
          quiet_hours: { active_days: [4] },
        },
      },
      deviceDocs: [DEVICE_1],
    });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).not.toBe('quiet_held');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Step 5 — In-app notification
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 5: In-app notification', () => {

  test('passes all gates: buildInAppNotification called with (eventType, data, eventId)', async () => {
    const event = makeEvent();
    await routeNotification(event, mockDb);

    expect(buildInAppNotification).toHaveBeenCalledTimes(1);
    expect(buildInAppNotification).toHaveBeenCalledWith(event.eventType, event.data, event.eventId);
  });

  test('passes all gates: in-app written to users/{uid}/notifications', async () => {
    await routeNotification(makeEvent(), mockDb);

    expect(notifAddSpy).toHaveBeenCalledTimes(1);
    expect(notifAddSpy).toHaveBeenCalledWith(MOCK_IN_APP_DOC);
  });

  test('dedup: in-app NOT written', async () => {
    mockDb = makeMockDb({ logDocs: [makeSentDoc(1000)] });
    await routeNotification(makeEvent(), mockDb);
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('cap_reached: in-app NOT written', async () => {
    const old = makeSentDoc(25 * 60 * 60 * 1000);
    mockDb = makeMockDb({ logDocs: [old, old] });
    await routeNotification(
      makeEvent({ eventType: 'host_checkin_due', data: { course_name: 'X' } }),
      mockDb,
    );
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('preference_disabled: in-app NOT written', async () => {
    getUserPreferences.mockResolvedValue(makePrefs({ pushEnabled: false }));
    await routeNotification(makeEvent(), mockDb);
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

  test('quiet_held: in-app NOT written', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));
    getUserPreferences.mockResolvedValue(
      makePrefs({ quietHours: { enabled: true, start: '22:00', end: '07:00' } }),
    );
    await routeNotification(makeEvent(), mockDb);
    expect(buildInAppNotification).not.toHaveBeenCalled();
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Step 6 — Device resolution
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 6: Device resolution', () => {

  test('no devices: no_devices result, in-app was already written, send not called', async () => {
    mockDb = makeMockDb({ deviceDocs: [] });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result).toMatchObject({ result: 'no_devices', inAppWritten: true });
    expect(result.inAppNotifId).toBe('notif_id_1');
    expect(buildInAppNotification).toHaveBeenCalled(); // step 5 ran
    expect(send).not.toHaveBeenCalled();
    expect(logAddSpy.mock.calls[0][0].status).toBe('dropped_no_devices');
  });

  test('device missing fcm_token: filtered out, treated as no devices', async () => {
    const noTokenDevice = { id: 'dev_x', data: () => ({ platform: 'ios' }) };
    mockDb = makeMockDb({ deviceDocs: [noTokenDevice] });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).toBe('no_devices');
    expect(send).not.toHaveBeenCalled();
  });

  test('single valid device: send called once', async () => {
    mockDb = makeMockDb({ deviceDocs: [DEVICE_1] });

    await routeNotification(makeEvent(), mockDb);

    expect(send).toHaveBeenCalledTimes(1);
    expect(send).toHaveBeenCalledWith('tok_abc', 'dev_1', MOCK_PAYLOAD, 0);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Steps 7 + 8 — Payload and fan-out
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Steps 7+8: Payload and fan-out', () => {

  test('buildPushPayload called with (eventType, data, eventId, isReminder=false)', async () => {
    const event = makeEvent({ isReminder: false });
    await routeNotification(event, mockDb);

    expect(buildPushPayload).toHaveBeenCalledWith(event.eventType, event.data, event.eventId, false);
  });

  test('isReminder=true passed through to buildPushPayload', async () => {
    const event = makeEvent({ eventType: 'host_checkin_due', isReminder: true, data: { course_name: 'X' } });
    await routeNotification(event, mockDb);

    expect(buildPushPayload).toHaveBeenCalledWith(event.eventType, event.data, event.eventId, true);
  });

  test('isReminder absent: defaults to false', async () => {
    const event = makeEvent();
    delete event.isReminder;
    await routeNotification(event, mockDb);

    expect(buildPushPayload).toHaveBeenCalledWith(event.eventType, event.data, event.eventId, false);
  });

  test('multi-device fan-out: send called for each device', async () => {
    send.mockImplementation(async (token, deviceId) => SEND_SUCCESS(deviceId));
    mockDb = makeMockDb({ deviceDocs: [DEVICE_1, DEVICE_2] });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(send).toHaveBeenCalledTimes(2);
    expect(send).toHaveBeenCalledWith('tok_abc', 'dev_1', MOCK_PAYLOAD, 0);
    expect(send).toHaveBeenCalledWith('tok_def', 'dev_2', MOCK_PAYLOAD, 0);
    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(2);
  });

  test('Promise.all: both sends run even if one fails', async () => {
    send.mockImplementation(async (token, deviceId) =>
      deviceId === 'dev_1' ? SEND_SUCCESS('dev_1') : SEND_FAIL_OTHER('dev_2'),
    );
    mockDb = makeMockDb({ deviceDocs: [DEVICE_1, DEVICE_2] });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(send).toHaveBeenCalledTimes(2);
    expect(result.sentCount).toBe(1);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Step 9 — Post-send
// ════════════════════════════════════════════════════════════════════════════

describe('routeNotification — Step 9: Post-send', () => {

  test('happy path: log status=sent with deviceResults, return shape correct', async () => {
    const result = await routeNotification(makeEvent(), mockDb);

    expect(result).toMatchObject({
      result:      'sent',
      sentCount:   1,
      inAppWritten: true,
      inAppNotifId: 'notif_id_1',
    });
    expect(result.deviceResults).toEqual([{ deviceId: 'dev_1', success: true }]);

    const logDoc = logAddSpy.mock.calls[0][0];
    expect(logDoc.status).toBe('sent');
    expect(logDoc.deviceResults).toEqual([{ deviceId: 'dev_1', success: true }]);
  });

  test('deviceResults includes errorCode on failure', async () => {
    send.mockResolvedValue(SEND_FAIL_OTHER('dev_1'));

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.deviceResults[0]).toMatchObject({
      deviceId: 'dev_1',
      success:  false,
      errorCode: 'messaging/server-unavailable',
    });
  });

  test('tokenInvalid: device doc deleted', async () => {
    send.mockResolvedValue(SEND_FAIL_INVALID('dev_1'));

    await routeNotification(makeEvent(), mockDb);

    expect(deviceDeleteSpy).toHaveBeenCalledTimes(1);
    expect(deviceDeleteSpy).toHaveBeenCalledWith('dev_1');
  });

  test('tokenInvalid: sentCount reflects successful sends (0 here)', async () => {
    send.mockResolvedValue(SEND_FAIL_INVALID('dev_1'));

    const result = await routeNotification(makeEvent(), mockDb);

    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(0);
  });

  test('non-tokenInvalid failure: device doc NOT deleted', async () => {
    send.mockResolvedValue(SEND_FAIL_OTHER('dev_1'));

    await routeNotification(makeEvent(), mockDb);

    expect(deviceDeleteSpy).not.toHaveBeenCalled();
  });

  test('two devices, one tokenInvalid: only that device deleted', async () => {
    send.mockImplementation(async (token, deviceId) =>
      deviceId === 'dev_1' ? SEND_SUCCESS('dev_1') : SEND_FAIL_INVALID('dev_2'),
    );
    mockDb = makeMockDb({ deviceDocs: [DEVICE_1, DEVICE_2] });

    const result = await routeNotification(makeEvent(), mockDb);

    expect(deviceDeleteSpy).toHaveBeenCalledTimes(1);
    expect(deviceDeleteSpy).toHaveBeenCalledWith('dev_2');
    expect(result.sentCount).toBe(1);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Pure helper: isInQuietWindow
// ════════════════════════════════════════════════════════════════════════════

describe('isInQuietWindow', () => {

  // Same-day windows
  test('same-day window: time inside → true', () => {
    expect(isInQuietWindow('13:00', '15:00', '14:00')).toBe(true);
  });

  test('same-day window: time at start (inclusive) → true', () => {
    expect(isInQuietWindow('13:00', '15:00', '13:00')).toBe(true);
  });

  test('same-day window: time at end (exclusive) → false', () => {
    expect(isInQuietWindow('13:00', '15:00', '15:00')).toBe(false);
  });

  test('same-day window: time outside → false', () => {
    expect(isInQuietWindow('13:00', '15:00', '20:00')).toBe(false);
  });

  // Overnight windows
  test('overnight window: time in late portion → true', () => {
    expect(isInQuietWindow('22:00', '07:00', '23:30')).toBe(true);
  });

  test('overnight window: time in early morning → true', () => {
    expect(isInQuietWindow('22:00', '07:00', '01:00')).toBe(true);
  });

  test('overnight window: exactly midnight → true', () => {
    expect(isInQuietWindow('22:00', '07:00', '00:00')).toBe(true);
  });

  test('overnight window: daytime → false', () => {
    expect(isInQuietWindow('22:00', '07:00', '12:00')).toBe(false);
  });

  test('overnight window: at end boundary (07:00) → false', () => {
    expect(isInQuietWindow('22:00', '07:00', '07:00')).toBe(false);
  });

  test('overnight window: at start boundary (22:00) → true', () => {
    expect(isInQuietWindow('22:00', '07:00', '22:00')).toBe(true);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Pure helper: isActiveDay
// ════════════════════════════════════════════════════════════════════════════

describe('isActiveDay', () => {
  test('empty or missing activeDays defaults to true', () => {
    expect(isActiveDay()).toBe(true);
    expect(isActiveDay([])).toBe(true);
    expect(isActiveDay(null)).toBe(true);
  });

  test('maps Vancouver weekday to ISO day correctly', () => {
    jest.useFakeTimers();
    // Monday in Vancouver
    jest.setSystemTime(new Date('2026-02-16T20:00:00Z'));

    expect(isActiveDay([1])).toBe(true);
    expect(isActiveDay([7])).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════════════════
// Pure helper: computeReleaseAt
// ════════════════════════════════════════════════════════════════════════════

describe('computeReleaseAt', () => {

  test('end time not yet passed today in Vancouver: returns same-day Vancouver 07:00 converted to UTC', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-18T10:00:00Z')); // 02:00 Vancouver

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-02-18T15:00:00.000Z');
  });

  test('end time already passed today in Vancouver: returns next-day Vancouver 07:00 converted to UTC', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-18T23:00:00Z')); // 15:00 Vancouver

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-02-19T15:00:00.000Z');
  });

  test('current time exactly equals Vancouver end time: rolls to next day', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-18T15:00:00.000Z')); // 07:00 Vancouver

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-02-19T15:00:00.000Z');
  });

  test('DST spring-forward: 07:00 Vancouver resolves with PDT offset', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-03-08T12:00:00Z')); // 04:00 Vancouver on DST transition day

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-03-08T14:00:00.000Z');
  });

  test('DST fall-back: 07:00 Vancouver resolves with PST offset', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-11-01T11:00:00Z')); // 03:00 Vancouver after fallback

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-11-01T15:00:00.000Z');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// Pure helper: isImminentGameCancellation
// ════════════════════════════════════════════════════════════════════════════

describe('isImminentGameCancellation', () => {

  const BASE_RELEASE = new Date('2026-02-19T07:00:00Z');

  function evt(game_start_iso) {
    return { data: game_start_iso !== undefined ? { game_start_iso } : {} };
  }

  test('game starts 2h after releaseAt (within 4h): true', () => {
    expect(isImminentGameCancellation(
      evt('2026-02-19T09:00:00Z'),
      BASE_RELEASE,
    )).toBe(true);
  });

  test('game starts exactly 4h after releaseAt (boundary): true', () => {
    expect(isImminentGameCancellation(
      evt('2026-02-19T11:00:00Z'),
      BASE_RELEASE,
    )).toBe(true);
  });

  test('game starts 5h after releaseAt (beyond 4h): false', () => {
    expect(isImminentGameCancellation(
      evt('2026-02-19T12:00:00Z'),
      BASE_RELEASE,
    )).toBe(false);
  });

  test('game starts before releaseAt: true (definitely within 4h window)', () => {
    expect(isImminentGameCancellation(
      evt('2026-02-19T06:00:00Z'),
      BASE_RELEASE,
    )).toBe(true);
  });

  test('game_start_iso absent: false', () => {
    expect(isImminentGameCancellation(evt(), BASE_RELEASE)).toBe(false);
  });

  test('game_start_iso is null: false', () => {
    expect(isImminentGameCancellation(evt(null), BASE_RELEASE)).toBe(false);
  });

  test('game_start_iso is unparseable: false', () => {
    expect(isImminentGameCancellation(evt('not-a-date'), BASE_RELEASE)).toBe(false);
  });

});
