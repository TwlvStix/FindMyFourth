'use strict';

/**
 * Trust System FCM Sender — Unit Tests
 *
 * Verifies that send() correctly:
 *   - Builds the Admin SDK Message with the right android + apns blocks
 *   - Returns success on a clean send
 *   - Returns tokenInvalid for unregistered/invalid token errors (no retry)
 *   - Returns failure immediately for invalid_arg and auth_error (no retry)
 *   - Retries up to 3 total attempts for rate-limit errors
 *   - Retries up to 5 total attempts for server errors
 *   - Returns latencyMs as a non-negative number
 *
 * Run: npx jest test/fcm-sender.test.js
 */

// ── Mock firebase-admin BEFORE requiring the module under test ────────────────
// mockSend is defined ONCE outside jest.mock so .mock.calls accumulates
// correctly across all retry attempts within a single test.

let mockSendResult = null;
let mockSendError  = null;

const mockSend = jest.fn(async () => {
  if (mockSendError) throw mockSendError;
  return mockSendResult;
});

jest.mock('firebase-admin', () => ({
  messaging: () => ({ send: mockSend }),
}));

const { send } = require('../notifications/trust/fcm-sender');

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Builds a minimal valid payload for each test. */
function makePayload(overrides) {
  return Object.assign({
    title:           'Test Title',
    body:            'Test body text.',
    deepLink:        'findmyfourth://trust/badge_earned/abc123',
    eventType:       'badge_earned',
    eventId:         'evt_001',
    priority:        'HIGH',
    threadId:        'trust-badges',
    androidChannelId:'important',
  }, overrides);
}

/** Creates an FCM-style error with the given code. */
function fcmError(code) {
  const err = new Error(`FCM error: ${code}`);
  err.code = code;
  return err;
}

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  // mockReset clears call history AND removes any mockImplementation set by previous tests
  mockSend.mockReset();
  mockSendResult = 'projects/test/messages/abc123';
  mockSendError  = null;
  // Restore the default implementation after reset
  mockSend.mockImplementation(async () => {
    if (mockSendError) throw mockSendError;
    return mockSendResult;
  });
});

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('send() — success', () => {

  test('returns success: true with deviceId and non-negative latencyMs', async () => {
    const result = await send('token_abc', 'device_1', makePayload(), 0);
    expect(result.success).toBe(true);
    expect(result.deviceId).toBe('device_1');
    expect(typeof result.latencyMs).toBe('number');
    expect(result.latencyMs).toBeGreaterThanOrEqual(0);
  });

  test('does not set errorCode or tokenInvalid on success', async () => {
    const result = await send('token_abc', 'device_1', makePayload(), 0);
    expect(result.errorCode).toBeUndefined();
    expect(result.tokenInvalid).toBeUndefined();
  });

  test('calls admin.messaging().send() exactly once on success', async () => {
    await send('token_abc', 'device_1', makePayload(), 0);
    expect(mockSend.mock.calls.length).toBe(1);
  });

});

describe('send() — message structure', () => {

  test('passes token, notification, data, android, and apns to FCM send', async () => {
    const payload = makePayload();
    await send('fcm_token_xyz', 'device_1', payload, 0);

    expect(mockSend.mock.calls.length).toBe(1);
    const msg = mockSend.mock.calls[0][0];

    // token
    expect(msg.token).toBe('fcm_token_xyz');

    // notification block
    expect(msg.notification.title).toBe(payload.title);
    expect(msg.notification.body).toBe(payload.body);

    // data block
    expect(msg.data.deep_link).toBe(payload.deepLink);
    expect(msg.data.event_type).toBe(payload.eventType);
    expect(msg.data.event_id).toBe(payload.eventId);

    // android block — HIGH priority maps to 'high'
    expect(msg.android.priority).toBe('high');
    expect(msg.android.notification.channelId).toBe(payload.androidChannelId);
    expect(msg.android.notification.sound).toBe('default');

    // apns block — HIGH priority maps to apns-priority '10'
    expect(msg.apns.headers['apns-priority']).toBe('10');
    expect(msg.apns.payload.aps['thread-id']).toBe(payload.threadId);
    expect(msg.apns.payload.aps['interruption-level']).toBe('active'); // HIGH
    expect(msg.apns.payload.aps.sound).toBe('default');
    expect(msg.apns.payload.aps['mutable-content']).toBe(1);
  });

  test('CRITICAL priority sets android high, apns-priority 10, interruption-level time-sensitive', async () => {
    await send('token_abc', 'device_1', makePayload({ priority: 'CRITICAL' }), 0);
    const msg = mockSend.mock.calls[0][0];
    expect(msg.android.priority).toBe('high');
    expect(msg.apns.headers['apns-priority']).toBe('10');
    expect(msg.apns.payload.aps['interruption-level']).toBe('time-sensitive');
  });

  test('DEFAULT priority sets android normal, apns-priority 5, interruption-level active', async () => {
    await send('token_abc', 'device_1', makePayload({ priority: 'DEFAULT' }), 0);
    const msg = mockSend.mock.calls[0][0];
    expect(msg.android.priority).toBe('normal');
    expect(msg.apns.headers['apns-priority']).toBe('5');
    expect(msg.apns.payload.aps['interruption-level']).toBe('active');
  });

  test('LOW priority sets android normal, apns-priority 1, interruption-level passive', async () => {
    await send('token_abc', 'device_1', makePayload({ priority: 'LOW' }), 0);
    const msg = mockSend.mock.calls[0][0];
    expect(msg.android.priority).toBe('normal');
    expect(msg.apns.headers['apns-priority']).toBe('1');
    expect(msg.apns.payload.aps['interruption-level']).toBe('passive');
  });

});

