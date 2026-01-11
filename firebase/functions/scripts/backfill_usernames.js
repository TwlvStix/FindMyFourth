const admin = require("firebase-admin");

admin.initializeApp();

const firestore = admin.firestore();
const { FieldValue } = admin.firestore;

const USERS_COLLECTION = "users";
const USERNAMES_COLLECTION = "usernames";
const BATCH_LIMIT = 400;

const normalizeUsername = (value) =>
  String(value || "").replace(/\s+/g, "").toLowerCase();

const backfillUsernames = async () => {
  const snapshot = await firestore.collection(USERS_COLLECTION).get();
  let batch = firestore.batch();
  let batchOps = 0;
  let created = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const displayName = normalizeUsername(data.display_name);
    if (!displayName) {
      skipped += 1;
      continue;
    }

    const usernameRef = firestore
      .collection(USERNAMES_COLLECTION)
      .doc(displayName);
    const existing = await usernameRef.get();
    if (existing.exists) {
      skipped += 1;
      continue;
    }

    batch.set(usernameRef, {
      uid: doc.ref,
      created_at: FieldValue.serverTimestamp(),
    });
    batchOps += 1;
    created += 1;

    if (batchOps >= BATCH_LIMIT) {
      await batch.commit();
      batch = firestore.batch();
      batchOps = 0;
    }
  }

  if (batchOps > 0) {
    await batch.commit();
  }

  console.log(
    `Backfill complete. Created ${created} username records. Skipped ${skipped}.`,
  );
};

backfillUsernames()
  .then(() => {
    console.log("Done.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Backfill failed:", error);
    process.exit(1);
  });
