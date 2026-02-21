'use strict';

/**
 * Trust System Background Workers — Unit Tests
 *
 * Covers:
 *   trustTokenHygieneHandler
 *     — no stale tokens (0 deleted)
 *     — stale tokens found (batch delete, correct count)
 *     — more than 500 docs (multiple batches)
 *
 *   trustQuietHoursCleanupHandler
 *     — no stuck entries (no-ops)
 *     — stuck entries → routeNotification called with quietHoursBypass: true
 *     — processed entries marked quiet_held_released
 *     — doc missing event payload → counted as error, not re-dispatched
 *     — routeNotification error → counted as error, run continues
 *
 * Run: npx jest test/workers.test.js --verbose
 */

// ── Shared mock state ─────────────────────────────────────────────────────────

let mockDb;

// Spies reassigned in makeMockDb; exposed for assertion
let batchDeleteSpy;
let batchCommitSpy;
let colQueryGetSpy;
let docUpdateSpy;

// ── Mock: firebase-admin ──────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  const serverTimestamp = jest.fn(() => ({ _sentinel: 'SERVER_TIMESTAMP' }));
  const fromDate        = jest.fn((d) => ({ _ts: d.toISOString() }));
  const FieldValue      = { serverTimestamp };
  const Timestamp       = { fromDate };

  function mockFirestoreFn() { return mockDb; }
  mockFirestoreFn.FieldValue = FieldValue;
  mockFirestoreFn.Timestamp  = Timestamp;

  return { firestore: mockFirestoreFn };
});

// ── Mock: router ──────────────────────────────────────────────────────────────

jest.mock('../notifications/trust/router', () => ({
  routeNotification: jest.fn(),
}));

// ── Module under test ─────────────────────────────────────────────────────────

const {
  trustTokenHygieneHandler,
  trustQuietHoursCleanupHandler,
} = require('../notifications/trust/workers');

const { routeNotification } = require('../notifications/trust/router');

// ── Fixtures ──────────────────────────────────────────────────────────────────

function makeEvent(overrides = {}) {
  return Object.assign({
    eventId:         'evt_001',
    eventType:       'host_checkin_due',
    recipientUserId: 'user_abc',
    sourceId:        'game_g1',
    data:            { course_name: 'Pebble Beach' },
    quietHoursBypass: false,
  }, overrides);
}

function makeLogDoc(overrides = {}) {
  const base = {
    status:          'quiet_held',
    eventType:       'host_checkin_due',
    recipientUserId: 'user_abc',
    sourceId:        'game_g1',
    eventId:         'evt_001',
    releaseAt:       { _ts: new Date(Date.now() - 10 * 60 * 1000).toISOString() },
    event:           makeEvent(),
  };
  return Object.assign(base, overrides);
}

// ── Mock DB builder (hygiene) ─────────────────────────────────────────────────

/**
 * Builds a minimal Firestore mock for trustTokenHygieneHandler.
 *
 * @param {object[]} deviceDocs - array of device doc stubs returned by collectionGroup query
 */
function makeHygieneDb(deviceDocs = []) {
  batchDeleteSpy = jest.fn();
  batchCommitSpy = jest.fn().mockResolvedValue(undefined);

  const db = {
    collectionGroup: (name) => {
      expect(name).toBe('devices');
      return {
        where: (field, op, val) => ({
          get: jest.fn().mockResolvedValue({ docs: deviceDocs }),
        }),
      };
    },
    batch: () => ({
      delete: batchDeleteSpy,
      commit: batchCommitSpy,
    }),
  };
  return db;
}

// ── Mock DB builder (cleanup) ─────────────────────────────────────────────────

/**
 * Builds a minimal Firestore mock for trustQuietHoursCleanupHandler.
 *
 * @param {object[]} logDocs - array of notificationLog doc stubs returned by query
 */
function makeCleanupDb(logDocs = []) {
  docUpdateSpy = jest.fn().mockResolvedValue(undefined);

  const queryDocs = logDocs.map((d, i) => ({
    id:   `log_doc_${i}`,
    data: () => d,
    ref:  { update: docUpdateSpy },
  }));

  colQueryGetSpy = jest.fn().mockResolvedValue({ docs: queryDocs });

  const db = {
    collection: (colName) => {
      expect(colName).toBe('notificationLog');
      return {
        where: () => ({
          where: () => ({
            get: colQueryGetSpy,
          }),
        }),
      };
    },
  };
  return db;
}

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });
});

// ── trustTokenHygieneHandler ──────────────────────────────────────────────────