describe('send() — tokenInvalid errors (no retry)', () => {

  test('messaging/registration-token-not-registered → tokenInvalid: true, called once', async () => {
    mockSendError = fcmError('messaging/registration-token-not-registered');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(result.tokenInvalid).toBe(true);
    expect(result.errorCode).toBe('messaging/registration-token-not-registered');
    expect(mockSend.mock.calls.length).toBe(1);
  });

  test('messaging/invalid-registration-token → tokenInvalid: true, called once', async () => {
    mockSendError = fcmError('messaging/invalid-registration-token');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(result.tokenInvalid).toBe(true);
    expect(result.errorCode).toBe('messaging/invalid-registration-token');
    expect(mockSend.mock.calls.length).toBe(1);
  });

  test('tokenInvalid errors do not set success: true', async () => {
    mockSendError = fcmError('messaging/registration-token-not-registered');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);
    expect(result.success).toBe(false);
  });

});

describe('send() — no-retry errors', () => {

  test('messaging/invalid-argument → success: false, no tokenInvalid, called once', async () => {
    mockSendError = fcmError('messaging/invalid-argument');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(result.tokenInvalid).toBeUndefined();
    expect(result.errorCode).toBe('messaging/invalid-argument');
    expect(mockSend.mock.calls.length).toBe(1);
  });

  test('messaging/authentication-error → success: false, no tokenInvalid, called once', async () => {
    mockSendError = fcmError('messaging/authentication-error');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(result.tokenInvalid).toBeUndefined();
    expect(result.errorCode).toBe('messaging/authentication-error');
    expect(mockSend.mock.calls.length).toBe(1);
  });

  test('unknown error code → success: false, no tokenInvalid, called once', async () => {
    mockSendError = fcmError('messaging/some-unrecognised-error');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(result.tokenInvalid).toBeUndefined();
    expect(result.errorCode).toBe('messaging/some-unrecognised-error');
    expect(mockSend.mock.calls.length).toBe(1);
  });

});

describe('send() — rate-limit retry (3 total attempts)', () => {

  test('fails twice then succeeds → success: true, called 3 times', async () => {
    let callCount = 0;
    mockSend.mockImplementation(async () => {
      callCount++;
      if (callCount < 3) throw fcmError('messaging/message-rate-exceeded');
      return 'projects/test/messages/rate_ok';
    });

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(true);
    expect(mockSend.mock.calls.length).toBe(3);
  });

  test('fails all 3 attempts → success: false, called 3 times', async () => {
    mockSendError = fcmError('messaging/message-rate-exceeded');

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(mockSend.mock.calls.length).toBe(3);
  });

  test('messaging/too-many-requests also retries up to 3 times', async () => {
    mockSendError = fcmError('messaging/too-many-requests');

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(mockSend.mock.calls.length).toBe(3);
  });

});

describe('send() — server error retry (5 total attempts)', () => {

  test('fails 4 times then succeeds → success: true, called 5 times', async () => {
    let callCount = 0;
    mockSend.mockImplementation(async () => {
      callCount++;
      if (callCount < 5) throw fcmError('messaging/server-unavailable');
      return 'projects/test/messages/server_ok';
    });

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(true);
    expect(mockSend.mock.calls.length).toBe(5);
  });

  test('fails all 5 attempts → success: false, called 5 times', async () => {
    mockSendError = fcmError('messaging/server-unavailable');

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(mockSend.mock.calls.length).toBe(5);
  });

  test('messaging/internal-error also retries up to 5 times', async () => {
    mockSendError = fcmError('messaging/internal-error');

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(false);
    expect(mockSend.mock.calls.length).toBe(5);
  });

  test('fails 3 times then succeeds on 4th attempt → success: true, called 4 times', async () => {
    let callCount = 0;
    mockSend.mockImplementation(async () => {
      callCount++;
      if (callCount < 4) throw fcmError('messaging/internal-error');
      return 'projects/test/messages/internal_ok';
    });

    const result = await send('token_abc', 'device_1', makePayload(), 0);

    expect(result.success).toBe(true);
    expect(mockSend.mock.calls.length).toBe(4);
  });

});

describe('send() — return shape completeness', () => {

  test('success result has exactly: success, deviceId, latencyMs', async () => {
    const result = await send('token_abc', 'device_1', makePayload(), 0);
    expect(Object.keys(result).sort()).toEqual(['deviceId', 'latencyMs', 'success']);
  });

  test('failure result has at least: success, deviceId, errorCode, latencyMs', async () => {
    mockSendError = fcmError('messaging/invalid-argument');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);
    expect(result).toHaveProperty('success', false);
    expect(result).toHaveProperty('deviceId', 'device_1');
    expect(result).toHaveProperty('errorCode');
    expect(result).toHaveProperty('latencyMs');
  });

  test('tokenInvalid result has tokenInvalid: true plus standard fields', async () => {
    mockSendError = fcmError('messaging/registration-token-not-registered');
    const result  = await send('token_abc', 'device_1', makePayload(), 0);
    expect(result).toHaveProperty('tokenInvalid', true);
    expect(result).toHaveProperty('success', false);
    expect(result).toHaveProperty('deviceId', 'device_1');
    expect(result).toHaveProperty('errorCode');
    expect(result).toHaveProperty('latencyMs');
  });

});
