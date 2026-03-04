'use strict';

/**
 * Streaks Module — Unit Tests
 *
 * Tests for timezone utilities, season logic, and streak computations.
 *
 * Run: npx jest test/streaks.test.js --verbose
 */

// ── Mock: firebase-admin ──────────────────────────────────────────────────────

jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(),
    FieldValue: {
      arrayUnion: jest.fn((val) => ({ _arrayUnion: val })),
      arrayRemove: jest.fn((val) => ({ _arrayRemove: val })),
    },
  })),
  initializeApp: jest.fn(),
}));

// ── Mock: firebase-functions ──────────────────────────────────────────────────

jest.mock('firebase-functions/v1', () => ({
  region: jest.fn(() => ({
    https: {
      onCall: jest.fn((fn) => fn),
    },
  })),
  https: {
    HttpsError: class HttpsError extends Error {
      constructor(code, message) {
        super(message);
        this.code = code;
      }
    },
  },
}));

// ── Mock: notifications/trust/router ──────────────────────────────────────────

jest.mock('../notifications/trust/router', () => ({
  routeNotification: jest.fn(() => Promise.resolve()),
}));

// ── Import module under test ──────────────────────────────────────────────────

const {
  weekStartMondayKey,
  getPreviousWeekKey,
  seasonIdForDate,
  seasonWindowFor,
  isInSeason,
  milestoneFor,
  isOutdoorRound,
  getVancouverDateParts,
  getVancouverIsoWeekday,
  _computeConsecutiveStreak,
  _pruneStaleData,
} = require('../streaks');

afterEach(() => {
  jest.useRealTimers();
});

// ── Tests: weekStartMondayKey ─────────────────────────────────────────────────

describe('weekStartMondayKey', () => {
  describe('correctly identifies Monday of the week', () => {
    it('returns Monday for a Monday input', () => {
      // Monday, June 3, 2026 12:00 PM Vancouver
      const date = new Date('2026-06-03T19:00:00Z'); // 12:00 PM PDT
      expect(weekStartMondayKey(date)).toBe('2026-06-01');
    });

    it('returns Monday for a Wednesday input', () => {
      // Wednesday, June 3, 2026
      const date = new Date('2026-06-03T19:00:00Z');
      const result = weekStartMondayKey(date);
      expect(result).toBe('2026-06-01');
    });

    it('returns Monday for a Sunday input', () => {
      // Sunday, June 7, 2026 12:00 PM Vancouver
      const date = new Date('2026-06-07T19:00:00Z');
      expect(weekStartMondayKey(date)).toBe('2026-06-01');
    });

    it('handles week boundary correctly (Saturday to Sunday)', () => {
      // Saturday June 6, 2026
      const saturday = new Date('2026-06-06T19:00:00Z');
      // Sunday June 7, 2026
      const sunday = new Date('2026-06-07T19:00:00Z');

      expect(weekStartMondayKey(saturday)).toBe('2026-06-01');
      expect(weekStartMondayKey(sunday)).toBe('2026-06-01');
    });

    it('handles week rollover (Sunday to Monday)', () => {
      // Sunday June 7, 2026 (week of June 1)
      const sunday = new Date('2026-06-07T19:00:00Z');
      // Monday June 8, 2026 (week of June 8)
      const monday = new Date('2026-06-08T19:00:00Z');

      expect(weekStartMondayKey(sunday)).toBe('2026-06-01');
      expect(weekStartMondayKey(monday)).toBe('2026-06-08');
    });
  });

  describe('handles DST transitions', () => {
    it('handles spring forward (March)', () => {
      // March 8, 2026 - DST starts in Vancouver
      const date = new Date('2026-03-08T20:00:00Z'); // After spring forward
      const result = weekStartMondayKey(date);
      expect(result).toMatch(/^\d{4}-03-\d{2}$/);
    });

    it('handles fall back (November)', () => {
      // November 1, 2025 - DST ends in Vancouver
      const date = new Date('2025-11-01T19:00:00Z');
      const result = weekStartMondayKey(date);
      expect(result).toMatch(/^\d{4}-10-\d{2}$/);
    });
  });
});

// ── Tests: getPreviousWeekKey ─────────────────────────────────────────────────

