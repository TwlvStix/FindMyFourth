const functions = require("firebase-functions");
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

const kPushNotificationRuntimeOpts = {
  timeoutSeconds: 540,
  memory: "2GB",
};

function extractUidFromJoinedEntry(entry) {
  if (!entry) {
    return null;
  }
  if (typeof entry === "string") {
    return entry;
  }
  if (entry instanceof admin.firestore.DocumentReference) {
    return entry.id;
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

function userRefsFromUids(uids) {
  return uids.map((uid) => firestore.collection("users").doc(uid));
}

function normalizeStyleToken(value) {
  if (typeof value !== "string") {
    return "";
  }
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function mapGameStyleToken(value) {
  const normalized = normalizeStyleToken(value);
  const map = {
    money_game: "money",
    money: "money",
    all_fun: "for_fun",
    for_fun: "for_fun",
    open_to_discuss: "open",
    open: "open",
    match_play: "match_play",
    stroke_play: "stroke_play",
    stableford: "stableford",
    vegas: "vegas",
    skins: "skins",
    competitive: "competitive",
    friends: "friends",
  };
  return map[normalized] || normalized;
}

function extractGameStyleTokens(gameData) {
  const tokens = new Set();
  const styleGame = gameData.style_game;
  const gameType = gameData.game_type;
  const rulesSetting = gameData.rules_setting;
  const friendGame = gameData.friend_game;
  const memberDiscount = gameData.member_discount;

  if (styleGame) {
    tokens.add(mapGameStyleToken(styleGame));
  }
  if (gameType) {
    tokens.add(mapGameStyleToken(gameType));
  }
  if (rulesSetting) {
    tokens.add(mapGameStyleToken(rulesSetting));
  }
  if (friendGame && normalizeStyleToken(friendGame) === "friends") {
    tokens.add("friends");
  }
  if (memberDiscount && normalizeStyleToken(memberDiscount) === "yes") {
    tokens.add("member_discount");
  }

  return Array.from(tokens).filter((token) => token.length > 0);
}

function getUserNotificationPrefs(userData) {
  const prefs = userData.notification_prefs || {};
  const gameAlerts = prefs.game_alerts || {};
  const chatAlerts = prefs.chat_alerts || {};
  const quietHours = prefs.quiet_hours || {};
  const pushEnabled =
    typeof prefs.push_enabled === "boolean"
      ? prefs.push_enabled
      : userData.notify_off === true
      ? false
      : userData.notify_all === true;
  const gameAlertsEnabled =
    typeof gameAlerts.enabled === "boolean" ? gameAlerts.enabled : true;
  const chatAlertsEnabled =
    typeof chatAlerts.enabled === "boolean" ? chatAlerts.enabled : true;
  const chatDirectEnabled =
    typeof chatAlerts.direct === "boolean" ? chatAlerts.direct : true;
  const chatGroupEnabled =
    typeof chatAlerts.group === "boolean" ? chatAlerts.group : true;
  let styles = Array.isArray(gameAlerts.styles)
    ? gameAlerts.styles.filter((style) => typeof style === "string")
    : [];
  if (styles.length === 0) {
    styles = [];
    if (userData.notify_money_game) styles.push("money");
    if (userData.notify_vegas_game) styles.push("vegas");
    if (userData.notify_competitive_game) styles.push("competitive");
    if (userData.notify_for_fun) styles.push("for_fun");
    if (userData.notify_only_from_friends) styles.push("friends");
    if (userData.notify_member_discount) styles.push("member_discount");
  }
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

function isWithinQuietHours(start, end, now) {
  if (typeof start !== "string" || typeof end !== "string") {
    return false;
  }
  const startParts = start.split(":");
  const endParts = end.split(":");
  if (startParts.length !== 2 || endParts.length !== 2) {
    return false;
  }
  const startMinutes = parseInt(startParts[0], 10) * 60 + parseInt(startParts[1], 10);
  const endMinutes = parseInt(endParts[0], 10) * 60 + parseInt(endParts[1], 10);
  const nowMinutes = now.getHours() * 60 + now.getMinutes();
  if (startMinutes === endMinutes) {
    return false;
  }
  if (startMinutes < endMinutes) {
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }
  return nowMinutes >= startMinutes || nowMinutes < endMinutes;
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

function buildChatMessagePreview(messageData) {
  const text = typeof messageData.text === "string" ? messageData.text.trim() : "";
  if (text.length > 0) {
    return text.length > 160 ? `${text.slice(0, 157)}...` : text;
  }
  const imageUrl =
    typeof messageData.imageUrl === "string" ? messageData.imageUrl.trim() : "";
  if (imageUrl.length > 0) {
    return "Sent a photo";
  }
  const videoUrl =
    typeof messageData.videoUrl === "string" ? messageData.videoUrl.trim() : "";
  if (videoUrl.length > 0) {
    return "Sent a video";
  }
  return "Sent a message";
}

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

exports.sendGameCreatedNotifications = functions
  .region("us-west2")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document("games/{gameId}")
  .onCreate(async (snapshot, context) => {
    const gameData = snapshot.data() || {};
    const gameId = context.params.gameId;
    const styleTokens = extractGameStyleTokens(gameData);
    if (styleTokens.length === 0) {
      return;
    }
    const creatorUid = gameData.userRef?.id || gameData.uid || null;
    const recipients = new Set();

    for (const token of styleTokens) {
      const subsSnap = await firestore
        .collection(kAlertSubsCollection)
        .where("style", "==", token)
        .where("enabled", "==", true)
        .get();
      subsSnap.docs.forEach((doc) => {
        const uid = doc.data()?.uid;
        if (typeof uid === "string" && uid.length > 0) {
          recipients.add(uid);
        }
      });
    }

    if (recipients.size === 0) {
      return;
    }

    const now = new Date();
    for (const uid of recipients) {
      if (creatorUid && uid === creatorUid) {
        continue;
      }
      const userRef = firestore.collection("users").doc(uid);
      const userSnap = await userRef.get();
      if (!userSnap.exists) {
        continue;
      }
      const userData = userSnap.data() || {};
      const prefs = getUserNotificationPrefs(userData);
      const styleMatches =
        prefs.styles.length === 0 ||
        prefs.styles.some((style) => styleTokens.includes(style));
      if (!prefs.pushEnabled || !prefs.gameAlertsEnabled || !styleMatches) {
        continue;
      }
      if (prefs.digestMode === "off") {
        continue;
      }

      const matchedStyle =
        prefs.styles.find((style) => styleTokens.includes(style)) ||
        styleTokens[0];
      const state = userData.notification_state || {};
      const styleLast = state.game_style_last || {};
      const lastStamp = styleLast[matchedStyle];
      if (lastStamp?.toDate) {
        const lastDate = lastStamp.toDate();
        const cooldownMs = kGameAlertCooldownMinutes * 60 * 1000;
        if (now - lastDate < cooldownMs) {
          continue;
        }
      }

      const dedupeKey = `game_${gameId}_to_${uid}`;
      const notificationRef = userRef
        .collection(kUserNotificationsCollection)
        .doc(dedupeKey);
      const existing = await notificationRef.get();
      if (existing.exists) {
        continue;
      }

      const styleLabel = styleLabelForToken(matchedStyle);
      const content = buildGameNotificationContent(gameData, styleLabel);
      await notificationRef.set({
        type: "game_created",
        title: content.title,
        body: content.body,
        data: {
          gameId,
          style: matchedStyle,
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        dedupeKey,
      });

      await userRef.set(
        {
          notification_state: {
            game_style_last: {
              [matchedStyle]: admin.firestore.FieldValue.serverTimestamp(),
            },
          },
        },
        { merge: true },
      );

      const inQuietHours =
        prefs.quietHoursEnabled &&
        isWithinQuietHours(prefs.quietHoursStart, prefs.quietHoursEnd, now);
      if (prefs.digestMode !== "instant" || inQuietHours) {
        continue;
      }

      const deviceSnap = await userRef
        .collection(kUserDevicesCollection)
        .get();
      if (deviceSnap.empty) {
        continue;
      }
      const deviceTokens = [];
      deviceSnap.docs.forEach((doc) => {
        const token = doc.data()?.fcmToken;
        if (typeof token === "string" && token.length > 0) {
          deviceTokens.push({ token, ref: doc.ref });
        }
      });
      if (deviceTokens.length === 0) {
        continue;
      }

      const message = {
        notification: {
          title: content.title,
          body: content.body,
        },
        data: {
          initialPageName: "JoinGameDetailed",
          parameterData: JSON.stringify({
            gameRef: `games/${gameId}`,
          }),
          type: "game_created",
          gameId,
        },
        tokens: deviceTokens.map((entry) => entry.token),
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      const invalidRefs = [];
      response.responses.forEach((resp, index) => {
        if (resp.success) {
          return;
        }
        const code = resp.error?.code || "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidRefs.push(deviceTokens[index]?.ref);
        }
      });
      if (invalidRefs.length > 0) {
        await Promise.all(
          invalidRefs
            .filter((ref) => ref)
            .map((ref) => ref.delete()),
        );
      }
    }
  });

exports.sendChatMessageNotifications = functions
  .region("us-west2")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data() || {};
    const chatId = context.params.chatId;
    const messageId = context.params.messageId;
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
    const messagePreview = buildChatMessagePreview(messageData);
    const isDirect = chatData.type === "direct" || memberIds.length === 2;
    const title = isDirect
      ? senderName || "New message"
      : chatData.gameId
      ? "Game chat"
      : "Group chat";
    const body = !isDirect && senderName
      ? `${senderName}: ${messagePreview}`
      : messagePreview;
    const now = new Date();

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

      const dedupeKey = `chat_${chatId}_msg_${messageId}_to_${uid}`;
      const notificationRef = userRef
        .collection(kUserNotificationsCollection)
        .doc(dedupeKey);
      const existing = await notificationRef.get();
      if (existing.exists) {
        continue;
      }

      await notificationRef.set({
        type: "chat_message",
        title,
        body,
        data: {
          threadId: chatId,
          senderId,
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        dedupeKey: `chat:${chatId}:msg:${messageId}:to:${uid}`,
      });

      const inQuietHours =
        prefs.quietHoursEnabled &&
        isWithinQuietHours(prefs.quietHoursStart, prefs.quietHoursEnd, now);
      if (prefs.digestMode !== "instant" || inQuietHours) {
        continue;
      }

      const deviceSnap = await userRef
        .collection(kUserDevicesCollection)
        .get();
      if (deviceSnap.empty) {
        continue;
      }
      const deviceTokens = [];
      deviceSnap.docs.forEach((doc) => {
        const token = doc.data()?.fcmToken;
        if (typeof token === "string" && token.length > 0) {
          deviceTokens.push({ token, ref: doc.ref });
        }
      });
      if (deviceTokens.length === 0) {
        continue;
      }

      const message = {
        notification: {
          title,
          body,
        },
        data: {
          initialPageName: "ChatDetails",
          parameterData: JSON.stringify({
            chatId,
          }),
          type: "chat_message",
          threadId: chatId,
        },
        tokens: deviceTokens.map((entry) => entry.token),
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      const invalidRefs = [];
      response.responses.forEach((resp, index) => {
        if (resp.success) {
          return;
        }
        const code = resp.error?.code || "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidRefs.push(deviceTokens[index]?.ref);
        }
      });
      if (invalidRefs.length > 0) {
        await Promise.all(
          invalidRefs
            .filter((ref) => ref)
            .map((ref) => ref.delete()),
        );
      }
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

exports.syncGameChatMembers = functions
  .region("us-west2")
  .firestore.document("games/{gameId}")
  .onUpdate(async (change, context) => {
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

    const chatDocRef = firestore.collection("chats").doc(chatRef.id);
    const updates = [];

    if (removed.length > 0) {
      const removeUpdate = {
        memberIds: admin.firestore.FieldValue.arrayRemove(...removed),
        users: admin.firestore.FieldValue.arrayRemove(
          ...userRefsFromUids(removed),
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      for (const uid of removed) {
        removeUpdate[`unreadCountByUser.${uid}`] =
          admin.firestore.FieldValue.delete();
      }
      updates.push(chatDocRef.update(removeUpdate));
    }

    if (added.length > 0) {
      const addUpdate = {
        memberIds: admin.firestore.FieldValue.arrayUnion(...added),
        users: admin.firestore.FieldValue.arrayUnion(
          ...userRefsFromUids(added),
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      for (const uid of added) {
        addUpdate[`unreadCountByUser.${uid}`] = 0;
      }
      updates.push(chatDocRef.update(addUpdate));
    }

    try {
      await Promise.all(updates);
    } catch (error) {
      console.log(
        `syncGameChatMembers: failed for game ${context.params.gameId}: ${error}`,
      );
    }
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
        newUsernameDoc.data()?.uid?.path !== userRef.path
      ) {
        await newUsernameRef.set(
          {
            uid: userRef,
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
          oldUsernameDoc.data()?.uid?.path === userRef.path
        ) {
          await oldUsernameRef.delete();
        }
      }
    } catch (error) {
      console.error("syncUsernameIndex failed", error);
    }
  });
