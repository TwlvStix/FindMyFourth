'use strict';

/**
 * Game Alerts — Unit Tests
 *
 * Tests for gender eligibility filtering in game notifications.
 *
 * Run: npx jest test/game_alerts.test.js --verbose
 */

// ── Mock: firebase-admin ──────────────────────────────────────────────────────
// Required because game_alerts.js imports it at the top level.

jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(),
  })),
  initializeApp: jest.fn(),
}));

// ── Mock: firebase-functions ──────────────────────────────────────────────────

jest.mock('firebase-functions', () => ({
  region: jest.fn(() => ({
    runWith: jest.fn(() => ({
      firestore: {
        document: jest.fn(() => ({
          onCreate: jest.fn(),
        })),
      },
    })),
  })),
}));

// ── Import module under test ──────────────────────────────────────────────────

const {
  isUserEligibleByGender,
  doesAlertSubMatchGame,
  isWithinQuietHours,
  isActiveDay,
  computeReleaseAt,
} = require('../game_alerts');

afterEach(() => {
  jest.useRealTimers();
});

// ── Tests: isUserEligibleByGender ─────────────────────────────────────────────

describe('isUserEligibleByGender', () => {
  describe('open_to_all games', () => {
    it('allows Male users', () => {
      expect(isUserEligibleByGender('Male', 'open_to_all')).toBe(true);
    });

    it('allows Female users', () => {
      expect(isUserEligibleByGender('Female', 'open_to_all')).toBe(true);
    });

    it('allows users with null gender', () => {
      expect(isUserEligibleByGender(null, 'open_to_all')).toBe(true);
    });

    it('allows users with undefined gender', () => {
      expect(isUserEligibleByGender(undefined, 'open_to_all')).toBe(true);
    });
  });

  describe('games with no eligibility set (defaults to open_to_all)', () => {
    it('allows Male users when eligibility is null', () => {
      expect(isUserEligibleByGender('Male', null)).toBe(true);
    });

    it('allows Female users when eligibility is null', () => {
      expect(isUserEligibleByGender('Female', null)).toBe(true);
    });

    it('allows Male users when eligibility is undefined', () => {
      expect(isUserEligibleByGender('Male', undefined)).toBe(true);
    });
  });

  describe('women_only games', () => {
    it('allows Female users', () => {
      expect(isUserEligibleByGender('Female', 'women_only')).toBe(true);
    });

    it('blocks Male users', () => {
      expect(isUserEligibleByGender('Male', 'women_only')).toBe(false);
    });

    it('blocks users with null gender', () => {
      expect(isUserEligibleByGender(null, 'women_only')).toBe(false);
    });

    it('blocks users with empty string gender', () => {
      expect(isUserEligibleByGender('', 'women_only')).toBe(false);
    });
  });

  describe('men_only games', () => {
    it('allows Male users', () => {
      expect(isUserEligibleByGender('Male', 'men_only')).toBe(true);
    });

    it('blocks Female users', () => {
      expect(isUserEligibleByGender('Female', 'men_only')).toBe(false);
    });

    it('blocks users with null gender', () => {
      expect(isUserEligibleByGender(null, 'men_only')).toBe(false);
    });

    it('blocks users with empty string gender', () => {
      expect(isUserEligibleByGender('', 'men_only')).toBe(false);
    });
  });

  describe('unknown eligibility values', () => {
    it('defaults to allowing for unknown eligibility value', () => {
      expect(isUserEligibleByGender('Male', 'some_unknown_value')).toBe(true);
      expect(isUserEligibleByGender('Female', 'some_unknown_value')).toBe(true);
    });
  });
});

// ── Tests: doesAlertSubMatchGame (existing function, basic coverage) ──────────

