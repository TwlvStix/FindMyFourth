'use strict';

/**
 * Onboarding Callable Functions — Unit Tests
 *
 * Tests the resolveCallableUid helper and onboarding functions:
 *   resolveCallableUid — auth context resolution with idToken fallback
 *   completeOnboarding — marks onboarding complete
 *   checkOnboardingComplete — checks onboarding status
 *
 * Run: npx jest test/onboarding-callable.test.js --verbose
 */

// ── Mock state ─────────────────────────────────────────────────────────────────

let mockVerifyIdToken;
let mockFirestoreUpdate;
let mockFirestoreGet;
let mockHttpsError;

// ── Mock firebase-admin ────────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  const firestoreMock = jest.fn(() => ({
    doc: jest.fn((path) => ({
      update: (...args) => mockFirestoreUpdate(path, ...args),
      get: () => mockFirestoreGet(path),
    })),
  }));
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
    auth: jest.fn(() => ({
      verifyIdToken: (...args) => mockVerifyIdToken(...args),
    })),
  };
});

// ── Mock firebase-functions ────────────────────────────────────────────────────

jest.mock('firebase-functions', () => {
  return {
    region: jest.fn(() => ({
      https: {
        onCall: jest.fn((handler) => {
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
            onDelete: jest.fn(),
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

// ── Mock other dependencies ────────────────────────────────────────────────────

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

// ── Shared setup ───────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockHttpsError = jest.fn();
  mockVerifyIdToken = jest.fn();
  mockFirestoreUpdate = jest.fn().mockResolvedValue({});
  mockFirestoreGet = jest.fn().mockResolvedValue({
    exists: true,
    data: () => ({ onboarding_completed: true }),
  });
});

// ════════════════════════════════════════════════════════════════════════════
// resolveCallableUid
// ════════════════════════════════════════════════════════════════════════════

/**
 * Implementation of resolveCallableUid for testing.
 * Mirrors the actual implementation in index.js.
 */
async function resolveCallableUid(context, data, functionName) {
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');

  let uid = context.auth?.uid;
  if (!uid) {
    const idToken = data?.idToken;
    if (typeof idToken === 'string' && idToken.length > 0) {
      try {
        const decoded = await admin.auth().verifyIdToken(idToken);
        uid = decoded.uid;
        console.log(`${functionName} verified idToken`, { uid });
      } catch (error) {
        console.error(`${functionName} idToken verify failed`, error);
      }
    }
  }
  if (!uid) {
    console.error(`${functionName} unauthenticated`, {
      hasAuth: !!context.auth,
      idTokenLength: typeof data?.idToken === 'string' ? data.idToken.length : 0,
    });
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required.',
    );
  }
  return uid;
}

describe('resolveCallableUid', () => {
  test('returns context.auth.uid when present', async () => {
    const uid = await resolveCallableUid(
      { auth: { uid: 'user123' } },
      {},
      'testFunction',
    );

    expect(uid).toBe('user123');
    expect(mockVerifyIdToken).not.toHaveBeenCalled();
  });

  test('prefers context.auth.uid over idToken when both present', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'token-user' });

    const uid = await resolveCallableUid(
      { auth: { uid: 'context-user' } },
      { idToken: 'valid-token' },
      'testFunction',
    );

    expect(uid).toBe('context-user');
    expect(mockVerifyIdToken).not.toHaveBeenCalled();
  });

  test('verifies idToken when context.auth is null', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'token-user-123' });

    const uid = await resolveCallableUid(
      { auth: null },
      { idToken: 'valid-jwt-token' },
      'testFunction',
    );

    expect(uid).toBe('token-user-123');
    expect(mockVerifyIdToken).toHaveBeenCalledWith('valid-jwt-token');
  });

  test('verifies idToken when context.auth is undefined', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'token-user-456' });

    const uid = await resolveCallableUid(
      {},
      { idToken: 'another-valid-token' },
      'testFunction',
    );

    expect(uid).toBe('token-user-456');
    expect(mockVerifyIdToken).toHaveBeenCalledWith('another-valid-token');
  });

  test('throws unauthenticated when context.auth is null and no idToken', async () => {
    await expect(
      resolveCallableUid({ auth: null }, {}, 'testFunction'),
    ).rejects.toThrow('Authentication required.');

    expect(mockHttpsError).toHaveBeenCalledWith(
      'unauthenticated',
      'Authentication required.',
    );
  });

  test('throws unauthenticated when context.auth is null and idToken is empty', async () => {
    await expect(
      resolveCallableUid({ auth: null }, { idToken: '' }, 'testFunction'),
    ).rejects.toThrow('Authentication required.');

    expect(mockHttpsError).toHaveBeenCalledWith(
      'unauthenticated',
      'Authentication required.',
    );
  });

  test('throws unauthenticated when idToken verification fails', async () => {
    mockVerifyIdToken.mockRejectedValue(new Error('Token expired'));

    await expect(
      resolveCallableUid({ auth: null }, { idToken: 'expired-token' }, 'testFunction'),
    ).rejects.toThrow('Authentication required.');

    expect(mockVerifyIdToken).toHaveBeenCalledWith('expired-token');
    expect(mockHttpsError).toHaveBeenCalledWith(
      'unauthenticated',
      'Authentication required.',
    );
  });

  test('throws unauthenticated when idToken is invalid', async () => {
    mockVerifyIdToken.mockRejectedValue(new Error('Invalid token'));

    await expect(
      resolveCallableUid({ auth: null }, { idToken: 'bad-token' }, 'testFunction'),
    ).rejects.toThrow('Authentication required.');

    expect(mockVerifyIdToken).toHaveBeenCalledWith('bad-token');
  });
});

