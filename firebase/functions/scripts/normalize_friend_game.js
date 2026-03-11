/**
 * One-time migration: normalize `friend_game` field on all game documents.
 *
 * Before: values could be 'Public', 'public', 'Friends', null, or ''
 * After:  'public' or 'friends' (lowercase only)
 *
 * Usage:
 *   node scripts/normalize_friend_game.js
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or Firebase Admin default credentials.
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const BATCH_LIMIT = 500;

async function normalize() {
  const gamesRef = db.collection("games");
  const snapshot = await gamesRef.get();

  let updated = 0;
  let skipped = 0;
  let nullToPublic = 0;
  let publicCaseFixed = 0;
  let friendsCaseFixed = 0;
  let emptyToPublic = 0;

  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const current = data.friend_game;
    let normalized = null;

    if (current === null || current === undefined) {
      normalized = "public";
      nullToPublic++;
    } else if (current === "") {
      normalized = "public";
      emptyToPublic++;
    } else if (current === "Public") {
      normalized = "public";
      publicCaseFixed++;
    } else if (current === "Friends") {
      normalized = "friends";
      friendsCaseFixed++;
    } else if (current === "public" || current === "friends") {
      // Already normalized
      skipped++;
      continue;
    } else {
      // Unknown value — default to public
      console.warn(`Unknown friend_game value "${current}" on ${doc.id}, defaulting to "public"`);
      normalized = "public";
    }

    batch.update(doc.ref, { friend_game: normalized });
    batchCount++;
    updated++;

    if (batchCount >= BATCH_LIMIT) {
      await batch.commit();
      console.log(`Committed batch of ${batchCount} updates...`);
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  console.log("\n=== Migration Complete ===");
  console.log(`Total documents:    ${snapshot.size}`);
  console.log(`Updated:            ${updated}`);
  console.log(`  null → public:    ${nullToPublic}`);
  console.log(`  "" → public:      ${emptyToPublic}`);
  console.log(`  Public → public:  ${publicCaseFixed}`);
  console.log(`  Friends → friends:${friendsCaseFixed}`);
  console.log(`Already correct:    ${skipped}`);
}

normalize()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Migration failed:", err);
    process.exit(1);
  });
