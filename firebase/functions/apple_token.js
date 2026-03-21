const jwt = require("jsonwebtoken");
const axios = require("axios");
const qs = require("qs");

const APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

/**
 * Generates an Apple client secret JWT signed with the app's .p8 private key.
 *
 * @param {string} teamId - Apple Developer Team ID (10 characters)
 * @param {string} serviceId - Apple Service ID or Bundle ID used for Sign in with Apple
 * @param {string} keyId - Key ID of the Sign in with Apple private key
 * @param {string} privateKey - Contents of the .p8 private key file (PEM format)
 * @returns {string} Signed JWT client secret
 */
function generateClientSecret(teamId, serviceId, keyId, privateKey) {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iss: teamId,
      iat: now,
      exp: now + 180 * 24 * 60 * 60, // 180 days (Apple maximum)
      aud: "https://appleid.apple.com",
      sub: serviceId,
    },
    privateKey,
    {
      algorithm: "ES256",
      header: { kid: keyId },
    },
  );
}

/**
 * Exchanges an Apple authorization code for access and refresh tokens.
 *
 * @param {string} authorizationCode - The authorization code from Sign in with Apple
 * @param {string} clientSecret - JWT client secret from generateClientSecret()
 * @param {string} serviceId - Apple Service ID or Bundle ID
 * @returns {Promise<{access_token: string, refresh_token: string, id_token: string, expires_in: number}|null>}
 *   Token response on success, null on failure.
 */
async function exchangeAuthCodeForTokens(
  authorizationCode,
  clientSecret,
  serviceId,
) {
  try {
    const response = await axios.post(
      APPLE_TOKEN_URL,
      qs.stringify({
        grant_type: "authorization_code",
        code: authorizationCode,
        client_id: serviceId,
        client_secret: clientSecret,
      }),
      { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
    );
    return response.data;
  } catch (error) {
    const status = error.response?.status;
    const body = error.response?.data;
    console.error("appleToken exchangeAuthCode failed", {
      status,
      body,
      message: error.message,
    });
    return null;
  }
}

/**
 * Revokes an Apple refresh token so Sign in with Apple is fully disconnected.
 *
 * @param {string} refreshToken - The stored Apple refresh token
 * @param {string} clientSecret - JWT client secret from generateClientSecret()
 * @param {string} serviceId - Apple Service ID or Bundle ID
 * @returns {Promise<boolean>} true if revocation succeeded, false otherwise
 */
async function revokeAppleToken(refreshToken, clientSecret, serviceId) {
  try {
    const response = await axios.post(
      APPLE_REVOKE_URL,
      qs.stringify({
        token: refreshToken,
        token_type_hint: "refresh_token",
        client_id: serviceId,
        client_secret: clientSecret,
      }),
      { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
    );
    return response.status === 200;
  } catch (error) {
    const status = error.response?.status;
    const body = error.response?.data;
    console.error("appleToken revokeToken failed", {
      status,
      body,
      message: error.message,
    });
    return false;
  }
}

module.exports = {
  generateClientSecret,
  exchangeAuthCodeForTokens,
  revokeAppleToken,
};
