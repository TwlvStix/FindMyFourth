'use strict';

/**
 * Chat Message Notification Debounce
 *
 * When a user sends multiple messages quickly, this module batches them into
 * a single push notification using Cloud Tasks. Each new message cancels
 * the prior pending task and schedules a fresh one 8 seconds out. Only when
 * no new message arrives within the window does the notification fire.
 *
 * Public API:
 *   scheduleDebouncedChatNotification(chatId, recipientUid, messageData, senderName, chatData, db)
 *   deliverChatNotificationHandler(req, res)
 */

const admin = require('firebase-admin');
const { getTasksClient } = require('./trust/scheduler');
const {
  getUserNotificationPrefs,
  isWithinQuietHours,
  buildChatMessagePreview,
} = require('../utils/notification-helpers');

// ── Constants ─────────────────────────────────────────────────────────────────

const PROJECT  = process.env.GCLOUD_PROJECT || 'find-my-fourth';
const LOCATION = 'us-west2';
const QUEUE_NAME = 'chat-notification-debounce';
const PENDING_COLLECTION = 'pendingChatNotifications';
const DEBOUNCE_SECONDS = 8;

function getDeliveryUrl() {
  return `https://${LOCATION}-${PROJECT}.cloudfunctions.net/deliverChatNotification`;
}

// ── scheduleDebouncedChatNotification ─────────────────────────────────────────

/**
 * Schedules (or reschedules) a debounced chat notification for a recipient.
 *
 * Uses a Firestore transaction to prevent race conditions when two messages
 * arrive simultaneously. If a pending task exists, it is cancelled before
 * a new one is created.
 *
 * @param {string} chatId
 * @param {string} recipientUid
 * @param {object} messageData - The message document data
 * @param {string} senderName - Display name of the sender
 * @param {object} chatData - The chat document data
 * @param {FirebaseFirestore.Firestore} db
 */
