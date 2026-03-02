'use strict';

/**
 * Avatar URL Utilities
 *
 * Helpers for resolving the best available avatar URL for a user,
 * with fallback from photo_url to avatar_initials_url.
 */

// ── URL Validation ────────────────────────────────────────────────────────────

/**
 * Validates that a URL is a valid HTTPS URL.
 *
 * @param {string|null|undefined} url - URL to validate
 * @returns {boolean} True if valid HTTPS URL
 */
function isValidHttpsUrl(url) {
  if (!url || typeof url !== 'string') {
    return false;
  }

  try {
    const parsed = new URL(url);
    return parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

// ── Avatar URL Resolution ─────────────────────────────────────────────────────

/**
 * Gets the best available avatar URL for a user.
 *
 * Priority:
 *   1. photo_url (user-uploaded profile photo)
 *   2. avatar_initials_url (generated initials avatar)
 *   3. null (no avatar available)
 *
 * Only returns URLs that are valid HTTPS URLs.
 *
 * @param {object|null|undefined} userData - User document data
 * @returns {string|null} Best available avatar URL, or null
 */
function getAvatarUrl(userData) {
  if (!userData) {
    return null;
  }

  // Prefer user-uploaded photo
  if (userData.photo_url && isValidHttpsUrl(userData.photo_url)) {
    return userData.photo_url;
  }

  // Fall back to generated initials avatar
  if (userData.avatar_initials_url && isValidHttpsUrl(userData.avatar_initials_url)) {
    return userData.avatar_initials_url;
  }

  return null;
}

/**
 * Checks if a user has any avatar (photo or initials).
 *
 * @param {object|null|undefined} userData - User document data
 * @returns {boolean} True if user has a valid avatar URL
 */
function hasAvatar(userData) {
  return getAvatarUrl(userData) !== null;
}

module.exports = {
  isValidHttpsUrl,
  getAvatarUrl,
  hasAvatar,
};