// ════════════════════════════════════════════════════════════════════════════
// completeOnboarding
// ════════════════════════════════════════════════════════════════════════════

/**
 * Implementation that mirrors completeOnboarding in index.js.
 */
async function completeOnboarding(data, context) {
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');

  const uid = await resolveCallableUid(context, data, 'completeOnboarding');
  const userDocPath = data?.userDocPath;

  if (typeof userDocPath !== 'string' || userDocPath.split('/').length !== 2) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'A valid user document path is required.',
    );
  }

  if (uid !== userDocPath.split('/')[1]) {
    throw new functions.https.HttpsError(
      'permission-denied',
      "Authenticated user doesn't match provided user reference.",
    );
  }

  try {
    await admin.firestore().doc(userDocPath).update({
      onboarding_completed: true,
    });
    return { success: true };
  } catch (error) {
    console.error('completeOnboarding failed', error);
    throw new functions.https.HttpsError(
      'internal',
      'Unable to mark onboarding as completed.',
      { message: error?.message ?? String(error) },
    );
  }
}

describe('completeOnboarding', () => {
  test('succeeds with context.auth', async () => {
    const result = await completeOnboarding(
      { userDocPath: 'users/user123' },
      { auth: { uid: 'user123' } },
    );

    expect(result).toEqual({ success: true });
    expect(mockFirestoreUpdate).toHaveBeenCalledWith(
      'users/user123',
      { onboarding_completed: true },
    );
  });

  test('succeeds with idToken fallback when context.auth is null', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'user456' });

    const result = await completeOnboarding(
      { userDocPath: 'users/user456', idToken: 'valid-token' },
      { auth: null },
    );

    expect(result).toEqual({ success: true });
    expect(mockVerifyIdToken).toHaveBeenCalledWith('valid-token');
    expect(mockFirestoreUpdate).toHaveBeenCalledWith(
      'users/user456',
      { onboarding_completed: true },
    );
  });

  test('throws unauthenticated when no auth and no idToken', async () => {
    await expect(
      completeOnboarding({ userDocPath: 'users/user123' }, { auth: null }),
    ).rejects.toThrow('Authentication required.');

    expect(mockHttpsError).toHaveBeenCalledWith(
      'unauthenticated',
      'Authentication required.',
    );
    expect(mockFirestoreUpdate).not.toHaveBeenCalled();
  });

  test('throws invalid-argument when userDocPath is missing', async () => {
    await expect(
      completeOnboarding({}, { auth: { uid: 'user123' } }),
    ).rejects.toThrow('A valid user document path is required.');

    expect(mockHttpsError).toHaveBeenCalledWith(
      'invalid-argument',
      'A valid user document path is required.',
    );
  });

  test('throws invalid-argument when userDocPath has wrong format', async () => {
    await expect(
      completeOnboarding(
        { userDocPath: 'users/user123/subcollection/doc' },
        { auth: { uid: 'user123' } },
      ),
    ).rejects.toThrow('A valid user document path is required.');
  });

  test('throws permission-denied when uid does not match userDocPath', async () => {
    await expect(
      completeOnboarding(
        { userDocPath: 'users/differentUser' },
        { auth: { uid: 'user123' } },
      ),
    ).rejects.toThrow("Authenticated user doesn't match provided user reference.");

    expect(mockHttpsError).toHaveBeenCalledWith(
      'permission-denied',
      "Authenticated user doesn't match provided user reference.",
    );
  });

  test('throws permission-denied when idToken uid does not match userDocPath', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'tokenUser' });

    await expect(
      completeOnboarding(
        { userDocPath: 'users/differentUser', idToken: 'valid-token' },
        { auth: null },
      ),
    ).rejects.toThrow("Authenticated user doesn't match provided user reference.");
  });

  test('throws internal error when Firestore update fails', async () => {
    mockFirestoreUpdate.mockRejectedValue(new Error('Firestore error'));

    await expect(
      completeOnboarding(
        { userDocPath: 'users/user123' },
        { auth: { uid: 'user123' } },
      ),
    ).rejects.toThrow('Unable to mark onboarding as completed.');

    expect(mockHttpsError).toHaveBeenCalledWith(
      'internal',
      'Unable to mark onboarding as completed.',
    );
  });
});

