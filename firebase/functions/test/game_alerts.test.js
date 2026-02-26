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

const { isUserEligibleByGender, doesAlertSubMatchGame } = require('../game_alerts');

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
});
