'use strict';

/**
 * Trust System Notification Hooks — Unit Tests
 *
 * Covers every hook:
 *   onGameConfirmed             — 4 scheduled jobs (2-player), 5 (3-player), host excluded from player_fallback
 *   onHostCheckinCompleted      — cancel game jobs + schedule player_rate_due
 *   onGameCancelled             — cancel game jobs + immediate game_cancelled fan-out
 *   onStrikeIssued              — immediate strike_issued
 *   onCooldownStarted           — immediate cooldown_started
 *   onRestrictionStarted        — immediate restriction_started + scheduled restriction_ended
 *   onSuspensionStarted         — immediate suspension_started
 *   onNoShowFlagged             — immediate no_show_flagged
 *   onDisputeResolved           — immediate dispute_resolved
 *   onBadgeEarned               — immediate badge_earned (numeric coercion)
 *   onSpotOpened                — immediate game_spot_opened fan-out
 *   onFriendRequestReceived     — immediate friend_request_received
 *   onFriendRequestAccepted     — immediate friend_request_accepted
 *
 * Run: npx jest test/hooks.test.js --verbose
 */

// ── Mock: crypto ──────────────────────────────────────────────────────────────
// Use inline jest.fn() so no out-of-scope variable is referenced in the factory.

jest.mock('crypto', () => ({
  randomUUID: jest.fn(),
}));

// ── Mock: scheduler ───────────────────────────────────────────────────────────

jest.mock('../notifications/trust/scheduler', () => ({
  scheduleJob:    jest.fn(),
  cancelGameJobs: jest.fn(),
}));

// ── Mock: router ──────────────────────────────────────────────────────────────

jest.mock('../notifications/trust/router', () => ({
  routeNotification: jest.fn(),
}));

// ── Mock: firebase-admin ──────────────────────────────────────────────────────
// Not used directly by hooks, but required because scheduler and router import it.

jest.mock('firebase-admin', () => ({
  firestore: jest.fn(),
}));

// ── Module under test ─────────────────────────────────────────────────────────

const {
  onGameConfirmed,
  onHostCheckinCompleted,
  onGameCancelled,
  onStrikeIssued,
  onCooldownStarted,
  onRestrictionStarted,
  onSuspensionStarted,
  onNoShowFlagged,
  onDisputeResolved,
  onBadgeEarned,
  onSpotOpened,
  onFriendRequestReceived,
  onFriendRequestAccepted,
} = require('../notifications/trust/hooks');

// ── Constants ─────────────────────────────────────────────────────────────────

const TEE_TIME_ISO = '2026-03-15T14:00:00.000Z';
const TEE_TIME_MS  = new Date(TEE_TIME_ISO).getTime();
const MS_IN_HOUR   = 60 * 60 * 1000;

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();

  // Predictable UUIDs for assertions
  let counter = 0;
  const { randomUUID } = require('crypto');
  randomUUID.mockImplementation(() => `uuid-${++counter}`);

  const { scheduleJob, cancelGameJobs } = require('../notifications/trust/scheduler');
  const { routeNotification }           = require('../notifications/trust/router');

  let jobNum = 0;
  scheduleJob.mockImplementation(async () => `job_${++jobNum}`);
  cancelGameJobs.mockResolvedValue({ count: 3 });
  routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });
});

afterEach(() => {
  jest.useRealTimers();
});

// ════════════════════════════════════════════════════════════════════════════
// onGameConfirmed
// ════════════════════════════════════════════════════════════════════════════

