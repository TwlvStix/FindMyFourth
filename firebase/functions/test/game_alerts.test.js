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

jest.mock('firebase-functions/v1', () => ({
  region: jest.fn(() => ({
    runWith: jest.fn(() => ({
      firestore: {
        document: jest.fn(() => ({
          onCreate: jest.fn(),
          onUpdate: jest.fn(),
        })),
      },
    })),
  })),
}));

// ── Import module under test ──────────────────────────────────────────────────

const {
  normalizeGender,
  normalizePlayerEligibility,
  isUserEligibleByGender,
  doesAlertSubMatchGame,
  isWithinQuietHours,
  isActiveDay,
  computeReleaseAt,
  computeSpots,
  formatGameDate,
  buildGameNotificationContent,
  buildFriendGameNotificationContent,
  buildLastSpotBody,
} = require('../game_alerts');

afterEach(() => {
  jest.useRealTimers();
});

// ── Tests: normalizeGender ────────────────────────────────────────────────────

describe('normalizeGender', () => {
  describe('male aliases', () => {
    it('normalizes "Male" to "male"', () => {
      expect(normalizeGender('Male')).toBe('male');
    });

    it('normalizes "male" to "male"', () => {
      expect(normalizeGender('male')).toBe('male');
    });

    it('normalizes "man" to "male"', () => {
      expect(normalizeGender('man')).toBe('male');
    });

    it('normalizes "Man" to "male"', () => {
      expect(normalizeGender('Man')).toBe('male');
    });

    it('normalizes "M" to "male"', () => {
      expect(normalizeGender('M')).toBe('male');
    });

    it('normalizes "m" to "male"', () => {
      expect(normalizeGender('m')).toBe('male');
    });

    it('normalizes " male " (with whitespace) to "male"', () => {
      expect(normalizeGender(' male ')).toBe('male');
    });
  });

  describe('female aliases', () => {
    it('normalizes "Female" to "female"', () => {
      expect(normalizeGender('Female')).toBe('female');
    });

    it('normalizes "female" to "female"', () => {
      expect(normalizeGender('female')).toBe('female');
    });

    it('normalizes "woman" to "female"', () => {
      expect(normalizeGender('woman')).toBe('female');
    });

    it('normalizes "Woman" to "female"', () => {
      expect(normalizeGender('Woman')).toBe('female');
    });

    it('normalizes "F" to "female"', () => {
      expect(normalizeGender('F')).toBe('female');
    });

    it('normalizes "f" to "female"', () => {
      expect(normalizeGender('f')).toBe('female');
    });

    it('normalizes " female " (with whitespace) to "female"', () => {
      expect(normalizeGender(' female ')).toBe('female');
    });
  });

  describe('invalid/null values', () => {
    it('returns null for null input', () => {
      expect(normalizeGender(null)).toBeNull();
    });

    it('returns null for undefined input', () => {
      expect(normalizeGender(undefined)).toBeNull();
    });

    it('returns null for empty string', () => {
      expect(normalizeGender('')).toBeNull();
    });

    it('returns null for unknown value', () => {
      expect(normalizeGender('other')).toBeNull();
    });

    it('returns null for non-string input', () => {
      expect(normalizeGender(123)).toBeNull();
    });
  });
});

// ── Tests: normalizePlayerEligibility ─────────────────────────────────────────

