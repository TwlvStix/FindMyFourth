const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

const kFcmTokensCollection = "fcm_tokens";
const kPushNotificationsCollection = "push_notifications";
const kUserPushNotificationsCollection = "user_push_notifications";
const kUserDevicesCollection = "devices";
const kAlertSubsCollection = "alertSubs";
const kUserNotificationsCollection = "notifications";
const kGameAlertCooldownMinutes = 60;
const firestore = admin.firestore();

const trustSystem = require("./trust_system");
const confirmationFlow = require("./confirmation_flow");
const trustProfileModule = require("./trust_profile");
const gameAlerts = require("./game_alerts");
const streaks = require("./streaks");
const testHarness = require("./test_harness");
// Remaining modules are lazy-required inside their handlers to reduce cold start.
// Node.js caches require() results, so repeated calls are free after the first load.

// Runtime options are set inline per function — see each trigger definition.

function extractUidFromJoinedEntry(entry) {
  if (!entry) {
    return null;
  }
  if (typeof entry === "string") {
    return entry;
  }
  if (typeof entry === "object" && typeof entry.id === "string") {
    return entry.id;
  }
  return null;
}

function extractJoinedUids(list) {
  if (!Array.isArray(list)) {
    return [];
  }
  const uids = [];
  for (const entry of list) {
    const uid = extractUidFromJoinedEntry(entry);
    if (uid) {
      uids.push(uid);
    }
  }
  return uids;
}

function userRefsFromUids(uids, db = firestore) {
  return uids.map((uid) => db.collection("users").doc(uid));
}

function getUserNotificationPrefs(userData) {
  const prefs = userData.notification_prefs || {};
  const gameAlerts = prefs.game_alerts || {};
  const chatAlerts = prefs.chat_alerts || {};
  const quietHours = prefs.quiet_hours || {};
  const pushEnabled =
    typeof prefs.push_enabled === "boolean" ? prefs.push_enabled : true;
  const gameAlertsEnabled =
    typeof gameAlerts.enabled === "boolean" ? gameAlerts.enabled : true;
  const chatAlertsEnabled =
    typeof chatAlerts.enabled === "boolean" ? chatAlerts.enabled : true;
  const chatDirectEnabled =
    typeof chatAlerts.direct === "boolean" ? chatAlerts.direct : true;
  const chatGroupEnabled =
    typeof chatAlerts.group === "boolean" ? chatAlerts.group : true;
  const styles = Array.isArray(gameAlerts.styles)
    ? gameAlerts.styles.filter((style) => typeof style === "string")
    : [];
  const mutedThreads = Array.isArray(prefs.muted_threads)
    ? prefs.muted_threads.filter((threadId) => typeof threadId === "string")
    : [];
  return {
    pushEnabled,
    gameAlertsEnabled,
    chatAlertsEnabled,
    chatDirectEnabled,
    chatGroupEnabled,
    styles,
    mutedThreads,
    quietHoursEnabled: quietHours.enabled === true,
    quietHoursStart:
      typeof quietHours.start === "string" ? quietHours.start : "22:00",
    quietHoursEnd: typeof quietHours.end === "string" ? quietHours.end : "07:00",
    digestMode:
      typeof prefs.digest_mode === "string" ? prefs.digest_mode : "instant",
  };
}

function buildGameNotificationContent(gameData, styleLabel) {
  const name = gameData.name_game || "New game";
  const course = gameData.course_play || "";
  const title = "New game posted";
  const suffix = styleLabel ? ` • ${styleLabel}` : "";
  const body = course ? `${name} at ${course}${suffix}` : `${name}${suffix}`;
  return { title, body };
}

function styleLabelForToken(token) {
  const map = {
    money: "Money game",
    vegas: "Vegas",
    skins: "Skins",
    match_play: "Match play",
    stroke_play: "Stroke play",
    stableford: "Stableford",
    competitive: "Competitive",
    for_fun: "For fun",
    friends: "Friends",
    member_discount: "Member discount",
    open: "Open to discuss",
  };
  return map[token] || token.replace(/_/g, " ");
}

function getUserDisplayName(userData) {
  if (!userData) {
    return "";
  }
  const displayName = userData.display_name;
  if (typeof displayName === "string" && displayName.trim().length > 0) {
    return displayName.trim();
  }
  const firstName =
    typeof userData.first_name === "string" ? userData.first_name.trim() : "";
  const lastName =
    typeof userData.last_name === "string" ? userData.last_name.trim() : "";
  const combined = `${firstName} ${lastName}`.trim();
  return combined;
}

exports.addFcmToken = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
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
  .runWith({ timeoutSeconds: 120, memory: "512MB" })
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
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
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

// Game alerts: Use the modularized implementation with gender eligibility checks.
exports.sendGameCreatedNotifications = gameAlerts.sendGameCreatedNotifications;

exports.sendChatMessageNotifications = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .firestore.document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data() || {};
    const chatId = context.params.chatId;
    const senderId =
      messageData.senderId || messageData.sender_id || messageData.sender;
    if (typeof senderId !== "string" || senderId.length === 0) {
      return;
    }

    const chatSnap = await firestore.collection("chats").doc(chatId).get();
    if (!chatSnap.exists) {
      return;
    }
    const chatData = chatSnap.data() || {};
    const memberIds = Array.isArray(chatData.memberIds)
      ? chatData.memberIds.filter((id) => typeof id === "string")
      : [];
    if (memberIds.length === 0) {
      return;
    }

    const recipients = memberIds.filter((id) => id !== senderId);
    if (recipients.length === 0) {
      return;
    }

    const senderSnap = await firestore.collection("users").doc(senderId).get();
    const senderName = senderSnap.exists
      ? getUserDisplayName(senderSnap.data())
      : "";
    const isDirect = chatData.type === "direct" || memberIds.length === 2;

    for (const uid of recipients) {
      const userRef = firestore.collection("users").doc(uid);
      const userSnap = await userRef.get();
      if (!userSnap.exists) {
        continue;
      }
      const prefs = getUserNotificationPrefs(userSnap.data() || {});
      if (!prefs.pushEnabled || !prefs.chatAlertsEnabled) {
        continue;
      }
      if (prefs.mutedThreads.includes(chatId)) {
        continue;
      }
      if (isDirect && !prefs.chatDirectEnabled) {
        continue;
      }
      if (!isDirect && !prefs.chatGroupEnabled) {
        continue;
      }
      if (prefs.digestMode === "off") {
        continue;
      }

      // Schedule debounced notification — cancels any pending task for this
      // chat+recipient pair and schedules a new one 8 seconds out
      try {
        const { scheduleDebouncedChatNotification } = require("./notifications/chat_debounce");
        await scheduleDebouncedChatNotification(
          chatId,
          uid,
          messageData,
          senderName,
          chatData,
          firestore,
        );
      } catch (error) {
        console.error('[ChatDebounce] Failed to schedule debounced notification', {
          chatId,
          uid,
          error: error.message,
        });
      }
    }
  });

exports.fetchReceiptants = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
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

    if (data.friend_game === "friends") {
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
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    const version = "deleteAccount-v3";
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

    try {
      await performAccountDeletion(uid, {
        deleteAuthUser: true,
        source: "callable_primary",
        version,
      });
      return { ok: true, version, deletionMode: "callable_primary", uid };
    } catch (error) {
      console.error("deleteAccount failed", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to delete account.",
        { message: error?.message ?? String(error) },
      );
    }
  });

/**
 * Resolves the authenticated user's UID from context.auth or data.idToken fallback.
 * Used by onboarding functions to handle race conditions during signup.
 * Follows the same pattern as deleteAccount (lines 932-944).
 */
