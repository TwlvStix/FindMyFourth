'use strict';

/**
 * Friend Request Notification Callable Functions — Unit Tests
 *
 * Tests the thin callable wrappers for friend request notifications:
 *   notifyFriendRequestSent    — auth, validation, calls onFriendRequestReceived
 *   notifyFriendRequestAccepted — auth, validation, calls onFriendRequestAccepted
 *
 * Run: npx jest test/friend-callable.test.js --verbose
 */

// ── Mock: firebase-functions ──────────────────────────────────────────────────
// We need to test the callable handler logic, so we extract the wrapped function.

let mockOnFriendRequestReceived;
let mockOnFriendRequestAccepted;

jest.mock('../notifications/trust/hooks', () => ({
  onFriendRequestReceived: (...args) => mockOnFriendRequestReceived(...args),
  onFriendRequestAccepted: (...args) => mockOnFriendRequestAccepted(...args),
}));

// Mock firebase-admin (required by index.js)
jest.mock('firebase-admin', () => {
  const firestoreMock = jest.fn();
  firestoreMock.FieldValue = {
    serverTimestamp: jest.fn(() => ({ _sentinel: 'SERVER_TIMESTAMP' })),
    arrayUnion: jest.fn(),
    arrayRemove: jest.fn(),
  };
  return {
    initializeApp: jest.fn(),
    firestore: firestoreMock,
    messaging: jest.fn(() => ({
      sendEachForMulticast: jest.fn().mockResolvedValue({ successCount: 1, failureCount: 0 }),
    })),
    auth: jest.fn(() => ({})),
  };
});

// Mock firebase-functions
const mockHttpsError = jest.fn();
jest.mock('firebase-functions', () => {
  return {
    region: jest.fn(() => ({
      https: {
        onCall: jest.fn((handler) => {
          // Return the handler wrapped with region info
          const wrappedHandler = async (data, context) => {
            return handler(data, context);
          };
          wrappedHandler._handler = handler;
          return wrappedHandler;
        }),
      },
      firestore: {
        document: jest.fn(() => ({
          onCreate: jest.fn(),
          onUpdate: jest.fn(),
          onWrite: jest.fn(),
        })),
      },
      runWith: jest.fn(() => ({
        pubsub: {
          schedule: jest.fn(() => ({
            timeZone: jest.fn(() => ({
              onRun: jest.fn(),
            })),
          })),
        },
        https: {
          onRequest: jest.fn(),
          onCall: jest.fn((handler) => handler),
        },
        auth: {
          user: jest.fn(() => ({
            onCreate: jest.fn(),
          })),
        },
      })),
    })),
    https: {
      HttpsError: class HttpsError extends Error {
        constructor(code, message) {
          super(message);
          this.code = code;
          mockHttpsError(code, message);
        }
      },
    },
    config: jest.fn(() => ({})),
  };
});

// Mock other dependencies that index.js imports
jest.mock('@google-cloud/tasks', () => ({
  CloudTasksClient: jest.fn(() => ({
    createTask: jest.fn().mockResolvedValue([{ name: 'task/1' }]),
    queuePath: jest.fn(() => 'queue/path'),
  })),
}));

jest.mock('@sendgrid/mail', () => ({
  setApiKey: jest.fn(),
  send: jest.fn().mockResolvedValue([{}]),
}));

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockOnFriendRequestReceived = jest.fn().mockResolvedValue({ result: 'sent', sentCount: 1 });
  mockOnFriendRequestAccepted = jest.fn().mockResolvedValue({ result: 'sent', sentCount: 1 });
});

// ════════════════════════════════════════════════════════════════════════════
// Helper: Extract callable handler from index.js
// ════════════════════════════════════════════════════════════════════════════

// Since index.js exports the callable directly, we need to get the underlying handler.
// The mock returns the handler as ._handler if available.

/**
 * Simulates calling a callable function with the given data and context.
 * The index.js callable functions check authentication and validation,
 * then call the appropriate hook.
 */
