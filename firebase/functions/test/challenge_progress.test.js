'use strict';

/**
 * Challenge Progress — Unit Tests
 *
 * Tests for challenge evaluation, progress tracking, completion detection,
 * idempotency, and error isolation.
 *
 * Run: npx jest test/challenge_progress.test.js --verbose
 */

// ── Mock: firebase-admin ──────────────────────────────────────────────────────

const mockTimestamp = { toDate: () => new Date('2026-07-15T12:00:00Z'), seconds: 1752580800, nanoseconds: 0 };

jest.mock('firebase-admin', () => {
  const FieldValue = {
    increment: jest.fn((n) => ({ _increment: n })),
    arrayUnion: jest.fn((val) => ({ _arrayUnion: val })),
  };
  return {
    firestore: Object.assign(jest.fn(), {
      Timestamp: {
        now: jest.fn(() => mockTimestamp),
      },
      FieldValue,
    }),
    initializeApp: jest.fn(),
  };
});

// ── Mock: firebase-functions ──────────────────────────────────────────────────

jest.mock('firebase-functions/v1', () => ({
  region: jest.fn(() => ({
    https: { onCall: jest.fn((fn) => fn) },
  })),
  https: {
    HttpsError: class HttpsError extends Error {
      constructor(code, message) { super(message); this.code = code; }
    },
  },
}));

// ── Mock: notifications/trust/router ──────────────────────────────────────────

const mockRouteNotification = jest.fn(() => Promise.resolve());
jest.mock('../notifications/trust/router', () => ({
  routeNotification: mockRouteNotification,
}));

// ── Import modules under test ─────────────────────────────────────────────────

const { CHALLENGES, CHALLENGES_BY_ID, getFormatKey } = require('../challenge_definitions');
const challengeProgress = require('../challenge_progress');

// ── Helpers ───────────────────────────────────────────────────────────────────

function makeMockDb(overrides = {}) {
  const userData = {
    streakCurrentWeeks: 0,
    streakLongestWeeks: 0,
    unique_co_players: [],
    friends: [],
    challenge_progress: {},
    ...(overrides.userData || {}),
  };

  const partnerPlaysDocs = (overrides.partnerPlays || []).map((pp) => ({
    id: pp.id,
    data: () => pp,
    ...pp,
  }));

  const coursesCount = overrides.coursesCount || 10;
  const userExists = overrides.userExists !== false;
  const gameData = overrides.gameData || {};

  let capturedUpdate = null;

  const db = {
    collection: jest.fn((collName) => {
      if (collName === 'users') {
        return {
          doc: jest.fn((uid) => ({
            get: jest.fn(() => Promise.resolve({
              exists: userExists,
              data: () => userData,
            })),
            update: jest.fn((data) => {
              capturedUpdate = data;
              return Promise.resolve();
            }),
            collection: jest.fn((subColl) => {
              if (subColl === 'partner_plays') {
                return {
                  get: jest.fn(() => Promise.resolve({ docs: partnerPlaysDocs })),
                };
              }
              if (subColl === 'cancellation_records') {
                return {
                  where: jest.fn(() => ({
                    where: jest.fn(() => ({
                      limit: jest.fn(() => ({
                        get: jest.fn(() => Promise.resolve({
                          empty: overrides.hasCancellations !== true,
                        })),
                      })),
                    })),
                  })),
                };
              }
              return { get: jest.fn(() => Promise.resolve({ docs: [] })) };
            }),
          })),
        };
      }
      if (collName === 'courses') {
        return {
          count: jest.fn(() => ({
            get: jest.fn(() => Promise.resolve({
              data: () => ({ count: coursesCount }),
            })),
          })),
        };
      }
      return { doc: jest.fn(() => ({ get: jest.fn(() => Promise.resolve({ exists: false })) })) };
    }),
    _getCapturedUpdate: () => capturedUpdate,
  };

  const gameRef = {
    id: overrides.gameId || 'game_123',
    get: jest.fn(() => Promise.resolve({
      exists: true,
      data: () => ({
        game_type: 'Stroke Play',
        is_2v2: false,
        has_side_games: false,
        courseRef: { id: 'course_abc' },
        course_play: 'Test Course',
        ...gameData,
      }),
    })),
  };

  const roundData = {
    tee_time: { toDate: () => new Date('2026-07-15T18:00:00Z') },
    _roundRefId: overrides.roundId || 'round_456',
    ...(overrides.roundData || {}),
  };

  return { db, gameRef, roundData, getCapturedUpdate: () => capturedUpdate };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
});