async function resolveCallableUid(context, data, functionName) {
  let uid = context.auth?.uid;
  if (!uid) {
    const idToken = data?.idToken;
    if (typeof idToken === "string" && idToken.length > 0) {
      try {
        const decoded = await admin.auth().verifyIdToken(idToken);
        uid = decoded.uid;
        console.log(`${functionName} verified idToken`, { uid });
      } catch (error) {
        console.error(`${functionName} idToken verify failed`, error);
      }
    }
  }
  if (!uid) {
    console.error(`${functionName} unauthenticated`, {
      hasAuth: !!context.auth,
      idTokenLength:
        typeof data?.idToken === "string" ? data.idToken.length : 0,
    });
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required.",
    );
  }
  return uid;
}

exports.completeOnboarding = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    const uid = await resolveCallableUid(context, data, "completeOnboarding");
    const userDocPath = data?.userDocPath;
    if (typeof userDocPath !== "string" || userDocPath.split("/").length !== 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid user document path is required.",
      );
    }
    if (uid !== userDocPath.split("/")[1]) {
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
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    const uid = await resolveCallableUid(
      context,
      data,
      "checkOnboardingComplete",
    );
    const userDocPath = data?.userDocPath;
    if (typeof userDocPath !== "string" || userDocPath.split("/").length !== 2) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid user document path is required.",
      );
    }
    if (uid !== userDocPath.split("/")[1]) {
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
        .collection(kUserDevicesCollection)
        .get();
      userTokens.docs.forEach((token) => {
        if (typeof token.data().fcmToken !== "undefined") {
          tokens.add(token.data().fcmToken);
        }
      });
    }
  } else {
    var userTokensQuery = firestore.collectionGroup(kUserDevicesCollection);
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
        targetAudience === "All" || data.platform === targetAudience;
      if (audienceMatches && typeof data.fcmToken !== "undefined") {
        tokens.add(data.fcmToken);
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
        headers: {
          'apns-push-type': 'alert',
          'apns-priority': '10',
        },
        payload: {
          aps: {
            ...(sound && { sound: sound }),
            badge: 1,
            'mutable-content': 1,
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
        friends: admin.firestore.FieldValue.arrayRemove(userRef),
        friend_requests: admin.firestore.FieldValue.arrayRemove(userRef),
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

  // Remove user from games they've joined
  const removeFromGames = async () => {
    const gamesSnap = await firestore
      .collection("games")
      .where("joined_players", "array-contains", userRef)
      .get();

    if (gamesSnap.empty) return;
    let batch = firestore.batch();
    let opCount = 0;

    for (const doc of gamesSnap.docs) {
      batch.update(doc.ref, {
        joined_players: admin.firestore.FieldValue.arrayRemove(userRef),
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

  // Remove user from chat memberIds and users arrays
  const removeFromChats = async () => {
    const chatsSnap = await firestore
      .collection("chats")
      .where("memberIds", "array-contains", userRef.id)
      .get();

    if (chatsSnap.empty) return;
    let batch = firestore.batch();
    let opCount = 0;

    for (const doc of chatsSnap.docs) {
      const updates = {
        memberIds: admin.firestore.FieldValue.arrayRemove(userRef.id),
        users: admin.firestore.FieldValue.arrayRemove(userRef),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      // Remove user's unread count field
      updates[`unreadCountByUser.${userRef.id}`] =
        admin.firestore.FieldValue.delete();

      batch.update(doc.ref, updates);
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

  await Promise.all([
    batchUpdates(
      firestore.collection("users").where("friends", "array-contains", userRef),
    ),
    batchUpdates(
      firestore
        .collection("users")
        .where("friend_requests", "array-contains", userRef),
    ),
    removeFromGames(),
    removeFromChats(),
  ]);
}

function isAuthUserNotFoundError(error) {
  const code = error?.code || "";
  const message = (error?.message || "").toLowerCase();
  return (
    code === "auth/user-not-found" ||
    code === "user-not-found" ||
    message.includes("user-not-found")
  );
}

async function deleteUserTokens(userRef) {
  const tokensSnap = await userRef.collection(kUserDevicesCollection).get();
  if (tokensSnap.empty) {
    return 0;
  }
  const batch = firestore.batch();
  tokensSnap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return tokensSnap.size;
}

async function cleanupUsernameReservation(userRef, displayName) {
  if (!displayName) {
    return false;
  }
  const usernameRef = firestore.doc(`usernames/${displayName}`);
  const usernameDoc = await usernameRef.get();
  if (
    usernameDoc.exists &&
    usernameDoc.data()?.uid?.path === userRef.path
  ) {
    await usernameRef.delete();
    return true;
  }
  return false;
}

async function performAccountDeletion(
  uid,
  { deleteAuthUser, source, version },
) {
  const startedAt = Date.now();
  const userRef = firestore.doc(`users/${uid}`);
  console.log("accountDeletion start", {
    uid,
    source,
    version,
    deleteAuthUser,
  });

  const userDoc = await userRef.get();
  const displayName = userDoc.exists ? userDoc.data()?.display_name || "" : "";
  console.log("accountDeletion userDoc", {
    uid,
    source,
    exists: userDoc.exists,
    displayName,
  });

  const deletedTokenCount = await deleteUserTokens(userRef);
  console.log("accountDeletion tokensDeleted", {
    uid,
    source,
    deletedTokenCount,
  });

  await removeUserFromArrays(userRef);
  console.log("accountDeletion refsRemoved", { uid, source });

  const usernameDeleted = await cleanupUsernameReservation(userRef, displayName);
  console.log("accountDeletion usernameCleaned", {
    uid,
    source,
    usernameDeleted,
  });

  await firestore.recursiveDelete(userRef);
  console.log("accountDeletion recursiveDeleteComplete", { uid, source });

  if (deleteAuthUser) {
    try {
      await admin.auth().deleteUser(uid);
      console.log("accountDeletion authDeleted", { uid, source });
    } catch (error) {
      if (isAuthUserNotFoundError(error)) {
        console.log("accountDeletion authAlreadyDeleted", { uid, source });
      } else {
        throw error;
      }
    }
  }

  const durationMs = Date.now() - startedAt;
  console.log("accountDeletion complete", {
    uid,
    source,
    version,
    durationMs,
  });
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
    const version = "deleteAccount-v3";
    try {
      await performAccountDeletion(user.uid, {
        deleteAuthUser: false,
        source: "auth_trigger",
        version,
      });
    } catch (error) {
      console.error("onUserDeleted failed", { uid: user.uid, error });
      throw error;
    }
  });

/**
 * Handler logic for syncGameChatMembers.
 * Extracted for testability - accepts optional db parameter for mock injection.
 *
 * @param {Object} change - Firestore change object with before/after snapshots
 * @param {Object} context - Cloud Functions context with params
 * @param {Object} db - Firestore instance (defaults to firestore for production)
 */
async function _syncGameChatMembersHandler(change, context, db = firestore) {
  const before = change.before.data() || {};
  const after = change.after.data() || {};

  const beforeJoined = extractJoinedUids(before.joined_players);
  const afterJoined = extractJoinedUids(after.joined_players);

  const beforeSet = new Set(beforeJoined);
  const afterSet = new Set(afterJoined);

  const added = afterJoined.filter((uid) => !beforeSet.has(uid));
  const removed = beforeJoined.filter((uid) => !afterSet.has(uid));

  if (added.length === 0 && removed.length === 0) {
    return;
  }

  const chatRef = after.chatRef;
  if (!(chatRef instanceof admin.firestore.DocumentReference)) {
    console.log(
      `syncGameChatMembers: missing chatRef for game ${context.params.gameId}`,
    );
    return;
  }

  const chatId = chatRef.id;
  const chatDocRef = db.collection("chats").doc(chatId);

  // Check if chat document exists - if not, this is non-retryable
  const chatDoc = await chatDocRef.get();
  if (!chatDoc.exists) {
    console.warn(
      `syncGameChatMembers: chat ${chatId} not found for game ${context.params.gameId}`,
      { added, removed },
    );
    return; // Non-retryable - don't throw
  }

  const batch = db.batch();

  // Handle removed members
  if (removed.length > 0) {
    const removeUpdate = {
      memberIds: admin.firestore.FieldValue.arrayRemove(...removed),
      users: admin.firestore.FieldValue.arrayRemove(
        ...userRefsFromUids(removed, db),
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    for (const uid of removed) {
      removeUpdate[`unreadCountByUser.${uid}`] =
        admin.firestore.FieldValue.delete();
      // Delete user's chatRef for this chat
      batch.delete(db.doc(`users/${uid}/chatRefs/${chatId}`));
    }
    batch.update(chatDocRef, removeUpdate);
  }

  // Handle added members
  if (added.length > 0) {
    const addUpdate = {
      memberIds: admin.firestore.FieldValue.arrayUnion(...added),
      users: admin.firestore.FieldValue.arrayUnion(
        ...userRefsFromUids(added, db),
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    for (const uid of added) {
      addUpdate[`unreadCountByUser.${uid}`] = 0;
      // Record join timestamp for "fresh start on rejoin" feature
      addUpdate[`memberJoinedAt.${uid}`] =
        admin.firestore.FieldValue.serverTimestamp();
      // Create user's chatRef for this chat
      batch.set(db.doc(`users/${uid}/chatRefs/${chatId}`), {
        chatId: chatId,
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    batch.update(chatDocRef, addUpdate);
  }

  try {
    await batch.commit();
    console.log(
      `syncGameChatMembers: synced ${added.length} added, ${removed.length} removed for game ${context.params.gameId}`,
    );
  } catch (error) {
    console.error(
      `syncGameChatMembers: failed for game ${context.params.gameId}`,
      { error: error.message, added, removed },
    );
    throw error; // Retry on failure
  }
}

// Export handler for testing
exports._syncGameChatMembersHandler = _syncGameChatMembersHandler;

/**
 * Syncs chat membership when game participants change.
 *
 * Maintains consistency across three data locations:
 * 1. games/{gameId}.joined_players - game participation (source of truth)
 * 2. chats/{chatId}.memberIds - chat membership
 * 3. users/{uid}/chatRefs/{chatId} - user's chat list for queries
 *
 * Uses batched write for atomicity - all updates succeed or all fail.
 * Throws on failure to enable Cloud Functions retry.
 */
exports.syncGameChatMembers = functions
  .region("us-west2")
  .firestore.document("games/{gameId}")
  .onUpdate((change, context) => _syncGameChatMembersHandler(change, context));

/**
 * Handler logic for onHostAddsPlayer.
 * Extracted for testability - accepts optional db parameter for mock injection.
 *
 * Detects when a host adds a player to a game by tracking the host_added_players
 * field, which is written alongside joined_players when the host manually adds
 * someone. This distinguishes host-initiated adds from self-joins.
 *
 * @param {Object} change - Firestore change object with before/after snapshots
 * @param {Object} context - Cloud Functions context with params
 * @param {Object} db - Firestore instance (defaults to firestore for production)
 */
async function _onHostAddsPlayerHandler(change, context, db = firestore) {
  const before = change.before.data() || {};
  const after = change.after.data() || {};

  // Track host_added_players changes (UIDs added by host, not self-joined)
  const beforeHostAdded = new Set(before.host_added_players || []);
  const afterHostAdded = new Set(after.host_added_players || []);
  const newlyHostAdded = [...afterHostAdded].filter(
    (uid) => !beforeHostAdded.has(uid)
  );

  if (newlyHostAdded.length === 0) {
    return;
  }

  // Get host info
  const hostUid = after.uid;
  if (!hostUid) {
    console.log(
      `onHostAddsPlayer: missing host uid for game ${context.params.gameId}`
    );
    return;
  }

  // Fetch host profile
  const hostDoc = await db.collection("users").doc(hostUid).get();
  const hostData = hostDoc.exists ? hostDoc.data() : {};
  const hostName = hostData.display_name || "A host";
  const hostAvatarUrl = hostData.photo_url || null;

  // Get game info
  const courseName = after.course_play || "a course";
  const gameDate = _formatGameDateWithTime(after.date);

  // Send notification to each newly host-added player
  for (const addedUid of newlyHostAdded) {
    try {
      const { onPlayerAddedByHost } = require("./host_add_notifications");
      await onPlayerAddedByHost(
        addedUid,
        hostUid,
        hostName,
        context.params.gameId,
        courseName,
        gameDate,
        hostAvatarUrl,
        db
      );
      console.log(
        `onHostAddsPlayer: notified ${addedUid} for game ${context.params.gameId}`
      );
    } catch (err) {
      // Non-fatal: log and continue to other players
      console.error(
        `onHostAddsPlayer: failed to notify ${addedUid} for game ${context.params.gameId}:`,
        err
      );
    }
  }
}

/**
 * Formats a Firestore Timestamp to a human-readable date with day of week and time.
 * e.g., Timestamp for 2026-03-15 10:00 → "Saturday, Mar 15 at 10:00 AM"
 *
 * @param {admin.firestore.Timestamp|null} teeTimeTs - Firestore timestamp
 * @returns {string} Formatted date string
 */
function _formatGameDateWithTime(teeTimeTs) {
  if (!teeTimeTs || typeof teeTimeTs.toDate !== "function") return "an upcoming game";
  const d = teeTimeTs.toDate();

  const dayOfWeek = d.toLocaleDateString("en-US", {
    weekday: "long",
    timeZone: "UTC",
  });
  const monthDay = d.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    timeZone: "UTC",
  });
  const time = d.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: "UTC",
  });

  return `${dayOfWeek}, ${monthDay} at ${time}`;
}

// Export handler for testing
exports._onHostAddsPlayerHandler = _onHostAddsPlayerHandler;
exports._formatGameDateWithTime = _formatGameDateWithTime;

/**
 * Sends a notification when a host manually adds a player to their game.
 *
 * Triggers on games/{gameId} onUpdate, detects when host_added_players array
 * has new entries, and notifies each added player via the Trust System router.
 *
 * This is separate from syncGameChatMembers which handles all player changes -
 * this function only fires for host-initiated adds (not self-joins).
 */
exports.onHostAddsPlayer = functions
  .region("us-west2")
  .firestore.document("games/{gameId}")
  .onUpdate((change, context) => _onHostAddsPlayerHandler(change, context));

/**
 * Handler logic for declineAddedSpot.
 * Extracted for testability - accepts optional db parameter for mock injection.
 *
 * Called when a player declines a spot they were added to by the host.
 * Removes the player from the game and notifies the host.
 *
 * @param {Object} data - Request data with gameId
 * @param {Object} context - Cloud Functions context with auth
 * @param {Object} db - Firestore instance (defaults to firestore for production)
 */
async function _declineAddedSpotHandler(data, context, db = firestore) {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required"
    );
  }

  const { gameId } = data;
  const playerUid = context.auth.uid;

  if (!gameId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "gameId is required"
    );
  }

  // Get game document
  const gameRef = db.collection("games").doc(gameId);
  const gameDoc = await gameRef.get();

  if (!gameDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Game not found");
  }

  const gameData = gameDoc.data();
  const hostUid = gameData.uid;

  // Verify the player was actually host-added
  const hostAddedPlayers = gameData.host_added_players || [];
  if (!hostAddedPlayers.includes(playerUid)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Player was not added by host"
    );
  }

  // Get player info for notification
  const playerDoc = await db.collection("users").doc(playerUid).get();
  const playerData = playerDoc.exists ? playerDoc.data() : {};
  const playerName = playerData.display_name || "A player";
  const playerAvatarUrl = playerData.photo_url || null;

  // Get game info for notification
  const courseName = gameData.course_play || "your game";

  // Remove player from game
  const playerRef = db.collection("users").doc(playerUid);
  await gameRef.update({
    joined_players: admin.firestore.FieldValue.arrayRemove(playerRef),
    host_added_players: admin.firestore.FieldValue.arrayRemove(playerUid),
  });

  // Notify host that spot is back open
  try {
    const { onPlayerDeclinedSpot } = require("./host_add_notifications");
    await onPlayerDeclinedSpot(
      hostUid,
      playerUid,
      playerName,
      gameId,
      courseName,
      playerAvatarUrl,
      db
    );
    console.log(
      `declineAddedSpot: notified host ${hostUid} that ${playerUid} declined game ${gameId}`
    );
  } catch (err) {
    // Non-fatal: player was already removed, just log notification failure
    console.error(
      `declineAddedSpot: failed to notify host for game ${gameId}:`,
      err
    );
  }

  return { success: true, gameId, playerUid };
}

// Export handler for testing
exports._declineAddedSpotHandler = _declineAddedSpotHandler;

/**
 * Callable function for a player to decline a spot they were added to by the host.
 *
 * Removes the player from the game and notifies the host that the spot is back open.
 * The player must have been added via host_added_players (not self-joined).
 *
 * @param {Object} data - { gameId: string }
 * @returns {{ success: boolean, gameId: string, playerUid: string }}
 */
exports.declineAddedSpot = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall((data, context) => _declineAddedSpotHandler(data, context));

/**
 * Handler logic for reconcileChatMembership.
 * Extracted for testability - accepts optional db parameter for mock injection.
 *
 * @param {Object} data - Request data with gameId
 * @param {Object} context - Cloud Functions context with auth
 * @param {Object} db - Firestore instance (defaults to firestore for production)
 */
async function _reconcileChatMembershipHandler(data, context, db = firestore) {
  // Enforce admin-only access
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required",
    );
  }
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin access required",
    );
  }

  const { gameId } = data;

  if (!gameId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "gameId is required",
    );
  }

  const gameDoc = await db.collection("games").doc(gameId).get();
  if (!gameDoc.exists) {
    return {
      status: "game_not_found",
      gameId,
      chatId: null,
      fixes: 0,
      added: [],
      removed: [],
    };
  }

  const gameData = gameDoc.data();
  const chatRef = gameData.chatRef;
  if (!(chatRef instanceof admin.firestore.DocumentReference)) {
    return {
      status: "no_chat",
      gameId,
      chatId: null,
      fixes: 0,
      added: [],
      removed: [],
    };
  }

  const chatId = chatRef.id;
  const joinedUids = extractJoinedUids(gameData.joined_players);

  const chatDoc = await db.collection("chats").doc(chatId).get();
  if (!chatDoc.exists) {
    return {
      status: "chat_not_found",
      gameId,
      chatId,
      fixes: 0,
      added: [],
      removed: [],
    };
  }

  const chatData = chatDoc.data() || {};
  // Normalize memberIds - ensure it's a string array
  const rawMemberIds = chatData.memberIds;
  const memberIds = Array.isArray(rawMemberIds)
    ? rawMemberIds.filter((id) => typeof id === "string")
    : [];

  const joinedSet = new Set(joinedUids);
  const memberSet = new Set(memberIds);

  // Find UIDs that need to be added (in game but not in chat)
  const toAdd = joinedUids.filter((uid) => !memberSet.has(uid));

  // Find UIDs that need to be removed (in chat but not in game)
  const toRemove = memberIds.filter((uid) => !joinedSet.has(uid));

  if (toAdd.length === 0 && toRemove.length === 0) {
    return {
      status: "ok",
      gameId,
      chatId,
      fixes: 0,
      added: [],
      removed: [],
    };
  }

  const batch = db.batch();
  const chatDocRef = db.collection("chats").doc(chatId);

  // Add missing members
  if (toAdd.length > 0) {
    const addUpdate = {
      memberIds: admin.firestore.FieldValue.arrayUnion(...toAdd),
      users: admin.firestore.FieldValue.arrayUnion(
        ...userRefsFromUids(toAdd, db),
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    for (const uid of toAdd) {
      addUpdate[`unreadCountByUser.${uid}`] = 0;
      addUpdate[`memberJoinedAt.${uid}`] =
        admin.firestore.FieldValue.serverTimestamp();
      batch.set(db.doc(`users/${uid}/chatRefs/${chatId}`), {
        chatId: chatId,
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    batch.update(chatDocRef, addUpdate);
  }

  // Remove orphaned members
  if (toRemove.length > 0) {
    const removeUpdate = {
      memberIds: admin.firestore.FieldValue.arrayRemove(...toRemove),
      users: admin.firestore.FieldValue.arrayRemove(
        ...userRefsFromUids(toRemove, db),
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    for (const uid of toRemove) {
      removeUpdate[`unreadCountByUser.${uid}`] =
        admin.firestore.FieldValue.delete();
      batch.delete(db.doc(`users/${uid}/chatRefs/${chatId}`));
    }
    batch.update(chatDocRef, removeUpdate);
  }

  await batch.commit();

  console.log(
    `reconcileChatMembership: fixed ${toAdd.length} added, ${toRemove.length} removed for game ${gameId}`,
  );

  return {
    status: "fixed",
    gameId,
    chatId,
    fixes: toAdd.length + toRemove.length,
    added: toAdd,
    removed: toRemove,
  };
}

// Export handler for testing
exports._reconcileChatMembershipHandler = _reconcileChatMembershipHandler;

/**
 * Reconcile chat membership for a game.
 *
 * Repairs historical drift by ensuring consistency between:
 * 1. games/{gameId}.joined_players (source of truth)
 * 2. chats/{chatId}.memberIds
 * 3. users/{uid}/chatRefs/{chatId}
 *
 * Call this for games that may have membership desync from before
 * the atomic syncGameChatMembers trigger was deployed.
 *
 * AUTHORIZATION: Admin-only. Requires context.auth.token.admin === true.
 */
exports.reconcileChatMembership = functions
  .region("us-west2")
  .https.onCall((data, context) =>
    _reconcileChatMembershipHandler(data, context),
  );

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
        usernameDoc.data()?.uid !== context.params.uid
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

exports.syncUsernameIndex = functions
  .region("us-west2")
  .firestore.document("users/{uid}")
  .onWrite(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const beforeDisplayName = before.display_name || "";
    const afterDisplayName = after.display_name || "";

    if (beforeDisplayName === afterDisplayName) {
      return;
    }
    if (!afterDisplayName) {
      return;
    }

    const firestore = admin.firestore();
    const userRef = change.after.ref;
    const usernames = firestore.collection("usernames");
    const newUsernameRef = usernames.doc(afterDisplayName);

    try {
      const newUsernameDoc = await newUsernameRef.get();
      if (
        !newUsernameDoc.exists ||
        newUsernameDoc.data()?.uid !== context.params.uid
      ) {
        await newUsernameRef.set(
          {
            uid: context.params.uid,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      if (beforeDisplayName) {
        const oldUsernameRef = usernames.doc(beforeDisplayName);
        const oldUsernameDoc = await oldUsernameRef.get();
        if (
          oldUsernameDoc.exists &&
          oldUsernameDoc.data()?.uid === context.params.uid
        ) {
          await oldUsernameRef.delete();
        }
      }
    } catch (error) {
      console.error("syncUsernameIndex failed", error);
    }
  });

/**
 * Cloud Function to delete a chat and all its messages.
 * Uses admin privileges to bypass security rules for efficient batch deletion.
 *
 * @param {Object} data - { chatId: string }
 * @param {Object} context - Authentication context
 * @returns {Promise<{success: boolean, messagesDeleted: number}>}
 */
const sgMail = require("@sendgrid/mail");

/**
 * Sends the signup confirmation email for a single Firebase Auth user.
 * This is the canonical implementation used by callable entrypoints.
 */
async function sendSignupConfirmationEmailForUid(uid, source = "callable") {
  // 1. Resolve email (Auth -> private/info fallback)
  let email;
  try {
    const authUser = await admin.auth().getUser(uid);
    email = authUser.email;
  } catch (authError) {
    console.error(
      `sendSignupConfirmationEmailForUid: Failed to get auth user ${uid}:`,
      authError,
    );
    throw new functions.https.HttpsError(
      "internal",
      "Failed to resolve user email",
    );
  }

  if (!email) {
    const privateDoc = await firestore.doc(`users/${uid}/private/info`).get();
    email = privateDoc.data()?.email;
  }

  if (!email) {
    console.log(
      `sendSignupConfirmationEmailForUid: No email found for user ${uid}`,
    );
    return { status: "skipped_no_email" };
  }

  // 2. Transactional idempotency check
  const userRef = firestore.doc(`users/${uid}`);
  let shouldSend = false;

  await firestore.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (userDoc.data()?.signup_email_sent_at) {
      shouldSend = false;
      return;
    }
    // Set marker atomically before sending.
    tx.set(
      userRef,
      {
        signup_email_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        signup_email_sent_source: source,
      },
      { merge: true },
    );
    shouldSend = true;
  });

  if (!shouldSend) {
    console.log(
      `sendSignupConfirmationEmailForUid: Already sent for user ${uid}`,
    );
    return { status: "skipped_already_sent" };
  }

  // 3. Send email (outside transaction)
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);

  const msg = {
    to: email,
    from: "findmyfourth@gmail.com",
    subject: "Welcome to Find My Fourth!",
    text: [
      "Welcome to Find My Fourth!",
      "",
      "Your account has been successfully created. We're excited to have you on the course!",
      "",
      "Head back to the app to complete your profile and start finding your next round.",
      "",
      "See you on the fairway,",
      "The Find My Fourth Team",
    ].join("\n"),
    html: [
      "<p>Welcome to <strong>Find My Fourth</strong>!</p>",
      "<p>Your account has been successfully created. We're excited to have you on the course!</p>",
      "<p>Head back to the app to complete your profile and start finding your next round.</p>",
      "<p>See you on the fairway,<br/>The Find My Fourth Team</p>",
    ].join(""),
  };

  try {
    await sgMail.send(msg);
    console.log(
      `sendSignupConfirmationEmailForUid: Welcome email sent to ${email} (uid: ${uid}, source: ${source})`,
    );
    return { status: "sent" };
  } catch (error) {
    console.error(
      `sendSignupConfirmationEmailForUid: Error sending to ${uid}:`,
      error,
    );
    // Email failed but marker is set - prevents retry spam.
    return { status: "send_failed" };
  }
}

/**
 * Sends a signup confirmation email to a newly created user.
 * Uses transactional idempotency to guarantee exactly-once delivery.
 *
 * Returns:
 * - { status: 'sent' } - Email was sent successfully
 * - { status: 'skipped_already_sent' } - Email was already sent (idempotent)
 * - { status: 'skipped_no_email' } - User has no email address
 * - { status: 'send_failed' } - SendGrid failed (marker set to prevent retry spam)
 */
exports.sendSignupConfirmationEmail = functions
  .region("us-west2")
  .runWith({ secrets: ["SENDGRID_API_KEY"] })
  .https.onCall(async (data, context) => {
    // NOTE: Legacy deployed-only onUserCreated should be deleted after verifying
    // this callable path in production.

    // 1. Require authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to request signup email.",
      );
    }
    const uid = context.auth.uid;
    return sendSignupConfirmationEmailForUid(uid, "callable");
  });

exports.deleteChat = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to delete a chat.",
      );
    }

    const { chatId } = data;
    const uid = context.auth.uid;

    // Validate input
    if (!chatId || typeof chatId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "chatId must be a non-empty string.",
      );
    }

    const firestore = admin.firestore();
    const chatRef = firestore.collection("chats").doc(chatId);

    try {
      // 1. Verify the chat exists and user has permission
      const chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Chat not found.",
        );
      }

      const chatData = chatSnapshot.data();
      const memberIds = Array.isArray(chatData.memberIds)
        ? chatData.memberIds
        : [];
      const chatType = chatData.type;

      // 2. Check permission based on chat type
      let hasPermission = false;

      if (chatType === "game") {
        // For game chats, only game owner can delete
        if (chatData.gameId) {
          const gameRef = firestore.collection("games").doc(chatData.gameId);
          const gameSnapshot = await gameRef.get();
          if (gameSnapshot.exists && gameSnapshot.data().uid === uid) {
            hasPermission = true;
          }
        }
      } else {
        // For direct chats, any member can delete
        hasPermission = memberIds.includes(uid);
      }

      if (!hasPermission) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You do not have permission to delete this chat.",
        );
      }

      // 3. Delete all messages in batches (admin SDK bypasses security rules)
      const messagesRef = chatRef.collection("messages");
      const messagesSnapshot = await messagesRef.get();
      const totalMessages = messagesSnapshot.docs.length;

      console.log(`Deleting chat ${chatId} with ${totalMessages} messages`);

      // Delete in batches of 500 (Firestore batch write limit)
      const batchSize = 500;
      let deletedCount = 0;

      for (let i = 0; i < totalMessages; i += batchSize) {
        const batch = firestore.batch();
        const end =
          i + batchSize < totalMessages ? i + batchSize : totalMessages;

        for (let j = i; j < end; j++) {
          batch.delete(messagesSnapshot.docs[j].ref);
          deletedCount++;
        }

        await batch.commit();
      }

      // 4. Delete the chat document itself
      await chatRef.delete();

      console.log(
        `Successfully deleted chat ${chatId} and ${deletedCount} messages`,
      );

      return {
        success: true,
        messagesDeleted: deletedCount,
      };
    } catch (error) {
      console.error("deleteChat Cloud Function failed:", error);

      // Re-throw HttpsErrors as-is
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Wrap other errors
      throw new functions.https.HttpsError(
        "internal",
        `Failed to delete chat: ${error.message}`,
      );
    }
  });

