const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const kFcmTokensCollection = "fcm_tokens";
const kPushNotificationsCollection = "push_notifications";
const kUserPushNotificationsCollection = "user_push_notifications";
const firestore = admin.firestore();

const kPushNotificationRuntimeOpts = {
  timeoutSeconds: 540,
  memory: "2GB",
};

exports.addFcmToken = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Unauthenticated calls are not allowed.",
      );
    }
    const userDocPath = data?.userDocPath;
    const fcmToken = data?.fcmToken;
    const deviceType = data?.deviceType;
    if (
      typeof userDocPath !== "string" ||
      typeof fcmToken !== "string" ||
      typeof deviceType !== "string" ||
      userDocPath.split("/").length <= 1 ||
      fcmToken.length === 0 ||
      deviceType.length === 0
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid arguments encountered when adding FCM token.",
      );
    }
    if (context.auth.uid !== userDocPath.split("/")[1]) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Authenticated user doesn't match user provided.",
      );
    }
    try {
      let existingTokens = null;
      try {
        existingTokens = await firestore
          .collectionGroup(kFcmTokensCollection)
          .where("fcm_token", "==", fcmToken)
          .get();
      } catch (error) {
        console.warn(
          "addFcmToken token lookup failed, continuing without cleanup",
          error,
        );
      }
      let userAlreadyHasToken = false;
      if (existingTokens) {
        for (const doc of existingTokens.docs) {
          const user = doc.ref.parent.parent;
          if (!user) {
            console.warn(
              "addFcmToken token doc missing parent user, deleting stale token",
              doc.ref.path,
            );
            await doc.ref.delete();
            continue;
          }
          if (user.path !== userDocPath) {
            // Should never have the same FCM token associated with multiple users.
            await doc.ref.delete();
          } else {
            userAlreadyHasToken = true;
          }
        }
      }
      if (userAlreadyHasToken) {
        return "FCM token already exists for this user. Ignoring...";
      }
      await getUserFcmTokensCollection(userDocPath).doc().set({
        fcm_token: fcmToken,
        device_type: deviceType,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return "Successfully added FCM token!";
    } catch (error) {
      console.error("addFcmToken failed", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to add FCM token.",
        {
          message: error?.message ?? String(error),
        },
      );
    }
  });

exports.sendPushNotificationsTrigger = functions
  .region("us-west2")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document(`${kPushNotificationsCollection}/{id}`)
  .onCreate(async (snapshot, _) => {
    try {
      // Ignore scheduled push notifications on create
      const scheduledTime = snapshot.data().scheduled_time || "";
      if (scheduledTime) {
        return;
      }

      await sendPushNotifications(snapshot);
    } catch (e) {
      console.log(`Error: ${e}`);
      await snapshot.ref.update({ status: "failed", error: `${e}` });
    }
  });

exports.sendUserPushNotificationsTrigger = functions
  .region("us-west2")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document(`${kUserPushNotificationsCollection}/{id}`)
  .onCreate(async (snapshot, _) => {
    try {
      // Ignore scheduled push notifications on create
      const scheduledTime = snapshot.data().scheduled_time || "";
      if (scheduledTime) {
        return;
      }

      // Don't let user-triggered notifications to be sent to all users.
      const userRefsStr = snapshot.data().user_refs || "";
      if (userRefsStr) {
        await sendPushNotifications(snapshot);
      }
    } catch (e) {
      console.log(`Error: ${e}`);
      await snapshot.ref.update({ status: "failed", error: `${e}` });
    }
  });

