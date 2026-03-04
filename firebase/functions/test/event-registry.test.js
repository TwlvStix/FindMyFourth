'use strict';

/**
 * Trust System Event Registry — Unit Tests
 *
 * Covers:
 *   - Enum values (snake_case convention, all 17 types, all priorities, all categories)
 *   - getEventConfig: valid types, unknown type error
 *   - getPriorityConfig: all 4 priorities, unknown priority error
 *   - PRIORITY_FCM_CONFIG: correct android/apns/interruption values
 *   - renderTemplate: all 17 event types (happy path + missing variable error)
 *   - reminderTemplate: host_checkin_due happy path + missing variable error
 *   - isReminder=true on event with no reminderTemplate → error
 *
 * Run: npx jest test/event-registry.test.js
 */

const {
  TrustEventType,
  NotificationPriority,
  TrustCategory,
  PRIORITY_FCM_CONFIG,
  getEventConfig,
  getPriorityConfig,
  renderTemplate,
} = require('../notifications/trust/event-registry');

// ── Enum value correctness ────────────────────────────────────────────────────

describe('TrustEventType enum', () => {
  test('all 28 values use snake_case', () => {
    const values = Object.values(TrustEventType);
    expect(values).toHaveLength(28); // 18 original + 5 join request + 5 streak events
    for (const v of values) {
      // snake_case: lowercase letters, digits, and underscores only
      expect(v).toMatch(/^[a-z][a-z0-9_]*$/);
    }
  });

  test('specific values match spec', () => {
    expect(TrustEventType.HOST_CHECKIN_DUE).toBe('host_checkin_due');
    expect(TrustEventType.PLAYER_RATE_DUE).toBe('player_rate_due');
    expect(TrustEventType.HOST_CHECKIN_FALLBACK).toBe('host_checkin_fallback');
    expect(TrustEventType.PLAYER_FALLBACK_CONFIRM).toBe('player_fallback_confirm');
    expect(TrustEventType.NO_SHOW_FLAGGED).toBe('no_show_flagged');
    expect(TrustEventType.DISPUTE_RESOLVED).toBe('dispute_resolved');
    expect(TrustEventType.STRIKE_ISSUED).toBe('strike_issued');
    expect(TrustEventType.COOLDOWN_STARTED).toBe('cooldown_started');
    expect(TrustEventType.RESTRICTION_STARTED).toBe('restriction_started');
    expect(TrustEventType.SUSPENSION_STARTED).toBe('suspension_started');
    expect(TrustEventType.RESTRICTION_ENDED).toBe('restriction_ended');
    expect(TrustEventType.BADGE_EARNED).toBe('badge_earned');
    expect(TrustEventType.BADGE_PROGRESS).toBe('badge_progress');
    expect(TrustEventType.GAME_SPOT_OPENED).toBe('game_spot_opened');
    expect(TrustEventType.GAME_CANCELLED).toBe('game_cancelled');
  });

  test('is frozen (immutable)', () => {
    expect(Object.isFrozen(TrustEventType)).toBe(true);
  });
});

describe('NotificationPriority enum', () => {
  test('contains CRITICAL, HIGH, DEFAULT, LOW', () => {
    expect(NotificationPriority.CRITICAL).toBe('CRITICAL');
    expect(NotificationPriority.HIGH).toBe('HIGH');
    expect(NotificationPriority.DEFAULT).toBe('DEFAULT');
    expect(NotificationPriority.LOW).toBe('LOW');
  });

  test('is frozen', () => {
    expect(Object.isFrozen(NotificationPriority)).toBe(true);
  });
});

describe('TrustCategory enum', () => {
  test('contains post_round, trust_alerts, badges, games, social, weekly_activity', () => {
    expect(TrustCategory.POST_ROUND).toBe('post_round');
    expect(TrustCategory.TRUST_ALERTS).toBe('trust_alerts');
    expect(TrustCategory.BADGES).toBe('badges');
    expect(TrustCategory.GAMES).toBe('games');
    expect(TrustCategory.SOCIAL).toBe('social');
    expect(TrustCategory.WEEKLY_ACTIVITY).toBe('weekly_activity');
  });

  test('is frozen', () => {
    expect(Object.isFrozen(TrustCategory)).toBe(true);
  });
});

// ── Priority FCM config ───────────────────────────────────────────────────────