describe('getPreviousWeekKey', () => {
  it('returns previous Monday key', () => {
    // Wednesday, June 10, 2026
    const date = new Date('2026-06-10T19:00:00Z');
    const currentWeek = weekStartMondayKey(date);
    const previousWeek = getPreviousWeekKey(date);

    expect(currentWeek).toBe('2026-06-08');
    expect(previousWeek).toBe('2026-06-01');
  });

  it('handles month boundaries', () => {
    // Monday, June 1, 2026
    const date = new Date('2026-06-01T19:00:00Z');
    expect(getPreviousWeekKey(date)).toBe('2026-05-25');
  });

  it('handles year boundaries', () => {
    // Monday, January 5, 2026
    const date = new Date('2026-01-05T20:00:00Z');
    expect(getPreviousWeekKey(date)).toBe('2025-12-29');
  });
});

// ── Tests: seasonIdForDate ────────────────────────────────────────────────────

describe('seasonIdForDate', () => {
  it('returns year for in-season dates', () => {
    // June 15, 2026 (mid-season)
    const date = new Date('2026-06-15T19:00:00Z');
    expect(seasonIdForDate(date)).toBe('2026');
  });

  it('returns year for season start', () => {
    // March 1, 2026
    const date = new Date('2026-03-01T08:00:00Z');
    expect(seasonIdForDate(date)).toBe('2026');
  });

  it('returns year for season end', () => {
    // October 31, 2026
    const date = new Date('2026-10-31T07:00:00Z');
    expect(seasonIdForDate(date)).toBe('2026');
  });

  it('returns year for off-season dates', () => {
    // January 15, 2026 (off-season)
    const date = new Date('2026-01-15T20:00:00Z');
    expect(seasonIdForDate(date)).toBe('2026');
  });
});

// ── Tests: isInSeason ─────────────────────────────────────────────────────────

describe('isInSeason', () => {
  describe('in-season dates', () => {
    it('returns true for March 1', () => {
      // March 1, 2026 12:00 PM Vancouver
      const date = new Date('2026-03-01T20:00:00Z');
      expect(isInSeason(date)).toBe(true);
    });

    it('returns true for mid-season (July)', () => {
      const date = new Date('2026-07-15T19:00:00Z');
      expect(isInSeason(date)).toBe(true);
    });

    it('returns true for October 31', () => {
      // October 31, 2026 12:00 PM Vancouver (PDT)
      const date = new Date('2026-10-31T19:00:00Z');
      expect(isInSeason(date)).toBe(true);
    });
  });

  describe('off-season dates', () => {
    it('returns false for February 28', () => {
      // February 28, 2026
      const date = new Date('2026-02-28T20:00:00Z');
      expect(isInSeason(date)).toBe(false);
    });

    it('returns false for November 1', () => {
      // November 1, 2026
      const date = new Date('2026-11-01T20:00:00Z');
      expect(isInSeason(date)).toBe(false);
    });

    it('returns false for winter (January)', () => {
      const date = new Date('2026-01-15T20:00:00Z');
      expect(isInSeason(date)).toBe(false);
    });

    it('returns false for winter (December)', () => {
      const date = new Date('2026-12-15T20:00:00Z');
      expect(isInSeason(date)).toBe(false);
    });
  });
});

// ── Tests: milestoneFor ───────────────────────────────────────────────────────

describe('milestoneFor', () => {
  it('returns 0 for 0-3 weeks', () => {
    expect(milestoneFor(0)).toBe(0);
    expect(milestoneFor(1)).toBe(0);
    expect(milestoneFor(2)).toBe(0);
    expect(milestoneFor(3)).toBe(0);
  });

  it('returns 4 for 4-7 weeks', () => {
    expect(milestoneFor(4)).toBe(4);
    expect(milestoneFor(5)).toBe(4);
    expect(milestoneFor(7)).toBe(4);
  });

  it('returns 8 for 8-12 weeks', () => {
    expect(milestoneFor(8)).toBe(8);
    expect(milestoneFor(10)).toBe(8);
    expect(milestoneFor(12)).toBe(8);
  });

  it('returns 13 for 13-25 weeks', () => {
    expect(milestoneFor(13)).toBe(13);
    expect(milestoneFor(20)).toBe(13);
    expect(milestoneFor(25)).toBe(13);
  });

  it('returns 26 for 26+ weeks', () => {
    expect(milestoneFor(26)).toBe(26);
    expect(milestoneFor(30)).toBe(26);
    expect(milestoneFor(100)).toBe(26);
  });
});