// Trust System — Stage 1 & 2
exports.recordCancellation = trustSystem.recordCancellation;
exports.onGameCreate = trustSystem.onGameCreate;
exports.checkPlayerRestriction = trustSystem.checkPlayerRestriction;
exports.markGhostNoShow = trustSystem.markGhostNoShow;

// Confirmation Flow — Stage 3
exports.onGameParticipantJoin = confirmationFlow.onGameParticipantJoin;
exports.onGameStatusToFilled = confirmationFlow.onGameStatusToFilled;
exports.onGameCreated = confirmationFlow.onGameCreated;
exports.onGameStatusToPlayed = confirmationFlow.onGameStatusToPlayed;
exports.onGameStatusToCancelled = confirmationFlow.onGameStatusToCancelled;
exports.submitHostCheckin = confirmationFlow.submitHostCheckin;
exports.submitPeerRatings = confirmationFlow.submitPeerRatings;
exports.submitFallbackConfirmation = confirmationFlow.submitFallbackConfirmation;
exports.submitPreGameConfirmation = confirmationFlow.submitPreGameConfirmation;

// Cloud Task receivers for confirmation flow
exports.processScheduledGameStatusChange = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest(confirmationFlow._processScheduledGameStatusChangeHandler);

exports.processScheduledWindowClose = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .https.onRequest(confirmationFlow._processScheduledWindowCloseHandler);

