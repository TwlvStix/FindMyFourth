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
const {
  scheduleFlexibleNudges,
  cancelFlexibleNudges,
} = require("./notifications/flexible_nudge");

// Behavioral Dataset modules
const { createRound, addParticipant, finalizeGroup } = require("./src/booking");
const { generatePairwiseMatches } = require("./src/matching");
const {
  confirmParticipant,
  declineParticipant,
  cancelParticipant,
  checkInParticipant,
  completeRound,
  detectNoShows,
} = require("./src/lifecycle");
const { submitFeedback, runBehavioralBackfill } = require("./src/feedback");
const {
  syncPlayerRound,
  syncAllPlayerRounds,
  exportEventsToBigQuery,
} = require("./src/sync");

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

/**
 * Check if any value in the list matches the target (case-insensitive)
 */
function matchesAny(values, target) {
  if (!target || typeof target !== "string") {
    return false;
  }

  const targetLower = target.toLowerCase().trim();

  for (const value of values) {
    if (typeof value === "string" && value.toLowerCase().trim() === targetLower) {
      return true;
    }
  }

  return false;
}

/**
 * Check if an alert subscription matches a game
 *
 * Implements exact matching logic:
 * 1. AND across categories: Every category the user selected must match
 * 2. OR within a category: If multiple values selected, any one match passes
 * 3. Empty category = match-all: If category is empty, it doesn't restrict
 */
function doesAlertSubMatchGame(subscription, gameData) {
  // If subscription is disabled, no match
  if (!subscription.enabled) {
    return false;
  }

  const gameVibes = subscription.gameVibes || [];
  const stakes = subscription.stakes || [];
  const formats = subscription.formats || [];
  const handicapUses = subscription.handicapUses || [];
  const courses = subscription.courses || [];
  const special = subscription.special || { games: false, twoVTwo: false };

  // If all categories are empty, match all games
  const hasActiveFilters =
    gameVibes.length > 0 ||
    stakes.length > 0 ||
    formats.length > 0 ||
    handicapUses.length > 0 ||
    courses.length > 0 ||
    special.games ||
    special.twoVTwo;

  if (!hasActiveFilters) {
    return true;
  }

  // 1. Game Vibe (rules_setting)
  if (gameVibes.length > 0) {
    const gameRulesSetting = gameData.rules_setting || "";
    if (!matchesAny(gameVibes, gameRulesSetting)) {
      return false;
    }
  }

  // 2. Stakes (style_game)
  if (stakes.length > 0) {
    const gameStyleGame = gameData.style_game || "";
    if (!matchesAny(stakes, gameStyleGame)) {
      return false;
    }
  }

  // 3. Format (game_type)
  if (formats.length > 0) {
    const gameType = gameData.game_type || "";
    if (!matchesAny(formats, gameType)) {
      return false;
    }
  }

  // 4. Handicap Use (scoring)
  if (handicapUses.length > 0) {
    const gameScoring = gameData.scoring || "";
    if (!matchesAny(handicapUses, gameScoring)) {
      return false;
    }
  }

  // 5. Course (courseRef ID)
  if (courses.length > 0) {
    const gameCourseId = gameData.courseRef?.id || null;
    if (!gameCourseId || !courses.includes(gameCourseId)) {
      return false;
    }
  }

  // 6. Special options
  // TODO: Add has_side_games and is_2v2 fields to game documents
  // if (special.games) {
  //   if (!gameData.has_side_games) return false;
  // }
  // if (special.twoVTwo) {
  //   if (!gameData.is_2v2) return false;
  // }

  // All categories matched
  return true;
}

/**
 * Build notification content for a game (simplified version for new system)
 */
function buildGameNotificationContentSimple(gameData) {
  const name = gameData.name_game || "New game";
  const course = gameData.course_play || "";
  const title = "New game posted";

  // Build a nice summary
  const parts = [];
  if (gameData.style_game) parts.push(gameData.style_game);
  if (gameData.game_type) parts.push(gameData.game_type);
  if (gameData.rules_setting) parts.push(gameData.rules_setting);

  const suffix = parts.length > 0 ? ` • ${parts.join(' • ')}` : "";
  const body = course ? `${name} at ${course}${suffix}` : `${name}${suffix}`;

  return { title, body };
}

