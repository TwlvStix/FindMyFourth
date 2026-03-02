'use strict';

/**
 * Initials Avatar Generator
 *
 * Generates initials avatars (colored circles with initials) for users
 * without profile photos. Avatars are stored in Firebase Storage and
 * used as fallbacks in push notifications.
 *
 * Uses `sharp` for image generation, which is more portable than `canvas`
 * and has pre-built binaries for all platforms.
 */

const sharp = require('sharp');
const admin = require('firebase-admin');

// ── Color Palette ─────────────────────────────────────────────────────────────

/**
 * Avatar background colors matching the app's design tokens.
 * Uses "The Clubhouse" palette: greens and navies.
 */
const AVATAR_COLORS = [
  '#1E6B5C', // green
  '#142A36', // navy
  '#2D5A4A', // greenDark
  '#1A3847', // navyLight
  '#247A69', // greenLight (variation)
  '#1D3A4A', // navy mid (variation)
];

// ── Internal Helpers ──────────────────────────────────────────────────────────

/**
 * Extracts initials from first and last name.
 * Returns up to 2 characters, uppercase.
 *
 * @param {string} firstName
 * @param {string} lastName
 * @returns {string} Initials (e.g., "JD" for John Doe)
 */
function extractInitials(firstName, lastName) {
  const first = (firstName || '').trim();
  const last = (lastName || '').trim();

  const firstInitial = first.length > 0 ? first[0].toUpperCase() : '';
  const lastInitial = last.length > 0 ? last[0].toUpperCase() : '';

  // If no initials at all, return a placeholder
  if (!firstInitial && !lastInitial) {
    return '?';
  }

  return `${firstInitial}${lastInitial}`;
}

/**
 * Selects a consistent color based on userId.
 * Same user always gets the same color.
 *
 * @param {string} userId
 * @returns {string} Hex color code
 */
function selectColor(userId) {
  // Use a simple hash of the userId to pick a color
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    hash = ((hash << 5) - hash) + userId.charCodeAt(i);
    hash = hash & hash; // Convert to 32-bit integer
  }
  const index = Math.abs(hash) % AVATAR_COLORS.length;
  return AVATAR_COLORS[index];
}

/**
 * Creates an SVG string for the initials avatar.
 *
 * @param {string} initials - The initials to display
 * @param {string} bgColor - Background color (hex)
 * @param {number} size - Image size in pixels
 * @returns {string} SVG markup
 */
function createAvatarSvg(initials, bgColor, size = 256) {
  const fontSize = Math.round(size * 0.4); // 40% of size
  const textY = size / 2 + fontSize * 0.35; // Vertical centering adjustment

  return `
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
      <circle cx="${size / 2}" cy="${size / 2}" r="${size / 2}" fill="${bgColor}"/>
      <text
        x="${size / 2}"
        y="${textY}"
        font-family="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
        font-size="${fontSize}"
        font-weight="600"
        fill="#FFFFFF"
        text-anchor="middle"
      >${initials}</text>
    </svg>
  `.trim();
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Generates an initials avatar image and uploads it to Firebase Storage.
 *
 * Creates a 256x256 PNG with a colored circular background and white initials.
 * The image is made publicly accessible and cached for 1 year.
 *
 * @param {string} userId - User's Firestore document ID
 * @param {string} firstName - User's first name
 * @param {string} lastName - User's last name
 * @returns {Promise<string>} Public URL of the generated avatar
 */
async function generateInitialsAvatar(userId, firstName, lastName) {
  const initials = extractInitials(firstName, lastName);
  const bgColor = selectColor(userId);
  const size = 256;

  // Create SVG and convert to PNG using sharp
  const svg = createAvatarSvg(initials, bgColor, size);
  const buffer = await sharp(Buffer.from(svg))
    .resize(size, size)
    .png()
    .toBuffer();

  // Upload to Firebase Storage
  const bucket = admin.storage().bucket();
  const filePath = `avatars/${userId}_initials.png`;
  const file = bucket.file(filePath);

  await file.save(buffer, {
    contentType: 'image/png',
    public: true,
    metadata: {
      cacheControl: 'public, max-age=31536000', // 1 year cache
      metadata: {
        generatedAt: new Date().toISOString(),
        initials: initials,
      },
    },
  });

  // Return public URL
  return file.publicUrl();
}

/**
 * Deletes an existing initials avatar from Firebase Storage.
 *
 * @param {string} userId - User's Firestore document ID
 * @returns {Promise<void>}
 */
async function deleteInitialsAvatar(userId) {
  const bucket = admin.storage().bucket();
  const filePath = `avatars/${userId}_initials.png`;
  const file = bucket.file(filePath);

  try {
    await file.delete();
  } catch (err) {
    // Ignore "not found" errors
    if (err.code !== 404) {
      throw err;
    }
  }
}

module.exports = {
  generateInitialsAvatar,
  deleteInitialsAvatar,
  // Exported for testing
  extractInitials,
  selectColor,
  createAvatarSvg,
};