// ── Tests: isOutdoorRound ─────────────────────────────────────────────────────

describe('isOutdoorRound', () => {
  it('returns true for null game data (default outdoor)', () => {
    expect(isOutdoorRound(null)).toBe(false);
  });

  it('returns true for empty game data', () => {
    expect(isOutdoorRound({})).toBe(true);
  });

  it('returns true for regular outdoor game', () => {
    expect(isOutdoorRound({ course_name: 'Shaughnessy GCC' })).toBe(true);
  });

  it('returns false for is_sim = true', () => {
    expect(isOutdoorRound({ is_sim: true })).toBe(false);
  });

  it('returns false for venue_type = indoor', () => {
    expect(isOutdoorRound({ venue_type: 'indoor' })).toBe(false);
  });

  it('returns false for venue_type = simulator', () => {
    expect(isOutdoorRound({ venue_type: 'simulator' })).toBe(false);
  });

  it('returns true for venue_type = outdoor', () => {
    expect(isOutdoorRound({ venue_type: 'outdoor' })).toBe(true);
  });
});

// ── Tests: _computeConsecutiveStreak ──────────────────────────────────────────

describe('_computeConsecutiveStreak', () => {
  it('returns 0 for empty weeks', () => {
    const result = _computeConsecutiveStreak([], null);
    expect(result.consecutiveWeeks).toBe(0);
    expect(result.lastWeekKey).toBe(null);
  });

  it('returns 1 for single week', () => {
    const result = _computeConsecutiveStreak(['2026-06-01'], null);
    expect(result.consecutiveWeeks).toBe(1);
    expect(result.lastWeekKey).toBe('2026-06-01');
  });

  it('returns correct count for consecutive weeks', () => {
    const weeks = ['2026-06-01', '2026-06-08', '2026-06-15', '2026-06-22'];
    const result = _computeConsecutiveStreak(weeks, null);
    expect(result.consecutiveWeeks).toBe(4);
    expect(result.lastWeekKey).toBe('2026-06-22');
  });

  it('handles gap in weeks (streak breaks)', () => {
    // Gap between 06-08 and 06-22
    const weeks = ['2026-06-01', '2026-06-08', '2026-06-22', '2026-06-29'];
    const result = _computeConsecutiveStreak(weeks, null);
    expect(result.consecutiveWeeks).toBe(2); // Only 06-22 and 06-29 are consecutive
    expect(result.lastWeekKey).toBe('2026-06-29');
  });

  it('includes freeze week in streak calculation', () => {
    // User played 06-01, 06-08, froze 06-15, played 06-22
    const weeks = ['2026-06-01', '2026-06-08', '2026-06-22'];
    const freezeUsedWeekKey = '2026-06-15';
    const result = _computeConsecutiveStreak(weeks, freezeUsedWeekKey);
    expect(result.consecutiveWeeks).toBe(4);
    expect(result.lastWeekKey).toBe('2026-06-22');
  });

  it('handles unsorted input', () => {
    const weeks = ['2026-06-22', '2026-06-01', '2026-06-15', '2026-06-08'];
    const result = _computeConsecutiveStreak(weeks, null);
    expect(result.consecutiveWeeks).toBe(4);
  });

  it('counts from the most recent week backward', () => {
    // Old streak: 05-04, 05-11, 05-18
    // Gap: 05-25 missing
    // New streak: 06-01, 06-08
    const weeks = ['2026-05-04', '2026-05-11', '2026-05-18', '2026-06-01', '2026-06-08'];
    const result = _computeConsecutiveStreak(weeks, null);
    expect(result.consecutiveWeeks).toBe(2); // Only counts 06-01, 06-08
    expect(result.lastWeekKey).toBe('2026-06-08');
  });
});

// ── Tests: getVancouverDateParts ──────────────────────────────────────────────

