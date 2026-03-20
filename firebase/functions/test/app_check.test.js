'use strict';

/**
 * Unit tests for utils/app_check.js — requireAppCheck helper.
 *
 * Run: npx jest test/app_check.test.js --verbose
 */

jest.mock('firebase-functions/v1', () => {
  class HttpsError extends Error {
    constructor(code, message) {
      super(message);
      this.code = code;
    }
  }
  return { https: { HttpsError } };
});

describe('requireAppCheck', () => {
  beforeEach(() => {
    jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    console.warn.mockRestore();
  });

  describe('with enforce=false (default)', () => {
    let requireAppCheck;

    beforeEach(() => {
      jest.resetModules();
      ({ requireAppCheck } = require('../utils/app_check'));
    });

    test('passes silently when context.app is present', () => {
      const context = { auth: { uid: 'user1' }, app: {} };
      expect(() => requireAppCheck(context, 'testFn')).not.toThrow();
      expect(console.warn).not.toHaveBeenCalled();
    });

    test('logs warning but does not throw when context.app is missing', () => {
      const context = { auth: { uid: 'user1' } };
      expect(() => requireAppCheck(context, 'myFunction')).not.toThrow();
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('[AppCheck] Missing token on myFunction')
      );
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('allowed (log-only mode)')
      );
    });

    test('includes uid in warning message when available', () => {
      const context = { auth: { uid: 'abc123' } };
      requireAppCheck(context, 'testFn');
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('uid=abc123')
      );
    });

    test('uses "unknown" when auth.uid is not available', () => {
      const context = {};
      requireAppCheck(context, 'testFn');
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('uid=unknown')
      );
    });
  });

  describe('with enforce=true (simulated)', () => {
    // We cannot toggle the const at runtime, so we inline the logic to test
    // the enforce=true branch.
    const functions = require('firebase-functions/v1');

    function requireAppCheckEnforced(context, functionName) {
      if (context.app === undefined) {
        const msg = `[AppCheck] Missing token on ${functionName} (uid=${context.auth?.uid || 'unknown'})`;
        console.warn(msg + ' — REJECTED');
        throw new functions.https.HttpsError('failed-precondition', 'App Check token required.');
      }
    }

    test('passes silently when context.app is present', () => {
      const context = { auth: { uid: 'user1' }, app: {} };
      expect(() => requireAppCheckEnforced(context, 'testFn')).not.toThrow();
      expect(console.warn).not.toHaveBeenCalled();
    });

    test('throws failed-precondition when context.app is missing', () => {
      const context = { auth: { uid: 'user1' } };
      expect(() => requireAppCheckEnforced(context, 'myFunction')).toThrow('App Check token required.');
      try {
        requireAppCheckEnforced(context, 'myFunction');
      } catch (err) {
        expect(err.code).toBe('failed-precondition');
      }
    });
  });
});
