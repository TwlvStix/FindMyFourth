'use strict';

/**
 * Challenge Definitions — Static challenge definitions as code constants.
 *
 * 24 challenges total (19 visible + 5 hidden), organized in 4 categories:
 *   - course_explorer: Explore different courses
 *   - streaks:         Weekly streak milestones (reads existing streak fields)
 *   - social:          Play with different partners
 *   - formats:         Try different game formats and side games
 *
 * Challenge types:
 *   - set:     tracks unique items in a data array (courses, formats)
 *   - counter: increments current per qualifying round
 *   - boolean: one-time achievement
 *   - read:    reads existing user doc fields, no write needed
 *   - special: custom logic
 *
 * Each evaluate() receives a context object:
 *   { db, uid, gameData, roundData, userDoc, currentProgress, presentUids, partnerPlays }
 *
 * evaluate() returns: { current, data?, completed }
 *   - current:   numeric progress value
 *   - data:      optional array/object for tracking unique items
 *   - completed: true if challenge is complete after this round
 *
 * NOTE: admin.initializeApp() is called in index.js — do NOT call it here.
 */

// ── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Extracts a normalized format key from game data.
 *
 * Game types on game docs: "Stroke Play", "Match Play", "Stableford", "Best Ball", "Scramble"
 * is_2v2 flag indicates team formats.
 *
 * Returns one of: stroke_play, match_play, stableford, best_ball, scramble
 */
function getFormatKey(gameData) {
  const gameType = (gameData.game_type || '').toLowerCase().trim();
  const is2v2 = gameData.is_2v2 === true;

  if (is2v2) {
    if (gameType.includes('best ball') || gameType.includes('best_ball')) {
      return 'best_ball';
    }
    if (gameType.includes('scramble')) {
      return 'scramble';
    }
    // Default team format to best_ball if is_2v2 but no recognized team type
    return 'best_ball';
  }

  if (gameType.includes('match')) return 'match_play';
  if (gameType.includes('stableford')) return 'stableford';
  // Default individual format
  return 'stroke_play';
}

/**
 * Gets the season range: March 1 – October 31 of the current year.
 * Returns { start: Date, end: Date } in UTC (for comparison with Firestore timestamps).
 */
function getSeasonRange(dateInSeason) {
  const year = dateInSeason.getFullYear();
  return {
    start: new Date(year, 2, 1),  // March 1
    end: new Date(year, 10, 1),   // November 1 (exclusive)
  };
}

// ── Challenge Definitions ───────────────────────────────────────────────────

