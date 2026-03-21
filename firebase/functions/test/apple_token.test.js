'use strict';

/**
 * Unit tests for apple_token.js — Apple Sign-In token helpers.
 *
 * Run: npx jest test/apple_token.test.js --verbose
 */

jest.mock('axios');
const axios = require('axios');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const {
  generateClientSecret,
  exchangeAuthCodeForTokens,
  revokeAppleToken,
} = require('../apple_token');

// Generate a valid ES256 (P-256) key pair for testing.
const { privateKey: TEST_PRIVATE_KEY } = crypto.generateKeyPairSync('ec', {
  namedCurve: 'P-256',
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

const TEST_TEAM_ID = 'TEAM123456';
const TEST_SERVICE_ID = 'com.test.service';
const TEST_KEY_ID = 'KEY1234567';

describe('apple_token', () => {
  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
    axios.post.mockReset();
  });

  afterEach(() => {
    console.error.mockRestore();
    console.warn.mockRestore();
  });

  describe('generateClientSecret', () => {
    it('generates a valid JWT with correct claims', () => {
      const secret = generateClientSecret(
        TEST_TEAM_ID,
        TEST_SERVICE_ID,
        TEST_KEY_ID,
        TEST_PRIVATE_KEY,
      );

      expect(typeof secret).toBe('string');
      expect(secret.split('.')).toHaveLength(3);

      // Decode without verification to check claims
      const decoded = jwt.decode(secret, { complete: true });
      expect(decoded.header.alg).toBe('ES256');
      expect(decoded.header.kid).toBe(TEST_KEY_ID);
      expect(decoded.payload.iss).toBe(TEST_TEAM_ID);
      expect(decoded.payload.sub).toBe(TEST_SERVICE_ID);
      expect(decoded.payload.aud).toBe('https://appleid.apple.com');

      // Expiry should be ~180 days from now
      const now = Math.floor(Date.now() / 1000);
      const expectedExp = now + 180 * 24 * 60 * 60;
      expect(decoded.payload.exp).toBeGreaterThan(expectedExp - 10);
      expect(decoded.payload.exp).toBeLessThan(expectedExp + 10);
    });

    it('throws with an invalid private key', () => {
      expect(() =>
        generateClientSecret(
          TEST_TEAM_ID,
          TEST_SERVICE_ID,
          TEST_KEY_ID,
          'not-a-real-key',
        ),
      ).toThrow();
    });
  });

  describe('exchangeAuthCodeForTokens', () => {
    it('returns token data on success', async () => {
      const mockResponse = {
        data: {
          access_token: 'at_mock',
          refresh_token: 'rt_mock',
          id_token: 'it_mock',
          expires_in: 3600,
        },
      };
      axios.post.mockResolvedValueOnce(mockResponse);

      const result = await exchangeAuthCodeForTokens(
        'auth_code_123',
        'client_secret_jwt',
        TEST_SERVICE_ID,
      );

      expect(result).toEqual(mockResponse.data);
      expect(axios.post).toHaveBeenCalledWith(
        'https://appleid.apple.com/auth/token',
        expect.stringContaining('grant_type=authorization_code'),
        expect.objectContaining({
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        }),
      );
      // Verify all params are in the request body
      const body = axios.post.mock.calls[0][1];
      expect(body).toContain('code=auth_code_123');
      expect(body).toContain(`client_id=${TEST_SERVICE_ID}`);
      expect(body).toContain('client_secret=client_secret_jwt');
    });

    it('returns null on HTTP error', async () => {
      axios.post.mockRejectedValueOnce({
        response: { status: 400, data: { error: 'invalid_grant' } },
        message: 'Request failed with status code 400',
      });

      const result = await exchangeAuthCodeForTokens(
        'expired_code',
        'client_secret_jwt',
        TEST_SERVICE_ID,
      );

      expect(result).toBeNull();
      expect(console.error).toHaveBeenCalled();
    });

    it('returns null on network error', async () => {
      axios.post.mockRejectedValueOnce(new Error('Network Error'));

      const result = await exchangeAuthCodeForTokens(
        'code',
        'secret',
        TEST_SERVICE_ID,
      );

      expect(result).toBeNull();
      expect(console.error).toHaveBeenCalled();
    });
  });

  describe('revokeAppleToken', () => {
    it('returns true on successful revocation (HTTP 200)', async () => {
      axios.post.mockResolvedValueOnce({ status: 200 });

      const result = await revokeAppleToken(
        'rt_mock',
        'client_secret_jwt',
        TEST_SERVICE_ID,
      );

      expect(result).toBe(true);
      expect(axios.post).toHaveBeenCalledWith(
        'https://appleid.apple.com/auth/revoke',
        expect.stringContaining('token=rt_mock'),
        expect.objectContaining({
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        }),
      );
      const body = axios.post.mock.calls[0][1];
      expect(body).toContain('token_type_hint=refresh_token');
      expect(body).toContain(`client_id=${TEST_SERVICE_ID}`);
    });

    it('returns false on HTTP error', async () => {
      axios.post.mockRejectedValueOnce({
        response: { status: 400, data: { error: 'invalid_token' } },
        message: 'Request failed with status code 400',
      });

      const result = await revokeAppleToken(
        'rt_invalid',
        'client_secret_jwt',
        TEST_SERVICE_ID,
      );

      expect(result).toBe(false);
      expect(console.error).toHaveBeenCalled();
    });

    it('returns false on network error', async () => {
      axios.post.mockRejectedValueOnce(new Error('ECONNREFUSED'));

      const result = await revokeAppleToken(
        'rt_mock',
        'secret',
        TEST_SERVICE_ID,
      );

      expect(result).toBe(false);
      expect(console.error).toHaveBeenCalled();
    });
  });
});