describe('PRIORITY_FCM_CONFIG', () => {
  test('CRITICAL → high android, apns 10, time-sensitive interruption', () => {
    expect(PRIORITY_FCM_CONFIG[NotificationPriority.CRITICAL]).toEqual({
      androidPriority:   'high',
      apnsPriority:      '10',
      interruptionLevel: 'time-sensitive',
    });
  });

  test('HIGH → high android, apns 10, active interruption', () => {
    expect(PRIORITY_FCM_CONFIG[NotificationPriority.HIGH]).toEqual({
      androidPriority:   'high',
      apnsPriority:      '10',
      interruptionLevel: 'active',
    });
  });

  test('DEFAULT → normal android, apns 5, active interruption', () => {
    expect(PRIORITY_FCM_CONFIG[NotificationPriority.DEFAULT]).toEqual({
      androidPriority:   'normal',
      apnsPriority:      '5',
      interruptionLevel: 'active',
    });
  });

  test('LOW → normal android, apns 1, passive interruption', () => {
    expect(PRIORITY_FCM_CONFIG[NotificationPriority.LOW]).toEqual({
      androidPriority:   'normal',
      apnsPriority:      '1',
      interruptionLevel: 'passive',
    });
  });
});

// ── getEventConfig ────────────────────────────────────────────────────────────

describe('getEventConfig', () => {
  test('returns config for a valid event type', () => {
    const config = getEventConfig(TrustEventType.STRIKE_ISSUED);
    expect(config).toBeDefined();
    expect(config.priority).toBe(NotificationPriority.CRITICAL);
    expect(config.category).toBe(TrustCategory.TRUST_ALERTS);
    expect(config.androidChannelId).toBe('critical');
    expect(config.icon).toBe('warning_amber');
  });

  test('throws for an unknown event type', () => {
    expect(() => getEventConfig('not_a_real_event')).toThrow(
      /Unknown Trust event type/,
    );
  });

  test('every registered event type returns a config', () => {
    for (const type of Object.values(TrustEventType)) {
      expect(() => getEventConfig(type)).not.toThrow();
    }
  });
});

// ── getPriorityConfig ─────────────────────────────────────────────────────────

describe('getPriorityConfig', () => {
  test('returns config for each valid priority', () => {
    for (const p of Object.values(NotificationPriority)) {
      const cfg = getPriorityConfig(p);
      expect(cfg).toHaveProperty('androidPriority');
      expect(cfg).toHaveProperty('apnsPriority');
      expect(cfg).toHaveProperty('interruptionLevel');
    }
  });

  test('throws for an unknown priority', () => {
    expect(() => getPriorityConfig('ULTRA')).toThrow(/Unknown notification priority/);
  });
});

// ── renderTemplate — helper ───────────────────────────────────────────────────

/** Asserts that a rendered template contains the substituted values. */
function expectRendered(result, partialTitle, partialBody) {
  expect(result).toHaveProperty('title');
  expect(result).toHaveProperty('body');
  if (partialTitle) expect(result.title).toContain(partialTitle);
  if (partialBody)  expect(result.body).toContain(partialBody);
}

/** Asserts that renderTemplate throws mentioning the missing variable. */
function expectMissingVar(eventType, data, missingKey) {
  expect(() => renderTemplate(eventType, data)).toThrow(
    new RegExp(missingKey),
  );
}

// ── renderTemplate — post-round ───────────────────────────────────────────────

describe('renderTemplate: host_checkin_due', () => {
  const type = TrustEventType.HOST_CHECKIN_DUE;
  const full  = { course_name: 'Pebble Beach', game_id: 'g1' };

  test('primary template renders course_name', () => {
    const result = renderTemplate(type, full);
    expectRendered(result, null, 'Pebble Beach');
  });

  test('primary template throws when course_name missing', () => {
    expectMissingVar(type, {}, 'course_name');
  });

  test('reminder template renders course_name and hours_remaining', () => {
    const result = renderTemplate(type, { course_name: 'Augusta', hours_remaining: 4 }, true);
    expectRendered(result, 'Quick check-in needed', 'Augusta');
    expect(result.body).toContain('4h');
  });

  test('reminder template throws when hours_remaining missing', () => {
    expect(() => renderTemplate(type, { course_name: 'Augusta' }, true)).toThrow(
      /hours_remaining/,
    );
  });

  test('reminder template throws when course_name missing', () => {
    expect(() => renderTemplate(type, { hours_remaining: 2 }, true)).toThrow(
      /course_name/,
    );
  });
});

