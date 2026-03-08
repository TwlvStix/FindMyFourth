'use strict';

/**
 * Trust System Template Engine — Unit Tests
 *
 * Covers:
 *   buildPushPayload():
 *     - All 15 event types (primary template + rendered content)
 *     - host_checkin_due reminder variant
 *     - game_id interpolation in deepLink and threadId
 *     - No-variable event types (cooldown_started, suspension_started, restriction_ended)
 *     - isReminder=true on non-reminder events → error propagated
 *     - Unknown event type → error
 *     - Return shape
 *
 *   buildInAppNotification():
 *     - All 15 event types (type, title, body, read, createdAt, data shape)
 *     - game_id / game_ref present vs absent
 *     - Unknown event type → error
 *     - Return shape (top-level keys and data keys)
 *
 * Run: npx jest test/template-engine.test.js
 */

// ── Mock firebase-admin BEFORE requiring the module under test ────────────────

jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => ({ _type: 'SERVER_TIMESTAMP' })),
    },
  },
}));

const { buildPushPayload, buildInAppNotification } = require('../notifications/trust/template-engine');
const { TrustEventType, getEventConfig } = require('../notifications/trust/event-registry');

// ── Helpers ───────────────────────────────────────────────────────────────────

const GAME_ID  = 'game123';
const EVENT_ID = 'evt_abc';

/** Minimal eventData sets for each event type. */
const EVENT_DATA = {
  [TrustEventType.HOST_CHECKIN_DUE]:       { course_name: 'Pebble Beach', game_id: GAME_ID },
  [TrustEventType.PLAYER_RATE_DUE]:        { course_name: 'Torrey Pines', game_id: GAME_ID },
  [TrustEventType.HOST_CHECKIN_FALLBACK]:  { course_name: 'St Andrews', game_id: GAME_ID },
  [TrustEventType.PLAYER_FALLBACK_CONFIRM]:{ course_name: 'Bandon Dunes', date: 'June 10', game_id: GAME_ID },
  [TrustEventType.NO_SHOW_FLAGGED]:        { course_name: 'Whistling Straits', date: 'July 4' },
  [TrustEventType.DISPUTE_RESOLVED]:       { course_name: 'Oakmont', date: 'Aug 1' },
  [TrustEventType.STRIKE_ISSUED]:          { reason: 'confirmed no-show' },
  [TrustEventType.COOLDOWN_STARTED]:       {},
  [TrustEventType.RESTRICTION_STARTED]:    { duration: '7 days' },
  [TrustEventType.SUSPENSION_STARTED]:     {},
  [TrustEventType.RESTRICTION_ENDED]:      {},
  [TrustEventType.BADGE_EARNED]:           { badge_name: 'Gold', rounds_count: 25, unique_players: 40 },
  [TrustEventType.BADGE_PROGRESS]:         { rounds_remaining: 3, next_badge_name: 'Platinum' },
  [TrustEventType.GAME_SPOT_OPENED]:       { game_date: 'Saturday', course_name: 'Chambers Bay', spots_remaining: 1, game_id: GAME_ID },
  [TrustEventType.GAME_CANCELLED]:         { game_date: 'Sunday', course_name: 'Pinehurst', game_id: GAME_ID },
  [TrustEventType.GAME_ALERT_DEFERRED]:    { title: 'New Game Nearby', body: 'A new game at Pebble Beach matches your alerts.', gameId: GAME_ID },
  [TrustEventType.FRIEND_REQUEST_RECEIVED]: { sender_name: 'Alice', sender_id: 'user_alice' },
  [TrustEventType.FRIEND_REQUEST_ACCEPTED]: { acceptor_name: 'Bob', acceptor_id: 'user_bob' },
  [TrustEventType.JOIN_REQUEST_NEW]: { requester_name: 'Charlie', game_id: GAME_ID },
  [TrustEventType.JOIN_REQUEST_APPROVED]: { owner_name: 'Dave', game_name: 'Saturday at Spyglass', game_id: GAME_ID },
  [TrustEventType.JOIN_REQUEST_DECLINED]: { game_name: 'Sunday at Cypress Point' },
  [TrustEventType.JOIN_REQUEST_ROUND_FILLED]: { game_name: 'Friday at Augusta National' },
  [TrustEventType.JOIN_REQUEST_EXPIRED]: { game_name: 'Monday at Merion' },
  // Streak events
  [TrustEventType.STREAK_WEEKEND_NUDGE]: { current_weeks: 5 },
  [TrustEventType.STREAK_FREEZE_UNLOCKED]: { current_weeks: 4 },
  [TrustEventType.STREAK_FREEZE_PROMPT]: { current_weeks: 7 },
  [TrustEventType.STREAK_MILESTONE_REACHED]: { milestone: 8, current_weeks: 8 },
  [TrustEventType.STREAK_BROKEN]: { previous_weeks: 6 },
  // Host-add-player events
  [TrustEventType.PLAYER_ADDED_BY_HOST]: { host_name: 'Alice', course_name: 'Pebble Beach', game_date: 'Saturday', game_id: GAME_ID },
  [TrustEventType.PLAYER_DECLINED_SPOT]: { player_name: 'Bob', course_name: 'Torrey Pines', game_id: GAME_ID },
  // Pre-game confirmation (partial games only)
  [TrustEventType.HOST_PRE_GAME_CONFIRM]: { course_name: 'Sawgrass', game_date: 'Saturday', game_id: GAME_ID },
};

