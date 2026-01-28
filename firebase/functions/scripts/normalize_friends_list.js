const admin = require("firebase-admin");

admin.initializeApp();

const firestore = admin.firestore();
const USERS_COLLECTION = "users";
const BATCH_LIMIT = 400;

function normalizeFriendEntries(entries) {
  if (!Array.isArray(entries)) {
    return { refs: [], changed: true };
  }

  const seen = new Set();
  const refs = [];
  let changed = false;

  for (const entry of entries) {
    let id = null;

    if (entry instanceof admin.firestore.DocumentReference) {
      id = entry.id;
    } else if (typeof entry === "string") {
      changed = true;
      const parts = entry.split("/").filter(Boolean);
      id = parts.length > 0 ? parts[parts.length - 1] : null;
    } else if (entry && typeof entry.id === "string") {
      changed = true;
      id = entry.id;
    } else {
      changed = true;
      continue;
    }

    if (!id) {
      changed = true;
      continue;
    }

    if (seen.has(id)) {
      changed = true;
      continue;
    }

    seen.add(id);
    refs.push(firestore.collection(USERS_COLLECTION).doc(id));
  }

  if (entries.length !== refs.length) {
    changed = true;
  }

  return { refs, changed };
}

async function normalizeFriendLists() {
  const snapshot = await firestore.collection(USERS_COLLECTION).get();
  let batch = firestore.batch();
  let batchOps = 0;
  let updates = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const { refs, changed } = normalizeFriendEntries(data.friends);

    if (changed) {
      batch.update(doc.ref, { friends: refs });
      batchOps += 1;
      updates += 1;
    }

    if (batchOps >= BATCH_LIMIT) {
      await batch.commit();
      batch = firestore.batch();
      batchOps = 0;
    }
  }

  if (batchOps > 0) {
    await batch.commit();
  }

  console.log(`Normalized friends lists for ${updates} user documents.`);
}

normalizeFriendLists()
  .then(() => {
    console.log("Done.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Normalize friends failed:", error);
    process.exit(1);
  });