// Pre-game confirmation (partial games only)
exports.processScheduledPreGameCheck = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest(confirmationFlow._processScheduledPreGameCheckHandler);

exports.processScheduledPreGameTimeout = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest(confirmationFlow._processScheduledPreGameTimeoutHandler);

// Trust Profile — Stage 5
exports.updateTrustProfile = trustProfileModule.updateTrustProfile;
exports.getMyStanding = trustProfileModule.getMyStanding;

// Trust Notification Scheduler — Session 7
const trustNotificationScheduler = require('./notifications/trust/scheduler');
exports.processScheduledTrustNotification = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest(trustNotificationScheduler.processScheduledTrustNotificationHandler);

// Chat Notification Debounce — delivers batched chat notifications after 8s window
exports.deliverChatNotification = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest((req, res) => {
    const { deliverChatNotificationHandler } = require("./notifications/chat_debounce");
    return deliverChatNotificationHandler(req, res);
  });

// Flexible Game Nudge System
// Schedules nudges when 2+ players join a flexible game, cancels when time confirmed
exports.onFlexibleGameUpdate = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .firestore.document('games/{gameId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const gameId = context.params.gameId;

    // Only process flexible games
    if (after.schedule_type !== 'flexible') {
      // Case 2: schedule_type changed FROM flexible to confirmed
      // Cancel any pending nudges
      if (before.schedule_type === 'flexible') {
        console.log(`[FlexibleNudge] Game ${gameId} confirmed — cancelling nudges`);
        const { cancelFlexibleNudges } = require("./notifications/flexible_nudge");
        await cancelFlexibleNudges(gameId);
      }
      return null;
    }

    // Extract joined player counts
    const beforeJoined = extractJoinedUids(before.joined_players || []);
    const afterJoined = extractJoinedUids(after.joined_players || []);

    // Case 1: Player count went from <2 to >=2 → schedule nudges
    if (beforeJoined.length < 2 && afterJoined.length >= 2) {
      // Check that no confirmed date exists
      if (!after.date) {
        console.log(`[FlexibleNudge] Game ${gameId} reached 2+ players — scheduling nudges`);
        const { scheduleFlexibleNudges } = require("./notifications/flexible_nudge");
        await scheduleFlexibleNudges(gameId, after);
      }
    }

    return null;
  });