exports.fetchReceiptants = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required.",
      );
    }

    const userCollection = firestore.collection("users");
    const users = new Set();

    if (data.style_game === "Money Game") {
      const moneyGameUsers = await userCollection
        .where("notify_money_game", "==", true)
        .get();
      moneyGameUsers.docs.forEach((doc) => users.add(doc.ref.path));
    }

    if (data.game_type === "Vegas") {
      const vegasGameUsers = await userCollection
        .where("notify_vegas_game", "==", true)
        .get();
      vegasGameUsers.docs.forEach((doc) => users.add(doc.ref.path));
    }

    if (data.rules_setting === "Competitive") {
      const competitiveUsers = await userCollection
        .where("notify_competitive_game", "==", true)
        .get();
      competitiveUsers.docs.forEach((doc) => users.add(doc.ref.path));
    }

    if (data.rules_setting === "For Fun") {
      const forFunUsers = await userCollection
        .where("notify_for_fun", "==", true)
        .get();
      forFunUsers.docs.forEach((doc) => users.add(doc.ref.path));
    }

    if (data.friend_game === "Friends") {
      const friendUsers = await userCollection
        .where("notify_only_from_friends", "==", true)
        .get();
      friendUsers.docs.forEach((doc) => users.add(doc.ref.path));
    }

    if (data.member_discount === "Yes") {
      const memberDiscountUsers = await userCollection
        .where("notify_member_discount", "==", true)
        .get();
      memberDiscountUsers.docs.forEach((doc) => users.add(doc.ref.path));
    }

    return { user_refs: Array.from(users) };
  });

exports.deleteAccount = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    const version = "deleteAccount-v2";
    let uid = context.auth?.uid;
    if (!uid) {
      const idToken = data?.idToken;
      if (typeof idToken === "string" && idToken.length > 0) {
        try {
          const decoded = await admin.auth().verifyIdToken(idToken);
          uid = decoded.uid;
          console.log("deleteAccount verified idToken", { uid, version });
        } catch (error) {
          console.error("deleteAccount idToken verify failed", error);
        }
      }
    }
    if (!uid) {
      console.error("deleteAccount unauthenticated", {
        hasAuth: !!context.auth,
        idTokenLength:
          typeof data?.idToken === "string" ? data.idToken.length : 0,
        dataKeys: data ? Object.keys(data) : [],
        version,
      });
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required.",
        {
          hasAuth: !!context.auth,
          idTokenLength:
            typeof data?.idToken === "string" ? data.idToken.length : 0,
          version,
        },
      );
    }
    const userRef = firestore.doc(`users/${uid}`);

    try {
      console.log("deleteAccount start", { uid, version });
      const userDoc = await userRef.get();
      const displayName = userDoc.exists
        ? userDoc.data()?.display_name || ""
        : "";
      console.log("deleteAccount userDoc", {
        exists: userDoc.exists,
        displayName,
      });

      const tokensSnap = await userRef.collection(kFcmTokensCollection).get();
      console.log("deleteAccount tokenCount", { count: tokensSnap.size });
      if (!tokensSnap.empty) {
        const batch = firestore.batch();
        tokensSnap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }
      console.log("deleteAccount tokensDeleted");

      await removeUserFromArrays(userRef);
      console.log("deleteAccount removedFromArrays");

      if (displayName) {
        const usernameRef = firestore.doc(`usernames/${displayName}`);
        const usernameDoc = await usernameRef.get();
        console.log("deleteAccount usernameDoc", {
          exists: usernameDoc.exists,
          uid: usernameDoc.exists ? usernameDoc.data()?.uid?.path : null,
        });
        if (
          usernameDoc.exists &&
          usernameDoc.data()?.uid?.path === userRef.path
        ) {
          await usernameRef.delete();
        }
      }
      console.log("deleteAccount usernameDeleted");

      await userRef.delete();
      console.log("deleteAccount userDocDeleted");
      await admin.auth().deleteUser(uid);
      console.log("deleteAccount authDeleted");

      return { ok: true, version };
    } catch (error) {
      console.error("deleteAccount failed", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to delete account.",
        { message: error?.message ?? String(error) },
      );
    }
  });

exports.completeOnboarding = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required.",
      );
    }
    const userDocPath = data?.userDocPath;
    if (typeof userDocPath !== "string" || userDocPath.split("/").length !== 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid user document path is required.",
      );
    }
    if (context.auth.uid !== userDocPath.split("/")[1]) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Authenticated user doesn't match provided user reference.",
      );
    }

    try {
      await firestore.doc(userDocPath).update({
        onboarding_completed: true,
      });
      return { success: true };
    } catch (error) {
      console.error("completeOnboarding failed", error);
      throw new functions.https.HttpsError(
        "internal",
        "Unable to mark onboarding as completed.",
        { message: error?.message ?? String(error) },
      );
    }
  });