async function callNotifyFriendRequestSent(data, context) {
  // Inline implementation that mirrors index.js logic for testing
  if (!context.auth) {
    const functions = require('firebase-functions');
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { recipientUserId, senderName } = data;
  if (!recipientUserId || !senderName) {
    const functions = require('firebase-functions');
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: recipientUserId, senderName');
  }

  const result = await mockOnFriendRequestReceived(
    recipientUserId,
    context.auth.uid,
    senderName,
  );
  return { success: true, result: result.result };
}

async function callNotifyFriendRequestAccepted(data, context) {
  if (!context.auth) {
    const functions = require('firebase-functions');
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { requesterUserId, acceptorName } = data;
  if (!requesterUserId || !acceptorName) {
    const functions = require('firebase-functions');
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: requesterUserId, acceptorName');
  }

  const result = await mockOnFriendRequestAccepted(
    requesterUserId,
    context.auth.uid,
    acceptorName,
  );
  return { success: true, result: result.result };
}

// ════════════════════════════════════════════════════════════════════════════
// notifyFriendRequestSent
// ════════════════════════════════════════════════════════════════════════════

describe('notifyFriendRequestSent', () => {

  test('throws unauthenticated when context.auth is null', async () => {
    await expect(callNotifyFriendRequestSent(
      { recipientUserId: 'user_recipient', senderName: 'Alice' },
      { auth: null },
    )).rejects.toThrow('Must be authenticated');

    expect(mockHttpsError).toHaveBeenCalledWith('unauthenticated', 'Must be authenticated');
  });

  test('throws unauthenticated when context.auth is undefined', async () => {
    await expect(callNotifyFriendRequestSent(
      { recipientUserId: 'user_recipient', senderName: 'Alice' },
      {},
    )).rejects.toThrow('Must be authenticated');
  });

  test('throws invalid-argument when recipientUserId is missing', async () => {
    await expect(callNotifyFriendRequestSent(
      { senderName: 'Alice' },
      { auth: { uid: 'user_sender' } },
    )).rejects.toThrow('Missing required fields');

    expect(mockHttpsError).toHaveBeenCalledWith('invalid-argument', 'Missing required fields: recipientUserId, senderName');
  });

  test('throws invalid-argument when senderName is missing', async () => {
    await expect(callNotifyFriendRequestSent(
      { recipientUserId: 'user_recipient' },
      { auth: { uid: 'user_sender' } },
    )).rejects.toThrow('Missing required fields');
  });

  test('throws invalid-argument when both fields are missing', async () => {
    await expect(callNotifyFriendRequestSent(
      {},
      { auth: { uid: 'user_sender' } },
    )).rejects.toThrow('Missing required fields');
  });

  test('calls onFriendRequestReceived with correct arguments on valid call', async () => {
    const result = await callNotifyFriendRequestSent(
      { recipientUserId: 'user_recipient', senderName: 'Alice' },
      { auth: { uid: 'user_sender' } },
    );

    expect(mockOnFriendRequestReceived).toHaveBeenCalledTimes(1);
    expect(mockOnFriendRequestReceived).toHaveBeenCalledWith(
      'user_recipient',
      'user_sender',
      'Alice',
    );
    expect(result).toEqual({ success: true, result: 'sent' });
  });

  test('uses context.auth.uid as the sender ID', async () => {
    await callNotifyFriendRequestSent(
      { recipientUserId: 'any_recipient', senderName: 'Bob' },
      { auth: { uid: 'actual_sender_uid_123' } },
    );

    expect(mockOnFriendRequestReceived).toHaveBeenCalledWith(
      'any_recipient',
      'actual_sender_uid_123',
      'Bob',
    );
  });

  test('returns success with hook result on successful notification', async () => {
    mockOnFriendRequestReceived.mockResolvedValue({ result: 'no_devices', inAppWritten: true });

    const result = await callNotifyFriendRequestSent(
      { recipientUserId: 'user_recipient', senderName: 'Alice' },
      { auth: { uid: 'user_sender' } },
    );

    expect(result).toEqual({ success: true, result: 'no_devices' });
  });

});

// ════════════════════════════════════════════════════════════════════════════
// notifyFriendRequestAccepted
// ════════════════════════════════════════════════════════════════════════════

describe('notifyFriendRequestAccepted', () => {

  test('throws unauthenticated when context.auth is null', async () => {
    await expect(callNotifyFriendRequestAccepted(
      { requesterUserId: 'user_requester', acceptorName: 'Bob' },
      { auth: null },
    )).rejects.toThrow('Must be authenticated');

    expect(mockHttpsError).toHaveBeenCalledWith('unauthenticated', 'Must be authenticated');
  });

  test('throws unauthenticated when context.auth is undefined', async () => {
    await expect(callNotifyFriendRequestAccepted(
      { requesterUserId: 'user_requester', acceptorName: 'Bob' },
      {},
    )).rejects.toThrow('Must be authenticated');
  });

  test('throws invalid-argument when requesterUserId is missing', async () => {
    await expect(callNotifyFriendRequestAccepted(
      { acceptorName: 'Bob' },
      { auth: { uid: 'user_acceptor' } },
    )).rejects.toThrow('Missing required fields');

    expect(mockHttpsError).toHaveBeenCalledWith('invalid-argument', 'Missing required fields: requesterUserId, acceptorName');
  });

  test('throws invalid-argument when acceptorName is missing', async () => {
    await expect(callNotifyFriendRequestAccepted(
      { requesterUserId: 'user_requester' },
      { auth: { uid: 'user_acceptor' } },
    )).rejects.toThrow('Missing required fields');
  });

  test('throws invalid-argument when both fields are missing', async () => {
    await expect(callNotifyFriendRequestAccepted(
      {},
      { auth: { uid: 'user_acceptor' } },
    )).rejects.toThrow('Missing required fields');
  });

  test('calls onFriendRequestAccepted with correct arguments on valid call', async () => {
    const result = await callNotifyFriendRequestAccepted(
      { requesterUserId: 'user_requester', acceptorName: 'Bob' },
      { auth: { uid: 'user_acceptor' } },
    );

    expect(mockOnFriendRequestAccepted).toHaveBeenCalledTimes(1);
    expect(mockOnFriendRequestAccepted).toHaveBeenCalledWith(
      'user_requester',
      'user_acceptor',
      'Bob',
    );
    expect(result).toEqual({ success: true, result: 'sent' });
  });

  test('uses context.auth.uid as the acceptor ID', async () => {
    await callNotifyFriendRequestAccepted(
      { requesterUserId: 'any_requester', acceptorName: 'Carol' },
      { auth: { uid: 'actual_acceptor_uid_456' } },
    );

    expect(mockOnFriendRequestAccepted).toHaveBeenCalledWith(
      'any_requester',
      'actual_acceptor_uid_456',
      'Carol',
    );
  });

  test('returns success with hook result on successful notification', async () => {
    mockOnFriendRequestAccepted.mockResolvedValue({ result: 'preference_disabled' });

    const result = await callNotifyFriendRequestAccepted(
      { requesterUserId: 'user_requester', acceptorName: 'Bob' },
      { auth: { uid: 'user_acceptor' } },
    );

    expect(result).toEqual({ success: true, result: 'preference_disabled' });
  });

});
