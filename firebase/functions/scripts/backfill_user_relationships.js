const admin = require("firebase-admin");

admin.initializeApp();

const firestore = admin.firestore();
const { FieldValue } = admin.firestore;

const USERS_COLLECTION = "users";
const FRIEND_REQUESTS_COLLECTION = "friend_request";
const BATCH_LIMIT = 400;

const ensureUserArrays = async () => {
  const snapshot = await firestore.collection(USERS_COLLECTION).get();
  let batch = firestore.batch();
  let batchOps = 0;
  let updates = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const update = {};

    if (!Array.isArray(data.friends)) {
      update.friends = [];
    }

    if (!Array.isArray(data.friend_requests)) {
      update.friend_requests = [];
    }

    if (Object.keys(update).length > 0) {
      batch.set(doc.ref, update, { merge: true });
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

  console.log(
    `Ensured friends/friend_requests arrays for ${updates} user documents.`,
  );
};

const backfillFriendsFromRequests = async () => {
  const acceptedStatus =
    process.env.FRIEND_REQUEST_ACCEPTED_STATUS ?? "accepted";
  const snapshot = await firestore
    .collection(FRIEND_REQUESTS_COLLECTION)
    .where("request_status", "==", acceptedStatus)
    .get();

  let batch = firestore.batch();
  let batchOps = 0;
  let updates = 0;

  for (const doc of snapshot.docs) {
    const { requester_id: requesterId, receiver_id: receiverId } = doc.data();

    if (!requesterId || !receiverId) {
      console.warn(
        `Skipping friend_request ${doc.id}: missing requester/receiver refs.`,
      );
      continue;
    }

    batch.update(requesterId, {
      friends: FieldValue.arrayUnion(receiverId),
    });
    batch.update(receiverId, {
      friends: FieldValue.arrayUnion(requesterId),
    });
    batchOps += 2;
    updates += 1;

    if (batchOps >= BATCH_LIMIT) {
      await batch.commit();
      batch = firestore.batch();
      batchOps = 0;
    }
  }

  if (batchOps > 0) {
    await batch.commit();
  }

  console.log(`Backfilled friends for ${updates} accepted requests.`);
};

const main = async () => {
  await ensureUserArrays();

  if (process.env.BACKFILL_FROM_REQUESTS === "true") {
    await backfillFriendsFromRequests();
  }
};

main()
  .then(() => {
    console.log("Done.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Backfill failed:", error);
    process.exit(1);
  });
