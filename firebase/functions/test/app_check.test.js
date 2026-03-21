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

  describe('with enforce=true', () => {
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

    test('throws failed-precondition when context.app is missing', () => {
      const context = { auth: { uid: 'user1' } };
      expect(() => requireAppCheck(context, 'myFunction')).toThrow('App Check token required.');
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('[AppCheck] Missing token on myFunction')
      );
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('REJECTED')
      );
    });

    test('includes uid in warning message when available', () => {
      const context = { auth: { uid: 'abc123' } };
      try { requireAppCheck(context, 'testFn'); } catch (_) {}
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('uid=abc123')
      );
    });

    test('uses "unknown" when auth.uid is not available', () => {
      const context = {};
      try { requireAppCheck(context, 'testFn'); } catch (_) {}
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('uid=unknown')
      );
    });

    test('throws with failed-precondition code', () => {
      const context = { auth: { uid: 'user1' } };
      try {
        requireAppCheck(context, 'myFunction');
      } catch (err) {
        expect(err.code).toBe('failed-precondition');
      }
    });
  });
});