describe('normalizePlayerEligibility', () => {
  describe('open_to_all aliases', () => {
    it('normalizes "open_to_all" to "open_to_all"', () => {
      expect(normalizePlayerEligibility('open_to_all')).toBe('open_to_all');
    });

    it('normalizes "Open To All" to "open_to_all"', () => {
      expect(normalizePlayerEligibility('Open To All')).toBe('open_to_all');
    });

    it('normalizes "openToAll" to "open_to_all"', () => {
      expect(normalizePlayerEligibility('openToAll')).toBe('open_to_all');
    });

    it('normalizes "open-to-all" to "open_to_all"', () => {
      expect(normalizePlayerEligibility('open-to-all')).toBe('open_to_all');
    });

    it('normalizes "open" to "open_to_all"', () => {
      expect(normalizePlayerEligibility('open')).toBe('open_to_all');
    });

    it('normalizes "all" to "open_to_all"', () => {
      expect(normalizePlayerEligibility('all')).toBe('open_to_all');
    });
  });

  describe('women_only aliases', () => {
    it('normalizes "women_only" to "women_only"', () => {
      expect(normalizePlayerEligibility('women_only')).toBe('women_only');
    });

    it('normalizes "Women Only" to "women_only"', () => {
      expect(normalizePlayerEligibility('Women Only')).toBe('women_only');
    });

    it('normalizes "womenOnly" to "women_only"', () => {
      expect(normalizePlayerEligibility('womenOnly')).toBe('women_only');
    });

    it('normalizes "women only" to "women_only"', () => {
      expect(normalizePlayerEligibility('women only')).toBe('women_only');
    });

    it('normalizes "female_only" to "women_only"', () => {
      expect(normalizePlayerEligibility('female_only')).toBe('women_only');
    });

    it('normalizes "femaleOnly" to "women_only"', () => {
      expect(normalizePlayerEligibility('femaleOnly')).toBe('women_only');
    });

    it('normalizes "ladies" to "women_only"', () => {
      expect(normalizePlayerEligibility('ladies')).toBe('women_only');
    });

    it('normalizes "Ladies Only" to "women_only"', () => {
      expect(normalizePlayerEligibility('Ladies Only')).toBe('women_only');
    });
  });

  describe('men_only aliases', () => {
    it('normalizes "men_only" to "men_only"', () => {
      expect(normalizePlayerEligibility('men_only')).toBe('men_only');
    });

    it('normalizes "Men Only" to "men_only"', () => {
      expect(normalizePlayerEligibility('Men Only')).toBe('men_only');
    });

    it('normalizes "menOnly" to "men_only"', () => {
      expect(normalizePlayerEligibility('menOnly')).toBe('men_only');
    });

    it('normalizes "men only" to "men_only"', () => {
      expect(normalizePlayerEligibility('men only')).toBe('men_only');
    });

    it('normalizes "male_only" to "men_only"', () => {
      expect(normalizePlayerEligibility('male_only')).toBe('men_only');
    });

    it('normalizes "maleOnly" to "men_only"', () => {
      expect(normalizePlayerEligibility('maleOnly')).toBe('men_only');
    });

    it('normalizes "gentlemen" to "men_only"', () => {
      expect(normalizePlayerEligibility('gentlemen')).toBe('men_only');
    });
  });

  describe('invalid/null values', () => {
    it('returns null for null input', () => {
      expect(normalizePlayerEligibility(null)).toBeNull();
    });

    it('returns null for undefined input', () => {
      expect(normalizePlayerEligibility(undefined)).toBeNull();
    });

    it('returns null for empty string', () => {
      expect(normalizePlayerEligibility('')).toBeNull();
    });

    it('returns null for unknown value', () => {
      expect(normalizePlayerEligibility('some_unknown_eligibility')).toBeNull();
    });

    it('returns null for non-string input', () => {
      expect(normalizePlayerEligibility(123)).toBeNull();
    });
  });
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

  // ── Tests with legacy alias values ──────────────────────────────────────────

  describe('women_only with alias eligibility values', () => {
    it('blocks Male users for "Women Only" (Title Case)', () => {
      expect(isUserEligibleByGender('Male', 'Women Only')).toBe(false);
    });

    it('allows Female users for "Women Only" (Title Case)', () => {
      expect(isUserEligibleByGender('Female', 'Women Only')).toBe(true);
    });

    it('blocks Male users for "womenOnly" (camelCase)', () => {
      expect(isUserEligibleByGender('Male', 'womenOnly')).toBe(false);
    });

    it('allows Female users for "womenOnly" (camelCase)', () => {
      expect(isUserEligibleByGender('Female', 'womenOnly')).toBe(true);
    });

    it('blocks Male users for "women only" (space-separated)', () => {
      expect(isUserEligibleByGender('Male', 'women only')).toBe(false);
    });

    it('blocks Male users for "ladies" alias', () => {
      expect(isUserEligibleByGender('Male', 'ladies')).toBe(false);
    });

    it('allows Female users for "ladies" alias', () => {
      expect(isUserEligibleByGender('Female', 'ladies')).toBe(true);
    });
  });

  describe('men_only with alias eligibility values', () => {
    it('blocks Female users for "Men Only" (Title Case)', () => {
      expect(isUserEligibleByGender('Female', 'Men Only')).toBe(false);
    });

    it('allows Male users for "Men Only" (Title Case)', () => {
      expect(isUserEligibleByGender('Male', 'Men Only')).toBe(true);
    });

    it('blocks Female users for "menOnly" (camelCase)', () => {
      expect(isUserEligibleByGender('Female', 'menOnly')).toBe(false);
    });

    it('allows Male users for "menOnly" (camelCase)', () => {
      expect(isUserEligibleByGender('Male', 'menOnly')).toBe(true);
    });

    it('blocks Female users for "gentlemen" alias', () => {
      expect(isUserEligibleByGender('Female', 'gentlemen')).toBe(false);
    });

    it('allows Male users for "gentlemen" alias', () => {
      expect(isUserEligibleByGender('Male', 'gentlemen')).toBe(true);
    });
  });

  describe('gender alias handling', () => {
    it('allows "man" gender for men_only games', () => {
      expect(isUserEligibleByGender('man', 'men_only')).toBe(true);
    });

    it('blocks "man" gender for women_only games', () => {
      expect(isUserEligibleByGender('man', 'women_only')).toBe(false);
    });

    it('allows "woman" gender for women_only games', () => {
      expect(isUserEligibleByGender('woman', 'women_only')).toBe(true);
    });

    it('blocks "woman" gender for men_only games', () => {
      expect(isUserEligibleByGender('woman', 'men_only')).toBe(false);
    });

    it('allows "M" gender for men_only games', () => {
      expect(isUserEligibleByGender('M', 'men_only')).toBe(true);
    });

    it('allows "F" gender for women_only games', () => {
      expect(isUserEligibleByGender('F', 'women_only')).toBe(true);
    });
  });

  // ── REGRESSION TEST: Reported issue ─────────────────────────────────────────

  describe('REGRESSION: Male user notified for women-only game', () => {
    it('blocks Male user from Women Only game (the reported bug scenario)', () => {
      // This is the exact scenario reported:
      // - User gender: "Male"
      // - Game eligibility stored as "Women Only" (Title Case legacy format)
      expect(isUserEligibleByGender('Male', 'Women Only')).toBe(false);
    });

    it('blocks male user (lowercase) from womenOnly game (camelCase)', () => {
      expect(isUserEligibleByGender('male', 'womenOnly')).toBe(false);
    });

    it('blocks user with unknown gender from restricted games', () => {
      expect(isUserEligibleByGender(null, 'women_only')).toBe(false);
      expect(isUserEligibleByGender('', 'Women Only')).toBe(false);
      expect(isUserEligibleByGender(undefined, 'men_only')).toBe(false);
    });

    it('allows any gender for open eligibility aliases', () => {
      expect(isUserEligibleByGender('Male', 'Open To All')).toBe(true);
      expect(isUserEligibleByGender('Female', 'openToAll')).toBe(true);
      expect(isUserEligibleByGender('Male', 'open')).toBe(true);
      expect(isUserEligibleByGender(null, 'all')).toBe(true);
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

  // ── REGRESSION: Reported scenario ──────────────────────────────────────────
  // User set alerts to "Low Stakes" + "High Stakes", another user created a
  // "Low Stakes" game. The subscription should match.

  it('matches Low Stakes game when subscription has Low Stakes + High Stakes', () => {
    const sub = {
      ...baseSubscription,
      stakes: ['Low Stakes', 'High Stakes'],
    };
    const game = { ...baseGame, style_game: 'Low Stakes' };
    expect(doesAlertSubMatchGame(sub, game)).toBe(true);
  });

  it('matches High Stakes game when subscription has Low Stakes + High Stakes', () => {
    const sub = {
      ...baseSubscription,
      stakes: ['Low Stakes', 'High Stakes'],
    };
    const game = { ...baseGame, style_game: 'High Stakes' };
    expect(doesAlertSubMatchGame(sub, game)).toBe(true);
  });

  it('does not match No Money game when subscription has only Low Stakes + High Stakes', () => {
    const sub = {
      ...baseSubscription,
      stakes: ['Low Stakes', 'High Stakes'],
    };
    const game = { ...baseGame, style_game: 'No Money' };
    expect(doesAlertSubMatchGame(sub, game)).toBe(false);
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

// ── Tests: buildFriendGameNotificationContent ─────────────────────────────────

describe('buildFriendGameNotificationContent', () => {
  const makeTimestamp = (isoStr) => ({
    toDate: () => new Date(isoStr),
  });

  it('builds content with all fields present', () => {
    const gameData = {
      course_play: 'Shaughnessy Golf Club',
      date: makeTimestamp('2026-03-14T21:00:00Z'),
      max_players: 4,
      joined_players: ['uid1'],
      guest_count: 0,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Ryan');

    expect(result.title).toBe('Ryan posted a game');
    expect(result.body).toContain('Shaughnessy Golf Club');
    expect(result.body).toContain('3 spots left');
  });

  it('calculates spots correctly: 4 players, 1 joined, 0 guests = 3 spots', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: ['uid1'],
      guest_count: 0,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('3 spots left');
  });

  it('shows full capacity when joined_players is empty', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: [],
      guest_count: 0,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('4 spots left');
  });

  it('shows full capacity when joined_players is missing', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('4 spots left');
  });

  it('omits date when date field is missing', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: ['uid1', 'uid2'],
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.title).toBe('Alex posted a game');
    // Body should only have course and spots, separated by middle dot
    expect(result.body).toBe('Test Course \u00B7 2 spots left');
  });

  it('uses "A friend" when creator name is missing', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
    };
    const result = buildFriendGameNotificationContent(gameData, null);

    expect(result.title).toBe('A friend posted a game');
  });

  it('uses "A friend" when creator name is empty string', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
    };
    const result = buildFriendGameNotificationContent(gameData, '');

    expect(result.title).toBe('A friend posted a game');
  });

  it('clamps negative spots to 0', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 2,
      joined_players: ['uid1', 'uid2', 'uid3'],
      guest_count: 1,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('0 spots left');
  });

  it('shows singular "1 spot left" when exactly one spot remains', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: ['uid1', 'uid2'],
      guest_count: 1,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('1 spot left');
    expect(result.body).not.toContain('spots left');
  });

  it('accounts for guest_count in spots calculation', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: ['uid1'],
      guest_count: 2,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('1 spot left');
  });

  it('defaults to 4 spots when max_players and num_players are both missing', () => {
    const gameData = {
      course_play: 'Test Course',
      joined_players: ['uid1'],
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.body).toContain('3 spots left');
  });

  it('uses spots-aware title when exactly 1 spot remains', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: ['uid1', 'uid2'],
      guest_count: 1,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.title).toBe('Alex posted a game \u2014 last spot!');
    expect(result.body).toContain('1 spot left');
  });

  it('uses standard title when more than 1 spot remains', () => {
    const gameData = {
      course_play: 'Test Course',
      max_players: 4,
      joined_players: ['uid1'],
      guest_count: 0,
    };
    const result = buildFriendGameNotificationContent(gameData, 'Alex');

    expect(result.title).toBe('Alex posted a game');
  });
});

