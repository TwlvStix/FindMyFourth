'use strict';

/**
 * Notification Test Harness — Cloud Functions
 *
 * Two HTTPS Callable functions for iOS notification verification:
 *
 *   sendTestNotification    — triggers a notification through the full router pipeline
 *   generateDeliveryReport  — correlates server-side sends with client-side receipts
 *
 * Deployed alongside the main Cloud Functions. Requires authentication.
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { requireAppCheck } = require('./utils/app_check');
const { TrustEventType } = require('./notifications/trust/event-registry');
const { routeNotification } = require('./notifications/trust/router');

// ── Valid event types (set for O(1) lookup) ─────────────────────────────────

const VALID_EVENT_TYPES = new Set(Object.values(TrustEventType));

// ── Default test data for template variable interpolation ───────────────────
//
// Each event type's template uses {variable} placeholders. These defaults
// ensure every placeholder is satisfied so the router's template engine
// does not throw on missing variables.

const DEFAULT_TEST_DATA = {
  // Common across many types
  course_name: 'Test Course (Pine Valley)',
  game_date: 'Today 2:00 PM',
  host_name: 'Test Host',
  spots_remaining: '2',
  player_name: 'Test Player',
  badge_name: 'First Round',
  rounds_count: '5',
  unique_players: '10',
  sender_name: 'Test Sender',
  reason: 'Testing notification delivery',
  duration: '7 days',
  end_date: 'March 15, 2026',
  date: 'March 8, 2026',
  hours_remaining: '19',
  game_id: 'test_game_001',
  rounds_remaining: '3',
  next_badge_name: 'Verified Regular',
  acceptor_name: 'Test Acceptor',
  requester_name: 'Test Requester',
  owner_name: 'Test Owner',
  game_name: 'Test Game',
  current_weeks: '4',
  previous_weeks: '3',
  milestone: '4',
  // Deferred game alert passthrough
  title: 'Test Game Alert',
  body: 'This is a test game alert notification.',
};

// ── Per-event-type data overrides ───────────────────────────────────────────
//
// Some event types need specific fields. These are merged on top of
// DEFAULT_TEST_DATA so only the unique keys need to be listed.

const EVENT_TYPE_OVERRIDES = {
  [TrustEventType.HOST_CHECKIN_DUE]: {},
  [TrustEventType.PLAYER_RATE_DUE]: {},
  [TrustEventType.HOST_CHECKIN_FALLBACK]: {},
  [TrustEventType.PLAYER_FALLBACK_CONFIRM]: {},
  [TrustEventType.NO_SHOW_FLAGGED]: {},
  [TrustEventType.DISPUTE_RESOLVED]: {},
  [TrustEventType.STRIKE_ISSUED]: {},
  [TrustEventType.COOLDOWN_STARTED]: {},
  [TrustEventType.RESTRICTION_STARTED]: {},
  [TrustEventType.SUSPENSION_STARTED]: {},
  [TrustEventType.RESTRICTION_ENDED]: {},
  [TrustEventType.BADGE_EARNED]: {},
  [TrustEventType.BADGE_PROGRESS]: {},
  [TrustEventType.GAME_SPOT_OPENED]: {},
  [TrustEventType.GAME_CANCELLED]: {},
  [TrustEventType.GAME_ALERT_DEFERRED]: {
    gameId: 'test_game_001',
  },
  [TrustEventType.FRIEND_REQUEST_RECEIVED]: {},
  [TrustEventType.FRIEND_REQUEST_ACCEPTED]: {},
  [TrustEventType.JOIN_REQUEST_NEW]: {},
  [TrustEventType.JOIN_REQUEST_APPROVED]: {},
  [TrustEventType.JOIN_REQUEST_DECLINED]: {},
  [TrustEventType.JOIN_REQUEST_ROUND_FILLED]: {},
  [TrustEventType.JOIN_REQUEST_EXPIRED]: {},
  [TrustEventType.STREAK_WEEKEND_NUDGE]: {},
  [TrustEventType.STREAK_FREEZE_UNLOCKED]: {},
  [TrustEventType.STREAK_FREEZE_PROMPT]: {},
  [TrustEventType.STREAK_MILESTONE_REACHED]: {},
  [TrustEventType.STREAK_BROKEN]: {},
  [TrustEventType.PLAYER_ADDED_BY_HOST]: {},
  [TrustEventType.PLAYER_DECLINED_SPOT]: {},
  [TrustEventType.HOST_PRE_GAME_CONFIRM]: {},
};

// ── sendTestNotification ────────────────────────────────────────────────────

const sendTestNotification = functions
  .region('us-west2')
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    // ── Auth gate ──────────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required.',
      );
    }
    requireAppCheck(context, 'sendTestNotification');

    const { eventType, recipientUserId, testData } = data || {};

    // ── Validate eventType ─────────────────────────────────────────────────
    if (!eventType || !VALID_EVENT_TYPES.has(eventType)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid eventType "${eventType}". Must be one of: ${[...VALID_EVENT_TYPES].join(', ')}`,
      );
    }

    // ── Validate recipientUserId ───────────────────────────────────────────
    if (!recipientUserId || typeof recipientUserId !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'recipientUserId is required and must be a string.',
      );
    }

    // ── Build event data ───────────────────────────────────────────────────
    const eventOverrides = EVENT_TYPE_OVERRIDES[eventType] || {};
    const mergedData = {
      ...DEFAULT_TEST_DATA,
      ...eventOverrides,
      ...(testData || {}),
    };

    const eventId = `test_${eventType}_${Date.now()}`;
    const sourceId = mergedData.game_id || `test_source_${eventType}`;

    const event = {
      eventId,
      eventType,
      recipientUserId,
      sourceId,
      data: mergedData,
      isReminder: false,
    };

    // ── Route through the full pipeline ────────────────────────────────────
    const db = admin.firestore();
    const pipelineResult = await routeNotification(event, db);

    return {
      result: pipelineResult.result,
      sentCount: pipelineResult.sentCount || 0,
      pipelineOutcome: pipelineResult,
      eventId,
    };
  });

// ── generateDeliveryReport ──────────────────────────────────────────────────

const generateDeliveryReport = functions
  .region('us-west2')
  .runWith({ minInstances: 0 })
  .https.onCall(async (data, context) => {
    // ── Auth gate ──────────────────────────────────────────────────────────
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required.',
      );
    }
    requireAppCheck(context, 'generateDeliveryReport');

    const { userId, since, limit } = data || {};

    if (!userId || typeof userId !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userId is required and must be a string.',
      );
    }

    const db = admin.firestore();
    const queryLimit = typeof limit === 'number' && limit > 0 ? limit : 100;

    // ── Query server-side notificationLog ──────────────────────────────────
    let serverQuery = db
      .collection('notificationLog')
      .where('recipientUserId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(queryLimit);

    if (since) {
      const sinceDate = new Date(since);
      if (!isNaN(sinceDate.getTime())) {
        serverQuery = db
          .collection('notificationLog')
          .where('recipientUserId', '==', userId)
          .where('timestamp', '>=', sinceDate)
          .orderBy('timestamp', 'desc')
          .limit(queryLimit);
      }
    }

    const serverSnap = await serverQuery.get();

    // ── Query client-side notification_receipts ────────────────────────────
    let clientQuery = db
      .collection('users')
      .doc(userId)
      .collection('notification_receipts')
      .orderBy('receivedAt', 'desc')
      .limit(queryLimit);

    if (since) {
      const sinceDate = new Date(since);
      if (!isNaN(sinceDate.getTime())) {
        clientQuery = db
          .collection('users')
          .doc(userId)
          .collection('notification_receipts')
          .where('receivedAt', '>=', sinceDate)
          .orderBy('receivedAt', 'desc')
          .limit(queryLimit);
      }
    }

    const clientSnap = await clientQuery.get();

    // ── Build receipt map (eventId → receipt data) ─────────────────────────
    const receiptMap = {};
    for (const doc of clientSnap.docs) {
      const d = doc.data();
      const eventId = d.eventId || doc.id;
      receiptMap[eventId] = {
        receivedAt: d.receivedAt ? (typeof d.receivedAt.toDate === 'function' ? d.receivedAt.toDate().toISOString() : d.receivedAt) : null,
        deliveryState: d.deliveryState || 'unknown',
      };
    }

    // ── Correlate server events with client receipts ───────────────────────
    const events = [];
    const gapDetails = [];
    let totalSent = 0;
    let totalReceived = 0;
    let fgReceived = 0;
    let bgOpened = 0;
    let coldOpened = 0;

    for (const doc of serverSnap.docs) {
      const d = doc.data();
      const eventId = d.eventId || doc.id;
      const eventType = d.eventType || 'unknown';
      const status = d.status || 'unknown';

      // Extract sentAt timestamp
      let sentAt = null;
      if (d.timestamp) {
        sentAt = typeof d.timestamp.toDate === 'function'
          ? d.timestamp.toDate().toISOString()
          : d.timestamp;
      }

      // Only count 'sent' status as actual sends
      if (status === 'sent') {
        totalSent++;
      }

      // Look up client receipt
      const receipt = receiptMap[eventId];
      let clientStatus = 'missing_receipt';
      let receivedAt = null;
      let latencyMs = null;

      if (receipt) {
        clientStatus = receipt.deliveryState;
        receivedAt = receipt.receivedAt;
        totalReceived++;

        if (receipt.deliveryState === 'foreground') fgReceived++;
        if (receipt.deliveryState === 'background') bgOpened++;
        if (receipt.deliveryState === 'cold_open') coldOpened++;

        // Calculate latency
        if (sentAt && receivedAt) {
          const sentMs = new Date(sentAt).getTime();
          const receivedMs = new Date(receivedAt).getTime();
          if (!isNaN(sentMs) && !isNaN(receivedMs)) {
            latencyMs = receivedMs - sentMs;
          }
        }
      } else if (status === 'sent') {
        gapDetails.push({
          eventType,
          eventId,
          sentAt,
          status: 'missing_receipt',
        });
      }

      events.push({
        eventType,
        eventId,
        serverStatus: status,
        clientStatus,
        sentAt,
        receivedAt,
        latencyMs,
      });
    }

    return {
      events,
      summary: {
        totalSent,
        totalReceived,
        fgReceived,
        bgOpened,
        coldOpened,
        gaps: gapDetails.length,
      },
      gapDetails,
    };
  });

// ── Exports ─────────────────────────────────────────────────────────────────

module.exports = { sendTestNotification, generateDeliveryReport };
