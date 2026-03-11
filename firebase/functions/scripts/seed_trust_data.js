/**
 * Seed Trust System Data for Firestore Emulator
 *
 * Run against the local Firestore emulator:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node firebase/functions/scripts/seed_trust_data.js
 *
 * Creates:
 *   - 5 test users (varying trust profiles)
 *   - 1 seed course
 *   - 3 test games (open, filled, played)
 *   - 8 game_participant records
 *   - 3 cancellation_records (one per tier: early, late, day_of)
 *   - 1 round_record (pending verification)
 *   - 3 pair_ratings
 */

"use strict";

process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "find-my-fourth" });

const db = admin.firestore();
const { Timestamp } = admin.firestore;

// Import pure tier helper from trust_system.js (no side effects, no initializeApp).
const { calculateCancellationTier } = require("../trust_system");

const now = new Date();
const DAY_MS = 24 * 60 * 60 * 1000;

function ts(offsetMs) {
  return Timestamp.fromMillis(now.getTime() + offsetMs);
}

// Remove null/undefined values before writing (mirrors Dart .withoutNulls behaviour).
function clean(obj) {
  return Object.fromEntries(
    Object.entries(obj).filter(([, v]) => v !== null && v !== undefined)
  );
}

// ── References ────────────────────────────────────────────────────────────────

const userRef = (id) => db.collection("users").doc(id);
const gameRef = (id) => db.collection("games").doc(id);
const courseRef = db.collection("course").doc("seed_course_1");

// ── Users ─────────────────────────────────────────────────────────────────────
// Alice: Anchor — 52 verified rounds, 21 unique co-players, 12 games hosted.
// Anchor badge requires: 50+ weighted rounds, 20+ unique co-players, 10+ hosted,
// under 10% cancellation rate. Alice legitimately qualifies.

const ALICE_CO_PLAYERS = Array.from({ length: 21 }, (_, i) => `player_${i + 10}`);

const users = [
  {
    id: "seed_user_1",
    uid: "seed_user_1",
    display_name: "Alice Driver",
    display_name_lower: "alice driver",
    display_name_lowercase: "alice driver",
    first_name: "Alice",
    last_name: "Driver",
    handicap: 8,
    home_course: "Pinehurst No. 2",
    badge_level: "anchor",
    show_up_rate: 0.97,
    total_verified_rounds: 52,
    games_hosted: 12,
    profile_completeness: 95,
    unique_co_players: ALICE_CO_PLAYERS,
    onboarding_completed: true,
    created_time: ts(-365 * DAY_MS),
    vibe_profile: { prefs: { pace: "medium", music: "low", drinks: "social" } },
  },
  {
    id: "seed_user_2",
    uid: "seed_user_2",
    display_name: "Bob Wedge",
    display_name_lower: "bob wedge",
    display_name_lowercase: "bob wedge",
    first_name: "Bob",
    last_name: "Wedge",
    handicap: 15,
    home_course: "Augusta National",
    badge_level: "regular",
    show_up_rate: 0.85,
    total_verified_rounds: 18,
    games_hosted: 4,
    profile_completeness: 80,
    unique_co_players: ["seed_user_1", "seed_user_3"],
    onboarding_completed: true,
    created_time: ts(-200 * DAY_MS),
    vibe_profile: { prefs: { pace: "fast", music: "off", drinks: "none" } },
  },
  {
    id: "seed_user_3",
    uid: "seed_user_3",
    display_name: "Carol Iron",
    display_name_lower: "carol iron",
    display_name_lowercase: "carol iron",
    first_name: "Carol",
    last_name: "Iron",
    handicap: 22,
    home_course: "Pebble Beach",
    badge_level: "confirmed",
    // show_up_rate intentionally absent — under 5 verified rounds
    total_verified_rounds: 3,
    games_hosted: 1,
    profile_completeness: 60,
    unique_co_players: ["seed_user_1"],
    onboarding_completed: true,
    created_time: ts(-90 * DAY_MS),
    vibe_profile: {},
  },
  {
    id: "seed_user_4",
    uid: "seed_user_4",
    display_name: "Dan Putter",
    display_name_lower: "dan putter",
    display_name_lowercase: "dan putter",
    first_name: "Dan",
    last_name: "Putter",
    handicap: 5,
    home_course: "St Andrews Old Course",
    badge_level: "starter",
    show_up_rate: 0.72,
    total_verified_rounds: 9,
    games_hosted: 2,
    profile_completeness: 70,
    unique_co_players: ["seed_user_1"],
    onboarding_completed: true,
    created_time: ts(-150 * DAY_MS),
    vibe_profile: { prefs: { pace: "slow", music: "high", drinks: "social" } },
  },
  {
    id: "seed_user_5",
    uid: "seed_user_5",
    display_name: "Eve Birdie",
    display_name_lower: "eve birdie",
    display_name_lowercase: "eve birdie",
    first_name: "Eve",
    last_name: "Birdie",
    handicap: 0,
    badge_level: "new",
    // show_up_rate absent — no rounds yet
    // home_course absent — profile incomplete
    total_verified_rounds: 0,
    games_hosted: 0,
    profile_completeness: 20,
    unique_co_players: [],
    onboarding_completed: false,
    created_time: ts(-7 * DAY_MS),
    vibe_profile: {},
  },
];