const CHALLENGES = [

  // ── Course Explorer ─────────────────────────────────────────────────────

  {
    id: 'new_course',
    name: 'New Horizons',
    category: 'course_explorer',
    type: 'set',
    target: 1,
    hidden: false,
    description: 'Play a new course',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.new_course || { current: 0, data: [] };
      const data = Array.isArray(progress.data) ? [...progress.data] : [];
      const courseId = ctx.gameData.courseRef?.id || ctx.gameData.courseRef?._path?.segments?.slice(-1)[0] || null;
      if (!courseId) return { current: data.length, data, completed: data.length >= 1 };
      if (!data.includes(courseId)) {
        data.push(courseId);
      }
      return { current: data.length, data, completed: data.length >= 1 };
    },
  },

  {
    id: 'courses_5',
    name: 'Branching Out',
    category: 'course_explorer',
    type: 'set',
    target: 5,
    hidden: false,
    description: 'Play 5 different courses',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.courses_5 || { current: 0, data: [] };
      const data = Array.isArray(progress.data) ? [...progress.data] : [];
      const courseId = ctx.gameData.courseRef?.id || ctx.gameData.courseRef?._path?.segments?.slice(-1)[0] || null;
      if (!courseId) return { current: data.length, data, completed: data.length >= 5 };
      if (!data.includes(courseId)) {
        data.push(courseId);
      }
      return { current: data.length, data, completed: data.length >= 5 };
    },
  },

  {
    id: 'courses_10',
    name: 'Course Collector',
    category: 'course_explorer',
    type: 'set',
    target: 10,
    hidden: false,
    description: 'Play 10 different courses',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.courses_10 || { current: 0, data: [] };
      const data = Array.isArray(progress.data) ? [...progress.data] : [];
      const courseId = ctx.gameData.courseRef?.id || ctx.gameData.courseRef?._path?.segments?.slice(-1)[0] || null;
      if (!courseId) return { current: data.length, data, completed: data.length >= 10 };
      if (!data.includes(courseId)) {
        data.push(courseId);
      }
      return { current: data.length, data, completed: data.length >= 10 };
    },
  },

  {
    id: 'courses_18',
    name: 'The Explorer',
    category: 'course_explorer',
    type: 'set',
    target: 18,
    hidden: false,
    description: 'Play 18 different courses',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.courses_18 || { current: 0, data: [] };
      const data = Array.isArray(progress.data) ? [...progress.data] : [];
      const courseId = ctx.gameData.courseRef?.id || ctx.gameData.courseRef?._path?.segments?.slice(-1)[0] || null;
      if (!courseId) return { current: data.length, data, completed: data.length >= 18 };
      if (!data.includes(courseId)) {
        data.push(courseId);
      }
      return { current: data.length, data, completed: data.length >= 18 };
    },
  },

  {
    id: 'grand_tour',
    name: 'Grand Tour',
    category: 'course_explorer',
    type: 'set',
    target: 0, // Dynamic — set at evaluation time from courses collection count
    hidden: false,
    description: 'Play every course in the system',
    evaluate: async (ctx) => {
      const progress = ctx.currentProgress.grand_tour || { current: 0, data: [] };
      const data = Array.isArray(progress.data) ? [...progress.data] : [];
      const courseId = ctx.gameData.courseRef?.id || ctx.gameData.courseRef?._path?.segments?.slice(-1)[0] || null;
      if (courseId && !data.includes(courseId)) {
        data.push(courseId);
      }
      // Dynamic target from courses collection count (cached in ctx)
      const target = ctx._coursesCount || 0;
      return { current: data.length, data, completed: target > 0 && data.length >= target, target };
    },
  },

  // ── Streaks (read existing user doc fields) ─────────────────────────────

  {
    id: 'streak_3',
    name: 'On a Roll',
    category: 'streaks',
    type: 'read',
    target: 3,
    hidden: false,
    description: 'Maintain a 3-week streak',
    evaluate: (ctx) => {
      const current = ctx.userDoc.streakCurrentWeeks || 0;
      return { current, completed: current >= 3 };
    },
  },

  {
    id: 'streak_4',
    name: 'Consistent',
    category: 'streaks',
    type: 'read',
    target: 4,
    hidden: false,
    description: 'Maintain a 4-week streak',
    evaluate: (ctx) => {
      const current = ctx.userDoc.streakCurrentWeeks || 0;
      return { current, completed: current >= 4 };
    },
  },

  {
    id: 'streak_10',
    name: 'Dedicated',
    category: 'streaks',
    type: 'read',
    target: 10,
    hidden: false,
    description: 'Achieve a 10-week longest streak',
    evaluate: (ctx) => {
      const current = ctx.userDoc.streakLongestWeeks || 0;
      return { current, completed: current >= 10 };
    },
  },

  {
    id: 'streak_28',
    name: 'Iron Will',
    category: 'streaks',
    type: 'read',
    target: 28,
    hidden: false,
    description: 'Achieve a 28-week longest streak',
    evaluate: (ctx) => {
      const current = ctx.userDoc.streakLongestWeeks || 0;
      return { current, completed: current >= 28 };
    },
  },

  // ── Social ──────────────────────────────────────────────────────────────

  {
    id: 'partner_1',
    name: 'First Foursome',
    category: 'social',
    type: 'read',
    target: 1,
    hidden: false,
    description: 'Play with your first partner',
    evaluate: (ctx) => {
      const coPlayers = ctx.userDoc.unique_co_players || [];
      const current = Array.isArray(coPlayers) ? coPlayers.length : 0;
      return { current, completed: current >= 1 };
    },
  },

  {
    id: 'partners_10',
    name: 'Social Golfer',
    category: 'social',
    type: 'read',
    target: 10,
    hidden: false,
    description: 'Play with 10 different partners',
    evaluate: (ctx) => {
      const coPlayers = ctx.userDoc.unique_co_players || [];
      const current = Array.isArray(coPlayers) ? coPlayers.length : 0;
      return { current, completed: current >= 10 };
    },
  },

  {
    id: 'partners_25',
    name: 'Networking Pro',
    category: 'social',
    type: 'read',
    target: 25,
    hidden: false,
    description: 'Play with 25 different partners',
    evaluate: (ctx) => {
      const coPlayers = ctx.userDoc.unique_co_players || [];
      const current = Array.isArray(coPlayers) ? coPlayers.length : 0;
      return { current, completed: current >= 25 };
    },
  },

  {
    id: 'all_strangers',
    name: 'Leap of Faith',
    category: 'social',
    type: 'boolean',
    target: 1,
    hidden: false,
    description: 'Play a full group (4 players) where no one knew each other beforehand',
    evaluate: async (ctx) => {
      // Check if any present player (excluding self) had prior partner_plays with this user
      const otherUids = ctx.presentUids.filter((u) => u !== ctx.uid);

      // Require at least 3 other players (4 total) for a full group of strangers
      if (otherUids.length < 3) return { current: 0, completed: false };

      // Check partner_plays docs for this user — if none of the otherUids have
      // a play_count > 1 (meaning they already played before THIS round), it's all strangers.
      // After this round, partner_plays will have play_count=1, so we check > 1
      // (since partner_plays is written before challenges in the verification pipeline).
      for (const otherUid of otherUids) {
        const ppDoc = ctx.partnerPlays.find((pp) => pp.id === otherUid);
        if (ppDoc && ppDoc.play_count > 1) {
          return { current: 0, completed: false };
        }
      }
      return { current: 1, completed: true };
    },
  },

  {
    id: 'referral',
    name: 'Ambassador',
    category: 'social',
    type: 'boolean',
    target: 1,
    hidden: false,
    description: 'Refer a friend who joins the app',
    evaluate: () => {
      // Stub — requires referral_code tracking infrastructure not yet built
      return { current: 0, completed: false };
    },
  },

  // ── Formats ─────────────────────────────────────────────────────────────

  {
    id: 'try_formats',
    name: 'Format Explorer',
    category: 'formats',
    type: 'set',
    target: 5,
    hidden: false,
    description: 'Play all 5 game formats',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.try_formats || { current: 0, data: [] };
      const data = Array.isArray(progress.data) ? [...progress.data] : [];
      const formatKey = getFormatKey(ctx.gameData);
      if (!data.includes(formatKey)) {
        data.push(formatKey);
      }
      return { current: data.length, data, completed: data.length >= 5 };
    },
  },

  {
    id: 'side_game_1',
    name: 'Side Action',
    category: 'formats',
    type: 'counter',
    target: 1,
    hidden: false,
    description: 'Play a round with side games',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.side_game_1 || { current: 0 };
      let current = progress.current || 0;
      if (ctx.gameData.has_side_games === true) {
        current += 1;
      }
      return { current, completed: current >= 1 };
    },
  },

  {
    id: 'monthly_variety',
    name: 'Monthly Mix',
    category: 'formats',
    type: 'special',
    target: 3,
    hidden: false,
    description: 'Play 3 different formats in the same calendar month',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.monthly_variety || { current: 0, data: {} };
      // data is { "YYYY-MM": ["format1", "format2"] }
      const dataMap = (typeof progress.data === 'object' && !Array.isArray(progress.data))
        ? { ...progress.data }
        : {};

      // Get the month of the round's tee time
      const teeTime = ctx.roundData.tee_time;
      let monthKey;
      if (teeTime && typeof teeTime.toDate === 'function') {
        const d = teeTime.toDate();
        monthKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      } else if (teeTime instanceof Date) {
        monthKey = `${teeTime.getFullYear()}-${String(teeTime.getMonth() + 1).padStart(2, '0')}`;
      } else {
        return { current: progress.current || 0, data: dataMap, completed: false };
      }

      const monthFormats = Array.isArray(dataMap[monthKey]) ? [...dataMap[monthKey]] : [];
      const formatKey = getFormatKey(ctx.gameData);
      if (!monthFormats.includes(formatKey)) {
        monthFormats.push(formatKey);
      }
      dataMap[monthKey] = monthFormats;

      // Check if any month has 3+ unique formats
      let maxFormats = 0;
      for (const key of Object.keys(dataMap)) {
        const count = Array.isArray(dataMap[key]) ? dataMap[key].length : 0;
        if (count > maxFormats) maxFormats = count;
      }

      return { current: maxFormats, data: dataMap, completed: maxFormats >= 3 };
    },
  },

  {
    id: 'side_games_5',
    name: 'Side Hustle',
    category: 'formats',
    type: 'counter',
    target: 5,
    hidden: false,
    description: 'Play 5 rounds with side games',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.side_games_5 || { current: 0 };
      let current = progress.current || 0;
      if (ctx.gameData.has_side_games === true) {
        current += 1;
      }
      return { current, completed: current >= 5 };
    },
  },

  {
    id: 'wildcard_season',
    name: 'Wildcard Season',
    category: 'formats',
    type: 'special',
    target: 1,
    hidden: false,
    description: 'Play all 5 formats and 3+ side game rounds in a season',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.wildcard_season || { current: 0, data: { formats: [], side_game_count: 0 } };
      const data = (typeof progress.data === 'object' && !Array.isArray(progress.data))
        ? { ...progress.data }
        : { formats: [], side_game_count: 0 };

      const formats = Array.isArray(data.formats) ? [...data.formats] : [];
      let sideGameCount = data.side_game_count || 0;

      const formatKey = getFormatKey(ctx.gameData);
      if (!formats.includes(formatKey)) {
        formats.push(formatKey);
      }
      if (ctx.gameData.has_side_games === true) {
        sideGameCount += 1;
      }

      const completed = formats.length >= 5 && sideGameCount >= 3;
      const newData = { formats, side_game_count: sideGameCount };

      return { current: completed ? 1 : 0, data: newData, completed };
    },
  },

  // ── Hidden Challenges ───────────────────────────────────────────────────

  {
    id: 'dawn_patrol',
    name: 'Dawn Patrol',
    category: 'formats',
    type: 'boolean',
    target: 1,
    hidden: true,
    description: 'Play a round with a tee time before 7:30 AM',
    evaluate: (ctx) => {
      const teeTime = ctx.roundData.tee_time;
      let hour, minute;
      if (teeTime && typeof teeTime.toDate === 'function') {
        const d = teeTime.toDate();
        // Convert to Vancouver time
        const parts = new Intl.DateTimeFormat('en-CA', {
          timeZone: 'America/Vancouver',
          hour: '2-digit',
          minute: '2-digit',
          hourCycle: 'h23',
        }).formatToParts(d);
        for (const p of parts) {
          if (p.type === 'hour') hour = parseInt(p.value, 10);
          if (p.type === 'minute') minute = parseInt(p.value, 10);
        }
      } else if (teeTime instanceof Date) {
        const parts = new Intl.DateTimeFormat('en-CA', {
          timeZone: 'America/Vancouver',
          hour: '2-digit',
          minute: '2-digit',
          hourCycle: 'h23',
        }).formatToParts(teeTime);
        for (const p of parts) {
          if (p.type === 'hour') hour = parseInt(p.value, 10);
          if (p.type === 'minute') minute = parseInt(p.value, 10);
        }
      } else {
        return { current: 0, completed: false };
      }

      const isBefore730 = (hour < 7) || (hour === 7 && minute < 30);
      return { current: isBefore730 ? 1 : 0, completed: isBefore730 };
    },
  },

  {
    id: 'home_course',
    name: 'Home Course',
    category: 'course_explorer',
    type: 'counter',
    target: 5,
    hidden: true,
    description: 'Play the same course 5 times',
    evaluate: (ctx) => {
      const progress = ctx.currentProgress.home_course || { current: 0, data: {} };
      // data is { [courseId]: playCount }
      const dataMap = (typeof progress.data === 'object' && !Array.isArray(progress.data))
        ? { ...progress.data }
        : {};

      const courseId = ctx.gameData.courseRef?.id || ctx.gameData.courseRef?._path?.segments?.slice(-1)[0] || null;
      if (courseId) {
        dataMap[courseId] = (dataMap[courseId] || 0) + 1;
      }

      // current = max play count across all courses
      let maxPlays = 0;
      for (const count of Object.values(dataMap)) {
        if (count > maxPlays) maxPlays = count;
      }

      return { current: maxPlays, data: dataMap, completed: maxPlays >= 5 };
    },
  },

  {
    id: 'small_world',
    name: 'Small World',
    category: 'social',
    type: 'boolean',
    target: 1,
    hidden: true,
    description: 'Match with the same non-friend stranger in 2+ different rounds',
    evaluate: async (ctx) => {
      // Check if any present player (excluding self) who is NOT a friend has
      // a partner_plays doc with play_count >= 2 (meaning 2+ rounds together)
      const otherUids = ctx.presentUids.filter((u) => u !== ctx.uid);
      const friends = ctx.userDoc.friends || [];
      const friendSet = new Set(Array.isArray(friends) ? friends : []);

      for (const otherUid of otherUids) {
        if (friendSet.has(otherUid)) continue; // skip friends
        const ppDoc = ctx.partnerPlays.find((pp) => pp.id === otherUid);
        // After this round's partner_plays write, play_count >= 2 means 2+ rounds
        if (ppDoc && ppDoc.play_count >= 2) {
          return { current: 1, completed: true };
        }
      }
      return { current: 0, completed: false };
    },
  },

  {
    id: 'full_circle',
    name: 'Full Circle',
    category: 'social',
    type: 'boolean',
    target: 1,
    hidden: true,
    description: 'Play with your first-ever partner after 10+ other unique partners',
    evaluate: async (ctx) => {
      const coPlayers = ctx.userDoc.unique_co_players || [];
      if (!Array.isArray(coPlayers) || coPlayers.length < 11) {
        return { current: 0, completed: false };
      }

      // The first co-player is the one at index 0 in unique_co_players (maintained in order)
      const firstPartner = coPlayers[0];
      if (!firstPartner) return { current: 0, completed: false };

      // Check if first partner is in this round
      const otherUids = ctx.presentUids.filter((u) => u !== ctx.uid);
      const isFirstPartnerPresent = otherUids.includes(firstPartner);

      return { current: isFirstPartnerPresent ? 1 : 0, completed: isFirstPartnerPresent };
    },
  },

  {
    id: 'never_miss',
    name: 'Never Miss',
    category: 'streaks',
    type: 'special',
    target: 4,
    hidden: true,
    description: 'Play 4+ games in a calendar month with no cancellations',
    evaluate: async (ctx) => {
      const progress = ctx.currentProgress.never_miss || { current: 0, data: {} };
      const dataMap = (typeof progress.data === 'object' && !Array.isArray(progress.data))
        ? { ...progress.data }
        : {};

      // Parse tee_time to get month key
      const teeTime = ctx.roundData.tee_time;
      let monthKey, monthStart, monthEnd;
      if (teeTime && typeof teeTime.toDate === 'function') {
        const d = teeTime.toDate();
        monthKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        monthStart = new Date(d.getFullYear(), d.getMonth(), 1);
        monthEnd = new Date(d.getFullYear(), d.getMonth() + 1, 1);
      } else if (teeTime instanceof Date) {
        monthKey = `${teeTime.getFullYear()}-${String(teeTime.getMonth() + 1).padStart(2, '0')}`;
        monthStart = new Date(teeTime.getFullYear(), teeTime.getMonth(), 1);
        monthEnd = new Date(teeTime.getFullYear(), teeTime.getMonth() + 1, 1);
      } else {
        return { current: 0, target: 4, data: dataMap, completed: false };
      }

      // Increment round count for this month
      dataMap[monthKey] = (dataMap[monthKey] || 0) + 1;
      const gamesThisMonth = dataMap[monthKey];

      // Need at least 4 games in the month
      if (gamesThisMonth < 4) {
        return { current: gamesThisMonth, target: 4, data: dataMap, completed: false };
      }

      // Check cancellations
      try {
        const cancellationsSnap = await ctx.db
          .collection('users').doc(ctx.uid)
          .collection('cancellation_records')
          .where('cancelled_at', '>=', monthStart)
          .where('cancelled_at', '<', monthEnd)
          .limit(1)
          .get();

        const hasCancellations = !cancellationsSnap.empty;
        return {
          current: gamesThisMonth,
          target: 4,
          data: dataMap,
          completed: !hasCancellations,
        };
      } catch (err) {
        console.warn(`[Challenges] never_miss evaluate failed for ${ctx.uid}:`, err);
        return { current: gamesThisMonth, target: 4, data: dataMap, completed: false };
      }
    },
  },
];

// ── Lookup Map ──────────────────────────────────────────────────────────────

const CHALLENGES_BY_ID = {};
for (const c of CHALLENGES) {
  CHALLENGES_BY_ID[c.id] = c;
}

// ── Exports ─────────────────────────────────────────────────────────────────

module.exports = {
  CHALLENGES,
  CHALLENGES_BY_ID,
  getFormatKey,
  getSeasonRange,
};