describe('getFormatKey', () => {
  it('returns stroke_play for default', () => {
    expect(getFormatKey({ game_type: 'Stroke Play' })).toBe('stroke_play');
  });

  it('returns match_play for Match Play', () => {
    expect(getFormatKey({ game_type: 'Match Play' })).toBe('match_play');
  });

  it('returns stableford for Stableford', () => {
    expect(getFormatKey({ game_type: 'Stableford' })).toBe('stableford');
  });

  it('returns best_ball for 2v2 Best Ball', () => {
    expect(getFormatKey({ game_type: 'Best Ball', is_2v2: true })).toBe('best_ball');
  });

  it('returns scramble for 2v2 Scramble', () => {
    expect(getFormatKey({ game_type: 'Scramble', is_2v2: true })).toBe('scramble');
  });

  it('defaults 2v2 to best_ball when type is unrecognized', () => {
    expect(getFormatKey({ game_type: 'Stroke Play', is_2v2: true })).toBe('best_ball');
  });
});

describe('Challenge definitions', () => {
  it('has 24 challenges total', () => {
    expect(CHALLENGES.length).toBe(24);
  });

  it('has 19 visible and 5 hidden', () => {
    const visible = CHALLENGES.filter((c) => !c.hidden);
    const hidden = CHALLENGES.filter((c) => c.hidden);
    expect(visible.length).toBe(19);
    expect(hidden.length).toBe(5);
  });

  it('each challenge has a unique id', () => {
    const ids = CHALLENGES.map((c) => c.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('each challenge has an evaluate function', () => {
    for (const c of CHALLENGES) {
      expect(typeof c.evaluate).toBe('function');
    }
  });
});

describe('Set challenge (courses)', () => {
  it('adds new course to progress data', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { courseRef: { id: 'course_new' } },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update).not.toBeNull();
    expect(update.challenge_progress.new_course.data).toContain('course_new');
    expect(update.challenge_progress.new_course.current).toBe(1);
    expect(update.challenge_progress.new_course.completedAt).toBeTruthy();
  });

  it('does not duplicate existing course in data', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { courseRef: { id: 'course_abc' } },
      userData: {
        challenge_progress: {
          courses_5: { current: 2, target: 5, data: ['course_abc', 'course_xyz'] },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.courses_5.data).toEqual(['course_abc', 'course_xyz']);
    expect(update.challenge_progress.courses_5.current).toBe(2);
  });
});

describe('Set challenge (formats)', () => {
  it('adds stroke_play to try_formats data', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { game_type: 'Stroke Play' },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.try_formats.data).toContain('stroke_play');
  });
});

describe('Counter challenge (side games)', () => {
  it('increments side_game_1 when game has side games', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { has_side_games: true },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.side_game_1.current).toBe(1);
    expect(update.challenge_progress.side_game_1.completedAt).toBeTruthy();
  });

  it('does not increment side_game_1 when no side games', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { has_side_games: false },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.side_game_1.current).toBe(0);
  });
});

describe('Read challenge (streaks)', () => {
  it('marks streak_4 completed when user has 4+ week streak', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      userData: { streakCurrentWeeks: 4 },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.streak_4.current).toBe(4);
    expect(update.challenge_progress.streak_4.completedAt).toBeTruthy();
  });
});

describe('Read challenge (partners)', () => {
  it('marks partners_10 completed when user has 10+ unique co-players', async () => {
    const coPlayers = Array.from({ length: 10 }, (_, i) => `player_${i}`);
    const { db, gameRef, roundData } = makeMockDb({
      userData: { unique_co_players: coPlayers },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.partners_10.current).toBe(10);
    expect(update.challenge_progress.partners_10.completedAt).toBeTruthy();
  });
});

describe('Boolean challenge (all_strangers)', () => {
  it('completes when 4 players and no prior partner_plays', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      partnerPlays: [
        // play_count = 1 means they only played THIS round (partner_plays written before challenges)
        { id: 'user2', play_count: 1 },
        { id: 'user3', play_count: 1 },
        { id: 'user4', play_count: 1 },
      ],
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1', 'user2', 'user3', 'user4']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.all_strangers.completed || update.challenge_progress.all_strangers.completedAt).toBeTruthy();
  });

  it('does not complete when a player has prior partner_plays', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      partnerPlays: [
        { id: 'user2', play_count: 3 }, // played with user2 before
        { id: 'user3', play_count: 1 },
        { id: 'user4', play_count: 1 },
      ],
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1', 'user2', 'user3', 'user4']);

    const notifCalls = mockRouteNotification.mock.calls;
    const allStrangersNotif = notifCalls.find(
      (c) => c[0].eventType === 'challenge_completed' && c[0].data.challenge_id === 'all_strangers'
        && c[0].recipientUserId === 'user1'
    );
    expect(allStrangersNotif).toBeUndefined();
  });
});