exports.checkOnboardingComplete = functions
  .region("us-west2")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required.",
      );
    }
    const userDocPath = data?.userDocPath;
    if (typeof userDocPath !== "string" || userDocPath.split("/").length !== 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid user document path is required.",
      );
    }
    if (context.auth.uid !== userDocPath.split("/")[1]) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Authenticated user doesn't match provided user reference.",
      );
    }

    try {
      const doc = await firestore.doc(userDocPath).get();
      const completed = doc.exists && doc.data()?.onboarding_completed === true;
      return { completed };
    } catch (error) {
      console.error("checkOnboardingComplete failed", error);
      throw new functions.https.HttpsError(
        "internal",
        "Unable to verify onboarding status.",
        { message: error?.message ?? String(error) },
      );
    }
  });

async function sendPushNotifications(snapshot) {
  const notificationData = snapshot.data();
  const title = notificationData.notification_title || "";
  const body = notificationData.notification_text || "";
  const imageUrl = notificationData.notification_image_url || "";
  const sound = notificationData.notification_sound || "";
  const parameterData = notificationData.parameter_data || "";
  const targetAudience = notificationData.target_audience || "";
  const initialPageName = notificationData.initial_page_name || "";
  const userRefsStr = notificationData.user_refs || "";
  const batchIndex = notificationData.batch_index || 0;
  const numBatches = notificationData.num_batches || 0;
  const status = notificationData.status || "";

  if (status !== "" && status !== "started") {
    console.log(`Already processed ${snapshot.ref.path}. Skipping...`);
    return;
  }

  if (title === "" || body === "") {
    await snapshot.ref.update({ status: "failed" });
    return;
  }

  const userRefs = userRefsStr === "" ? [] : userRefsStr.trim().split(",");
  var tokens = new Set();
  if (userRefsStr) {
    for (var userRef of userRefs) {
      const userTokens = await firestore
        .doc(userRef)
        .collection(kFcmTokensCollection)
        .get();
      userTokens.docs.forEach((token) => {
        if (typeof token.data().fcm_token !== undefined) {
          tokens.add(token.data().fcm_token);
        }
      });
    }
  } else {
    var userTokensQuery = firestore.collectionGroup(kFcmTokensCollection);
    // Handle batched push notifications by splitting tokens up by document
    // id.
    if (numBatches > 0) {
      userTokensQuery = userTokensQuery
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAt(getDocIdBound(batchIndex, numBatches))
        .endBefore(getDocIdBound(batchIndex + 1, numBatches));
    }
    const userTokens = await userTokensQuery.get();
    userTokens.docs.forEach((token) => {
      const data = token.data();
      const audienceMatches =
        targetAudience === "All" || data.device_type === targetAudience;
      if (audienceMatches && typeof data.fcm_token !== undefined) {
        tokens.add(data.fcm_token);
      }
    });
  }

  const tokensArr = Array.from(tokens);
  var messageBatches = [];
  for (let i = 0; i < tokensArr.length; i += 500) {
    const tokensBatch = tokensArr.slice(i, Math.min(i + 500, tokensArr.length));
    const messages = {
      notification: {
        title,
        body,
        ...(imageUrl && { imageUrl: imageUrl }),
      },
      data: {
        initialPageName,
        parameterData,
      },
      android: {
        notification: {
          ...(sound && { sound: sound }),
        },
      },
      apns: {
        payload: {
          aps: {
            ...(sound && { sound: sound }),
          },
        },
      },
      tokens: tokensBatch,
    };
    messageBatches.push(messages);
  }

  var numSent = 0;
  await Promise.all(
    messageBatches.map(async (messages) => {
      const response = await admin.messaging().sendEachForMulticast(messages);
      numSent += response.successCount;
    }),
  );

  await snapshot.ref.update({ status: "succeeded", num_sent: numSent });
}

function getUserFcmTokensCollection(userDocPath) {
  return firestore.doc(userDocPath).collection(kFcmTokensCollection);
}