// Trust Background Workers — Session 10
const trustWorkers = require('./notifications/trust/workers');

exports.trustTokenHygieneJob = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 540, memory: '256MB' })
  .pubsub.schedule('0 3 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const result = await trustWorkers.trustTokenHygieneHandler();
    console.log('[trustTokenHygieneJob]', result);
  });

exports.trustQuietHoursCleanup = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 120, memory: '256MB' })
  .pubsub.schedule('every 15 minutes')
  .onRun(async () => {
    const result = await trustWorkers.trustQuietHoursCleanupHandler();
    console.log('[trustQuietHoursCleanup]', result);
  });

// Social Notifications — Friend Requests
const { onFriendRequestReceived, onFriendRequestAccepted } = require('./notifications/trust/hooks');

// Join Request Notifications — Vibe Floor
const {
  onJoinRequestReceived,
  onJoinRequestApproved,
  onJoinRequestDeclined,
  onRoundFilledBeforeApproval,
} = require('./join_request_notifications');

/**
 * Sends a push notification when a friend request is sent.
 * Called by Flutter after successfully adding to friend_requests array.
 */
exports.notifyFriendRequestSent = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { recipientUserId, senderName } = data;
    if (!recipientUserId || !senderName) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: recipientUserId, senderName');
    }

    try {
      // Fetch sender's avatar URL (photo or initials fallback)
      const senderDoc = await firestore.collection('users').doc(context.auth.uid).get();
      const { getAvatarUrl } = require("./utils/avatar-utils");
      const senderAvatarUrl = getAvatarUrl(senderDoc.data());

      const result = await onFriendRequestReceived(
        recipientUserId,
        context.auth.uid,
        senderName,
        senderAvatarUrl,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyFriendRequestSent error:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Sends a push notification when a friend request is accepted.
 * Called by Flutter after successfully accepting a friend request.
 */
exports.notifyFriendRequestAccepted = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { requesterUserId, acceptorName } = data;
    if (!requesterUserId || !acceptorName) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: requesterUserId, acceptorName');
    }

    try {
      // Fetch acceptor's avatar URL (photo or initials fallback)
      const acceptorDoc = await firestore.collection('users').doc(context.auth.uid).get();
      const { getAvatarUrl } = require("./utils/avatar-utils");
      const acceptorAvatarUrl = getAvatarUrl(acceptorDoc.data());

      const result = await onFriendRequestAccepted(
        requesterUserId,
        context.auth.uid,
        acceptorName,
        acceptorAvatarUrl,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyFriendRequestAccepted error:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

// Join Request Notifications — Vibe Floor

/**
 * Sends a push notification to the game owner when a join request is submitted.
 * Called by Flutter after successfully creating a join request.
 */
exports.notifyNewJoinRequest = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { gameId, ownerId, requesterName } = data;
    if (!gameId || !ownerId || !requesterName) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: gameId, ownerId, requesterName');
    }

    try {
      // Fetch requester's avatar URL (photo or initials fallback)
      const requesterDoc = await firestore.collection('users').doc(context.auth.uid).get();
      const { getAvatarUrl } = require("./utils/avatar-utils");
      const requesterAvatarUrl = getAvatarUrl(requesterDoc.data());

      const result = await onJoinRequestReceived(
        ownerId,
        context.auth.uid,
        requesterName,
        gameId,
        requesterAvatarUrl,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyNewJoinRequest error:', error);
      const message = error?.message || error?.errorInfo?.message || 'Notification delivery failed';
      throw new functions.https.HttpsError('internal', message);
    }
  });

/**
 * Sends a push notification to the player when their join request is approved.
 * Called by Flutter after successfully approving a join request.
 */
exports.notifyJoinRequestApproved = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { gameId, playerId } = data;
    if (!gameId || !playerId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: gameId, playerId');
    }

    try {
      // Fetch owner name, avatar, and game name for the notification
      const gameDoc = await firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        throw new Error('Game not found');
      }
      const gameData = gameDoc.data() || {};
      const gameName = gameData.name_game || 'a round';

      const ownerRef = gameData.userRef;
      let ownerName = 'The host';
      let ownerAvatarUrl = null;
      if (ownerRef) {
        const ownerDoc = await firestore.collection('users').doc(ownerRef.id).get();
        if (ownerDoc.exists) {
          const ownerData = ownerDoc.data() || {};
          ownerName = ownerData.first_name || ownerData.display_name || 'The host';
          const { getAvatarUrl } = require("./utils/avatar-utils");
          ownerAvatarUrl = getAvatarUrl(ownerData);
        }
      }

      const result = await onJoinRequestApproved(
        playerId,
        context.auth.uid,
        ownerName,
        gameId,
        gameName,
        ownerAvatarUrl,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyJoinRequestApproved error:', error);
      const message = error?.message || error?.errorInfo?.message || 'Notification delivery failed';
      throw new functions.https.HttpsError('internal', message);
    }
  });