/** Interpolates {game_id} in a string, mirroring the engine's logic. */
function renderLink(template, gameId) {
  return template.replace(/\{game_id\}/g, gameId);
}

// ══════════════════════════════════════════════════════════════════════════════
// buildPushPayload
// ══════════════════════════════════════════════════════════════════════════════

describe('buildPushPayload — return shape', () => {
  test('returns all required TrustNotificationPayload fields', () => {
    const payload = buildPushPayload(TrustEventType.COOLDOWN_STARTED, {}, EVENT_ID);
    expect(Object.keys(payload).sort()).toEqual([
      'androidChannelId', 'body', 'deepLink', 'eventId', 'eventType',
      'priority', 'threadId', 'title',
    ]);
  });

  test('eventType and eventId are passed through unchanged', () => {
    const payload = buildPushPayload(TrustEventType.COOLDOWN_STARTED, {}, 'my_event_id');
    expect(payload.eventType).toBe(TrustEventType.COOLDOWN_STARTED);
    expect(payload.eventId).toBe('my_event_id');
  });

  test('priority matches getEventConfig().priority', () => {
    for (const type of Object.values(TrustEventType)) {
      const payload = buildPushPayload(type, EVENT_DATA[type], EVENT_ID);
      expect(payload.priority).toBe(getEventConfig(type).priority);
    }
  });

  test('androidChannelId matches getEventConfig().androidChannelId', () => {
    for (const type of Object.values(TrustEventType)) {
      const payload = buildPushPayload(type, EVENT_DATA[type], EVENT_ID);
      expect(payload.androidChannelId).toBe(getEventConfig(type).androidChannelId);
    }
  });
});

// ── Post-round ────────────────────────────────────────────────────────────────

describe('buildPushPayload: host_checkin_due', () => {
  const type = TrustEventType.HOST_CHECKIN_DUE;
  const data  = EVENT_DATA[type];

  test('primary template renders course_name in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Pebble Beach');
  });

  test('deepLink has game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(renderLink(getEventConfig(type).deepLink, GAME_ID));
    expect(payload.deepLink).not.toContain('{game_id}');
  });

  test('threadId has game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.threadId).toBe(renderLink(getEventConfig(type).threadId, GAME_ID));
    expect(payload.threadId).not.toContain('{game_id}');
  });

  test('reminder variant uses reminderTemplate copy', () => {
    const payload = buildPushPayload(type, { course_name: 'Augusta', hours_remaining: 4, game_id: GAME_ID }, EVENT_ID, true);
    expect(payload.title).toContain('Quick check-in needed');
    expect(payload.body).toContain('Augusta');
    expect(payload.body).toContain('4h');
  });

  test('reminder variant deepLink is still interpolated', () => {
    const payload = buildPushPayload(type, { course_name: 'Augusta', hours_remaining: 4, game_id: GAME_ID }, EVENT_ID, true);
    expect(payload.deepLink).not.toContain('{game_id}');
  });
});

describe('buildPushPayload: player_rate_due', () => {
  const type = TrustEventType.PLAYER_RATE_DUE;
  const data  = EVENT_DATA[type];

  test('renders course_name in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Torrey Pines');
  });

  test('deepLink and threadId have game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).not.toContain('{game_id}');
    expect(payload.threadId).not.toContain('{game_id}');
  });
});