async function scheduleDebouncedChatNotification(chatId, recipientUid, messageData, senderName, chatData, db) {
  const client = getTasksClient();
  const docKey = `chat_${chatId}_${recipientUid}`;
  const docRef = db.collection(PENDING_COLLECTION).doc(docKey);

  const senderId = messageData.senderId || messageData.sender_id || messageData.sender;
  const messagePreview = buildChatMessagePreview(messageData);
  const isDirect = chatData.type === 'direct' || (Array.isArray(chatData.memberIds) && chatData.memberIds.length === 2);
  const chatType = isDirect ? 'direct' : (chatData.gameId ? 'game' : 'group');

  // Use a transaction to prevent race conditions
  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(docRef);

    // Cancel existing Cloud Task if one is pending
    if (snap.exists) {
      const existingTaskName = snap.data().taskName;
      if (existingTaskName) {
        try {
          await client.deleteTask({ name: existingTaskName });
        } catch (err) {
          // gRPC NOT_FOUND (code 5) — task already executed or was deleted; safe to ignore
          if (err.code !== 5) throw err;
        }
      }
    }

    // Schedule new Cloud Task
    const queuePath = client.queuePath(PROJECT, LOCATION, QUEUE_NAME);
    const scheduleTimeSeconds = Math.floor(Date.now() / 1000) + DEBOUNCE_SECONDS;

    const payload = {
      chatId,
      recipientUid,
      senderId,
      senderName,
      latestMessagePreview: messagePreview,
      chatType,
      gameId: chatData.gameId || null,
    };

    const task = {
      httpRequest: {
        httpMethod: 'POST',
        url: getDeliveryUrl(),
        headers: { 'Content-Type': 'application/json' },
        body: Buffer.from(JSON.stringify(payload)).toString('base64'),
        oidcToken: {
          serviceAccountEmail: `${PROJECT}@appspot.gserviceaccount.com`,
        },
      },
      scheduleTime: { seconds: scheduleTimeSeconds },
    };

    const [createdTask] = await client.createTask({ parent: queuePath, task });

    // Write/overwrite tracking doc
    transaction.set(docRef, {
      taskName: createdTask.name,
      chatId,
      recipientUid,
      senderId,
      senderName,
      latestMessagePreview: messagePreview,
      chatType,
      gameId: chatData.gameId || null,
      scheduledAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

// ── deliverChatNotificationHandler ────────────────────────────────────────────

/**
 * HTTP handler for the deliverChatNotification Cloud Function.
 *
 * Called by Cloud Tasks after the debounce window expires. Checks current
 * unread count and user preferences before sending.
 *
 * Always returns 200 to prevent Cloud Tasks retries on non-error outcomes.
 *
 * @param {import('express').Request}  req
 * @param {import('express').Response} res
 */
async function deliverChatNotificationHandler(req, res) {
  const db = admin.firestore();
  console.log('[CHAT_DELIVER] started, request body:', JSON.stringify(req.body));

  // 1. Parse payload
  const {
    chatId,
    recipientUid,
    senderId,
    senderName,
    latestMessagePreview,
    chatType,
  } = req.body || {};

  if (!chatId || !recipientUid) {
    console.error('[ChatDebounce] Missing chatId or recipientUid in request body');
    return res.status(400).send('Missing chatId or recipientUid');
  }

  const docKey = `chat_${chatId}_${recipientUid}`;
  const trackingRef = db.collection(PENDING_COLLECTION).doc(docKey);

  // 2. Read tracking doc — if missing, this task was superseded or cleaned up
  const trackingSnap = await trackingRef.get();
  if (!trackingSnap.exists) {
    console.log(`[ChatDebounce] Tracking doc not found for ${docKey}`);
    return res.status(200).send('NOT_FOUND');
  }

  // 3. Check unread count — if 0, user already read the messages
  const chatSnap = await db.collection('chats').doc(chatId).get();
  if (chatSnap.exists) {
    const chatData = chatSnap.data() || {};
    const unreadCount = (chatData.unreadCountByUser || {})[recipientUid] || 0;
    if (unreadCount === 0) {
      console.log(`[ChatDebounce] Unread count is 0 for ${recipientUid} in chat ${chatId} — skipping`);
      console.log('[CHAT_DELIVER] skipping - reason: unread count is 0 for', recipientUid);
      await trackingRef.delete();
      return res.status(200).send('SKIPPED_READ');
    }
  }

  // 4. Re-check user notification preferences
  const userRef = db.collection('users').doc(recipientUid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.log('[CHAT_DELIVER] skipping - reason: user doc not found for', recipientUid);
    await trackingRef.delete();
    return res.status(200).send('SKIPPED_NO_USER');
  }

  const userData = userSnap.data() || {};
  const prefs = getUserNotificationPrefs(userData);
  const isDirect = chatType === 'direct';

  if (!prefs.pushEnabled || !prefs.chatAlertsEnabled) {
    console.log('[CHAT_DELIVER] skipping - reason: push or chat alerts disabled for', recipientUid);
    await trackingRef.delete();
    return res.status(200).send('PREFS_DISABLED');
  }
  if (prefs.mutedThreads.includes(chatId)) {
    console.log('[CHAT_DELIVER] skipping - reason: thread muted for', recipientUid, 'chat:', chatId);
    await trackingRef.delete();
    return res.status(200).send('PREFS_DISABLED');
  }
  if (isDirect && !prefs.chatDirectEnabled) {
    console.log('[CHAT_DELIVER] skipping - reason: direct chat notifications disabled for', recipientUid);
    await trackingRef.delete();
    return res.status(200).send('PREFS_DISABLED');
  }
  if (!isDirect && !prefs.chatGroupEnabled) {
    console.log('[CHAT_DELIVER] skipping - reason: group chat notifications disabled for', recipientUid);
    await trackingRef.delete();
    return res.status(200).send('PREFS_DISABLED');
  }

  const now = new Date();
  const inQuietHours =
    prefs.quietHoursEnabled &&
    isWithinQuietHours(prefs.quietHoursStart, prefs.quietHoursEnd, now);
  if (prefs.digestMode !== 'instant' || inQuietHours) {
    console.log('[CHAT_DELIVER] skipping - reason:', inQuietHours ? 'quiet hours active' : 'digest mode is ' + prefs.digestMode, 'for', recipientUid);
    await trackingRef.delete();
    return res.status(200).send('PREFS_DISABLED');
  }

  // 5. Build notification content based on unread count
  const unreadCount = chatSnap.exists
    ? ((chatSnap.data() || {}).unreadCountByUser || {})[recipientUid] || 1
    : 1;

  let title;
  let body;

  if (isDirect) {
    title = senderName || 'New message';
    if (unreadCount > 1) {
      body = `${senderName} sent you ${unreadCount} messages`;
    } else {
      body = latestMessagePreview || 'Sent a message';
    }
  } else {
    title = chatType === 'game' ? 'Game chat' : 'Group chat';
    if (unreadCount > 1) {
      body = `${unreadCount} new messages`;
    } else {
      body = senderName
        ? `${senderName}: ${latestMessagePreview || 'Sent a message'}`
        : latestMessagePreview || 'Sent a message';
    }
  }

  // 6. Write notification doc
  const timestamp = Date.now();
  const notificationRef = userRef
    .collection('notifications')
    .doc(`chat_${chatId}_debounced_${timestamp}`);

  await notificationRef.set({
    type: 'chat_message',
    title,
    body,
    data: {
      threadId: chatId,
      senderId: senderId || '',
    },
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    dedupeKey: `chat:${chatId}:debounced:${timestamp}`,
  });

  // 7. Fetch FCM tokens and send
  const deviceSnap = await userRef.collection('devices').get();
  if (deviceSnap.empty) {
    console.log('[CHAT_DELIVER] skipping - reason: no device docs for', recipientUid);
    await trackingRef.delete();
    return res.status(200).send('OK');
  }

  const deviceTokens = [];
  deviceSnap.docs.forEach((doc) => {
    const token = doc.data()?.fcmToken;
    if (typeof token === 'string' && token.length > 0) {
      deviceTokens.push({ token, ref: doc.ref });
    }
  });

  console.log('[CHAT_DELIVER] tokens found:', deviceTokens.length, JSON.stringify(deviceTokens.map(t => ({ token: t.token?.substring(0, 20) + '...', ref: t.ref?.path }))));

  if (deviceTokens.length === 0) {
    console.log('[CHAT_DELIVER] skipping - reason: no valid device tokens');
    await trackingRef.delete();
    return res.status(200).send('OK');
  }

  const message = {
    notification: { title, body },
    data: {
      initialPageName: 'ChatDetails',
      parameterData: JSON.stringify({ chatId }),
      type: 'chat_message',
      threadId: chatId,
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'fmm_general',
        sound: 'default',
      },
    },
    apns: {
      headers: {
        'apns-push-type': 'alert',
        'apns-priority': '10',
      },
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          'mutable-content': 1,
        },
      },
    },
    tokens: deviceTokens.map((entry) => entry.token),
  };

  console.log('[CHAT_DELIVER] sending FCM message:', JSON.stringify(message, null, 2));

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log('[CHAT_DELIVER] FCM result:', JSON.stringify({ successCount: response.successCount, failureCount: response.failureCount, responses: response.responses.map(r => ({ success: r.success, error: r.error?.code })) }));

    // Record success
    await userRef.update({
      'notification_state.last_send_success': admin.firestore.FieldValue.serverTimestamp(),
    });

    // Clean up invalid tokens
    const invalidRefs = [];
    response.responses.forEach((resp, index) => {
      if (resp.success) return;
      const code = resp.error?.code || '';
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        invalidRefs.push(deviceTokens[index]?.ref);
      }
    });
    if (invalidRefs.length > 0) {
      await Promise.all(
        invalidRefs.filter((ref) => ref).map((ref) => ref.delete()),
      );
    }
  } catch (error) {
    console.error('[ChatDebounce] Notification send failed', {
      recipientUid,
      error: error.message,
    });

    await userRef.update({
      'notification_state.last_error': {
        message: error.message || 'Failed to send notification',
        code: error.code || 'unknown',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        type: 'notification_send',
      },
    });
  }

  // 8. Clean up tracking doc
  await trackingRef.delete();
  return res.status(200).send('OK');
}

module.exports = {
  scheduleDebouncedChatNotification,
  deliverChatNotificationHandler,
  // Exported for testing
  PENDING_COLLECTION,
  DEBOUNCE_SECONDS,
  QUEUE_NAME,
};