// ── Games ─────────────────────────────────────────────────────────────────────

const games = [
  {
    id: "seed_game_open",
    name_game: "Weekend Stroke Play",
    game_type: "Stroke Play",
    style_game: "Casual",
    course_play: "Pinehurst No. 2",
    courseRef: courseRef,
    userRef: userRef("seed_user_1"),
    uid: "seed_user_1",
    date: ts(3 * DAY_MS),
    status: "open",
    isCancelled: false,
    num_players: 1,
    max_players: 4,
    min_app_users: 2,
    app_user_count: 1,
    guest_count: 0,
    verification_status: "pending",
    joined_players: [userRef("seed_user_1")],
    guest_players: [],
    created_time: ts(-1 * DAY_MS),
    scoring: "Net",
    rules_setting: "Casual",
    friend_game: "public",
    member_discount: "",
    is_fun_game: true,
  },
  {
    id: "seed_game_filled",
    name_game: "Tuesday Match Play",
    game_type: "Match Play",
    style_game: "Low Stakes",
    course_play: "Augusta National",
    courseRef: courseRef,
    userRef: userRef("seed_user_2"),
    uid: "seed_user_2",
    date: ts(1 * DAY_MS),
    status: "filled",
    isCancelled: false,
    num_players: 4,
    max_players: 4,
    min_app_users: 2,
    app_user_count: 3,
    guest_count: 1,
    verification_status: "pending",
    joined_players: [
      userRef("seed_user_2"),
      userRef("seed_user_3"),
      userRef("seed_user_4"),
    ],
    guest_players: ["Guest Greg"],
    created_time: ts(-3 * DAY_MS),
    scoring: "Gross",
    rules_setting: "Competitive",
    friend_game: "public",
    member_discount: "",
    is_fun_game: false,
  },
  {
    id: "seed_game_played",
    name_game: "Last Saturday Round",
    game_type: "Stroke Play",
    style_game: "No Money",
    course_play: "Pebble Beach",
    courseRef: courseRef,
    userRef: userRef("seed_user_1"),
    uid: "seed_user_1",
    date: ts(-2 * DAY_MS),
    status: "played",
    isCancelled: false,
    num_players: 4,
    max_players: 4,
    min_app_users: 2,
    app_user_count: 4,
    guest_count: 0,
    verification_status: "pending",
    joined_players: [
      userRef("seed_user_1"),
      userRef("seed_user_2"),
      userRef("seed_user_3"),
      userRef("seed_user_4"),
    ],
    guest_players: [],
    created_time: ts(-7 * DAY_MS),
    scoring: "Net",
    rules_setting: "Casual",
    friend_game: "public",
    member_discount: "",
    is_fun_game: true,
  },
];

// ── Cancellation tier calculations ────────────────────────────────────────────
// Each scenario uses calculateCancellationTier so values match production logic.

// early: user_3 cancelled 60 hours before a tee time
const earlyTeeTimeMs = now.getTime() + 48 * 60 * 60 * 1000;
const earlyCancelledMs = now.getTime() - 12 * 60 * 60 * 1000;
const earlyTier = calculateCancellationTier(earlyCancelledMs, earlyTeeTimeMs);

// late: user_4 cancelled 20 hours before tee time
const lateTeeTimeMs = now.getTime() + 20 * 60 * 60 * 1000;
const lateCancelledMs = now.getTime();
const lateTier = calculateCancellationTier(lateCancelledMs, lateTeeTimeMs);

