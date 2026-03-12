'use strict';

/**
 * Flexible Game Nudge System
 *
 * Sends reminder notifications to hosts of flexible games when 2+ players have joined
 * but no tee time has been confirmed yet.
 *
 * Nudge schedule (based on flexible window duration):
 *   - 50% of window: Soft nudge ("You've got X players interested — ready to lock in a time?")
 *   - 85% of window: Urgency nudge ("Your game window closes in X days — set a tee time to keep your group")
 *
 * Exports:
 *   scheduleFlexibleNudges(gameId, gameData, db)  - Schedules both nudges when 2nd player joins
 *   cancelFlexibleNudges(gameId, db)              - Cancels all pending nudges (when time confirmed)
 *   processFlexibleNudge(event, db)               - Handles nudge delivery via Cloud Tasks
 */

const admin = require('firebase-admin');
const { scheduleJob, cancelJob } = require('./trust/scheduler');

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const SOFT_NUDGE_RATIO = 0.5;   // 50% through the window
const URGENT_NUDGE_RATIO = 0.85; // 85% through the window

const EVENT_TYPE_SOFT = 'flexible_nudge_soft';
const EVENT_TYPE_URGENT = 'flexible_nudge_urgent';

// ─────────────────────────────────────────────────────────────────────────────
// scheduleFlexibleNudges
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Schedules soft (50%) and urgent (85%) nudge notifications for a flexible game.
 *
 * Called when the 2nd player joins a flexible game that has no confirmed tee time.
 *
 * @param {string} gameId - The game document ID
 * @param {Object} gameData - The game document data (must include flexible_start_date, flexible_end_date, uid)
 * @param {FirebaseFirestore.Firestore} [db] - Optional Firestore instance (for testing)
 * @returns {Promise<{softJobId: string|null, urgentJobId: string|null}>}
 */