// ── Tests: computeSpots ───────────────────────────────────────────────────────

describe('computeSpots', () => {
  it('computes spots: 4 max_players, 1 joined, 0 guests = 3', () => {
    expect(computeSpots({ max_players: 4, joined_players: ['uid1'], guest_count: 0 })).toBe(3);
  });

  it('computes spots: 4 max_players, 2 joined, 1 guest = 1', () => {
    expect(computeSpots({ max_players: 4, joined_players: ['uid1', 'uid2'], guest_count: 1 })).toBe(1);
  });

  it('clamps to 0 when over capacity', () => {
    expect(computeSpots({ max_players: 2, joined_players: ['a', 'b', 'c'], guest_count: 1 })).toBe(0);
  });

  it('falls back to num_players when max_players is absent', () => {
    expect(computeSpots({ num_players: 4, joined_players: ['uid1'] })).toBe(3);
  });

  it('defaults to 4 when both max_players and num_players are absent', () => {
    expect(computeSpots({ joined_players: ['uid1'] })).toBe(3);
  });

  it('prefers max_players over num_players', () => {
    expect(computeSpots({ max_players: 4, num_players: 1, joined_players: ['uid1'] })).toBe(3);
  });

  it('defaults joined_players to empty array', () => {
    expect(computeSpots({ max_players: 4 })).toBe(4);
  });

  it('defaults guest_count to 0', () => {
    expect(computeSpots({ max_players: 4, joined_players: ['uid1'] })).toBe(3);
  });

  it('handles all defaults (empty object)', () => {
    expect(computeSpots({})).toBe(4);
  });
});