async function removeUserFromArrays(userRef) {
  const batchUpdates = async (query) => {
    const snap = await query.get();
    if (snap.empty) return;
    let batch = firestore.batch();
    let opCount = 0;

    for (const doc of snap.docs) {
      batch.update(doc.ref, {
        friends: admin.firestore.FieldValue.arrayRemove([userRef]),
        friend_requests: admin.firestore.FieldValue.arrayRemove([userRef]),
      });
      opCount++;
      if (opCount >= 450) {
        await batch.commit();
        batch = firestore.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) {
      await batch.commit();
    }
  };

  await batchUpdates(
    firestore.collection("users").where("friends", "array-contains", userRef),
  );
  await batchUpdates(
    firestore
      .collection("users")
      .where("friend_requests", "array-contains", userRef),
  );
}

function getDocIdBound(index, numBatches) {
  if (index <= 0) {
    return "users/(";
  }
  if (index >= numBatches) {
    return "users/}";
  }
  const numUidChars = 62;
  const twoCharOptions = Math.pow(numUidChars, 2);

  var twoCharIdx = (index * twoCharOptions) / numBatches;
  var firstCharIdx = Math.floor(twoCharIdx / numUidChars);
  var secondCharIdx = Math.floor(twoCharIdx % numUidChars);
  const firstChar = getCharForIndex(firstCharIdx);
  const secondChar = getCharForIndex(secondCharIdx);
  return "users/" + firstChar + secondChar;
}

function getCharForIndex(charIdx) {
  if (charIdx < 10) {
    return String.fromCharCode(charIdx + "0".charCodeAt(0));
  } else if (charIdx < 36) {
    return String.fromCharCode("A".charCodeAt(0) + charIdx - 10);
  } else {
    return String.fromCharCode("a".charCodeAt(0) + charIdx - 36);
  }
}
exports.onUserDeleted = functions
  .region("us-west2")
  .auth.user()
  .onDelete(async (user) => {
    let firestore = admin.firestore();
    let userRef = firestore.doc("users/" + user.uid);
    console.log("onUserDeleted start", { uid: user.uid });
    const userDoc = await userRef.get();
    const displayName = userDoc.exists ? userDoc.data()?.display_name || null : null;
    const tokensSnap = await userRef.collection(kFcmTokensCollection).get();
    if (!tokensSnap.empty) {
      const batch = firestore.batch();
      tokensSnap.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
    await removeUserFromArrays(userRef);
    if (displayName) {
      const usernameRef = firestore.doc("usernames/" + displayName);
      const usernameDoc = await usernameRef.get();
      if (
        usernameDoc.exists &&
        usernameDoc.data()?.uid?.path === userRef.path
      ) {
        await usernameRef.delete();
      }
    }
    await firestore.collection("users").doc(user.uid).delete();
    console.log("onUserDeleted userDocDeleted", { uid: user.uid });
    await firestore
      .collection("chat_messages")
      .where("user", "==", userRef)
      .get()
      .then(async (querySnapshot) => {
        for (var doc of querySnapshot.docs) {
          console.log(
            `Deleting document ${doc.id} from collection chat_messages`,
          );
          await doc.ref.delete();
        }
      });
  });

exports.monitorUsernameChanges = functions
  .region("us-west2")
  .firestore.document("users/{uid}")
  .onWrite(async (change, context) => {
    const beforeDisplayName = change.before.data()?.display_name || "";
    const afterDisplayName = change.after.data()?.display_name || "";
    if (beforeDisplayName === afterDisplayName || afterDisplayName === "") {
      return;
    }
    try {
      const usernameRef = firestore.doc(`usernames/${afterDisplayName}`);
      const usernameDoc = await usernameRef.get();
      if (
        !usernameDoc.exists ||
        usernameDoc.data()?.uid?.path !== change.after.ref.path
      ) {
        console.warn(
          `Username inconsistency detected for ${change.after.ref.path}:`,
          "display_name changed to",
          afterDisplayName,
          "without matching /usernames entry",
        );
      }
    } catch (error) {
      console.error("monitorUsernameChanges failed", error);
    }
  });