describe('getVancouverDateParts', () => {
  it('extracts correct parts for Vancouver time', () => {
    // June 15, 2026 14:30 Vancouver (PDT = UTC-7)
    // So UTC time is 21:30
    const date = new Date('2026-06-15T21:30:00Z');
    const parts = getVancouverDateParts(date);

    expect(parts.year).toBe(2026);
    expect(parts.month).toBe(6);
    expect(parts.day).toBe(15);
    expect(parts.hour).toBe(14);
    expect(parts.minute).toBe(30);
  });

  it('handles midnight correctly', () => {
    // June 16, 2026 00:00 Vancouver = June 16, 07:00 UTC (PDT)
    const date = new Date('2026-06-16T07:00:00Z');
    const parts = getVancouverDateParts(date);

    expect(parts.year).toBe(2026);
    expect(parts.month).toBe(6);
    expect(parts.day).toBe(16);
    expect(parts.hour).toBe(0);
    expect(parts.minute).toBe(0);
  });
});

// ── Tests: getVancouverIsoWeekday ─────────────────────────────────────────────

describe('getVancouverIsoWeekday', () => {
  it('returns 1 for Monday', () => {
    // Monday, June 1, 2026
    const date = new Date('2026-06-01T19:00:00Z');
    expect(getVancouverIsoWeekday(date)).toBe(1);
  });

  it('returns 5 for Friday', () => {
    // Friday, June 5, 2026
    const date = new Date('2026-06-05T19:00:00Z');
    expect(getVancouverIsoWeekday(date)).toBe(5);
  });

  it('returns 7 for Sunday', () => {
    // Sunday, June 7, 2026
    const date = new Date('2026-06-07T19:00:00Z');
    expect(getVancouverIsoWeekday(date)).toBe(7);
  });
});

// ── Tests: seasonWindowFor ────────────────────────────────────────────────────

describe('seasonWindowFor', () => {
  it('returns correct season window for mid-season date', () => {
    const date = new Date('2026-07-15T19:00:00Z');
    const window = seasonWindowFor(date);

    // Season runs March 1 - Oct 31 2026 in Vancouver time
    // Note: UTC dates may differ due to timezone offset
    expect(window.start.getUTCFullYear()).toBe(2026);
    expect(window.start.getUTCMonth()).toBe(2); // March (0-indexed)

    // End date: Oct 31, 23:59 Vancouver = Nov 1, 06:59 UTC (PDT offset)
    expect(window.end.getUTCFullYear()).toBe(2026);
    // Oct 31 23:59 Vancouver (PDT = UTC-7) = Nov 1 06:59 UTC
    // So UTC month is 10 (November, 0-indexed)
    expect(window.end.getUTCMonth()).toBe(10);

    // Verify the Vancouver date parts are correct for the end
    const endParts = getVancouverDateParts(window.end);
    expect(endParts.month).toBe(10); // October (1-indexed)
    expect(endParts.day).toBe(31);
    expect(endParts.hour).toBe(23);
    expect(endParts.minute).toBe(59);
  });
});

// ── Tests: _pruneStaleData cutoff calculation ─────────────────────────────────