describe('renderTemplate: player_rate_due', () => {
  const type = TrustEventType.PLAYER_RATE_DUE;

  test('renders course_name', () => {
    const result = renderTemplate(type, { course_name: 'Torrey Pines' });
    expectRendered(result, 'Rate your round', 'Torrey Pines');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, {}, 'course_name');
  });

  test('throws when isReminder=true (no reminder template)', () => {
    expect(() => renderTemplate(type, { course_name: 'X' }, true)).toThrow(
      /No reminder template/,
    );
  });
});

describe('renderTemplate: host_checkin_fallback', () => {
  const type = TrustEventType.HOST_CHECKIN_FALLBACK;

  test('renders course_name', () => {
    const result = renderTemplate(type, { course_name: 'St Andrews' });
    expectRendered(result, 'Did you play today?', 'St Andrews');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, {}, 'course_name');
  });
});

describe('renderTemplate: player_fallback_confirm', () => {
  const type = TrustEventType.PLAYER_FALLBACK_CONFIRM;

  test('renders course_name and date', () => {
    const result = renderTemplate(type, { course_name: 'Bandon Dunes', date: 'June 10' });
    expectRendered(result, 'Did you play today?', 'Bandon Dunes');
    expect(result.body).toContain('June 10');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, { date: 'June 10' }, 'course_name');
  });

  test('throws when date missing', () => {
    expectMissingVar(type, { course_name: 'Bandon Dunes' }, 'date');
  });
});

// ── renderTemplate — trust & enforcement ──────────────────────────────────────

describe('renderTemplate: no_show_flagged', () => {
  const type = TrustEventType.NO_SHOW_FLAGGED;

  test('renders course_name and date', () => {
    const result = renderTemplate(type, { course_name: 'Whistling Straits', date: 'July 4' });
    expectRendered(result, 'Attendance question', 'Whistling Straits');
    expect(result.body).toContain('July 4');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, { date: 'July 4' }, 'course_name');
  });

  test('throws when date missing', () => {
    expectMissingVar(type, { course_name: 'X' }, 'date');
  });
});

describe('renderTemplate: dispute_resolved', () => {
  const type = TrustEventType.DISPUTE_RESOLVED;

  test('renders course_name and date', () => {
    const result = renderTemplate(type, { course_name: 'Oakmont', date: 'Aug 1' });
    expect(result.body).toContain('Oakmont');
    expect(result.body).toContain('Aug 1');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, { date: 'Aug 1' }, 'course_name');
  });

  test('throws when date missing', () => {
    expectMissingVar(type, { course_name: 'Oakmont' }, 'date');
  });
});

describe('renderTemplate: strike_issued', () => {
  const type = TrustEventType.STRIKE_ISSUED;

  test('renders reason', () => {
    const result = renderTemplate(type, { reason: 'no-show' });
    expectRendered(result, 'Reliability notice', 'no-show');
  });

  test('throws when reason missing', () => {
    expectMissingVar(type, {}, 'reason');
  });
});

describe('renderTemplate: cooldown_started', () => {
  const type = TrustEventType.COOLDOWN_STARTED;

  test('renders with no variables required', () => {
    const result = renderTemplate(type, {});
    expectRendered(result, '24-hour cooldown', '2 active strikes');
  });

  test('renders with extra data (ignored)', () => {
    // Extra keys in data should not cause errors
    const result = renderTemplate(type, { some_extra_key: 'x' });
    expect(result.title).toBe('24-hour cooldown');
  });
});

describe('renderTemplate: restriction_started', () => {
  const type = TrustEventType.RESTRICTION_STARTED;

  test('renders duration', () => {
    const result = renderTemplate(type, { duration: '7 days' });
    expectRendered(result, 'Account restricted', '7 days');
  });

  test('throws when duration missing', () => {
    expectMissingVar(type, {}, 'duration');
  });
});

describe('renderTemplate: suspension_started', () => {
  const type = TrustEventType.SUSPENSION_STARTED;

  test('renders with no variables required', () => {
    const result = renderTemplate(type, {});
    expectRendered(result, 'Account suspended', '5 business days');
  });
});

describe('renderTemplate: restriction_ended', () => {
  const type = TrustEventType.RESTRICTION_ENDED;

  test('renders with no variables required', () => {
    const result = renderTemplate(type, {});
    expectRendered(result, 'Welcome back', 'restriction has been lifted');
  });
});

// ── renderTemplate — badges ───────────────────────────────────────────────────