// ── Tests: formatGameDate ─────────────────────────────────────────────────────

describe('formatGameDate', () => {
  const makeTimestamp = (isoStr) => ({
    toDate: () => new Date(isoStr),
  });

  it('formats a valid Firestore timestamp', () => {
    const gameData = { date: makeTimestamp('2026-03-14T21:00:00Z') };
    const result = formatGameDate(gameData);
    expect(result).toBeTruthy();
    expect(result).toContain('Mar');
    expect(result).toContain('14');
  });

  it('returns null when date is missing', () => {
    expect(formatGameDate({})).toBeNull();
  });

  it('returns null when date has no toDate method', () => {
    expect(formatGameDate({ date: '2026-03-14' })).toBeNull();
  });
});

// ── Tests: buildGameNotificationContent ───────────────────────────────────────

describe('buildGameNotificationContent', () => {
  const makeTimestamp = (isoStr) => ({
    toDate: () => new Date(isoStr),
  });

  it('uses course in title when available', () => {
    const result = buildGameNotificationContent({
      course_play: 'Tower Ranch',
      max_players: 4,
      joined_players: [],
    });
    expect(result.title).toBe('New game at Tower Ranch');
  });

  it('falls back to generic title when no course', () => {
    const result = buildGameNotificationContent({
      max_players: 4,
      joined_players: [],
    });
    expect(result.title).toBe('New game posted');
  });

  it('uses last-spot title when exactly 1 spot with course', () => {
    const result = buildGameNotificationContent({
      course_play: 'Tower Ranch',
      max_players: 4,
      joined_players: ['a', 'b'],
      guest_count: 1,
    });
    expect(result.title).toBe('Last spot at Tower Ranch');
  });

  it('uses last-spot title without course', () => {
    const result = buildGameNotificationContent({
      max_players: 4,
      joined_players: ['a', 'b'],
      guest_count: 1,
    });
    expect(result.title).toBe('Last spot available');
  });

  it('includes stakes in body', () => {
    const result = buildGameNotificationContent({
      course_play: 'Tower Ranch',
      style_game: 'Low Stakes',
      max_players: 4,
      joined_players: ['a'],
    });
    expect(result.body).toContain('Low Stakes');
    expect(result.body).toContain('3 spots left');
  });

  it('includes date in body when available', () => {
    const result = buildGameNotificationContent({
      course_play: 'Tower Ranch',
      date: makeTimestamp('2026-03-14T21:00:00Z'),
      max_players: 4,
      joined_players: [],
    });
    expect(result.body).toContain('Mar');
  });

  it('shows singular spot label', () => {
    const result = buildGameNotificationContent({
      max_players: 4,
      joined_players: ['a', 'b'],
      guest_count: 1,
    });
    expect(result.body).toContain('1 spot left');
    expect(result.body).not.toContain('spots left');
  });

  it('body parts separated by middle dot', () => {
    const result = buildGameNotificationContent({
      style_game: 'No Money',
      max_players: 4,
      joined_players: [],
    });
    expect(result.body).toContain('\u00B7');
  });
});

// ── Tests: buildLastSpotBody ──────────────────────────────────────────────────

describe('buildLastSpotBody', () => {
  const makeTimestamp = (isoStr) => ({
    toDate: () => new Date(isoStr),
  });

  it('includes all parts when course and date present', () => {
    const result = buildLastSpotBody({
      course_play: 'Tower Ranch',
      date: makeTimestamp('2026-03-14T21:00:00Z'),
    });
    expect(result).toContain('Last spot!');
    expect(result).toContain('Tower Ranch');
    expect(result).toContain('Mar');
    expect(result).toContain('Join now');
  });

  it('omits course when missing', () => {
    const result = buildLastSpotBody({
      date: makeTimestamp('2026-03-14T21:00:00Z'),
    });
    expect(result).toContain('Last spot!');
    expect(result).not.toContain('Tower');
    expect(result).toContain('Join now');
  });

  it('omits date when missing', () => {
    const result = buildLastSpotBody({
      course_play: 'Tower Ranch',
    });
    expect(result).toBe('Last spot! \u00B7 Tower Ranch \u00B7 Join now');
  });

  it('handles minimal data', () => {
    const result = buildLastSpotBody({});
    expect(result).toBe('Last spot! \u00B7 Join now');
  });
});