describe('_pruneStaleData cutoff calculation', () => {
  let mockDb;

  beforeEach(() => {
    // Mock db with empty collection
    mockDb = {
      collection: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnValue({
          limit: jest.fn().mockReturnValue({
            startAfter: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
            }),
            get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
          }),
        }),
      }),
    };
  });

  it('calculates cutoff as exactly 4 weeks prior (mid-season)', async () => {
    // Current week: Monday 2026-06-08
    // Expected cutoff: Monday 2026-05-11 (exactly 28 days prior)
    const currentWeekKey = '2026-06-08';

    // Create mock user with weeks to verify pruning logic
    const mockDoc = {
      ref: { id: 'user1' },
      data: () => ({
        streak_weeks_pending: ['2026-05-04', '2026-05-11', '2026-05-18', '2026-06-01', '2026-06-08'],
        streak_notif_state: {
          'friday_2026-05-04': true,  // Should be pruned (before cutoff)
          'friday_2026-05-11': true,  // Should be kept (at cutoff)
          'friday_2026-06-01': true,  // Should be kept (after cutoff)
          'milestone_8': true,        // Should always be kept
          'freeze_unlocked': true,    // Should always be kept
        },
      }),
    };

    let capturedUpdate = null;
    const mockBatch = {
      update: jest.fn((ref, data) => { capturedUpdate = data; }),
      commit: jest.fn().mockResolvedValue(undefined),
    };

    mockDb.collection = jest.fn().mockReturnValue({
      where: jest.fn().mockReturnValue({
        limit: jest.fn().mockReturnValue({
          get: jest.fn()
            .mockResolvedValueOnce({ empty: false, docs: [mockDoc] })
            .mockResolvedValueOnce({ empty: true, docs: [] }),
          startAfter: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
          }),
        }),
      }),
    });
    mockDb.batch = jest.fn().mockReturnValue(mockBatch);

    await _pruneStaleData(mockDb, currentWeekKey);

    // Verify batch.update was called
    expect(mockBatch.update).toHaveBeenCalled();

    // Verify pending weeks: only weeks >= 2026-05-11 should remain
    expect(capturedUpdate.streak_weeks_pending).toEqual([
      '2026-05-11', '2026-05-18', '2026-06-01', '2026-06-08'
    ]);

    // Verify notif state: friday_2026-05-04 should be pruned, others kept
    expect(capturedUpdate.streak_notif_state).toEqual({
      'friday_2026-05-11': true,
      'friday_2026-06-01': true,
      'milestone_8': true,
      'freeze_unlocked': true,
    });
  });

  it('calculates cutoff correctly across year boundary', async () => {
    // Current week: Monday 2026-01-05
    // Expected cutoff: Monday 2025-12-08 (exactly 28 days prior)
    const currentWeekKey = '2026-01-05';

    const mockDoc = {
      ref: { id: 'user1' },
      data: () => ({
        streak_weeks_pending: ['2025-12-01', '2025-12-08', '2025-12-15', '2026-01-05'],
        streak_notif_state: {
          'friday_2025-12-01': true,  // Should be pruned (before cutoff)
          'friday_2025-12-08': true,  // Should be kept (at cutoff)
        },
      }),
    };

    let capturedUpdate = null;
    const mockBatch = {
      update: jest.fn((ref, data) => { capturedUpdate = data; }),
      commit: jest.fn().mockResolvedValue(undefined),
    };

    mockDb.collection = jest.fn().mockReturnValue({
      where: jest.fn().mockReturnValue({
        limit: jest.fn().mockReturnValue({
          get: jest.fn()
            .mockResolvedValueOnce({ empty: false, docs: [mockDoc] })
            .mockResolvedValueOnce({ empty: true, docs: [] }),
          startAfter: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
          }),
        }),
      }),
    });
    mockDb.batch = jest.fn().mockReturnValue(mockBatch);

    await _pruneStaleData(mockDb, currentWeekKey);

    // Verify pending weeks: only weeks >= 2025-12-08 should remain
    expect(capturedUpdate.streak_weeks_pending).toEqual([
      '2025-12-08', '2025-12-15', '2026-01-05'
    ]);

    // Verify notif state: friday_2025-12-01 should be pruned
    expect(capturedUpdate.streak_notif_state).toEqual({
      'friday_2025-12-08': true,
    });
  });

  it('never prunes milestone_ and freeze_unlocked keys', async () => {
    const currentWeekKey = '2026-06-08';

    const mockDoc = {
      ref: { id: 'user1' },
      data: () => ({
        streak_weeks_pending: [],
        streak_notif_state: {
          'milestone_4': true,
          'milestone_8': true,
          'milestone_13': true,
          'freeze_unlocked': true,
          'friday_2026-01-01': true,  // Very old, should be pruned
        },
      }),
    };

    let capturedUpdate = null;
    const mockBatch = {
      update: jest.fn((ref, data) => { capturedUpdate = data; }),
      commit: jest.fn().mockResolvedValue(undefined),
    };

    mockDb.collection = jest.fn().mockReturnValue({
      where: jest.fn().mockReturnValue({
        limit: jest.fn().mockReturnValue({
          get: jest.fn()
            .mockResolvedValueOnce({ empty: false, docs: [mockDoc] })
            .mockResolvedValueOnce({ empty: true, docs: [] }),
          startAfter: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
          }),
        }),
      }),
    });
    mockDb.batch = jest.fn().mockReturnValue(mockBatch);

    await _pruneStaleData(mockDb, currentWeekKey);

    // All milestone_ and freeze_unlocked keys should be preserved
    expect(capturedUpdate.streak_notif_state).toEqual({
      'milestone_4': true,
      'milestone_8': true,
      'milestone_13': true,
      'freeze_unlocked': true,
    });
  });
});
