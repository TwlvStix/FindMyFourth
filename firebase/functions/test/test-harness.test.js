'use strict';

/**
 * Notification Test Harness — Unit Tests
 *
 * Covers both HTTPS Callable functions:
 *   sendTestNotification    — auth gate, eventType validation, router integration
 *   generateDeliveryReport  — auth gate, server/client correlation, gaps, latency
 *
 * Run: npx jest test/test-harness.test.js --verbose
 */

// ── Shared mock state ───────────────────────────────────────────────────────

let mockDb;
let mockLogDocs;
let mockReceiptDocs;

// ── firebase-admin mock ─────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  const serverTimestamp = jest.fn(() => ({ _sentinel: 'SERVER_TIMESTAMP' }));
  function mockFirestoreFn() { return mockDb; }
  mockFirestoreFn.FieldValue = { serverTimestamp };
  return {
    firestore: mockFirestoreFn,
    auth: jest.fn(() => ({
      verifyIdToken: jest.fn(),
    })),
  };
});

// ── firebase-functions/v1 mock ──────────────────────────────────────────────

jest.mock('firebase-functions/v1', () => {
  class HttpsError extends Error {
    constructor(code, message, details) {
      super(message);
      this.code = code;
      this.details = details;
    }
  }

  return {
    region: jest.fn(() => ({
      runWith: jest.fn(() => ({
        https: {
          onCall: jest.fn((handler) => handler),
        },
      })),
    })),
    https: {
      HttpsError,
    },
  };
});

// ── Router mock ─────────────────────────────────────────────────────────────

jest.mock('../notifications/trust/router', () => ({
  routeNotification: jest.fn(),
}));

// ── Module under test ───────────────────────────────────────────────────────

const { sendTestNotification, generateDeliveryReport } = require('../test_harness');
const { routeNotification } = require('../notifications/trust/router');
const { TrustEventType } = require('../notifications/trust/event-registry');

// ── Mock DB builder ─────────────────────────────────────────────────────────

function buildMockDb({ logDocs = [], receiptDocs = [] } = {}) {
  mockLogDocs = logDocs;
  mockReceiptDocs = receiptDocs;

  const makeSnap = (docs) => ({
    docs: docs.map((d, i) => ({
      id: d.id || `doc_${i}`,
      data: () => d,
      exists: true,
    })),
    size: docs.length,
    empty: docs.length === 0,
  });

  const chainable = (docs) => {
    const snap = makeSnap(docs);
    const q = {
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue(snap),
    };
    return q;
  };

  // Track which collection path is requested
  const db = {
    collection: jest.fn((path) => {
      if (path === 'notificationLog') {
        return chainable(logDocs);
      }
      if (path === 'users') {
        return {
          doc: jest.fn(() => ({
            collection: jest.fn((subPath) => {
              if (subPath === 'notification_receipts') {
                return chainable(receiptDocs);
              }
              return chainable([]);
            }),
          })),
        };
      }
      return chainable([]);
    }),
  };

  return db;
}

// ── Setup ───────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockDb = buildMockDb();
  routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });
});

// ════════════════════════════════════════════════════════════════════════════
// sendTestNotification
// ════════════════════════════════════════════════════════════════════════════