/**
 * Sends a push notification to the player when their join request is declined.
 * Called by Flutter after successfully declining a join request.
 */
exports.notifyJoinRequestDeclined = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { gameId, playerId } = data;
    if (!gameId || !playerId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: gameId, playerId');
    }

    try {
      // Fetch game name for the notification
      const gameDoc = await firestore.collection('games').doc(gameId).get();
      const gameName = gameDoc.exists ? (gameDoc.data()?.name_game || 'a round') : 'a round';

      const result = await onJoinRequestDeclined(
        playerId,
        gameId,
        gameName,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyJoinRequestDeclined error:', error);
      const message = error?.message || error?.errorInfo?.message || 'Notification delivery failed';
      throw new functions.https.HttpsError('internal', message);
    }
  });

/**
 * Sends a push notification to the player when the round fills before their request was approved.
 * Called by Flutter when approval fails due to the round being full.
 */
exports.notifyRoundFilledBeforeApproval = functions
  .region('us-west2')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { gameId, playerId } = data;
    if (!gameId || !playerId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: gameId, playerId');
    }

    try {
      // Fetch game name for the notification
      const gameDoc = await firestore.collection('games').doc(gameId).get();
      const gameName = gameDoc.exists ? (gameDoc.data()?.name_game || 'This round') : 'This round';

      const result = await onRoundFilledBeforeApproval(
        playerId,
        gameId,
        gameName,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyRoundFilledBeforeApproval error:', error);
      const message = error?.message || error?.errorInfo?.message || 'Notification delivery failed';
      throw new functions.https.HttpsError('internal', message);
    }
  });