describe('Boolean challenge (dawn_patrol)', () => {
  it('completes when tee time is before 7:30 AM Vancouver', async () => {
    // 6:45 AM PDT = 13:45 UTC
    const { db, gameRef, roundData } = makeMockDb({
      roundData: {
        tee_time: { toDate: () => new Date('2026-07-15T13:45:00Z') },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.dawn_patrol.completedAt).toBeTruthy();
  });

  it('does not complete when tee time is after 7:30 AM Vancouver', async () => {
    // 9:00 AM PDT = 16:00 UTC
    const { db, gameRef, roundData } = makeMockDb({
      roundData: {
        tee_time: { toDate: () => new Date('2026-07-15T16:00:00Z') },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.dawn_patrol.completedAt).toBeUndefined();
  });
});

describe('Special challenge (monthly_variety)', () => {
  it('tracks format keys per month', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { game_type: 'Match Play' },
      userData: {
        challenge_progress: {
          monthly_variety: {
            current: 2,
            target: 3,
            data: { '2026-07': ['stroke_play', 'stableford'] },
          },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.monthly_variety.data['2026-07']).toContain('match_play');
    expect(update.challenge_progress.monthly_variety.current).toBe(3);
    expect(update.challenge_progress.monthly_variety.completedAt).toBeTruthy();
  });
});

describe('Completion detection', () => {
  it('sets completedAt timestamp when challenge crosses threshold', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      userData: { streakCurrentWeeks: 3 },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.streak_3.completedAt).toEqual(mockTimestamp);
  });

  it('sends notification on newly completed challenge', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      userData: { streakCurrentWeeks: 3 },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    // streak_3 should be newly completed → notification sent
    const calls = mockRouteNotification.mock.calls;
    const challengeNotif = calls.find(
      (c) => c[0].eventType === 'challenge_completed' && c[0].data.challenge_id === 'streak_3'
    );
    expect(challengeNotif).toBeTruthy();
  });

  it('does not re-notify already completed challenges', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      userData: {
        streakCurrentWeeks: 5,
        challenge_progress: {
          streak_3: { current: 3, target: 3, completedAt: mockTimestamp },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const calls = mockRouteNotification.mock.calls;
    const streak3Notif = calls.find(
      (c) => c[0].eventType === 'challenge_completed' && c[0].data.challenge_id === 'streak_3'
    );
    expect(streak3Notif).toBeUndefined();
  });
});

describe('Idempotency', () => {
  it('skips processing when round was already processed', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      userData: {
        challenge_progress: {
          _lastProcessedRound: 'round_456',
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    // No update should have been written
    const update = db._getCapturedUpdate();
    expect(update).toBeNull();
  });

  it('writes _lastProcessedRound sentinel after processing', async () => {
    const { db, gameRef, roundData } = makeMockDb();

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress._lastProcessedRound).toBe('round_456');
  });
});

describe('Non-fatal isolation', () => {
  it('continues processing other challenges when one evaluate throws', async () => {
    // Temporarily break one challenge's evaluate
    const origEvaluate = CHALLENGES_BY_ID.grand_tour.evaluate;
    CHALLENGES_BY_ID.grand_tour.evaluate = () => { throw new Error('test error'); };

    const { db, gameRef, roundData } = makeMockDb();

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    // Restore
    CHALLENGES_BY_ID.grand_tour.evaluate = origEvaluate;

    // Other challenges should still be processed
    const update = db._getCapturedUpdate();
    expect(update).not.toBeNull();
    expect(update.challenge_progress.new_course).toBeDefined();
    expect(update.challenge_progress.streak_3).toBeDefined();
  });

  it('does not block verification when entire challenge processing fails', async () => {
    const { db, gameRef, roundData } = makeMockDb({ userExists: false });

    // Should not throw — just logs warning
    await expect(
      challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1'])
    ).resolves.not.toThrow();
  });
});

describe('Dynamic target (grand_tour)', () => {
  it('uses courses collection count as target', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      coursesCount: 3,
      gameData: { courseRef: { id: 'course_1' } },
      userData: {
        challenge_progress: {
          grand_tour: { current: 2, target: 3, data: ['course_2', 'course_3'] },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.grand_tour.target).toBe(3);
    expect(update.challenge_progress.grand_tour.data).toContain('course_1');
    expect(update.challenge_progress.grand_tour.current).toBe(3);
    expect(update.challenge_progress.grand_tour.completedAt).toBeTruthy();
  });
});

describe('Home course (hidden counter)', () => {
  it('tracks play counts per course and completes at 5', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      gameData: { courseRef: { id: 'home_c' } },
      userData: {
        challenge_progress: {
          home_course: { current: 4, target: 5, data: { home_c: 4 } },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.home_course.data.home_c).toBe(5);
    expect(update.challenge_progress.home_course.current).toBe(5);
    expect(update.challenge_progress.home_course.completedAt).toBeTruthy();
  });
});

describe('never_miss threshold (4 games minimum)', () => {
  it('does NOT complete with 1 game and 0 cancellations', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      hasCancellations: false,
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.never_miss.current).toBe(1);
    expect(update.challenge_progress.never_miss.completedAt).toBeUndefined();
  });

  it('does NOT complete with 3 games and 0 cancellations', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      hasCancellations: false,
      userData: {
        challenge_progress: {
          never_miss: { current: 2, target: 4, data: { '2026-07': 2 } },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.never_miss.current).toBe(3);
    expect(update.challenge_progress.never_miss.completedAt).toBeUndefined();
  });

  it('completes with 4 games and 0 cancellations', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      hasCancellations: false,
      userData: {
        challenge_progress: {
          never_miss: { current: 3, target: 4, data: { '2026-07': 3 } },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.never_miss.current).toBe(4);
    expect(update.challenge_progress.never_miss.completedAt).toBeTruthy();
  });

  it('does NOT complete with 4 games and cancellations present', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      hasCancellations: true,
      userData: {
        challenge_progress: {
          never_miss: { current: 3, target: 4, data: { '2026-07': 3 } },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.never_miss.current).toBe(4);
    expect(update.challenge_progress.never_miss.completedAt).toBeUndefined();
  });

  it('tracks round count per month in data', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      hasCancellations: false,
      userData: {
        challenge_progress: {
          never_miss: { current: 1, target: 4, data: { '2026-06': 2, '2026-07': 1 } },
        },
      },
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    // July should increment from 1 to 2, June stays at 2
    expect(update.challenge_progress.never_miss.data['2026-07']).toBe(2);
    expect(update.challenge_progress.never_miss.data['2026-06']).toBe(2);
  });
});