describe('sendTestNotification', () => {

  const validData = {
    eventType: TrustEventType.BADGE_EARNED,
    recipientUserId: 'user_abc',
  };

  const authContext = { auth: { uid: 'caller_123' } };
  const noAuthContext = {};

  test('rejects unauthenticated calls', async () => {
    await expect(sendTestNotification(validData, noAuthContext))
      .rejects.toThrow('Authentication required.');
  });

  test('rejects unauthenticated calls with correct error code', async () => {
    try {
      await sendTestNotification(validData, noAuthContext);
      fail('Should have thrown');
    } catch (err) {
      expect(err.code).toBe('unauthenticated');
    }
  });

  test('rejects invalid eventType', async () => {
    const data = { eventType: 'not_a_real_event', recipientUserId: 'user_abc' };
    await expect(sendTestNotification(data, authContext))
      .rejects.toThrow(/Invalid eventType/);
  });

  test('rejects missing eventType', async () => {
    const data = { recipientUserId: 'user_abc' };
    await expect(sendTestNotification(data, authContext))
      .rejects.toThrow(/Invalid eventType/);
  });

  test('rejects missing recipientUserId', async () => {
    const data = { eventType: TrustEventType.BADGE_EARNED };
    await expect(sendTestNotification(data, authContext))
      .rejects.toThrow(/recipientUserId is required/);
  });

  test('calls routeNotification with correct event structure', async () => {
    await sendTestNotification(validData, authContext);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    const [event, db] = routeNotification.mock.calls[0];

    expect(event.eventType).toBe(TrustEventType.BADGE_EARNED);
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.eventId).toMatch(/^test_badge_earned_/);
    expect(event.sourceId).toBeDefined();
    expect(event.data).toBeDefined();
    expect(event.isReminder).toBe(false);
    expect(db).toBe(mockDb);
  });

  test('event data includes default template variables', async () => {
    await sendTestNotification(validData, authContext);

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.badge_name).toBe('First Round');
    expect(event.data.rounds_count).toBe('5');
    expect(event.data.unique_players).toBe('10');
    expect(event.data.course_name).toBe('Test Course (Pine Valley)');
  });

  test('merges custom testData with defaults', async () => {
    const data = {
      ...validData,
      testData: {
        badge_name: 'Custom Badge',
        custom_field: 'custom_value',
      },
    };

    await sendTestNotification(data, authContext);

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.badge_name).toBe('Custom Badge');
    expect(event.data.custom_field).toBe('custom_value');
    // Defaults still present for non-overridden fields
    expect(event.data.rounds_count).toBe('5');
  });

  test('returns pipeline result', async () => {
    routeNotification.mockResolvedValue({
      result: 'sent',
      sentCount: 2,
      inAppWritten: true,
    });

    const result = await sendTestNotification(validData, authContext);

    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(2);
    expect(result.pipelineOutcome).toEqual({
      result: 'sent',
      sentCount: 2,
      inAppWritten: true,
    });
    expect(result.eventId).toMatch(/^test_badge_earned_/);
  });

  test('returns sentCount 0 when pipeline drops notification', async () => {
    routeNotification.mockResolvedValue({ result: 'deduped' });

    const result = await sendTestNotification(validData, authContext);

    expect(result.result).toBe('deduped');
    expect(result.sentCount).toBe(0);
  });

  // Test all event types can be invoked
  const allEventTypes = Object.values(TrustEventType);

  test.each(allEventTypes)('accepts event type: %s', async (eventType) => {
    const data = { eventType, recipientUserId: 'user_test' };
    await sendTestNotification(data, authContext);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe(eventType);
  });
});

// ════════════════════════════════════════════════════════════════════════════
// generateDeliveryReport
// ════════════════════════════════════════════════════════════════════════════

