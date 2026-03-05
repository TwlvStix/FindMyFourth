'use strict';

/**
 * Signup Confirmation Email Callable — Unit Tests
 *
 * Tests the sendSignupConfirmationEmail callable function:
 *   - Sends welcome email to new users
 *   - Uses transactional idempotency to prevent duplicates
 *   - Returns appropriate status codes
 *
 * Run: npx jest test/signup-email.test.js --verbose
 */

// ── Mock state ─────────────────────────────────────────────────────────────────

let mockGetUser;
let mockFirestoreGet;
let mockFirestoreSet;
let mockRunTransaction;
let mockSendGridSend;
let mockHttpsError;

// Track transaction state for concurrent tests
let transactionMarkerState = {};

// ── Mock firebase-admin ────────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  const firestoreMock = jest.fn(() => ({
    doc: jest.fn((path) => ({
      path, // Include path so tx.get can extract uid
      get: () => mockFirestoreGet(path),
      set: (...args) => mockFirestoreSet(path, ...args),
    })),
    runTransaction: (callback) => mockRunTransaction(callback),
  }));
  firestoreMock.FieldValue = {
    serverTimestamp: jest.fn(() => ({ _sentinel: 'SERVER_TIMESTAMP' })),
  };
  return {
    initializeApp: jest.fn(),
    firestore: firestoreMock,
    auth: jest.fn(() => ({
      getUser: (uid) => mockGetUser(uid),
    })),
  };
});

// ── Mock firebase-functions ────────────────────────────────────────────────────