describe('onGameConfirmed', () => {

  const GAME_ID     = 'game_g1';
  const HOST        = 'user_host';
  const PLAYER_1    = 'user_p1';
  const PLAYER_2    = 'user_p2';
  const COURSE_NAME = 'Pebble Beach';
  const GAME_DATE   = 'Mar 15';

  test('2-player game (host + 1): schedules exactly 4 jobs', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);
    expect(scheduleJob).toHaveBeenCalledTimes(4);
  });

  test('3-player game (host + 2): schedules exactly 5 jobs', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1, PLAYER_2], COURSE_NAME, GAME_DATE);
    expect(scheduleJob).toHaveBeenCalledTimes(5);
  });

  test('host_checkin_due (initial): scheduleTime = teeTime + 5h, conditionCheck=always, isReminder=false', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const calls = scheduleJob.mock.calls.map((c) => c[0]);
    const initial = calls.find(
      (e) => e.eventType === 'host_checkin_due' && e.conditionCheck === 'always',
    );

    expect(initial).toBeDefined();
    expect(initial.recipientUserId).toBe(HOST);
    expect(new Date(initial.scheduleTime).getTime()).toBe(TEE_TIME_MS + 5 * MS_IN_HOUR);
    expect(initial.isReminder).toBe(false);
    expect(initial.data.course_name).toBe(COURSE_NAME);
    expect(initial.data.game_id).toBe(GAME_ID);
  });

  test('host_checkin_due (reminder): scheduleTime = teeTime + 29h, conditionCheck=host_not_checked_in, isReminder=true', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const calls = scheduleJob.mock.calls.map((c) => c[0]);
    const reminder = calls.find(
      (e) => e.eventType === 'host_checkin_due' && e.conditionCheck === 'host_not_checked_in',
    );

    expect(reminder).toBeDefined();
    expect(reminder.recipientUserId).toBe(HOST);
    expect(new Date(reminder.scheduleTime).getTime()).toBe(TEE_TIME_MS + 29 * MS_IN_HOUR);
    expect(reminder.isReminder).toBe(true);
    expect(reminder.data.hours_remaining).toBe('19');
  });

  test('host_checkin_fallback: scheduleTime = teeTime + 24h, conditionCheck=host_not_checked_in', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const calls = scheduleJob.mock.calls.map((c) => c[0]);
    const fallback = calls.find((e) => e.eventType === 'host_checkin_fallback');

    expect(fallback).toBeDefined();
    expect(fallback.recipientUserId).toBe(HOST);
    expect(new Date(fallback.scheduleTime).getTime()).toBe(TEE_TIME_MS + 24 * MS_IN_HOUR);
    expect(fallback.conditionCheck).toBe('host_not_checked_in');
  });

  test('player_fallback_confirm: scheduleTime = teeTime + 24h, sent to non-host player, includes gameDate', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const calls = scheduleJob.mock.calls.map((c) => c[0]);
    const fallback = calls.find((e) => e.eventType === 'player_fallback_confirm');

    expect(fallback).toBeDefined();
    expect(fallback.recipientUserId).toBe(PLAYER_1);
    expect(new Date(fallback.scheduleTime).getTime()).toBe(TEE_TIME_MS + 24 * MS_IN_HOUR);
    expect(fallback.conditionCheck).toBe('host_not_checked_in');
    expect(fallback.data.date).toBe(GAME_DATE);
    expect(fallback.data.game_id).toBe(GAME_ID);
  });

  test('host is excluded from player_fallback_confirm fan-out', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const fallbacks = scheduleJob.mock.calls
      .map((c) => c[0])
      .filter((e) => e.eventType === 'player_fallback_confirm');

    expect(fallbacks.every((e) => e.recipientUserId !== HOST)).toBe(true);
  });

  test('3-player game: two player_fallback_confirm jobs (one per non-host)', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1, PLAYER_2], COURSE_NAME, GAME_DATE);

    const fallbacks = scheduleJob.mock.calls
      .map((c) => c[0])
      .filter((e) => e.eventType === 'player_fallback_confirm');

    expect(fallbacks).toHaveLength(2);
    const recipients = fallbacks.map((e) => e.recipientUserId).sort();
    expect(recipients).toEqual([PLAYER_1, PLAYER_2].sort());
  });

  test('returns all jobIds keyed correctly', async () => {
    const result = await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    expect(result).toHaveProperty('hostCheckinJobId');
    expect(result).toHaveProperty('hostCheckinReminderJobId');
    expect(result).toHaveProperty('hostFallbackJobId');
    expect(result.playerFallbackJobIds).toHaveProperty(PLAYER_1);
  });

  test('all scheduleJob calls include sourceId=gameId', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onGameConfirmed(GAME_ID, TEE_TIME_ISO, HOST, [HOST, PLAYER_1], COURSE_NAME, GAME_DATE);

    const badCalls = scheduleJob.mock.calls
      .map((c) => c[0])
      .filter((e) => e.sourceId !== GAME_ID);

    expect(badCalls).toHaveLength(0);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onHostCheckinCompleted
// ════════════════════════════════════════════════════════════════════════════

describe('onHostCheckinCompleted', () => {

  const GAME_ID     = 'game_g1';
  const HOST        = 'user_host';
  const PLAYER_1    = 'user_p1';
  const COURSE_NAME = 'Augusta National';

  test('calls cancelGameJobs with the correct gameId', async () => {
    const { cancelGameJobs } = require('../notifications/trust/scheduler');
    await onHostCheckinCompleted(GAME_ID, HOST, [HOST, PLAYER_1], COURSE_NAME);
    expect(cancelGameJobs).toHaveBeenCalledWith(GAME_ID, undefined);
  });

  test('schedules player_rate_due for every user in playerUserIds', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onHostCheckinCompleted(GAME_ID, HOST, [HOST, PLAYER_1], COURSE_NAME);

    const rateCalls = scheduleJob.mock.calls
      .map((c) => c[0])
      .filter((e) => e.eventType === 'player_rate_due');

    expect(rateCalls).toHaveLength(2);
    const recipients = rateCalls.map((e) => e.recipientUserId).sort();
    expect(recipients).toEqual([HOST, PLAYER_1].sort());
  });

  test('player_rate_due jobs: conditionCheck=always, scheduleTime ≈ now + 30min', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-03-15T10:00:00Z'));

    await onHostCheckinCompleted(GAME_ID, HOST, [HOST], COURSE_NAME);

    const event = scheduleJob.mock.calls.find((c) => c[0].eventType === 'player_rate_due')[0];
    expect(event.conditionCheck).toBe('always');
    expect(new Date(event.scheduleTime).getTime()).toBe(
      new Date('2026-03-15T10:00:00Z').getTime() + 30 * 60 * 1000,
    );
  });

  test('player_rate_due data includes course_name and game_id', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onHostCheckinCompleted(GAME_ID, HOST, [HOST], COURSE_NAME);

    const event = scheduleJob.mock.calls.find((c) => c[0].eventType === 'player_rate_due')[0];
    expect(event.data.course_name).toBe(COURSE_NAME);
    expect(event.data.game_id).toBe(GAME_ID);
  });

  test('returns cancelledCount and playerRateJobIds map', async () => {
    const { cancelGameJobs, scheduleJob } = require('../notifications/trust/scheduler');
    cancelGameJobs.mockResolvedValue({ count: 3 });
    let n = 0;
    scheduleJob.mockImplementation(async () => `rate_job_${++n}`);

    const result = await onHostCheckinCompleted(GAME_ID, HOST, [HOST, PLAYER_1], COURSE_NAME);

    expect(result.cancelledCount).toBe(3);
    expect(result.playerRateJobIds).toHaveProperty(HOST);
    expect(result.playerRateJobIds).toHaveProperty(PLAYER_1);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onGameCancelled
// ════════════════════════════════════════════════════════════════════════════

describe('onGameCancelled', () => {

  const GAME_ID     = 'game_g1';
  const PLAYER_1    = 'user_p1';
  const PLAYER_2    = 'user_p2';
  const COURSE_NAME = 'Torrey Pines';
  const GAME_DATE   = 'Mar 15';

  test('calls cancelGameJobs with the correct gameId', async () => {
    const { cancelGameJobs } = require('../notifications/trust/scheduler');
    await onGameCancelled(GAME_ID, [PLAYER_1], COURSE_NAME, GAME_DATE);
    expect(cancelGameJobs).toHaveBeenCalledWith(GAME_ID, undefined);
  });

  test('calls routeNotification once per player', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onGameCancelled(GAME_ID, [PLAYER_1, PLAYER_2], COURSE_NAME, GAME_DATE);
    expect(routeNotification).toHaveBeenCalledTimes(2);
  });

  test('game_cancelled event has correct data fields', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onGameCancelled(GAME_ID, [PLAYER_1], COURSE_NAME, GAME_DATE);

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('game_cancelled');
    expect(event.recipientUserId).toBe(PLAYER_1);
    expect(event.sourceId).toBe(GAME_ID);
    expect(event.data.game_date).toBe(GAME_DATE);
    expect(event.data.course_name).toBe(COURSE_NAME);
    expect(event.data.game_id).toBe(GAME_ID);
  });

  test('returns cancelledCount and notifyResults array', async () => {
    const { cancelGameJobs } = require('../notifications/trust/scheduler');
    const { routeNotification } = require('../notifications/trust/router');
    cancelGameJobs.mockResolvedValue({ count: 2 });
    routeNotification.mockResolvedValue({ result: 'sent' });

    const result = await onGameCancelled(GAME_ID, [PLAYER_1, PLAYER_2], COURSE_NAME, GAME_DATE);

    expect(result.cancelledCount).toBe(2);
    expect(result.notifyResults).toHaveLength(2);
    expect(result.notifyResults[0]).toHaveProperty('userId');
    expect(result.notifyResults[0]).toHaveProperty('result');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onStrikeIssued
// ════════════════════════════════════════════════════════════════════════════

describe('onStrikeIssued', () => {

  test('calls routeNotification with strike_issued, correct data and sourceId=userId', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onStrikeIssued('user_abc', 'confirmed no-show');

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('strike_issued');
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.sourceId).toBe('user_abc');
    expect(event.data.reason).toBe('confirmed no-show');
  });

  test('returns routeNotification result', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });
    const result = await onStrikeIssued('user_abc', 'no-show');
    expect(result.result).toBe('sent');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onCooldownStarted
// ════════════════════════════════════════════════════════════════════════════

describe('onCooldownStarted', () => {

  test('calls routeNotification with cooldown_started and empty data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onCooldownStarted('user_abc');

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('cooldown_started');
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.sourceId).toBe('user_abc');
    expect(event.data).toEqual({});
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onRestrictionStarted
// ════════════════════════════════════════════════════════════════════════════

describe('onRestrictionStarted', () => {

  const USER_ID  = 'user_abc';
  const DURATION = '7 days';
  const END_DATE = '2026-03-22T10:00:00.000Z';

  test('calls routeNotification with restriction_started and data.duration', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onRestrictionStarted(USER_ID, DURATION, END_DATE);

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('restriction_started');
    expect(event.recipientUserId).toBe(USER_ID);
    expect(event.sourceId).toBe(USER_ID);
    expect(event.data.duration).toBe(DURATION);
  });

  test('calls scheduleJob with restriction_ended at endDate, sourceId=userId, conditionCheck=always', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    await onRestrictionStarted(USER_ID, DURATION, END_DATE);

    const jobEvent = scheduleJob.mock.calls[0][0];
    expect(jobEvent.eventType).toBe('restriction_ended');
    expect(jobEvent.recipientUserId).toBe(USER_ID);
    expect(jobEvent.sourceId).toBe(USER_ID);
    expect(new Date(jobEvent.scheduleTime).toISOString()).toBe(new Date(END_DATE).toISOString());
    expect(jobEvent.conditionCheck).toBe('always');
    expect(jobEvent.data).toEqual({});
  });

  test('returns both notifyResult and restrictionEndedJobId', async () => {
    const { scheduleJob } = require('../notifications/trust/scheduler');
    const { routeNotification } = require('../notifications/trust/router');
    routeNotification.mockResolvedValue({ result: 'sent' });
    scheduleJob.mockResolvedValue('job_restriction_ended_001');

    const result = await onRestrictionStarted(USER_ID, DURATION, END_DATE);

    expect(result.notifyResult).toEqual({ result: 'sent' });
    expect(result.restrictionEndedJobId).toBe('job_restriction_ended_001');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onSuspensionStarted
// ════════════════════════════════════════════════════════════════════════════

describe('onSuspensionStarted', () => {

  test('calls routeNotification with suspension_started and empty data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onSuspensionStarted('user_abc');

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('suspension_started');
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.sourceId).toBe('user_abc');
    expect(event.data).toEqual({});
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onNoShowFlagged
// ════════════════════════════════════════════════════════════════════════════

describe('onNoShowFlagged', () => {

  test('calls routeNotification with no_show_flagged and correct data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onNoShowFlagged('user_abc', 'Pebble Beach', 'Mar 10');

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('no_show_flagged');
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.sourceId).toBe('user_abc');
    expect(event.data.course_name).toBe('Pebble Beach');
    expect(event.data.date).toBe('Mar 10');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onDisputeResolved
// ════════════════════════════════════════════════════════════════════════════

describe('onDisputeResolved', () => {

  test('calls routeNotification with dispute_resolved and correct data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onDisputeResolved('user_abc', 'Torrey Pines', 'Mar 12');

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('dispute_resolved');
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.sourceId).toBe('user_abc');
    expect(event.data.course_name).toBe('Torrey Pines');
    expect(event.data.date).toBe('Mar 12');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onBadgeEarned
// ════════════════════════════════════════════════════════════════════════════

describe('onBadgeEarned', () => {

  test('calls routeNotification with badge_earned and correct data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onBadgeEarned('user_abc', 'Verified Regular', 10, 15);

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('badge_earned');
    expect(event.recipientUserId).toBe('user_abc');
    expect(event.sourceId).toBe('user_abc');
    expect(event.data.badge_name).toBe('Verified Regular');
    expect(event.data.rounds_count).toBe('10');
    expect(event.data.unique_players).toBe('15');
  });

  test('numeric roundsCount and uniquePlayers are coerced to strings', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onBadgeEarned('user_abc', 'Gold', 5, 8);

    const event = routeNotification.mock.calls[0][0];
    expect(typeof event.data.rounds_count).toBe('string');
    expect(typeof event.data.unique_players).toBe('string');
  });

  test('string inputs pass through as-is', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onBadgeEarned('user_abc', 'Platinum', '20', '30');

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.rounds_count).toBe('20');
    expect(event.data.unique_players).toBe('30');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onSpotOpened
// ════════════════════════════════════════════════════════════════════════════

describe('onSpotOpened', () => {

  const GAME_ID     = 'game_g1';
  const PLAYER_1    = 'user_p1';
  const PLAYER_2    = 'user_p2';
  const COURSE_NAME = 'Augusta National';
  const GAME_DATE   = 'Mar 20';

  test('calls routeNotification once per user in playerUserIds', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onSpotOpened([PLAYER_1, PLAYER_2], GAME_ID, COURSE_NAME, GAME_DATE, 2);
    expect(routeNotification).toHaveBeenCalledTimes(2);
  });

  test('game_spot_opened event has correct data including game_id', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onSpotOpened([PLAYER_1], GAME_ID, COURSE_NAME, GAME_DATE, 3);

    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('game_spot_opened');
    expect(event.recipientUserId).toBe(PLAYER_1);
    expect(event.sourceId).toBe(GAME_ID);
    expect(event.data.game_date).toBe(GAME_DATE);
    expect(event.data.course_name).toBe(COURSE_NAME);
    expect(event.data.spots_remaining).toBe('3');
    expect(event.data.game_id).toBe(GAME_ID);
  });

  test('spotsRemaining is coerced to a string', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onSpotOpened([PLAYER_1], GAME_ID, COURSE_NAME, GAME_DATE, 1);

    const event = routeNotification.mock.calls[0][0];
    expect(typeof event.data.spots_remaining).toBe('string');
    expect(event.data.spots_remaining).toBe('1');
  });

  test('returns array of { userId, result } for each player', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    routeNotification.mockResolvedValue({ result: 'sent' });

    const results = await onSpotOpened([PLAYER_1, PLAYER_2], GAME_ID, COURSE_NAME, GAME_DATE, 2);

    expect(results).toHaveLength(2);
    expect(results[0]).toHaveProperty('userId');
    expect(results[0]).toHaveProperty('result', 'sent');
  });

  test('single user: one routeNotification call', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onSpotOpened([PLAYER_1], GAME_ID, COURSE_NAME, GAME_DATE, 1);
    expect(routeNotification).toHaveBeenCalledTimes(1);
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onFriendRequestReceived
// ════════════════════════════════════════════════════════════════════════════

describe('onFriendRequestReceived', () => {

  const RECIPIENT_ID = 'user_recipient_123';
  const SENDER_ID    = 'user_sender_456';
  const SENDER_NAME  = 'Alice';
  const SENDER_AVATAR_URL = 'https://storage.example.com/avatar.png';

  test('calls routeNotification with friend_request_received eventType', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, SENDER_AVATAR_URL);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('friend_request_received');
  });

  test('sends to the correct recipient', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, SENDER_AVATAR_URL);

    const event = routeNotification.mock.calls[0][0];
    expect(event.recipientUserId).toBe(RECIPIENT_ID);
  });

  test('includes sender_name, sender_id, and actor_avatar_url in data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, SENDER_AVATAR_URL);

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.sender_name).toBe(SENDER_NAME);
    expect(event.data.sender_id).toBe(SENDER_ID);
    expect(event.data.actor_avatar_url).toBe(SENDER_AVATAR_URL);
  });

  test('generates unique sourceId for dedup: friend_request_{senderId}_{recipientId}', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, SENDER_AVATAR_URL);

    const event = routeNotification.mock.calls[0][0];
    expect(event.sourceId).toBe(`friend_request_${SENDER_ID}_${RECIPIENT_ID}`);
  });

  test('returns routeNotification result', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });

    const result = await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, SENDER_AVATAR_URL);

    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(1);
  });

  test('passes db parameter through to routeNotification', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    const mockDb = { collection: jest.fn() };

    await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, SENDER_AVATAR_URL, mockDb);

    expect(routeNotification).toHaveBeenCalledWith(
      expect.any(Object),
      mockDb,
    );
  });

  test('handles null avatar URL gracefully', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestReceived(RECIPIENT_ID, SENDER_ID, SENDER_NAME, null);

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.actor_avatar_url).toBeNull();
  });

});