describe('generateDeliveryReport', () => {

  const authContext = { auth: { uid: 'caller_123' } };
  const noAuthContext = {};

  test('rejects unauthenticated calls', async () => {
    await expect(
      generateDeliveryReport({ userId: 'user_abc' }, noAuthContext),
    ).rejects.toThrow('Authentication required.');
  });

  test('rejects unauthenticated calls with correct error code', async () => {
    try {
      await generateDeliveryReport({ userId: 'user_abc' }, noAuthContext);
      fail('Should have thrown');
    } catch (err) {
      expect(err.code).toBe('unauthenticated');
    }
  });

  test('rejects missing userId', async () => {
    await expect(
      generateDeliveryReport({}, authContext),
    ).rejects.toThrow(/userId is required/);
  });

  test('correlates server sends with client receipts', async () => {
    const sentAt = new Date('2026-03-08T10:00:00Z');
    const receivedAt = new Date('2026-03-08T10:00:02Z');

    mockDb = buildMockDb({
      logDocs: [
        {
          id: 'log_1',
          eventId: 'evt_001',
          eventType: 'badge_earned',
          status: 'sent',
          recipientUserId: 'user_abc',
          timestamp: { toDate: () => sentAt },
        },
      ],
      receiptDocs: [
        {
          id: 'receipt_1',
          eventId: 'evt_001',
          deliveryState: 'foreground',
          receivedAt: { toDate: () => receivedAt },
        },
      ],
    });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.events).toHaveLength(1);
    expect(result.events[0].eventType).toBe('badge_earned');
    expect(result.events[0].serverStatus).toBe('sent');
    expect(result.events[0].clientStatus).toBe('foreground');
    expect(result.summary.totalSent).toBe(1);
    expect(result.summary.totalReceived).toBe(1);
    expect(result.summary.fgReceived).toBe(1);
    expect(result.summary.gaps).toBe(0);
    expect(result.gapDetails).toHaveLength(0);
  });

  test('identifies gaps (server sent but no client receipt)', async () => {
    const sentAt = new Date('2026-03-08T10:00:00Z');

    mockDb = buildMockDb({
      logDocs: [
        {
          id: 'log_1',
          eventId: 'evt_001',
          eventType: 'strike_issued',
          status: 'sent',
          recipientUserId: 'user_abc',
          timestamp: { toDate: () => sentAt },
        },
        {
          id: 'log_2',
          eventId: 'evt_002',
          eventType: 'badge_earned',
          status: 'sent',
          recipientUserId: 'user_abc',
          timestamp: { toDate: () => sentAt },
        },
      ],
      receiptDocs: [],
    });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.summary.totalSent).toBe(2);
    expect(result.summary.totalReceived).toBe(0);
    expect(result.summary.gaps).toBe(2);
    expect(result.gapDetails).toHaveLength(2);
    expect(result.gapDetails[0].status).toBe('missing_receipt');
    expect(result.gapDetails[0].eventType).toBe('strike_issued');
    expect(result.gapDetails[1].eventType).toBe('badge_earned');
  });

  test('does not count non-sent statuses as gaps', async () => {
    mockDb = buildMockDb({
      logDocs: [
        {
          id: 'log_1',
          eventId: 'evt_001',
          eventType: 'badge_earned',
          status: 'deduped',
          recipientUserId: 'user_abc',
          timestamp: { toDate: () => new Date() },
        },
      ],
      receiptDocs: [],
    });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.summary.totalSent).toBe(0);
    expect(result.summary.gaps).toBe(0);
    expect(result.gapDetails).toHaveLength(0);
  });

  test('respects since filter (passes to query)', async () => {
    // Build a db that tracks calls on its chainable methods
    const whereSpy = jest.fn().mockReturnThis();
    const orderBySpy = jest.fn().mockReturnThis();
    const limitSpy = jest.fn().mockReturnThis();
    const getSpy = jest.fn().mockResolvedValue({ docs: [], size: 0, empty: true });

    const trackedChainable = { where: whereSpy, orderBy: orderBySpy, limit: limitSpy, get: getSpy };

    mockDb = {
      collection: jest.fn((path) => {
        if (path === 'notificationLog') {
          return trackedChainable;
        }
        if (path === 'users') {
          return {
            doc: jest.fn(() => ({
              collection: jest.fn(() => ({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnThis(),
                get: jest.fn().mockResolvedValue({ docs: [], size: 0, empty: true }),
              })),
            })),
          };
        }
        return trackedChainable;
      }),
    };

    await generateDeliveryReport(
      { userId: 'user_abc', since: '2026-03-01T00:00:00Z' },
      authContext,
    );

    expect(mockDb.collection).toHaveBeenCalledWith('notificationLog');
    // When since is provided, an additional where clause for timestamp is added
    const timestampCalls = whereSpy.mock.calls.filter((c) => c[0] === 'timestamp');
    expect(timestampCalls.length).toBeGreaterThanOrEqual(1);
    expect(timestampCalls[0][1]).toBe('>=');
  });

  test('respects limit parameter', async () => {
    const limitSpy = jest.fn().mockReturnThis();
    const getSpy = jest.fn().mockResolvedValue({ docs: [], size: 0, empty: true });

    const trackedChainable = {
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: limitSpy,
      get: getSpy,
    };

    mockDb = {
      collection: jest.fn((path) => {
        if (path === 'notificationLog') {
          return trackedChainable;
        }
        if (path === 'users') {
          return {
            doc: jest.fn(() => ({
              collection: jest.fn(() => ({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnThis(),
                get: jest.fn().mockResolvedValue({ docs: [], size: 0, empty: true }),
              })),
            })),
          };
        }
        return trackedChainable;
      }),
    };

    await generateDeliveryReport(
      { userId: 'user_abc', limit: 10 },
      authContext,
    );

    expect(limitSpy).toHaveBeenCalledWith(10);
  });

  test('uses default limit of 100 when not specified', async () => {
    const limitSpy = jest.fn().mockReturnThis();
    const getSpy = jest.fn().mockResolvedValue({ docs: [], size: 0, empty: true });

    const trackedChainable = {
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: limitSpy,
      get: getSpy,
    };

    mockDb = {
      collection: jest.fn((path) => {
        if (path === 'notificationLog') {
          return trackedChainable;
        }
        if (path === 'users') {
          return {
            doc: jest.fn(() => ({
              collection: jest.fn(() => ({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnThis(),
                get: jest.fn().mockResolvedValue({ docs: [], size: 0, empty: true }),
              })),
            })),
          };
        }
        return trackedChainable;
      }),
    };

    await generateDeliveryReport(
      { userId: 'user_abc' },
      authContext,
    );

    expect(limitSpy).toHaveBeenCalledWith(100);
  });

  test('calculates latencyMs correctly', async () => {
    const sentAt = new Date('2026-03-08T10:00:00.000Z');
    const receivedAt = new Date('2026-03-08T10:00:03.500Z'); // 3500ms later

    mockDb = buildMockDb({
      logDocs: [
        {
          id: 'log_1',
          eventId: 'evt_001',
          eventType: 'badge_earned',
          status: 'sent',
          recipientUserId: 'user_abc',
          timestamp: { toDate: () => sentAt },
        },
      ],
      receiptDocs: [
        {
          id: 'receipt_1',
          eventId: 'evt_001',
          deliveryState: 'foreground',
          receivedAt: { toDate: () => receivedAt },
        },
      ],
    });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.events[0].latencyMs).toBe(3500);
  });

  test('latencyMs is null when receipt has no receivedAt', async () => {
    mockDb = buildMockDb({
      logDocs: [
        {
          id: 'log_1',
          eventId: 'evt_001',
          eventType: 'badge_earned',
          status: 'sent',
          recipientUserId: 'user_abc',
          timestamp: { toDate: () => new Date('2026-03-08T10:00:00Z') },
        },
      ],
      receiptDocs: [
        {
          id: 'receipt_1',
          eventId: 'evt_001',
          deliveryState: 'foreground',
          receivedAt: null,
        },
      ],
    });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.events[0].latencyMs).toBeNull();
  });

  test('counts delivery states correctly in summary', async () => {
    const ts = { toDate: () => new Date('2026-03-08T10:00:00Z') };

    mockDb = buildMockDb({
      logDocs: [
        { id: 'log_1', eventId: 'evt_001', eventType: 'a', status: 'sent', recipientUserId: 'u', timestamp: ts },
        { id: 'log_2', eventId: 'evt_002', eventType: 'b', status: 'sent', recipientUserId: 'u', timestamp: ts },
        { id: 'log_3', eventId: 'evt_003', eventType: 'c', status: 'sent', recipientUserId: 'u', timestamp: ts },
        { id: 'log_4', eventId: 'evt_004', eventType: 'd', status: 'sent', recipientUserId: 'u', timestamp: ts },
      ],
      receiptDocs: [
        { eventId: 'evt_001', deliveryState: 'foreground', receivedAt: ts },
        { eventId: 'evt_002', deliveryState: 'background', receivedAt: ts },
        { eventId: 'evt_003', deliveryState: 'cold_open', receivedAt: ts },
        // evt_004 has no receipt — gap
      ],
    });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.summary.totalSent).toBe(4);
    expect(result.summary.totalReceived).toBe(3);
    expect(result.summary.fgReceived).toBe(1);
    expect(result.summary.bgOpened).toBe(1);
    expect(result.summary.coldOpened).toBe(1);
    expect(result.summary.gaps).toBe(1);
  });

  test('returns empty report for user with no notifications', async () => {
    mockDb = buildMockDb({ logDocs: [], receiptDocs: [] });

    const result = await generateDeliveryReport({ userId: 'user_abc' }, authContext);

    expect(result.events).toHaveLength(0);
    expect(result.summary.totalSent).toBe(0);
    expect(result.summary.totalReceived).toBe(0);
    expect(result.summary.gaps).toBe(0);
    expect(result.gapDetails).toHaveLength(0);
  });
});