describe('buildPushPayload: host_checkin_fallback', () => {
  const type = TrustEventType.HOST_CHECKIN_FALLBACK;
  const data  = EVENT_DATA[type];

  test('renders course_name in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('St Andrews');
  });

  test('deepLink and threadId have game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).not.toContain('{game_id}');
    expect(payload.threadId).not.toContain('{game_id}');
  });
});

describe('buildPushPayload: player_fallback_confirm', () => {
  const type = TrustEventType.PLAYER_FALLBACK_CONFIRM;
  const data  = EVENT_DATA[type];

  test('renders course_name and date in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Bandon Dunes');
    expect(payload.body).toContain('June 10');
  });

  test('deepLink and threadId have game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).not.toContain('{game_id}');
    expect(payload.threadId).not.toContain('{game_id}');
  });
});

// ── Trust & enforcement ───────────────────────────────────────────────────────

describe('buildPushPayload: no_show_flagged', () => {
  const type = TrustEventType.NO_SHOW_FLAGGED;
  const data  = EVENT_DATA[type];

  test('renders course_name and date in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Whistling Straits');
    expect(payload.body).toContain('July 4');
  });

  test('deepLink is findmyfourth://trust/standing (no game_id)', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });

  test('threadId is trust_alerts (no game_id)', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.threadId).toBe('trust_alerts');
  });
});