describe('all_strangers player count threshold', () => {
  it('does NOT complete with only 1 other player (2 total)', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      partnerPlays: [
        { id: 'user2', play_count: 1 },
      ],
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1', 'user2']);

    const notifCalls = mockRouteNotification.mock.calls;
    const allStrangersNotif = notifCalls.find(
      (c) => c[0].eventType === 'challenge_completed' && c[0].data.challenge_id === 'all_strangers'
        && c[0].recipientUserId === 'user1'
    );
    expect(allStrangersNotif).toBeUndefined();
  });

  it('does NOT complete with 2 other players (3 total)', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      partnerPlays: [
        { id: 'user2', play_count: 1 },
        { id: 'user3', play_count: 1 },
      ],
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1', 'user2', 'user3']);

    const notifCalls = mockRouteNotification.mock.calls;
    const allStrangersNotif = notifCalls.find(
      (c) => c[0].eventType === 'challenge_completed' && c[0].data.challenge_id === 'all_strangers'
        && c[0].recipientUserId === 'user1'
    );
    expect(allStrangersNotif).toBeUndefined();
  });

  it('completes with 3+ other strangers (4 total)', async () => {
    const { db, gameRef, roundData } = makeMockDb({
      partnerPlays: [
        { id: 'user2', play_count: 1 },
        { id: 'user3', play_count: 1 },
        { id: 'user4', play_count: 1 },
      ],
    });

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1', 'user2', 'user3', 'user4']);

    const update = db._getCapturedUpdate();
    expect(update.challenge_progress.all_strangers.completedAt).toBeTruthy();
  });
});

describe('season_rounds_played', () => {
  it('increments season_rounds_played on user doc', async () => {
    const { db, gameRef, roundData } = makeMockDb();

    await challengeProgress.onRoundVerified(db, gameRef, roundData, ['user1']);

    const update = db._getCapturedUpdate();
    expect(update.season_rounds_played).toEqual({ _increment: 1 });
  });
});