// ═══════════════════════════════════════════════════════════════
// AVATAR GENERATION TRIGGERS
// ═══════════════════════════════════════════════════════════════

/**
 * Generates an initials avatar when a user profile is created.
 * Only generates if the user doesn't have a photo_url and has a first_name.
 */
exports.onUserProfileCreated = functions
  .region("us-west2")
  .runWith({ memory: "512MB", timeoutSeconds: 60 })
  .firestore.document("users/{userId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const data = snap.data();

    // Only generate if no photo_url and we have a name
    if (!data.photo_url && data.first_name) {
      try {
        const { generateInitialsAvatar } = require("./avatar-generator");
        const avatarUrl = await generateInitialsAvatar(
          userId,
          data.first_name || "",
          data.last_name || ""
        );

        // Save URL to user doc
        await snap.ref.update({ avatar_initials_url: avatarUrl });
        console.log(`Generated initials avatar for user ${userId}`);
      } catch (error) {
        console.error(`Error generating initials avatar for ${userId}:`, error);
        // Don't throw - avatar generation is non-critical
      }
    }

    // Create default alertSub so the user receives game alert notifications.
    // Schema matches AlertSubscription.defaults() from the Flutter client.
    try {
      const now = admin.firestore.FieldValue.serverTimestamp();
      await admin.firestore().collection("alertSubs").doc(userId).set({
        userId,
        enabled: true,
        gameVibes: [],
        stakes: [],
        formats: [],
        handicapUses: [],
        courses: [],
        special: { games: false, twoVTwo: false, discount: false },
        createdAt: now,
        updatedAt: now,
      });
      console.log(`Created default alertSub for user ${userId}`);
    } catch (error) {
      console.error(`Error creating alertSub for ${userId}:`, error);
      // Don't throw - alertSub creation is non-critical
    }

    // Generate search tokens for substring-based user search
    try {
      const { generateSearchTokens } = require("./utils/search-tokens");
      const tokens = generateSearchTokens(
        data.display_name,
        data.first_name,
        data.last_name
      );
      if (tokens.length > 0) {
        await snap.ref.update({ search_tokens: tokens });
        console.log(`Generated ${tokens.length} search tokens for user ${userId}`);
      }
    } catch (error) {
      console.error(`Error generating search tokens for ${userId}:`, error);
      // Don't throw - search token generation is non-critical
    }
  });

/**
 * Regenerates initials avatar when a user's name changes.
 */
exports.onUserProfileUpdated = functions
  .region("us-west2")
  .runWith({ memory: "512MB", timeoutSeconds: 60 })
  .firestore.document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if name changed
    const nameChanged =
      before.first_name !== after.first_name ||
      before.last_name !== after.last_name ||
      before.display_name !== after.display_name;

    // Regenerate if name changed and we have a first name
    if (nameChanged && after.first_name) {
      try {
        const { generateInitialsAvatar } = require("./avatar-generator");
        const avatarUrl = await generateInitialsAvatar(
          context.params.userId,
          after.first_name || "",
          after.last_name || ""
        );
        await change.after.ref.update({ avatar_initials_url: avatarUrl });
        console.log(`Regenerated initials avatar for user ${context.params.userId}`);
      } catch (error) {
        console.error(`Error regenerating initials avatar:`, error);
        // Don't throw - avatar generation is non-critical
      }
    }

    // Regenerate search tokens when any name field changes
    if (nameChanged) {
      try {
        const { generateSearchTokens } = require("./utils/search-tokens");
        const tokens = generateSearchTokens(
          after.display_name,
          after.first_name,
          after.last_name
        );
        await change.after.ref.update({ search_tokens: tokens });
        console.log(`Regenerated search tokens for user ${context.params.userId}`);
      } catch (error) {
        console.error(`Error regenerating search tokens:`, error);
        // Don't throw - search token generation is non-critical
      }
    }
  });

// ═══════════════════════════════════════════════════════════════
// BEHAVIORAL DATASET FUNCTIONS (added 2026-02-21)
// ═══════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
// CALLABLE FUNCTIONS (invoked by your app)
// ─────────────────────────────────────────────

/**
 * Creates a new round and adds the host as the first participant.
 *
 * Call from app: firebase.functions().httpsCallable('createNewRound')({...})
 */
exports.createNewRound = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { createRound } = require("./src/booking");
    const roundId = await createRound({
      game_type: data.game_type,
      game_settings: data.game_settings || {},
      tee_time: data.tee_time,
      course_id: data.course_id,
      weather_snapshot: data.weather_snapshot || null,
      host_player_id: context.auth.uid,
      match_source: data.match_source,
      group_size: data.group_size,
    });

    return { success: true, round_id: roundId };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Adds a player to an existing round.
 */
exports.joinRound = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { addParticipant } = require("./src/booking");
    await addParticipant({
      round_id: data.round_id,
      player_id: context.auth.uid,
      role: "joined",
    });

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Finalizes the group and generates all pairwise match predictions.
 * Call this when the group is full or the host locks it in.
 */