describe('doesAlertSubMatchGame', () => {
  const baseSubscription = {
    enabled: true,
    gameVibes: [],
    stakes: [],
    formats: [],
    handicapUses: [],
    courses: [],
    special: { games: false, twoVTwo: false, discount: false },
  };

  const baseGame = {
    rules_setting: 'Casual',
    style_game: 'No Money',
    game_type: 'Stroke Play',
    scoring: 'Net',
    has_side_games: false,
    is_2v2: false,
    member_discount: 'No',
    player_eligibility: 'open_to_all',
  };

  it('matches when subscription is enabled with no filters (match-all)', () => {
    expect(doesAlertSubMatchGame(baseSubscription, baseGame)).toBe(true);
  });

  it('does not match when subscription is disabled', () => {
    const disabled = { ...baseSubscription, enabled: false };
    expect(doesAlertSubMatchGame(disabled, baseGame)).toBe(false);
  });

  it('matches when vibe filter matches game', () => {
    const sub = { ...baseSubscription, gameVibes: ['Casual'] };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(true);
  });

  it('does not match when vibe filter does not match game', () => {
    const sub = { ...baseSubscription, gameVibes: ['Competitive'] };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(false);
  });

  it('matches when stakes filter matches game', () => {
    const sub = { ...baseSubscription, stakes: ['No Money', 'Low Stakes'] };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(true);
  });

  it('does not match when stakes filter does not match game', () => {
    const sub = { ...baseSubscription, stakes: ['High Stakes'] };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(false);
  });

  it('matches when special.games is enabled and game has side games', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, games: true },
    };
    const game = { ...baseGame, has_side_games: true };
    expect(doesAlertSubMatchGame(sub, game)).toBe(true);
  });

  it('does not match when special.games is enabled and game has no side games', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, games: true },
    };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(false);
  });

  it('matches when special.twoVTwo is enabled and game is 2v2', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, twoVTwo: true },
    };
    const game = { ...baseGame, is_2v2: true };
    expect(doesAlertSubMatchGame(sub, game)).toBe(true);
  });

  it('does not match when special.twoVTwo is enabled and game is not 2v2', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, twoVTwo: true },
    };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(false);
  });

  it('matches when special.discount is enabled and member discount is yes', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, discount: true },
    };
    const game = { ...baseGame, member_discount: 'Yes' };
    expect(doesAlertSubMatchGame(sub, game)).toBe(true);
  });

  it('matches when special.discount is enabled and member discount is case-insensitive yes', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, discount: true },
    };
    const game = { ...baseGame, member_discount: '  yEs  ' };
    expect(doesAlertSubMatchGame(sub, game)).toBe(true);
  });

  it('does not match when special.discount is enabled and member discount is no', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, discount: true },
    };
    expect(doesAlertSubMatchGame(sub, baseGame)).toBe(false);
  });

  it('does not match discount for legacy truthy non-contract values', () => {
    const sub = {
      ...baseSubscription,
      special: { ...baseSubscription.special, discount: true },
    };

    expect(doesAlertSubMatchGame(sub, { ...baseGame, member_discount: true })).toBe(false);
    expect(doesAlertSubMatchGame(sub, { ...baseGame, member_discount: 1 })).toBe(false);
    expect(doesAlertSubMatchGame(sub, { ...baseGame, member_discount: 'true' })).toBe(false);
    expect(doesAlertSubMatchGame(sub, { ...baseGame, member_discount: '1' })).toBe(false);
  });

  it('requires all enabled special filters to pass', () => {
    const sub = {
      ...baseSubscription,
      special: { games: true, twoVTwo: true, discount: true },
    };

    const fullMatchGame = {
      ...baseGame,
      has_side_games: true,
      is_2v2: true,
      member_discount: 'Yes',
    };
    expect(doesAlertSubMatchGame(sub, fullMatchGame)).toBe(true);

    const missingOne = { ...fullMatchGame, is_2v2: false };
    expect(doesAlertSubMatchGame(sub, missingOne)).toBe(false);
  });
});

describe('isActiveDay', () => {
  it('defaults to true when activeDays is missing or empty', () => {
    expect(isActiveDay()).toBe(true);
    expect(isActiveDay([])).toBe(true);
    expect(isActiveDay(null)).toBe(true);
  });

  it('maps Vancouver weekday to ISO day', () => {
    jest.useFakeTimers();
    // Monday in Vancouver
    jest.setSystemTime(new Date('2026-02-16T20:00:00Z'));

    expect(isActiveDay([1])).toBe(true);
    expect(isActiveDay([7])).toBe(false);
  });
});

describe('isWithinQuietHours', () => {
  it('22:00-07:00 at Vancouver 23:30 is in quiet hours', () => {
    expect(isWithinQuietHours('22:00', '07:00', '23:30')).toBe(true);
  });

  it('22:00-07:00 at Vancouver 08:00 is outside quiet hours', () => {
    expect(isWithinQuietHours('22:00', '07:00', '08:00')).toBe(false);
  });
});

describe('computeReleaseAt', () => {
  it('schedules next-day release for 07:00 Vancouver when current Vancouver time is 23:00', () => {
    jest.useFakeTimers();
    // 23:00 Vancouver on Feb 18, 2026
    jest.setSystemTime(new Date('2026-02-19T07:00:00Z'));

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-02-19T15:00:00.000Z');
  });

  it('handles spring-forward DST day using PDT offset', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-03-08T12:00:00Z')); // 04:00 Vancouver

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-03-08T14:00:00.000Z');
  });

  it('handles fall-back DST day using PST offset', () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-11-01T11:00:00Z')); // 03:00 Vancouver

    const release = computeReleaseAt('07:00');

    expect(release.toISOString()).toBe('2026-11-01T15:00:00.000Z');
  });
});