async function scheduleFlexibleNudges(gameId, gameData, db) {
  if (!db) db = admin.firestore();

  const { flexible_start_date, flexible_end_date, uid: hostUid } = gameData;

  // Validate required fields
  if (!flexible_start_date || !flexible_end_date) {
    console.warn(`[FlexibleNudge] Game ${gameId} missing flexible dates, skipping nudge scheduling`);
    return { softJobId: null, urgentJobId: null };
  }

  if (!hostUid) {
    console.warn(`[FlexibleNudge] Game ${gameId} missing host uid, skipping nudge scheduling`);
    return { softJobId: null, urgentJobId: null };
  }

  // Calculate window duration and nudge times
  const startMs = flexible_start_date.toMillis();
  const endMs = flexible_end_date.toMillis();
  const windowMs = endMs - startMs;

  const now = Date.now();
  const softNudgeAt = startMs + (windowMs * SOFT_NUDGE_RATIO);
  const urgentNudgeAt = startMs + (windowMs * URGENT_NUDGE_RATIO);

  let softJobId = null;
  let urgentJobId = null;

  // Schedule soft nudge if it's still in the future
  if (softNudgeAt > now) {
    try {
      softJobId = await scheduleJob({
        eventId: `flexible_nudge_soft_${gameId}`,
        eventType: EVENT_TYPE_SOFT,
        recipientUserId: hostUid,
        sourceId: gameId,
        data: {
          gameId,
          nudgeType: 'soft',
        },
        scheduleTime: new Date(softNudgeAt),
        conditionCheck: 'flexible_game_still_active',
      }, db);
      console.log(`[FlexibleNudge] Scheduled soft nudge for game ${gameId} at ${new Date(softNudgeAt).toISOString()}`);
    } catch (error) {
      console.error(`[FlexibleNudge] Failed to schedule soft nudge for game ${gameId}:`, error);
    }
  } else {
    console.log(`[FlexibleNudge] Soft nudge time already passed for game ${gameId}, skipping`);
  }

  // Schedule urgent nudge if it's still in the future
  if (urgentNudgeAt > now) {
    try {
      urgentJobId = await scheduleJob({
        eventId: `flexible_nudge_urgent_${gameId}`,
        eventType: EVENT_TYPE_URGENT,
        recipientUserId: hostUid,
        sourceId: gameId,
        data: {
          gameId,
          nudgeType: 'urgent',
        },
        scheduleTime: new Date(urgentNudgeAt),
        conditionCheck: 'flexible_game_still_active',
      }, db);
      console.log(`[FlexibleNudge] Scheduled urgent nudge for game ${gameId} at ${new Date(urgentNudgeAt).toISOString()}`);
    } catch (error) {
      console.error(`[FlexibleNudge] Failed to schedule urgent nudge for game ${gameId}:`, error);
    }
  } else {
    console.log(`[FlexibleNudge] Urgent nudge time already passed for game ${gameId}, skipping`);
  }

  // Store job IDs on the game document for tracking/debugging
  if (softJobId || urgentJobId) {
    try {
      await db.collection('games').doc(gameId).update({
        'flexible_nudge_jobs': {
          soft_job_id: softJobId,
          urgent_job_id: urgentJobId,
          scheduled_at: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
    } catch (error) {
      console.warn(`[FlexibleNudge] Failed to store job IDs on game ${gameId}:`, error);
    }
  }

  return { softJobId, urgentJobId };
}

// ─────────────────────────────────────────────────────────────────────────────
// cancelFlexibleNudges
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Cancels all pending flexible nudge jobs for a game.
 *
 * Called when the host confirms a tee time (schedule_type changes to 'confirmed').
 *
 * @param {string} gameId - The game document ID
 * @param {FirebaseFirestore.Firestore} [db] - Optional Firestore instance (for testing)
 * @returns {Promise<{cancelledCount: number}>}
 */
async function cancelFlexibleNudges(gameId, db) {
  if (!db) db = admin.firestore();

  // Query for pending nudge jobs for this game
  const snap = await db.collection('scheduledNotifications')
    .where('gameId', '==', gameId)
    .where('status', '==', 'PENDING')
    .where('eventType', 'in', [EVENT_TYPE_SOFT, EVENT_TYPE_URGENT])
    .get();

  if (snap.empty) {
    console.log(`[FlexibleNudge] No pending nudges to cancel for game ${gameId}`);
    return { cancelledCount: 0 };
  }

  let cancelledCount = 0;
  for (const doc of snap.docs) {
    try {
      const result = await cancelJob(doc.id, db);
      if (result.cancelled) {
        cancelledCount++;
      }
    } catch (error) {
      console.error(`[FlexibleNudge] Failed to cancel job ${doc.id}:`, error);
    }
  }

  // Clear the job IDs from the game document
  try {
    await db.collection('games').doc(gameId).update({
      'flexible_nudge_jobs': admin.firestore.FieldValue.delete(),
    });
  } catch (error) {
    console.warn(`[FlexibleNudge] Failed to clear job IDs from game ${gameId}:`, error);
  }

  console.log(`[FlexibleNudge] Cancelled ${cancelledCount} nudges for game ${gameId}`);
  return { cancelledCount };
}

// ─────────────────────────────────────────────────────────────────────────────
// processFlexibleNudge
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Processes a flexible nudge notification.
 *
 * Called by the Cloud Tasks receiver when a scheduled nudge fires.
 * Re-checks conditions before sending to handle edge cases (game confirmed, players left, etc.).
 *
 * @param {Object} event - The event object from the scheduler
 * @param {FirebaseFirestore.Firestore} [db] - Optional Firestore instance (for testing)
 * @returns {Promise<{sent: boolean, reason?: string}>}
 */
async function processFlexibleNudge(event, db) {
  if (!db) db = admin.firestore();

  const { sourceId: gameId, data } = event;
  const nudgeType = data?.nudgeType || 'soft';

  // Fetch current game state
  const gameSnap = await db.collection('games').doc(gameId).get();
  if (!gameSnap.exists) {
    console.log(`[FlexibleNudge] Game ${gameId} no longer exists, skipping nudge`);
    return { sent: false, reason: 'game_deleted' };
  }

  const game = gameSnap.data();

  // Check: still a flexible game?
  if (game.schedule_type !== 'flexible') {
    console.log(`[FlexibleNudge] Game ${gameId} is no longer flexible (now ${game.schedule_type}), skipping nudge`);
    return { sent: false, reason: 'game_confirmed' };
  }

  // Check: game not cancelled?
  if (game.status === 'cancelled') {
    console.log(`[FlexibleNudge] Game ${gameId} is cancelled, skipping nudge`);
    return { sent: false, reason: 'game_cancelled' };
  }

  // Check: still has 2+ players?
  const joinedCount = game.joined_players?.length || 0;
  if (joinedCount < 2) {
    console.log(`[FlexibleNudge] Game ${gameId} now has only ${joinedCount} players, skipping nudge`);
    return { sent: false, reason: 'insufficient_players' };
  }

  // Calculate days until window closes
  const endMs = game.flexible_end_date?.toMillis?.() || 0;
  const now = Date.now();
  const daysRemaining = Math.max(0, Math.ceil((endMs - now) / (24 * 60 * 60 * 1000)));

  // Build notification content
  let title, body;
  if (nudgeType === 'soft') {
    title = 'Ready to lock in a time?';
    body = `You've got ${joinedCount} player${joinedCount > 2 ? 's' : ''} interested in your round.`;
  } else {
    title = "Don't lose your group!";
    if (daysRemaining <= 1) {
      body = `Your game window closes tomorrow — set a tee time to keep your ${joinedCount} players.`;
    } else {
      body = `Your game window closes in ${daysRemaining} days — set a tee time to keep your ${joinedCount} players.`;
    }
  }

  // Get host user and send notification
  const hostUid = game.uid || game.userRef?.id;
  if (!hostUid) {
    console.error(`[FlexibleNudge] Game ${gameId} has no host uid`);
    return { sent: false, reason: 'no_host' };
  }

  try {
    await sendPushToUser(hostUid, {
      title,
      body,
      data: {
        type: nudgeType === 'soft' ? 'flexible_nudge_soft' : 'flexible_nudge_urgent',
        gameId,
        initialPageName: 'GameJoinedDetailed',
        parameterData: JSON.stringify({ gameRef: `games/${gameId}` }),
      },
    }, db);

    console.log(`[FlexibleNudge] Sent ${nudgeType} nudge to host ${hostUid} for game ${gameId}`);
    return { sent: true };
  } catch (error) {
    console.error(`[FlexibleNudge] Failed to send nudge to host ${hostUid}:`, error);
    return { sent: false, reason: 'send_failed' };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: sendPushToUser
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Sends a push notification to a user via their registered device tokens.
 *
 * @param {string} userId - The user ID
 * @param {Object} notification - { title, body, data }
 * @param {FirebaseFirestore.Firestore} db - Firestore instance
 */
async function sendPushToUser(userId, notification, db) {
  const userRef = db.collection('users').doc(userId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    console.warn(`[FlexibleNudge] User ${userId} not found`);
    return;
  }

  // Check notification preferences
  const userData = userSnap.data();
  const prefs = userData.notification_prefs || {};
  const pushEnabled = prefs.push_enabled !== false; // Default to enabled

  if (!pushEnabled) {
    console.log(`[FlexibleNudge] User ${userId} has push disabled, skipping`);
    return;
  }

  // Get device tokens
  const deviceSnap = await userRef.collection('devices').get();
  if (deviceSnap.empty) {
    console.log(`[FlexibleNudge] User ${userId} has no devices`);
    return;
  }

  const deviceTokens = [];
  deviceSnap.docs.forEach((doc) => {
    const token = doc.data()?.fcmToken;
    if (typeof token === 'string' && token.length > 0) {
      deviceTokens.push({ token, ref: doc.ref });
    }
  });

  if (deviceTokens.length === 0) {
    console.log(`[FlexibleNudge] User ${userId} has no valid FCM tokens`);
    return;
  }

  // Send notification
  const message = {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: notification.data || {},
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

  const response = await admin.messaging().sendEachForMulticast(message);
  console.log(`[FlexibleNudge] Sent notification to ${userId}: ${response.successCount}/${response.responses.length} succeeded`);

  // Clean up invalid tokens
  const invalidRefs = [];
  response.responses.forEach((resp, index) => {
    if (!resp.success) {
      const code = resp.error?.code || '';
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        invalidRefs.push(deviceTokens[index]?.ref);
      }
    }
  });

  if (invalidRefs.length > 0) {
    await Promise.all(
      invalidRefs.filter((ref) => ref).map((ref) => ref.delete())
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────

module.exports = {
  scheduleFlexibleNudges,
  cancelFlexibleNudges,
  processFlexibleNudge,
  // Constants exported for testing
  EVENT_TYPE_SOFT,
  EVENT_TYPE_URGENT,
  SOFT_NUDGE_RATIO,
  URGENT_NUDGE_RATIO,
};