// ════════════════════════════════════════════════════════════════════════════
// onFriendRequestAccepted
// ════════════════════════════════════════════════════════════════════════════

describe('onFriendRequestAccepted', () => {

  const REQUESTER_ID  = 'user_requester_123';
  const ACCEPTOR_ID   = 'user_acceptor_456';
  const ACCEPTOR_NAME = 'Bob';
  const ACCEPTOR_AVATAR_URL = 'https://storage.example.com/avatar-bob.png';

  test('calls routeNotification with friend_request_accepted eventType', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, ACCEPTOR_AVATAR_URL);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    const event = routeNotification.mock.calls[0][0];
    expect(event.eventType).toBe('friend_request_accepted');
  });

  test('sends to the original requester (not the acceptor)', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, ACCEPTOR_AVATAR_URL);

    const event = routeNotification.mock.calls[0][0];
    expect(event.recipientUserId).toBe(REQUESTER_ID);
  });

  test('includes acceptor_name, acceptor_id, and actor_avatar_url in data', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, ACCEPTOR_AVATAR_URL);

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.acceptor_name).toBe(ACCEPTOR_NAME);
    expect(event.data.acceptor_id).toBe(ACCEPTOR_ID);
    expect(event.data.actor_avatar_url).toBe(ACCEPTOR_AVATAR_URL);
  });

  test('generates unique sourceId for dedup: friend_accept_{acceptorId}_{requesterId}', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, ACCEPTOR_AVATAR_URL);

    const event = routeNotification.mock.calls[0][0];
    expect(event.sourceId).toBe(`friend_accept_${ACCEPTOR_ID}_${REQUESTER_ID}`);
  });

  test('returns routeNotification result', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });

    const result = await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, ACCEPTOR_AVATAR_URL);

    expect(result.result).toBe('sent');
    expect(result.sentCount).toBe(1);
  });

  test('passes db parameter through to routeNotification', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    const mockDb = { collection: jest.fn() };

    await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, ACCEPTOR_AVATAR_URL, mockDb);

    expect(routeNotification).toHaveBeenCalledWith(
      expect.any(Object),
      mockDb,
    );
  });

  test('handles null avatar URL gracefully', async () => {
    const { routeNotification } = require('../notifications/trust/router');
    await onFriendRequestAccepted(REQUESTER_ID, ACCEPTOR_ID, ACCEPTOR_NAME, null);

    const event = routeNotification.mock.calls[0][0];
    expect(event.data.actor_avatar_url).toBeNull();
  });

});