describe('buildPushPayload: dispute_resolved', () => {
  const type = TrustEventType.DISPUTE_RESOLVED;
  const data  = EVENT_DATA[type];

  test('renders course_name and date in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Oakmont');
    expect(payload.body).toContain('Aug 1');
  });

  test('deepLink is findmyfourth://trust/standing', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

describe('buildPushPayload: strike_issued', () => {
  const type = TrustEventType.STRIKE_ISSUED;
  const data  = EVENT_DATA[type];

  test('renders reason in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('confirmed no-show');
  });

  test('deepLink is findmyfourth://trust/standing', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

describe('buildPushPayload: cooldown_started', () => {
  const type = TrustEventType.COOLDOWN_STARTED;

  test('renders with no variables required', () => {
    const payload = buildPushPayload(type, {}, EVENT_ID);
    expect(payload.title).toContain('24-hour cooldown');
    expect(payload.body).toContain('2 active strikes');
  });

  test('deepLink is findmyfourth://trust/standing', () => {
    const payload = buildPushPayload(type, {}, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

describe('buildPushPayload: restriction_started', () => {
  const type = TrustEventType.RESTRICTION_STARTED;
  const data  = EVENT_DATA[type];

  test('renders duration in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('7 days');
  });

  test('deepLink is findmyfourth://trust/standing', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

describe('buildPushPayload: suspension_started', () => {
  const type = TrustEventType.SUSPENSION_STARTED;

  test('renders with no variables required', () => {
    const payload = buildPushPayload(type, {}, EVENT_ID);
    expect(payload.title).toContain('Account suspended');
    expect(payload.body).toContain('5 business days');
  });

  test('deepLink is findmyfourth://trust/standing', () => {
    const payload = buildPushPayload(type, {}, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

describe('buildPushPayload: restriction_ended', () => {
  const type = TrustEventType.RESTRICTION_ENDED;

  test('renders with no variables required', () => {
    const payload = buildPushPayload(type, {}, EVENT_ID);
    expect(payload.title).toContain('Welcome back');
    expect(payload.body).toContain('restriction has been lifted');
  });

  test('deepLink is findmyfourth://trust/standing', () => {
    const payload = buildPushPayload(type, {}, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

// ── Badges ────────────────────────────────────────────────────────────────────

describe('buildPushPayload: badge_earned', () => {
  const type = TrustEventType.BADGE_EARNED;
  const data  = EVENT_DATA[type];

  test('renders badge_name, rounds_count, unique_players in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Gold');
    expect(payload.body).toContain('25');
    expect(payload.body).toContain('40');
  });

  test('deepLink is findmyfourth://badges (no game_id)', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
    expect(payload.deepLink).not.toContain('{game_id}');
  });

  test('threadId is badges', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.threadId).toBe('badges');
  });
});

describe('buildPushPayload: badge_progress', () => {
  const type = TrustEventType.BADGE_PROGRESS;
  const data  = EVENT_DATA[type];

  test('renders rounds_remaining and next_badge_name in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('3');
    expect(payload.body).toContain('Platinum');
  });

  test('deepLink is findmyfourth://badges', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(getEventConfig(type).deepLink);
  });
});

// ── Games ─────────────────────────────────────────────────────────────────────

describe('buildPushPayload: game_spot_opened', () => {
  const type = TrustEventType.GAME_SPOT_OPENED;
  const data  = EVENT_DATA[type];

  test('renders game_date, course_name, spots_remaining in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Saturday');
    expect(payload.body).toContain('Chambers Bay');
    expect(payload.body).toContain('1');
  });

  test('deepLink has game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(renderLink(getEventConfig(type).deepLink, GAME_ID));
    expect(payload.deepLink).not.toContain('{game_id}');
  });

  test('threadId has game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.threadId).toBe(renderLink(getEventConfig(type).threadId, GAME_ID));
    expect(payload.threadId).not.toContain('{game_id}');
  });
});

describe('buildPushPayload: game_cancelled', () => {
  const type = TrustEventType.GAME_CANCELLED;
  const data  = EVENT_DATA[type];

  test('renders game_date and course_name in body', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.body).toContain('Sunday');
    expect(payload.body).toContain('Pinehurst');
  });

  test('deepLink has game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.deepLink).toBe(renderLink(getEventConfig(type).deepLink, GAME_ID));
    expect(payload.deepLink).not.toContain('{game_id}');
  });

  test('threadId has game_id interpolated', () => {
    const payload = buildPushPayload(type, data, EVENT_ID);
    expect(payload.threadId).toBe(renderLink(getEventConfig(type).threadId, GAME_ID));
    expect(payload.threadId).not.toContain('{game_id}');
  });
});

// ── buildPushPayload error paths ──────────────────────────────────────────────

describe('buildPushPayload — error paths', () => {
  test('unknown event type throws', () => {
    expect(() => buildPushPayload('not_a_real_type', {}, EVENT_ID)).toThrow(
      /Unknown Trust event type/,
    );
  });

  test('missing required template variable throws', () => {
    expect(() =>
      buildPushPayload(TrustEventType.STRIKE_ISSUED, {}, EVENT_ID),
    ).toThrow(/reason/);
  });

  test('isReminder=true on event with no reminderTemplate throws', () => {
    expect(() =>
      buildPushPayload(TrustEventType.PLAYER_RATE_DUE, { course_name: 'X' }, EVENT_ID, true),
    ).toThrow(/No reminder template/);
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// buildInAppNotification
// ══════════════════════════════════════════════════════════════════════════════

describe('buildInAppNotification — return shape', () => {
  test('top-level keys are exactly: type, title, body, read, createdAt, data', () => {
    const doc = buildInAppNotification(TrustEventType.COOLDOWN_STARTED, {}, EVENT_ID);
    expect(Object.keys(doc).sort()).toEqual(
      ['body', 'createdAt', 'data', 'read', 'title', 'type'],
    );
  });

  test('data keys are exactly: eventId, eventType, gameId, gameRef', () => {
    const doc = buildInAppNotification(TrustEventType.COOLDOWN_STARTED, {}, EVENT_ID);
    expect(Object.keys(doc.data).sort()).toEqual(
      ['eventId', 'eventType', 'gameId', 'gameRef'],
    );
  });

  test('read is always false', () => {
    for (const type of Object.values(TrustEventType)) {
      const doc = buildInAppNotification(type, EVENT_DATA[type], EVENT_ID);
      expect(doc.read).toBe(false);
    }
  });

  test('createdAt is the serverTimestamp sentinel', () => {
    const doc = buildInAppNotification(TrustEventType.COOLDOWN_STARTED, {}, EVENT_ID);
    expect(doc.createdAt).toEqual({ _type: 'SERVER_TIMESTAMP' });
  });

  test('data.eventId equals the passed eventId', () => {
    const doc = buildInAppNotification(TrustEventType.COOLDOWN_STARTED, {}, 'specific_event_id');
    expect(doc.data.eventId).toBe('specific_event_id');
  });

  test('data.eventType equals the event type', () => {
    for (const type of Object.values(TrustEventType)) {
      const doc = buildInAppNotification(type, EVENT_DATA[type], EVENT_ID);
      expect(doc.data.eventType).toBe(type);
    }
  });

  test('type field equals the event type (snake_case)', () => {
    for (const type of Object.values(TrustEventType)) {
      const doc = buildInAppNotification(type, EVENT_DATA[type], EVENT_ID);
      expect(doc.type).toBe(type);
    }
  });
});

describe('buildInAppNotification — game_id and game_ref handling', () => {
  test('game_id present → data.gameId is set', () => {
    const doc = buildInAppNotification(
      TrustEventType.HOST_CHECKIN_DUE,
      { course_name: 'X', game_id: 'game_abc' },
      EVENT_ID,
    );
    expect(doc.data.gameId).toBe('game_abc');
  });

  test('game_id absent → data.gameId is null', () => {
    const doc = buildInAppNotification(
      TrustEventType.COOLDOWN_STARTED,
      {},
      EVENT_ID,
    );
    expect(doc.data.gameId).toBeNull();
  });

  test('game_ref present → data.gameRef is set', () => {
    const doc = buildInAppNotification(
      TrustEventType.HOST_CHECKIN_DUE,
      { course_name: 'X', game_id: 'g1', game_ref: 'games/g1' },
      EVENT_ID,
    );
    expect(doc.data.gameRef).toBe('games/g1');
  });

  test('game_ref absent → data.gameRef is null', () => {
    const doc = buildInAppNotification(
      TrustEventType.COOLDOWN_STARTED,
      {},
      EVENT_ID,
    );
    expect(doc.data.gameRef).toBeNull();
  });
});

// ── Post-round ────────────────────────────────────────────────────────────────

describe('buildInAppNotification: host_checkin_due', () => {
  test('title and body are rendered', () => {
    const doc = buildInAppNotification(
      TrustEventType.HOST_CHECKIN_DUE,
      { course_name: 'Pebble Beach', game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.title).toBeTruthy();
    expect(doc.body).toContain('Pebble Beach');
  });
});

describe('buildInAppNotification: player_rate_due', () => {
  test('title and body are rendered', () => {
    const doc = buildInAppNotification(
      TrustEventType.PLAYER_RATE_DUE,
      { course_name: 'Torrey Pines', game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.body).toContain('Torrey Pines');
  });
});

describe('buildInAppNotification: host_checkin_fallback', () => {
  test('title and body are rendered', () => {
    const doc = buildInAppNotification(
      TrustEventType.HOST_CHECKIN_FALLBACK,
      { course_name: 'St Andrews', game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.body).toContain('St Andrews');
  });
});

describe('buildInAppNotification: player_fallback_confirm', () => {
  test('title and body are rendered', () => {
    const doc = buildInAppNotification(
      TrustEventType.PLAYER_FALLBACK_CONFIRM,
      { course_name: 'Bandon Dunes', date: 'June 10', game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.body).toContain('Bandon Dunes');
    expect(doc.body).toContain('June 10');
  });
});

// ── Trust & enforcement ───────────────────────────────────────────────────────

describe('buildInAppNotification: no_show_flagged', () => {
  test('title and body are rendered', () => {
    const doc = buildInAppNotification(
      TrustEventType.NO_SHOW_FLAGGED,
      { course_name: 'Whistling Straits', date: 'July 4' },
      EVENT_ID,
    );
    expect(doc.body).toContain('Whistling Straits');
    expect(doc.body).toContain('July 4');
  });

  test('data.gameId and data.gameRef are null (no game_id in eventData)', () => {
    const doc = buildInAppNotification(
      TrustEventType.NO_SHOW_FLAGGED,
      { course_name: 'X', date: 'Y' },
      EVENT_ID,
    );
    expect(doc.data.gameId).toBeNull();
    expect(doc.data.gameRef).toBeNull();
  });
});

describe('buildInAppNotification: dispute_resolved', () => {
  test('title and body are rendered', () => {
    const doc = buildInAppNotification(
      TrustEventType.DISPUTE_RESOLVED,
      { course_name: 'Oakmont', date: 'Aug 1' },
      EVENT_ID,
    );
    expect(doc.body).toContain('Oakmont');
    expect(doc.body).toContain('Aug 1');
  });
});

describe('buildInAppNotification: strike_issued', () => {
  test('renders reason in body', () => {
    const doc = buildInAppNotification(
      TrustEventType.STRIKE_ISSUED,
      { reason: 'late cancellation' },
      EVENT_ID,
    );
    expect(doc.body).toContain('late cancellation');
  });
});

describe('buildInAppNotification: cooldown_started', () => {
  test('renders with no variables required', () => {
    const doc = buildInAppNotification(TrustEventType.COOLDOWN_STARTED, {}, EVENT_ID);
    expect(doc.title).toContain('24-hour cooldown');
    expect(doc.body).toContain('2 active strikes');
  });
});

describe('buildInAppNotification: restriction_started', () => {
  test('renders duration in body', () => {
    const doc = buildInAppNotification(
      TrustEventType.RESTRICTION_STARTED,
      { duration: '30 days' },
      EVENT_ID,
    );
    expect(doc.body).toContain('30 days');
  });
});

describe('buildInAppNotification: suspension_started', () => {
  test('renders with no variables required', () => {
    const doc = buildInAppNotification(TrustEventType.SUSPENSION_STARTED, {}, EVENT_ID);
    expect(doc.title).toContain('Account suspended');
  });
});

describe('buildInAppNotification: restriction_ended', () => {
  test('renders with no variables required', () => {
    const doc = buildInAppNotification(TrustEventType.RESTRICTION_ENDED, {}, EVENT_ID);
    expect(doc.title).toContain('Welcome back');
    expect(doc.body).toContain('restriction has been lifted');
  });
});

// ── Badges ────────────────────────────────────────────────────────────────────

describe('buildInAppNotification: badge_earned', () => {
  test('renders badge_name, rounds_count, unique_players', () => {
    const doc = buildInAppNotification(
      TrustEventType.BADGE_EARNED,
      { badge_name: 'Gold', rounds_count: 25, unique_players: 40 },
      EVENT_ID,
    );
    expect(doc.body).toContain('Gold');
    expect(doc.body).toContain('25');
    expect(doc.body).toContain('40');
  });
});

describe('buildInAppNotification: badge_progress', () => {
  test('renders rounds_remaining and next_badge_name', () => {
    const doc = buildInAppNotification(
      TrustEventType.BADGE_PROGRESS,
      { rounds_remaining: 5, next_badge_name: 'Diamond' },
      EVENT_ID,
    );
    expect(doc.body).toContain('5');
    expect(doc.body).toContain('Diamond');
  });
});

// ── Games ─────────────────────────────────────────────────────────────────────

describe('buildInAppNotification: game_spot_opened', () => {
  test('renders game_date, course_name, spots_remaining', () => {
    const doc = buildInAppNotification(
      TrustEventType.GAME_SPOT_OPENED,
      { game_date: 'Saturday', course_name: 'Chambers Bay', spots_remaining: 2, game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.body).toContain('Saturday');
    expect(doc.body).toContain('Chambers Bay');
    expect(doc.body).toContain('2');
  });

  test('data.gameId is set from game_id', () => {
    const doc = buildInAppNotification(
      TrustEventType.GAME_SPOT_OPENED,
      { game_date: 'X', course_name: 'Y', spots_remaining: 1, game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.data.gameId).toBe(GAME_ID);
  });
});

describe('buildInAppNotification: game_cancelled', () => {
  test('renders game_date and course_name', () => {
    const doc = buildInAppNotification(
      TrustEventType.GAME_CANCELLED,
      { game_date: 'Sunday', course_name: 'Pinehurst', game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.body).toContain('Sunday');
    expect(doc.body).toContain('Pinehurst');
  });

  test('data.gameId is set from game_id', () => {
    const doc = buildInAppNotification(
      TrustEventType.GAME_CANCELLED,
      { game_date: 'X', course_name: 'Y', game_id: GAME_ID },
      EVENT_ID,
    );
    expect(doc.data.gameId).toBe(GAME_ID);
  });
});

// ── buildInAppNotification error paths ────────────────────────────────────────

describe('buildInAppNotification — error paths', () => {
  test('unknown event type throws', () => {
    expect(() =>
      buildInAppNotification('not_a_real_type', {}, EVENT_ID),
    ).toThrow(/Unknown Trust event type/);
  });

  test('missing required template variable throws', () => {
    expect(() =>
      buildInAppNotification(TrustEventType.STRIKE_ISSUED, {}, EVENT_ID),
    ).toThrow(/reason/);
  });
});