exports.finalizeAndScore = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { finalizeGroup } = require("./src/booking");
    const { generatePairwiseMatches } = require("./src/matching");
    const playerIds = await finalizeGroup(data.round_id);
    const pairCount = await generatePairwiseMatches(data.round_id);

    return {
      success: true,
      players: playerIds.length,
      pairs_scored: pairCount,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Confirms participation (invited → confirmed).
 */
exports.confirmJoin = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { confirmParticipant } = require("./src/lifecycle");
    const result = await confirmParticipant(data.round_id, context.auth.uid);
    return { success: true, ...result };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Declines an invitation (invited → declined).
 */
exports.declineInvitation = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { declineParticipant } = require("./src/lifecycle");
    const result = await declineParticipant(data.round_id, context.auth.uid);
    return { success: true, ...result };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Cancels participation (confirmed → cancelled).
 * Automatically detects if cancellation happened after seeing the group.
 */
exports.cancelJoin = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { cancelParticipant } = require("./src/lifecycle");
    const result = await cancelParticipant(
      data.round_id,
      context.auth.uid,
      data.cancellation_reason || "other"
    );
    return { success: true, ...result };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Checks in a player at the course (confirmed → checked_in).
 */
exports.checkIn = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { checkInParticipant } = require("./src/lifecycle");
    const result = await checkInParticipant(data.round_id, context.auth.uid);
    return { success: true, ...result };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Marks the round as complete. Transitions all checked-in players to "completed"
 * and marks confirmed-but-absent players as no-shows.
 *
 * Typically called by the host or triggered by a game-end event.
 */
exports.endRound = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { completeRound } = require("./src/lifecycle");
    const { syncAllPlayerRounds } = require("./src/sync");
    const result = await completeRound(data.round_id);

    // Sync all player_rounds for this round
    await syncAllPlayerRounds(data.round_id);

    return { success: true, ...result };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * Submits post-round feedback.
 */
exports.submitRoundFeedback = functions
  .region("us-west2")
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
    const { submitFeedback } = require("./src/feedback");
    await submitFeedback({
      round_id: data.round_id,
      player_id: context.auth.uid,
      play_again: data.play_again ?? null,
      rating: data.rating ?? null,
      text_feedback: data.text_feedback ?? null,
      feedback_source: data.feedback_source || "in_app_prompt",
      prompt_attempt_count: data.prompt_attempt_count || 1,
    });

    // Re-sync this player's player_round with feedback data
    const { syncPlayerRound } = require("./src/sync");
    await syncPlayerRound(data.round_id, context.auth.uid);

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ─────────────────────────────────────────────
// FIRESTORE TRIGGERS (automatic sync)
// ─────────────────────────────────────────────

/**
 * When a participant document is created or updated,
 * sync it to the player_rounds denormalized collection.
 */
exports.onParticipantWrite = functions
  .region("us-west2")
  .firestore.document("rounds/{roundId}/participants/{playerId}")
  .onWrite(async (change, context) => {
    const { roundId, playerId } = context.params;

    // Don't sync if the document was deleted
    if (!change.after.exists) return;

    try {
      const { syncPlayerRound } = require("./src/sync");
      await syncPlayerRound(roundId, playerId);
    } catch (error) {
      console.error(`Failed to sync player_round for ${playerId} in ${roundId}:`, error);
    }
  });

/**
 * When feedback is written (including behavioral backfill),
 * re-sync the player_round to pick up the new labels.
 */
exports.onFeedbackWrite = functions
  .region("us-west2")
  .firestore.document("rounds/{roundId}/feedback/{playerId}")
  .onWrite(async (change, context) => {
    const { roundId, playerId } = context.params;

    if (!change.after.exists) return;

    try {
      const { syncPlayerRound } = require("./src/sync");
      await syncPlayerRound(roundId, playerId);
    } catch (error) {
      console.error(`Failed to sync player_round after feedback for ${playerId} in ${roundId}:`, error);
    }
  });

// ─────────────────────────────────────────────
// SCHEDULED FUNCTIONS (cron jobs)
// ─────────────────────────────────────────────

/**
 * Runs the behavioral backfill job daily at 3:00 AM.
 *
 * Checks all feedback docs that haven't been backfilled yet,
 * computes whether the player actually played again, and writes
 * the behavioral labels.
 */
exports.scheduledBehavioralBackfill = functions
  .region("us-west2")
  .pubsub.schedule("0 3 * * *") // 3:00 AM daily
  .timeZone("America/Vancouver") // Adjust to your timezone
  .onRun(async () => {
    try {
      const { runBehavioralBackfill } = require("./src/feedback");
      const results = await runBehavioralBackfill();
      console.log("Behavioral backfill results:", results);
    } catch (error) {
      console.error("Behavioral backfill failed:", error);
    }
  });

/**
 * Detects no-shows every hour.
 * Marks confirmed players as no-shows if the round started 60+ minutes ago.
 */
exports.scheduledNoShowDetection = functions
  .region("us-west2")
  .pubsub.schedule("0 * * * *") // Every hour
  .timeZone("America/Vancouver")
  .onRun(async () => {
    try {
      const { detectNoShows } = require("./src/lifecycle");
      const noShows = await detectNoShows(60);
      if (noShows.length > 0) {
        console.log(`Detected ${noShows.length} no-shows:`, noShows);
      }
    } catch (error) {
      console.error("No-show detection failed:", error);
    }
  });

/**
 * Exports flat event log to BigQuery every 6 hours.
 * Phase 3: Replace the placeholder in sync.js with actual BQ inserts.
 */
exports.scheduledBigQueryExport = functions
  .region("us-west2")
  .pubsub.schedule("0 */6 * * *") // Every 6 hours
  .timeZone("America/Vancouver")
  .onRun(async () => {
    try {
      const { exportEventsToBigQuery } = require("./src/sync");
      const results = await exportEventsToBigQuery(500);
      console.log("BigQuery export results:", results);
    } catch (error) {
      console.error("BigQuery export failed:", error);
    }
  });

// ─────────────────────────────────────────────
// CLEANUP FUNCTIONS
// ─────────────────────────────────────────────

const { cleanupCancelledGamesHandler, cleanupScheduledChatsHandler } = require("./cleanup");

/**
 * Nightly cleanup of cancelled games.
 * Runs at 3:00 AM Pacific daily.
 *
 * Deletes:
 * - Scheduled games: cancelled AND date < today
 * - Flexible games: cancelled AND cancelled_at < today
 */
exports.cleanupCancelledGames = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .pubsub.schedule("0 3 * * *") // 3:00 AM daily
  .timeZone("America/Los_Angeles")
  .onRun(async () => {
    try {
      const results = await cleanupCancelledGamesHandler();
      console.log("Cancelled games cleanup results:", results);
    } catch (error) {
      console.error("Cancelled games cleanup failed:", error);
    }
  });

/**
 * Cleanup of chats scheduled for deletion.
 * Runs at 3:30 AM Pacific daily (offset from game cleanup).
 *
 * Deletes chats where deletesAt <= now, including:
 * - All messages in the messages subcollection
 * - chatRefs for all members
 * - The chat document itself
 */
exports.cleanupScheduledChats = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .pubsub.schedule("30 3 * * *") // 3:30 AM daily
  .timeZone("America/Los_Angeles")
  .onRun(async () => {
    try {
      const results = await cleanupScheduledChatsHandler();
      console.log("Scheduled chats cleanup results:", results);
    } catch (error) {
      console.error("Scheduled chats cleanup failed:", error);
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Streak System
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: deployStreakFreeze
 * User deploys their freeze for the current week.
 */
exports.deployStreakFreeze = streaks.deployStreakFreeze;

/**
 * Friday 18:00 Vancouver: Nudge users with active streak who haven't played yet.
 */
exports.streakFridayNudge = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 540, memory: "256MB" })
  .pubsub.schedule("0 18 * * 5") // Friday 18:00
  .timeZone("America/Vancouver")
  .onRun(async () => {
    try {
      const result = await streaks.fridayNudgeHandler();
      console.log("[streakFridayNudge]", result);
    } catch (error) {
      console.error("[streakFridayNudge] failed:", error);
    }
  });

/**
 * Sunday 20:00 Vancouver: Prompt users with freeze available who haven't played.
 */
exports.streakSundayPrompt = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 540, memory: "256MB" })
  .pubsub.schedule("0 20 * * 0") // Sunday 20:00
  .timeZone("America/Vancouver")
  .onRun(async () => {
    try {
      const result = await streaks.sundayPromptHandler();
      console.log("[streakSundayPrompt]", result);
    } catch (error) {
      console.error("[streakSundayPrompt] failed:", error);
    }
  });

/**
 * Monday 00:01 Vancouver: Break streaks for users who missed previous week.
 */
exports.streakMondayRollover = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 540, memory: "256MB" })
  .pubsub.schedule("1 0 * * 1") // Monday 00:01
  .timeZone("America/Vancouver")
  .onRun(async () => {
    try {
      const result = await streaks.mondayRolloverHandler();
      console.log("[streakMondayRollover]", result);
    } catch (error) {
      console.error("[streakMondayRollover] failed:", error);
    }
  });

/**
 * Nov 1 00:05 Vancouver: Season close — reset streak state.
 */
exports.streakSeasonClose = functions
  .region("us-west2")
  .runWith({ timeoutSeconds: 540, memory: "256MB" })
  .pubsub.schedule("5 0 1 11 *") // Nov 1 00:05
  .timeZone("America/Vancouver")
  .onRun(async () => {
    try {
      const result = await streaks.seasonCloseHandler();
      console.log("[streakSeasonClose]", result);
    } catch (error) {
      console.error("[streakSeasonClose] failed:", error);
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// Notification Test Harness (iOS verification)
// ─────────────────────────────────────────────────────────────────────────────

exports.sendTestNotification = testHarness.sendTestNotification;
exports.generateDeliveryReport = testHarness.generateDeliveryReport;