describe('renderTemplate: badge_earned', () => {
  const type = TrustEventType.BADGE_EARNED;
  const full  = { badge_name: 'Gold', rounds_count: 25, unique_players: 40 };

  test('renders badge_name, rounds_count, unique_players', () => {
    const result = renderTemplate(type, full);
    expectRendered(result, 'New badge earned', 'Gold');
    expect(result.body).toContain('25');
    expect(result.body).toContain('40');
  });

  test('throws when badge_name missing', () => {
    expectMissingVar(type, { rounds_count: 25, unique_players: 40 }, 'badge_name');
  });

  test('throws when rounds_count missing', () => {
    expectMissingVar(type, { badge_name: 'Gold', unique_players: 40 }, 'rounds_count');
  });

  test('throws when unique_players missing', () => {
    expectMissingVar(type, { badge_name: 'Gold', rounds_count: 25 }, 'unique_players');
  });
});

describe('renderTemplate: badge_progress', () => {
  const type = TrustEventType.BADGE_PROGRESS;

  test('renders rounds_remaining and next_badge_name', () => {
    const result = renderTemplate(type, { rounds_remaining: 3, next_badge_name: 'Platinum' });
    expectRendered(result, 'Almost there', '3');
    expect(result.body).toContain('Platinum');
  });

  test('throws when rounds_remaining missing', () => {
    expectMissingVar(type, { next_badge_name: 'Platinum' }, 'rounds_remaining');
  });

  test('throws when next_badge_name missing', () => {
    expectMissingVar(type, { rounds_remaining: 3 }, 'next_badge_name');
  });
});

// ── renderTemplate — games ────────────────────────────────────────────────────

describe('renderTemplate: game_spot_opened', () => {
  const type = TrustEventType.GAME_SPOT_OPENED;
  const full  = { game_date: 'Saturday', course_name: 'Chambers Bay', spots_remaining: 1 };

  test('renders game_date, course_name, spots_remaining', () => {
    const result = renderTemplate(type, full);
    expectRendered(result, 'Spot opened', 'Chambers Bay');
    expect(result.body).toContain('Saturday');
    expect(result.body).toContain('1');
  });

  test('throws when game_date missing', () => {
    expectMissingVar(type, { course_name: 'X', spots_remaining: 1 }, 'game_date');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, { game_date: 'Saturday', spots_remaining: 1 }, 'course_name');
  });

  test('throws when spots_remaining missing', () => {
    expectMissingVar(type, { game_date: 'Saturday', course_name: 'X' }, 'spots_remaining');
  });
});

describe('renderTemplate: game_cancelled', () => {
  const type = TrustEventType.GAME_CANCELLED;

  test('renders game_date and course_name', () => {
    const result = renderTemplate(type, { game_date: 'Sunday', course_name: 'Pinehurst' });
    expectRendered(result, 'Game cancelled', 'Pinehurst');
    expect(result.body).toContain('Sunday');
  });

  test('throws when game_date missing', () => {
    expectMissingVar(type, { course_name: 'Pinehurst' }, 'game_date');
  });

  test('throws when course_name missing', () => {
    expectMissingVar(type, { game_date: 'Sunday' }, 'course_name');
  });
});

// ── renderTemplate — weekly streaks ───────────────────────────────────────────

describe('renderTemplate: streak_weekend_nudge', () => {
  const type = TrustEventType.STREAK_WEEKEND_NUDGE;

  test('renders current_weeks', () => {
    const result = renderTemplate(type, { current_weeks: 5 });
    expectRendered(result, 'Keep your streak alive', '5-week streak');
  });

  test('throws when current_weeks missing', () => {
    expectMissingVar(type, {}, 'current_weeks');
  });
});

describe('renderTemplate: streak_freeze_unlocked', () => {
  const type = TrustEventType.STREAK_FREEZE_UNLOCKED;

  test('renders current_weeks', () => {
    const result = renderTemplate(type, { current_weeks: 4 });
    expectRendered(result, 'Freeze unlocked', '4 consecutive weeks');
  });

  test('throws when current_weeks missing', () => {
    expectMissingVar(type, {}, 'current_weeks');
  });
});

describe('renderTemplate: streak_freeze_prompt', () => {
  const type = TrustEventType.STREAK_FREEZE_PROMPT;

  test('renders current_weeks', () => {
    const result = renderTemplate(type, { current_weeks: 7 });
    expectRendered(result, 'Use your freeze?', '7-week streak');
  });

  test('throws when current_weeks missing', () => {
    expectMissingVar(type, {}, 'current_weeks');
  });
});

describe('renderTemplate: streak_milestone_reached', () => {
  const type = TrustEventType.STREAK_MILESTONE_REACHED;

  test('renders milestone and current_weeks', () => {
    const result = renderTemplate(type, { milestone: 8, current_weeks: 8 });
    expectRendered(result, '8-week streak!', '8 consecutive weeks');
  });

  test('throws when milestone missing', () => {
    expectMissingVar(type, { current_weeks: 8 }, 'milestone');
  });

  test('throws when current_weeks missing', () => {
    expectMissingVar(type, { milestone: 8 }, 'current_weeks');
  });
});