describe('trustTokenHygieneHandler', () => {
  it('returns 0 deleted when no stale device docs exist', async () => {
    const db = makeHygieneDb([]);
    const result = await trustTokenHygieneHandler(db);

    expect(result.scanned).toBe(0);
    expect(result.deleted).toBe(0);
    expect(batchCommitSpy).not.toHaveBeenCalled();
    expect(result.cutoff).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  it('deletes stale device docs and returns correct count', async () => {
    const fakeDocs = [
      { ref: { path: 'users/u1/devices/d1' } },
      { ref: { path: 'users/u2/devices/d2' } },
      { ref: { path: 'users/u3/devices/d3' } },
    ];
    const db = makeHygieneDb(fakeDocs);

    const result = await trustTokenHygieneHandler(db);

    expect(result.scanned).toBe(3);
    expect(result.deleted).toBe(3);
    expect(batchCommitSpy).toHaveBeenCalledTimes(1);
    expect(batchDeleteSpy).toHaveBeenCalledTimes(3);
    fakeDocs.forEach((doc) => {
      expect(batchDeleteSpy).toHaveBeenCalledWith(doc.ref);
    });
  });

  it('uses multiple batches when doc count exceeds 500', async () => {
    // 501 docs → 2 batches (500 + 1)
    const fakeDocs = Array.from({ length: 501 }, (_, i) => ({
      ref: { path: `users/u${i}/devices/d${i}` },
    }));
    const db = makeHygieneDb(fakeDocs);

    const result = await trustTokenHygieneHandler(db);

    expect(result.scanned).toBe(501);
    expect(result.deleted).toBe(501);
    expect(batchCommitSpy).toHaveBeenCalledTimes(2);
  });

  it('passes a Timestamp cutoff 90 days in the past to the query', async () => {
    const admin = require('firebase-admin');
    const db = makeHygieneDb([]);

    await trustTokenHygieneHandler(db);

    expect(admin.firestore.Timestamp.fromDate).toHaveBeenCalledTimes(1);
    const cutoffDate = admin.firestore.Timestamp.fromDate.mock.calls[0][0];
    const expectedCutoffApprox = Date.now() - 90 * 24 * 60 * 60 * 1000;
    expect(Math.abs(cutoffDate.getTime() - expectedCutoffApprox)).toBeLessThan(5000);
  });
});

// ── trustQuietHoursCleanupHandler ─────────────────────────────────────────────

describe('trustQuietHoursCleanupHandler', () => {
  it('returns zero counts and does nothing when no stuck entries exist', async () => {
    const db = makeCleanupDb([]);
    const result = await trustQuietHoursCleanupHandler(db);

    expect(result.found).toBe(0);
    expect(result.requeued).toBe(0);
    expect(result.errors).toBe(0);
    expect(routeNotification).not.toHaveBeenCalled();
  });

  it('calls routeNotification with quietHoursBypass: true for each stuck entry', async () => {
    const event1 = makeEvent({ eventId: 'evt_001' });
    const event2 = makeEvent({ eventId: 'evt_002' });
    const db = makeCleanupDb([
      makeLogDoc({ event: event1 }),
      makeLogDoc({ event: event2 }),
    ]);

    const result = await trustQuietHoursCleanupHandler(db);

    expect(result.found).toBe(2);
    expect(result.requeued).toBe(2);
    expect(result.errors).toBe(0);

    expect(routeNotification).toHaveBeenCalledTimes(2);
    expect(routeNotification).toHaveBeenCalledWith(
      expect.objectContaining({ eventId: 'evt_001', quietHoursBypass: true }),
      db,
    );
    expect(routeNotification).toHaveBeenCalledWith(
      expect.objectContaining({ eventId: 'evt_002', quietHoursBypass: true }),
      db,
    );
  });

  it('does not override other event fields when adding quietHoursBypass', async () => {
    const event = makeEvent({ gameId: 'game_xyz', data: { course_name: 'Augusta' } });
    const db = makeCleanupDb([makeLogDoc({ event })]);

    await trustQuietHoursCleanupHandler(db);

    const calledWith = routeNotification.mock.calls[0][0];
    expect(calledWith.gameId).toBe('game_xyz');
    expect(calledWith.data).toEqual({ course_name: 'Augusta' });
    expect(calledWith.quietHoursBypass).toBe(true);
  });

  it('marks each processed entry as quiet_held_released', async () => {
    const db = makeCleanupDb([makeLogDoc(), makeLogDoc()]);

    await trustQuietHoursCleanupHandler(db);

    expect(docUpdateSpy).toHaveBeenCalledTimes(2);
    expect(docUpdateSpy).toHaveBeenCalledWith({ status: 'quiet_held_released' });
  });

  it('counts doc with missing event payload as error and skips re-dispatch', async () => {
    const docWithNoEvent = makeLogDoc({ event: undefined });
    const db = makeCleanupDb([docWithNoEvent]);

    const result = await trustQuietHoursCleanupHandler(db);

    expect(result.found).toBe(1);
    expect(result.requeued).toBe(0);
    expect(result.errors).toBe(1);
    expect(routeNotification).not.toHaveBeenCalled();
    expect(docUpdateSpy).not.toHaveBeenCalled();
  });

  it('counts routeNotification error as error and continues processing remaining docs', async () => {
    const event1 = makeEvent({ eventId: 'evt_fail' });
    const event2 = makeEvent({ eventId: 'evt_ok' });

    routeNotification
      .mockRejectedValueOnce(new Error('FCM error'))
      .mockResolvedValueOnce({ result: 'sent', sentCount: 1 });

    const db = makeCleanupDb([
      makeLogDoc({ event: event1 }),
      makeLogDoc({ event: event2 }),
    ]);

    const result = await trustQuietHoursCleanupHandler(db);

    expect(result.found).toBe(2);
    expect(result.requeued).toBe(1);
    expect(result.errors).toBe(1);

    // Second doc still processed
    expect(routeNotification).toHaveBeenCalledTimes(2);
    // Only the successful doc gets status update
    expect(docUpdateSpy).toHaveBeenCalledTimes(1);
    expect(docUpdateSpy).toHaveBeenCalledWith({ status: 'quiet_held_released' });
  });

  it('passes a Timestamp threshold 5 minutes in the past to the query', async () => {
    const admin = require('firebase-admin');
    const db = makeCleanupDb([]);

    await trustQuietHoursCleanupHandler(db);

    expect(admin.firestore.Timestamp.fromDate).toHaveBeenCalledTimes(1);
    const thresholdDate = admin.firestore.Timestamp.fromDate.mock.calls[0][0];
    const expectedApprox = Date.now() - 5 * 60 * 1000;
    expect(Math.abs(thresholdDate.getTime() - expectedApprox)).toBeLessThan(5000);
  });
});