/**
 * Send game created notifications using new matching logic
 *
 * Triggered when a new game is created in Firestore.
 * Matches against user alert subscriptions and sends push notifications.
 */
exports.sendGameCreatedNotifications = functions
  .region("us-west2")
  .runWith(kPushNotificationRuntimeOpts)
  .firestore.document("games/{gameId}")
  .onCreate(async (snapshot, context) => {
    const gameData = snapshot.data() || {};
    const gameId = context.params.gameId;
    const creatorUid = gameData.userRef?.id || gameData.uid || null;

    console.log(`[GameAlerts] New game created: ${gameId}`);
    console.log(`[GameAlerts] Game data:`, {
      name: gameData.name_game,
      course: gameData.course_play,
      vibe: gameData.rules_setting,
      stakes: gameData.style_game,
      format: gameData.game_type,
      handicap: gameData.scoring,
    });

    try {
      // Get all enabled alert subscriptions
      const subsSnapshot = await firestore
        .collection(kAlertSubsCollection)
        .where("enabled", "==", true)
        .get();

      console.log(`[GameAlerts] Found ${subsSnapshot.docs.length} enabled subscriptions`);

      if (subsSnapshot.empty) {
        console.log(`[GameAlerts] No enabled subscriptions, skipping`);
        return;
      }

      const now = new Date();
      let matchedCount = 0;
      let notifiedCount = 0;

      // Check each subscription for a match
      for (const subDoc of subsSnapshot.docs) {
        const subscription = subDoc.data();
        const userId = subscription.userId;

        // Skip creator
        if (creatorUid && userId === creatorUid) {
          continue;
        }

        // Check if subscription matches game
        const matches = doesAlertSubMatchGame(subscription, gameData);

        if (!matches) {
          continue;
        }

        matchedCount++;
        console.log(`[GameAlerts] Subscription ${userId} matches game ${gameId}`);

        // Load user document
        const userRef = firestore.collection("users").doc(userId);
        const userSnap = await userRef.get();

        if (!userSnap.exists) {
          console.log(`[GameAlerts] User ${userId} not found, skipping`);
          continue;
        }

        const userData = userSnap.data() || {};
        const prefs = getUserNotificationPrefs(userData);

        // Check if push notifications are enabled
        if (!prefs.pushEnabled) {
          console.log(`[GameAlerts] User ${userId} has push disabled, skipping`);
          continue;
        }

        // Check digest mode
        if (prefs.digestMode === "off") {
          console.log(`[GameAlerts] User ${userId} has digest mode off, skipping`);
          continue;
        }

        // Check cooldown (60 minutes between game alerts)
        const state = userData.notification_state || {};
        const lastGameAlert = state.last_game_alert;
        if (lastGameAlert?.toDate) {
          const lastDate = lastGameAlert.toDate();
          const cooldownMs = kGameAlertCooldownMinutes * 60 * 1000;
          if (now - lastDate < cooldownMs) {
            console.log(`[GameAlerts] User ${userId} in cooldown, skipping`);
            continue;
          }
        }

        // Create notification document (deduplicated)
        const dedupeKey = `game_${gameId}_to_${userId}`;
        const notificationRef = userRef
          .collection(kUserNotificationsCollection)
          .doc(dedupeKey);

        const existing = await notificationRef.get();
        if (existing.exists) {
          console.log(`[GameAlerts] Notification already sent to ${userId}, skipping`);
          continue;
        }

        const content = buildGameNotificationContentSimple(gameData);
        await notificationRef.set({
          type: "game_created",
          title: content.title,
          body: content.body,
          data: {
            gameId,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          dedupeKey,
        });

        // Update cooldown timestamp
        await userRef.set(
          {
            notification_state: {
              last_game_alert: admin.firestore.FieldValue.serverTimestamp(),
            },
          },
          { merge: true },
        );

        // Check if we should send push notification now
        const inQuietHours =
          prefs.quietHoursEnabled &&
          isWithinQuietHours(prefs.quietHoursStart, prefs.quietHoursEnd, now);

        if (prefs.digestMode !== "instant" || inQuietHours) {
          console.log(`[GameAlerts] User ${userId} in quiet hours or digest mode, notification saved but not sent`);
          continue;
        }

        // Get user devices
        const deviceSnap = await userRef
          .collection(kUserDevicesCollection)
          .get();

        if (deviceSnap.empty) {
          console.log(`[GameAlerts] User ${userId} has no devices, skipping push`);
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
          console.log(`[GameAlerts] User ${userId} has no valid tokens, skipping push`);
          continue;
        }

        // Send push notification
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

        try {
          const response = await admin.messaging().sendEachForMulticast(message);
          console.log(`[GameAlerts] Sent push notification to ${userId}, success: ${response.successCount}/${response.responses.length}`);

          notifiedCount++;

          // Record success
          await userRef.update({
            "notification_state.last_send_success": admin.firestore.FieldValue.serverTimestamp(),
          });

          // Clean up invalid tokens
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
        } catch (error) {
          console.error(`[GameAlerts] Failed to send push to ${userId}:`, error.message);

          // Store error for frontend to read
          await userRef.update({
            "notification_state.last_error": {
              message: error.message || "Failed to send notification",
              code: error.code || "unknown",
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              type: "notification_send",
            },
          });
        }
      }

      console.log(`[GameAlerts] Game ${gameId} complete: ${matchedCount} matched, ${notifiedCount} notified`);
    } catch (error) {
      console.error(`[GameAlerts] Error processing game ${gameId}:`, error);
      throw error;
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

      try {
        const response = await admin.messaging().sendEachForMulticast(message);

        // Record success
        await userRef.update({
          "notification_state.last_send_success": admin.firestore.FieldValue.serverTimestamp(),
        });

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
      } catch (error) {
        console.error("Notification send failed", { uid, error: error.message });

        // Store error for frontend to read
        await userRef.update({
          "notification_state.last_error": {
            message: error.message || "Failed to send notification",
            code: error.code || "unknown",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            type: "notification_send",
          },
        });
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

/**
 * Cloud Function to delete a chat and all its messages.
 * Uses admin privileges to bypass security rules for efficient batch deletion.
 *
 * @param {Object} data - { chatId: string }
 * @param {Object} context - Authentication context
 * @returns {Promise<{success: boolean, messagesDeleted: number}>}
 */
/**
 * One-time migration function to backfill alertSubs for existing users.
 * Call this once after deploying the syncNotificationPreferencesToAlertSubs function.
 *
 * Usage: firebase functions:call backfillAlertSubs
 */
exports.backfillAlertSubs = functions
  .region("us-west2")
  .runWith({
    timeoutSeconds: 540,
    memory: "2GB",
  })
  .https.onCall(async (data, context) => {
    // Require authentication and optionally restrict to admins
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to run backfill",
      );
    }

    console.log(`Starting alertSubs backfill initiated by ${context.auth.uid}`);

    try {
      // Get all users
      const usersSnap = await firestore.collection("users").get();
      console.log(`Found ${usersSnap.docs.length} users to process`);

      let processedCount = 0;
      let skippedCount = 0;
      let errorCount = 0;

      for (const userDoc of usersSnap.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data() || {};

        try {
          const prefs = getUserNotificationPrefs(userData);
          const gameAlertsEnabled = prefs.pushEnabled && prefs.gameAlertsEnabled;
          const styles = prefs.styles || [];

          if (styles.length === 0) {
            skippedCount++;
            continue;
          }

          const batch = firestore.batch();

          for (const style of styles) {
            const docId = `${userId}_${style}`;
            const subRef = firestore.collection(kAlertSubsCollection).doc(docId);

            batch.set(subRef, {
              uid: userId,
              style,
              enabled: gameAlertsEnabled,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();
          processedCount++;

          if (processedCount % 50 === 0) {
            console.log(`Processed ${processedCount} users so far...`);
          }
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);
          errorCount++;
        }
      }

      const summary = {
        totalUsers: usersSnap.docs.length,
        processedCount,
        skippedCount,
        errorCount,
      };

      console.log("Backfill complete:", summary);
      return summary;
    } catch (error) {
      console.error("Backfill failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Backfill failed: ${error.message}`,
      );
    }
  });

const sgMail = require("@sendgrid/mail");

exports.onUserCreated = functions
  .region("us-west2")
  .runWith({ secrets: ["SENDGRID_API_KEY"] })
  .auth.user()
  .onCreate(async (user) => {
    const email = user.email;
    if (!email) {
      // Skip anonymous or phone-only accounts that have no email address.
      return;
    }

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
      console.log(`Welcome email sent to ${email}`);
    } catch (error) {
      console.error("Error sending welcome email:", error);
    }
  });

exports.deleteChat = functions
  .region("us-west2")
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
exports.onGameStatusToPlayed = confirmationFlow.onGameStatusToPlayed;
exports.submitHostCheckin = confirmationFlow.submitHostCheckin;
exports.submitPeerRatings = confirmationFlow.submitPeerRatings;
exports.submitFallbackConfirmation = confirmationFlow.submitFallbackConfirmation;

// Cloud Task receivers for confirmation flow
exports.processScheduledGameStatusChange = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest(confirmationFlow._processScheduledGameStatusChangeHandler);

exports.processScheduledWindowClose = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .https.onRequest(confirmationFlow._processScheduledWindowCloseHandler);

// Trust Profile — Stage 5
exports.updateTrustProfile = trustProfileModule.updateTrustProfile;
exports.getMyStanding = trustProfileModule.getMyStanding;

// Trust Notification Scheduler — Session 7
const trustNotificationScheduler = require('./notifications/trust/scheduler');
exports.processScheduledTrustNotification = functions
  .region('us-west2')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onRequest(trustNotificationScheduler.processScheduledTrustNotificationHandler);

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
      const result = await onFriendRequestReceived(
        recipientUserId,
        context.auth.uid,
        senderName,
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
      const result = await onFriendRequestAccepted(
        requesterUserId,
        context.auth.uid,
        acceptorName,
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
      const result = await onJoinRequestReceived(
        ownerId,
        context.auth.uid,
        requesterName,
        gameId,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyNewJoinRequest error:', error);
      throw new functions.https.HttpsError('internal', error.message);
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
      // Fetch owner name and game name for the notification
      const gameDoc = await firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        throw new Error('Game not found');
      }
      const gameData = gameDoc.data() || {};
      const gameName = gameData.name_game || 'a round';

      const ownerRef = gameData.userRef;
      let ownerName = 'The host';
      if (ownerRef) {
        const ownerDoc = await firestore.collection('users').doc(ownerRef.id).get();
        if (ownerDoc.exists) {
          const ownerData = ownerDoc.data() || {};
          ownerName = ownerData.first_name || ownerData.display_name || 'The host';
        }
      }

      const result = await onJoinRequestApproved(
        playerId,
        context.auth.uid,
        ownerName,
        gameId,
        gameName,
      );
      return { success: true, result: result.result };
    } catch (error) {
      console.error('notifyJoinRequestApproved error:', error);
      throw new functions.https.HttpsError('internal', error.message);
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
      throw new functions.https.HttpsError('internal', error.message);
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
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

// Welcome email — restored from main (accidentally dropped in checkpoint branch)
// Note: sgMail already declared at top of file

exports.onUserCreated = functions
  .region("us-west2")
  .runWith({ secrets: ["SENDGRID_API_KEY"] })
  .auth.user()
  .onCreate(async (user) => {
    const email = user.email;
    if (!email) {
      return;
    }

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
      console.log(`Welcome email sent to ${email}`);
    } catch (error) {
      console.error("Error sending welcome email:", error);
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
  .https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }

  try {
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
      const results = await exportEventsToBigQuery(500);
      console.log("BigQuery export results:", results);
    } catch (error) {
      console.error("BigQuery export failed:", error);
    }
  });

// ─────────────────────────────────────────────
// CLEANUP FUNCTIONS
// ─────────────────────────────────────────────

const { cleanupCancelledGamesHandler } = require("./cleanup");

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