jest.mock('firebase-functions', () => {
  return {
    region: jest.fn(() => ({
      runWith: jest.fn(() => ({
        https: {
          onCall: jest.fn((handler) => handler),
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

// ── Mock @sendgrid/mail ────────────────────────────────────────────────────────

jest.mock('@sendgrid/mail', () => ({
  setApiKey: jest.fn(),
  send: (...args) => mockSendGridSend(...args),
}));

// ── Mock other dependencies ────────────────────────────────────────────────────

jest.mock('@google-cloud/tasks', () => ({
  CloudTasksClient: jest.fn(() => ({
    createTask: jest.fn().mockResolvedValue([{ name: 'task/1' }]),
    queuePath: jest.fn(() => 'queue/path'),
  })),
}));

// ── Implementation under test ──────────────────────────────────────────────────

/**
 * Implementation that mirrors sendSignupConfirmationEmail in index.js.
 */
async function sendSignupConfirmationEmail(data, context) {
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');
  const sgMail = require('@sendgrid/mail');

  // 1. Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to request signup email.',
    );
  }
  const uid = context.auth.uid;

  // 2. Resolve email (Auth → private/info fallback)
  let email;
  try {
    const authUser = await admin.auth().getUser(uid);
    email = authUser.email;
  } catch (authError) {
    console.error(`sendSignupConfirmationEmail: Failed to get auth user ${uid}:`, authError);
    throw new functions.https.HttpsError('internal', 'Failed to resolve user email');
  }

  if (!email) {
    // Fallback to private profile email
    const privateDoc = await admin.firestore().doc(`users/${uid}/private/info`).get();
    email = privateDoc.data()?.email;
  }

  if (!email) {
    console.log(`sendSignupConfirmationEmail: No email found for user ${uid}`);
    return { status: 'skipped_no_email' };
  }

  // 3. Transactional idempotency check
  const db = admin.firestore();
  const userRef = db.doc(`users/${uid}`);
  let shouldSend = false;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (userDoc.data()?.signup_email_sent_at) {
      shouldSend = false;
      return;
    }
    // Set marker atomically before sending
    tx.set(
      userRef,
      { signup_email_sent_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    shouldSend = true;
  });

  if (!shouldSend) {
    console.log(`sendSignupConfirmationEmail: Already sent for user ${uid}`);
    return { status: 'skipped_already_sent' };
  }

  // 4. Send email (outside transaction)
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);

  const msg = {
    to: email,
    from: 'findmyfourth@gmail.com',
    subject: 'Welcome to Find My Fourth!',
    text: 'Welcome to Find My Fourth!',
    html: '<p>Welcome to <strong>Find My Fourth</strong>!</p>',
  };

  try {
    await sgMail.send(msg);
    console.log(`sendSignupConfirmationEmail: Welcome email sent to ${email} (uid: ${uid})`);
    return { status: 'sent' };
  } catch (error) {
    console.error(`sendSignupConfirmationEmail: Error sending to ${uid}:`, error);
    return { status: 'send_failed' };
  }
}

// ── Shared setup ───────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockHttpsError = jest.fn();
  transactionMarkerState = {};

  // Default mocks
  mockGetUser = jest.fn().mockResolvedValue({ email: 'test@example.com' });
  mockSendGridSend = jest.fn().mockResolvedValue([{}]);

  // Default Firestore get (no marker set)
  mockFirestoreGet = jest.fn().mockImplementation((path) => {
    if (path.includes('/private/info')) {
      return Promise.resolve({
        exists: true,
        data: () => ({ email: 'fallback@example.com' }),
      });
    }
    return Promise.resolve({
      exists: true,
      data: () => ({}),
    });
  });

  // Default Firestore set
  mockFirestoreSet = jest.fn().mockResolvedValue({});

  // Default transaction implementation with proper isolation
  // Uses a simple mutex to simulate transaction serialization
  let transactionLock = Promise.resolve();

  mockRunTransaction = jest.fn().mockImplementation(async (callback) => {
    // Wait for any pending transaction to complete (serialization)
    const previousLock = transactionLock;
    let releaseLock;
    transactionLock = new Promise((resolve) => {
      releaseLock = resolve;
    });

    await previousLock;

    try {
      // Create a mock transaction object
      const tx = {
        get: jest.fn().mockImplementation((ref) => {
          // Check if marker was already set by another transaction
          const path = typeof ref === 'string' ? ref : ref.path || 'users/test';
          const uid = path.split('/')[1];
          return Promise.resolve({
            exists: true,
            data: () => transactionMarkerState[uid] || {},
          });
        }),
        set: jest.fn().mockImplementation((ref, data, options) => {
          // Simulate setting the marker
          const path = typeof ref === 'string' ? ref : ref.path || 'users/test';
          const uid = path.split('/')[1];
          if (data.signup_email_sent_at) {
            transactionMarkerState[uid] = { signup_email_sent_at: true };
          }
        }),
      };
      return await callback(tx);
    } finally {
      releaseLock();
    }
  });
});

// ════════════════════════════════════════════════════════════════════════════
// sendSignupConfirmationEmail
// ════════════════════════════════════════════════════════════════════════════

describe('sendSignupConfirmationEmail', () => {
  describe('authentication', () => {
    test('throws unauthenticated when context.auth is missing', async () => {
      await expect(
        sendSignupConfirmationEmail({}, {}),
      ).rejects.toThrow('User must be authenticated to request signup email.');

      expect(mockHttpsError).toHaveBeenCalledWith(
        'unauthenticated',
        'User must be authenticated to request signup email.',
      );
    });

    test('throws unauthenticated when context.auth is null', async () => {
      await expect(
        sendSignupConfirmationEmail({}, { auth: null }),
      ).rejects.toThrow('User must be authenticated to request signup email.');
    });
  });

  describe('email resolution', () => {
    test('uses Firebase Auth email when present', async () => {
      mockGetUser.mockResolvedValue({ email: 'auth@example.com' });

      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'sent' });
      expect(mockGetUser).toHaveBeenCalledWith('user123');
      expect(mockSendGridSend).toHaveBeenCalledWith(
        expect.objectContaining({ to: 'auth@example.com' }),
      );
    });

    test('falls back to private profile email when Auth email is null', async () => {
      mockGetUser.mockResolvedValue({ email: null });
      mockFirestoreGet.mockImplementation((path) => {
        if (path === 'users/user123/private/info') {
          return Promise.resolve({
            exists: true,
            data: () => ({ email: 'private@example.com' }),
          });
        }
        return Promise.resolve({ exists: true, data: () => ({}) });
      });

      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'sent' });
      expect(mockSendGridSend).toHaveBeenCalledWith(
        expect.objectContaining({ to: 'private@example.com' }),
      );
    });

    test('returns skipped_no_email when no email found anywhere', async () => {
      mockGetUser.mockResolvedValue({ email: null });
      mockFirestoreGet.mockImplementation((path) => {
        if (path.includes('/private/info')) {
          return Promise.resolve({
            exists: true,
            data: () => ({}), // No email
          });
        }
        return Promise.resolve({ exists: true, data: () => ({}) });
      });

      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'skipped_no_email' });
      expect(mockSendGridSend).not.toHaveBeenCalled();
    });
  });

  describe('idempotency', () => {
    test('sends email on first call and sets marker', async () => {
      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'sent' });
      expect(mockRunTransaction).toHaveBeenCalled();
      expect(mockSendGridSend).toHaveBeenCalledTimes(1);
    });

    test('returns skipped_already_sent when marker exists', async () => {
      // Set marker before call
      transactionMarkerState['user123'] = { signup_email_sent_at: true };

      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'skipped_already_sent' });
      expect(mockSendGridSend).not.toHaveBeenCalled();
    });

    test('handles sequential duplicate calls correctly', async () => {
      // First call - should send
      const result1 = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user456' } },
      );
      expect(result1).toEqual({ status: 'sent' });

      // Second call - marker should now exist
      const result2 = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user456' } },
      );
      expect(result2).toEqual({ status: 'skipped_already_sent' });

      expect(mockSendGridSend).toHaveBeenCalledTimes(1);
    });

    test('handles concurrent duplicate calls - exactly one email sent', async () => {
      // The default mockRunTransaction now properly serializes transactions,
      // so concurrent calls will be serialized and only the first will send.

      // Launch 3 concurrent calls
      const results = await Promise.all([
        sendSignupConfirmationEmail({}, { auth: { uid: 'concurrent-user' } }),
        sendSignupConfirmationEmail({}, { auth: { uid: 'concurrent-user' } }),
        sendSignupConfirmationEmail({}, { auth: { uid: 'concurrent-user' } }),
      ]);

      // Exactly 1 should return 'sent', others 'skipped_already_sent'
      const sentCount = results.filter((r) => r.status === 'sent').length;
      const skippedCount = results.filter((r) => r.status === 'skipped_already_sent').length;

      expect(sentCount).toBe(1);
      expect(skippedCount).toBe(2);
      expect(mockSendGridSend).toHaveBeenCalledTimes(1);
    });
  });

  describe('email sending', () => {
    test('returns sent on successful email delivery', async () => {
      mockSendGridSend.mockResolvedValue([{}]);

      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'sent' });
    });

    test('returns send_failed when SendGrid fails', async () => {
      mockSendGridSend.mockRejectedValue(new Error('SendGrid API error'));

      const result = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(result).toEqual({ status: 'send_failed' });
    });

    test('marker is set even when SendGrid fails (prevents retry spam)', async () => {
      mockSendGridSend.mockRejectedValue(new Error('SendGrid API error'));

      // First call - SendGrid fails but marker should be set
      const result1 = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'failuser' } },
      );
      expect(result1).toEqual({ status: 'send_failed' });

      // Second call - should skip because marker exists
      const result2 = await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'failuser' } },
      );
      expect(result2).toEqual({ status: 'skipped_already_sent' });

      // SendGrid should only have been called once
      expect(mockSendGridSend).toHaveBeenCalledTimes(1);
    });

    test('email contains correct welcome message', async () => {
      await sendSignupConfirmationEmail(
        {},
        { auth: { uid: 'user123' } },
      );

      expect(mockSendGridSend).toHaveBeenCalledWith(
        expect.objectContaining({
          from: 'findmyfourth@gmail.com',
          subject: 'Welcome to Find My Fourth!',
        }),
      );
    });
  });

  describe('error handling', () => {
    test('throws internal error when getUser fails', async () => {
      mockGetUser.mockRejectedValue(new Error('Auth service unavailable'));

      await expect(
        sendSignupConfirmationEmail({}, { auth: { uid: 'user123' } }),
      ).rejects.toThrow('Failed to resolve user email');

      expect(mockHttpsError).toHaveBeenCalledWith(
        'internal',
        'Failed to resolve user email',
      );
    });
  });
});