describe('renderTemplate: streak_broken', () => {
  const type = TrustEventType.STREAK_BROKEN;

  test('renders previous_weeks', () => {
    const result = renderTemplate(type, { previous_weeks: 6 });
    expectRendered(result, 'Streak ended', '6-week streak');
  });

  test('throws when previous_weeks missing', () => {
    expectMissingVar(type, {}, 'previous_weeks');
  });
});

// ── renderTemplate — edge cases ───────────────────────────────────────────────

describe('renderTemplate edge cases', () => {
  test('numeric values are coerced to strings', () => {
    const result = renderTemplate(TrustEventType.BADGE_PROGRESS, {
      rounds_remaining: 0,
      next_badge_name: 'Diamond',
    });
    expect(result.body).toContain('0');
  });

  test('throws a descriptive error listing ALL missing variables', () => {
    // badge_earned needs badge_name, rounds_count, unique_players
    let errorMessage = '';
    try {
      renderTemplate(TrustEventType.BADGE_EARNED, {});
    } catch (e) {
      errorMessage = e.message;
    }
    expect(errorMessage).toMatch(/badge_name/);
    expect(errorMessage).toMatch(/rounds_count/);
    expect(errorMessage).toMatch(/unique_players/);
  });

  test('throws for completely unknown event type', () => {
    expect(() => renderTemplate('ghost_type', {})).toThrow(/Unknown Trust event type/);
  });

  test('null value for a key is treated as missing', () => {
    expect(() =>
      renderTemplate(TrustEventType.STRIKE_ISSUED, { reason: null }),
    ).toThrow(/reason/);
  });
});

// ── Registry completeness ─────────────────────────────────────────────────────

describe('registry completeness', () => {
  test('every event has required config fields', () => {
    for (const type of Object.values(TrustEventType)) {
      const config = getEventConfig(type);
      expect(config).toHaveProperty('priority');
      expect(config).toHaveProperty('category');
      expect(config).toHaveProperty('maxDeliveries');
      expect(config).toHaveProperty('timing');
      expect(config).toHaveProperty('template');
      expect(config).toHaveProperty('template.title');
      expect(config).toHaveProperty('template.body');
      expect(config).toHaveProperty('deepLink');
      expect(config).toHaveProperty('threadId');
      expect(config).toHaveProperty('androidChannelId');
      expect(config).toHaveProperty('icon');
    }
  });

  test('maxDeliveries is 1 or 2 for every event', () => {
    for (const type of Object.values(TrustEventType)) {
      const { maxDeliveries } = getEventConfig(type);
      expect([1, 2]).toContain(maxDeliveries);
    }
  });

  test('timing is "immediate" or "scheduled" for every event', () => {
    for (const type of Object.values(TrustEventType)) {
      const { timing } = getEventConfig(type);
      expect(['immediate', 'scheduled']).toContain(timing);
    }
  });

  test('host_checkin_due is the only event with a reminderTemplate', () => {
    for (const type of Object.values(TrustEventType)) {
      const config = getEventConfig(type);
      if (type === TrustEventType.HOST_CHECKIN_DUE) {
        expect(config.reminderTemplate).toBeDefined();
      } else {
        expect(config.reminderTemplate).toBeUndefined();
      }
    }
  });

  test('host_checkin_due has maxDeliveries of 2', () => {
    expect(getEventConfig(TrustEventType.HOST_CHECKIN_DUE).maxDeliveries).toBe(2);
  });

  test('androidChannelId is one of the four valid values', () => {
    const valid = new Set(['critical', 'important', 'default', 'updates']);
    for (const type of Object.values(TrustEventType)) {
      expect(valid.has(getEventConfig(type).androidChannelId)).toBe(true);
    }
  });

  test('category values are all valid TrustCategory values', () => {
    const validCategories = new Set(Object.values(TrustCategory));
    for (const type of Object.values(TrustEventType)) {
      expect(validCategories.has(getEventConfig(type).category)).toBe(true);
    }
  });

  test('priority values are all valid NotificationPriority values', () => {
    const validPriorities = new Set(Object.values(NotificationPriority));
    for (const type of Object.values(TrustEventType)) {
      expect(validPriorities.has(getEventConfig(type).priority)).toBe(true);
    }
  });
});