// day_of: user_5 cancelled 6 hours before tee time
const dayOfTeeTimeMs = now.getTime() + 6 * 60 * 60 * 1000;
const dayOfCancelledMs = now.getTime();
const dayOfTierResult = calculateCancellationTier(dayOfCancelledMs, dayOfTeeTimeMs);

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {
  console.log("Starting trust system seed...");

  // 1. Users
  const userBatch = db.batch();
  for (const user of users) {
    const { id, ...data } = user;
    userBatch.set(db.collection("users").doc(id), clean(data), { merge: true });
  }
  await userBatch.commit();
  console.log(`✓ ${users.length} users`);

  // 2. Course
  await courseRef.set({ name: "Pinehurst No. 2", picture: "" }, { merge: true });
  console.log("✓ 1 course");

  // 3. Games
  const gameBatch = db.batch();
  for (const game of games) {
    const { id, ...data } = game;
    gameBatch.set(db.collection("games").doc(id), clean(data));
  }
  await gameBatch.commit();
  console.log(`✓ ${games.length} games`);

  // 4. Game participants
  const participantBatch = db.batch();

  // seed_game_open: host = user_1
  participantBatch.set(
    db.collection("game_participants").doc("gp_open_1"),
    {
      game_ref: gameRef("seed_game_open"),
      user_ref: userRef("seed_user_1"),
      role: "host",
      status: "joined",
      joined_at: ts(-1 * DAY_MS),
    }
  );

  // seed_game_filled: host = user_2, players = user_3, user_4, guest
  participantBatch.set(
    db.collection("game_participants").doc("gp_filled_1"),
    {
      game_ref: gameRef("seed_game_filled"),
      user_ref: userRef("seed_user_2"),
      role: "host",
      status: "joined",
      joined_at: ts(-3 * DAY_MS),
    }
  );
  participantBatch.set(
    db.collection("game_participants").doc("gp_filled_2"),
    {
      game_ref: gameRef("seed_game_filled"),
      user_ref: userRef("seed_user_3"),
      role: "player",
      status: "joined",
      joined_at: ts(-2 * DAY_MS),
    }
  );
  participantBatch.set(
    db.collection("game_participants").doc("gp_filled_3"),
    {
      game_ref: gameRef("seed_game_filled"),
      user_ref: userRef("seed_user_4"),
      role: "player",
      status: "joined",
      joined_at: ts(-2 * DAY_MS),
    }
  );
  // Guest participant: no user_ref field (omitted entirely, not null)
  participantBatch.set(
    db.collection("game_participants").doc("gp_filled_guest"),
    {
      game_ref: gameRef("seed_game_filled"),
      guest_name: "Guest Greg",
      role: "guest",
      status: "joined",
      joined_at: ts(-1 * DAY_MS),
    }
  );

  // seed_game_played: all 4 app users
  for (let i = 1; i <= 4; i++) {
    participantBatch.set(
      db.collection("game_participants").doc(`gp_played_${i}`),
      {
        game_ref: gameRef("seed_game_played"),
        user_ref: userRef(`seed_user_${i}`),
        role: i === 1 ? "host" : "player",
        status: "joined",
        joined_at: ts(-(8 - i) * DAY_MS),
      }
    );
  }

  await participantBatch.commit();
  console.log("✓ 8 game_participants");

  // 5. Cancellation records (one per tier)
  const cancelBatch = db.batch();

  cancelBatch.set(db.collection("cancellation_records").doc("cr_early"), {
    player_ref: userRef("seed_user_3"),
    game_ref: gameRef("seed_game_open"),
    cancelled_at: Timestamp.fromMillis(earlyCancelledMs),
    tee_time: Timestamp.fromMillis(earlyTeeTimeMs),
    hours_before_tee_time: earlyTier.hoursBeforeTeeTime,
    tier: earlyTier.tier,
    game_type: "Stroke Play",
    is_ghost: false,
  });

  cancelBatch.set(db.collection("cancellation_records").doc("cr_late"), {
    player_ref: userRef("seed_user_4"),
    game_ref: gameRef("seed_game_filled"),
    cancelled_at: Timestamp.fromMillis(lateCancelledMs),
    tee_time: Timestamp.fromMillis(lateTeeTimeMs),
    hours_before_tee_time: lateTier.hoursBeforeTeeTime,
    tier: lateTier.tier,
    game_type: "Match Play",
    is_ghost: false,
  });

  cancelBatch.set(db.collection("cancellation_records").doc("cr_day_of"), {
    player_ref: userRef("seed_user_5"),
    game_ref: gameRef("seed_game_open"),
    cancelled_at: Timestamp.fromMillis(dayOfCancelledMs),
    tee_time: Timestamp.fromMillis(dayOfTeeTimeMs),
    hours_before_tee_time: dayOfTierResult.hoursBeforeTeeTime,
    tier: dayOfTierResult.tier,
    game_type: "Stroke Play",
    is_ghost: false,
  });

  await cancelBatch.commit();
  console.log(
    `✓ 3 cancellation_records: ` +
    `cr_early (${earlyTier.tier}, ${earlyTier.hoursBeforeTeeTime.toFixed(1)}h), ` +
    `cr_late (${lateTier.tier}, ${lateTier.hoursBeforeTeeTime.toFixed(1)}h), ` +
    `cr_day_of (${dayOfTierResult.tier}, ${dayOfTierResult.hoursBeforeTeeTime.toFixed(1)}h)`
  );

  // 6. Round record
  const roundRef = db.collection("round_records").doc("rr_played_1");
  await roundRef.set({
    game_ref: gameRef("seed_game_played"),
    course_ref: courseRef,
    tee_time: ts(-2 * DAY_MS),
    game_type: "Stroke Play",
    game_settings: {
      scoring: "Net",
      rules_setting: "Casual",
      style_game: "No Money",
      friend_game: "public",
    },
    participant_snapshots: [
      { uid: "seed_user_1", display_name: "Alice Driver", handicap: 8, badge_level: "anchor" },
      { uid: "seed_user_2", display_name: "Bob Wedge", handicap: 15, badge_level: "regular" },
      { uid: "seed_user_3", display_name: "Carol Iron", handicap: 22, badge_level: "confirmed" },
      { uid: "seed_user_4", display_name: "Dan Putter", handicap: 5, badge_level: "starter" },
    ],
    // vibe_match_scores: keyed by sorted pair UID ("uid_a:uid_b").
    // Placeholder scores — will be populated by game-join flow in a later stage.
    vibe_match_scores: {
      "seed_user_1:seed_user_2": 0.82,
      "seed_user_1:seed_user_3": 0.61,
      "seed_user_1:seed_user_4": 0.74,
      "seed_user_2:seed_user_3": 0.55,
      "seed_user_2:seed_user_4": 0.68,
      "seed_user_3:seed_user_4": 0.49,
    },
    verification_status: "pending",
    confirmed_player_refs: [
      userRef("seed_user_1"),
      userRef("seed_user_2"),
      userRef("seed_user_3"),
      userRef("seed_user_4"),
    ],
    attendance_records: {
      seed_user_1: "pending",
      seed_user_2: "pending",
      seed_user_3: "pending",
      seed_user_4: "pending",
    },
  });
  console.log("✓ 1 round_record");

  // 7. Pair ratings
  const ratingsBatch = db.batch();

  ratingsBatch.set(db.collection("pair_ratings").doc("pr_1_rates_2"), {
    rater_ref: userRef("seed_user_1"),
    rated_ref: userRef("seed_user_2"),
    game_ref: gameRef("seed_game_played"),
    round_ref: roundRef,
    would_play_again: true,
    rated_at: ts(-1 * DAY_MS),
    game_type: "Stroke Play",
  });
  ratingsBatch.set(db.collection("pair_ratings").doc("pr_2_rates_1"), {
    rater_ref: userRef("seed_user_2"),
    rated_ref: userRef("seed_user_1"),
    game_ref: gameRef("seed_game_played"),
    round_ref: roundRef,
    would_play_again: true,
    rated_at: ts(-1 * DAY_MS),
    game_type: "Stroke Play",
  });
  ratingsBatch.set(db.collection("pair_ratings").doc("pr_3_rates_4"), {
    rater_ref: userRef("seed_user_3"),
    rated_ref: userRef("seed_user_4"),
    game_ref: gameRef("seed_game_played"),
    round_ref: roundRef,
    would_play_again: false,
    rated_at: ts(-1 * DAY_MS),
    game_type: "Stroke Play",
  });

  await ratingsBatch.commit();
  console.log("✓ 3 pair_ratings");

  console.log("\nSeed complete.");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