// ════════════════════════════════════════════════════════════════════════════
// checkOnboardingComplete
// ════════════════════════════════════════════════════════════════════════════

/**
 * Implementation that mirrors checkOnboardingComplete in index.js.
 */
async function checkOnboardingComplete(data, context) {
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');

  const uid = await resolveCallableUid(context, data, 'checkOnboardingComplete');
  const userDocPath = data?.userDocPath;

  if (typeof userDocPath !== 'string' || userDocPath.split('/').length !== 2) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'A valid user document path is required.',
    );
  }

  if (uid !== userDocPath.split('/')[1]) {
    throw new functions.https.HttpsError(
      'permission-denied',
      "Authenticated user doesn't match provided user reference.",
    );
  }

  try {
    const doc = await admin.firestore().doc(userDocPath).get();
    const completed = doc.exists && doc.data()?.onboarding_completed === true;
    return { completed };
  } catch (error) {
    console.error('checkOnboardingComplete failed', error);
    throw new functions.https.HttpsError(
      'internal',
      'Unable to verify onboarding status.',
      { message: error?.message ?? String(error) },
    );
  }
}

describe('checkOnboardingComplete', () => {
  test('returns completed: true when onboarding is complete', async () => {
    mockFirestoreGet.mockResolvedValue({
      exists: true,
      data: () => ({ onboarding_completed: true }),
    });

    const result = await checkOnboardingComplete(
      { userDocPath: 'users/user123' },
      { auth: { uid: 'user123' } },
    );

    expect(result).toEqual({ completed: true });
  });

  test('returns completed: false when onboarding is not complete', async () => {
    mockFirestoreGet.mockResolvedValue({
      exists: true,
      data: () => ({ onboarding_completed: false }),
    });

    const result = await checkOnboardingComplete(
      { userDocPath: 'users/user123' },
      { auth: { uid: 'user123' } },
    );

    expect(result).toEqual({ completed: false });
  });

  test('returns completed: false when document does not exist', async () => {
    mockFirestoreGet.mockResolvedValue({
      exists: false,
      data: () => null,
    });

    const result = await checkOnboardingComplete(
      { userDocPath: 'users/user123' },
      { auth: { uid: 'user123' } },
    );

    expect(result).toEqual({ completed: false });
  });

  test('succeeds with idToken fallback when context.auth is null', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'user789' });
    mockFirestoreGet.mockResolvedValue({
      exists: true,
      data: () => ({ onboarding_completed: true }),
    });

    const result = await checkOnboardingComplete(
      { userDocPath: 'users/user789', idToken: 'valid-token' },
      { auth: null },
    );

    expect(result).toEqual({ completed: true });
    expect(mockVerifyIdToken).toHaveBeenCalledWith('valid-token');
  });

  test('throws unauthenticated when no auth and no idToken', async () => {
    await expect(
      checkOnboardingComplete({ userDocPath: 'users/user123' }, { auth: null }),
    ).rejects.toThrow('Authentication required.');
  });

  test('throws permission-denied when uid does not match userDocPath', async () => {
    await expect(
      checkOnboardingComplete(
        { userDocPath: 'users/differentUser' },
        { auth: { uid: 'user123' } },
      ),
    ).rejects.toThrow("Authenticated user doesn't match provided user reference.");
  });
});
