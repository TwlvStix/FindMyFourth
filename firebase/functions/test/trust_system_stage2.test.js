/**
 * Trust System — Stage 2 Tests
 *
 * Tests for strike accumulation logic, pattern detection, restriction ladder,
 * and all boundary conditions.
 *
 * Run with: npm test (from firebase/functions directory)
 * or: npx jest test/trust_system_stage2.test.js
 *
 * These tests use manual mocks for Firebase Admin SDK — no live Firestore needed.
 */

"use strict";

// ─────────────────────────────────────────────────────────────────────────────
// MOCK SETUP
// Must happen before requiring the module under test.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Minimal in-memory Firestore mock.
 * Supports: collection, doc, add, get, where, orderBy.
 * Documents are stored in a flat map: collectionName → docId → data.
 */
class MockTimestamp {
  constructor(ms) {
    this._ms = ms;
  }
  toMillis() {
    return this._ms;
  }
  toDate() {
    return new Date(this._ms);
  }
  static fromMillis(ms) {
    return new MockTimestamp(ms);
  }
  // Support Firestore comparison operators in where() filters.
  valueOf() {
    return this._ms;
  }
}

class MockDocRef {
  constructor(db, collectionName, id) {
    this._db = db;
    this._collection = collectionName;
    this.id = id;
    this.path = `${collectionName}/${id}`;
  }
  async get() {
    const col = this._db._collections[this._collection] || {};
    const data = col[this.id];
    return {
      exists: !!data,
      id: this.id,
      ref: this,
      data: () => (data ? { ...data } : undefined),
    };
  }
}

class MockQuery {
  constructor(collectionRef) {
    this._colRef = collectionRef;
    this._filters = [];
    this._orderField = null;
    this._orderDir = "asc";
  }
  where(field, op, value) {
    const clone = new MockQuery(this._colRef);
    clone._filters = [...this._filters, { field, op, value }];
    clone._orderField = this._orderField;
    clone._orderDir = this._orderDir;
    return clone;
  }
  orderBy(field, dir = "asc") {
    const clone = new MockQuery(this._colRef);
    clone._filters = [...this._filters];
    clone._orderField = field;
    clone._orderDir = dir;
    return clone;
  }
  async get() {
    const col = this._colRef._db._collections[this._colRef._name] || {};
    let docs = Object.entries(col).map(([id, data]) => ({
      id,
      data: () => ({ ...data }),
      ref: new MockDocRef(this._colRef._db, this._colRef._name, id),
    }));

    for (const { field, op, value } of this._filters) {
      docs = docs.filter((doc) => {
        const docVal = getNestedField(doc.data(), field);
        const compareVal = value instanceof MockTimestamp ? value.toMillis() :
          (value && typeof value.toMillis === "function" ? value.toMillis() : value);
        const docMs = docVal instanceof MockTimestamp ? docVal.toMillis() :
          (docVal && typeof docVal.toMillis === "function" ? docVal.toMillis() : docVal);

        switch (op) {
          case "==": {
            // DocumentReference equality by id
            if (typeof docMs === "object" && docMs !== null && "id" in docMs) {
              return docMs.id === (compareVal && compareVal.id ? compareVal.id : compareVal);
            }
            if (typeof compareVal === "object" && compareVal !== null && "id" in compareVal) {
              return (docVal && docVal.id) === compareVal.id;
            }
            return docVal === compareVal;
          }
          case ">": return docMs > compareVal;
          case ">=": return docMs >= compareVal;
          case "<": return docMs < compareVal;
          case "<=": return docMs <= compareVal;
          default: return true;
        }
      });
    }

    return { docs, size: docs.length, empty: docs.length === 0 };
  }
}

function getNestedField(obj, field) {
  return field.split(".").reduce((o, k) => (o && o[k] !== undefined ? o[k] : undefined), obj);
}

class MockCollectionRef {
  constructor(db, name) {
    this._db = db;
    this._name = name;
  }
  doc(id) {
    const docId = id || `auto_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    return new MockDocRef(this._db, this._name, docId);
  }
  async add(data) {
    const col = this._db._collections[this._name] || {};
    const id = `auto_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    col[id] = { ...data };
    this._db._collections[this._name] = col;
    return new MockDocRef(this._db, this._name, id);
  }
  where(field, op, value) {
    return new MockQuery(this).where(field, op, value);
  }
  orderBy(field, dir) {
    return new MockQuery(this).orderBy(field, dir);
  }
}

class MockFirestore {
  constructor() {
    this._collections = {};
  }
  collection(name) {
    return new MockCollectionRef(this, name);
  }
  reset() {
    this._collections = {};
  }
  // Seed a document directly for test setup.
  seedDoc(collectionName, id, data) {
    if (!this._collections[collectionName]) {
      this._collections[collectionName] = {};
    }
    this._collections[collectionName][id] = { ...data };
  }
}

// Stub firebase-functions before requiring the module.
const mockCallableHandler = {};
const functions = {
  region: () => functions,
  https: {
    onCall: (handler) => {
      // Return a wrapper that calls the handler directly (for unit tests).
      const fn = handler;
      fn._handler = handler;
      return fn;
    },
    HttpsError: class HttpsError extends Error {
      constructor(code, message) {
        super(message);
        this.code = code;
      }
    },
  },
  firestore: {
    document: () => ({ onCreate: (handler) => handler }),
  },
};

// Stub firebase-admin.
const mockDb = new MockFirestore();
const admin = {
  firestore: () => mockDb,
  initializeApp: () => {},
};
admin.firestore.Timestamp = MockTimestamp;

// Inject mocks before require.
const Module = require("module");
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === "firebase-functions") return functions;
  if (request === "firebase-admin") return admin;
  return originalLoad.apply(this, arguments);
};

// Now load the module under test.
const trustSystem = require("../trust_system");

const {
  calculateCancellationTier,
  getRestrictionForStrikes,
  recordStrike,
  checkLateCancelPattern,
  getActiveStrikeCount,
  LATE_CANCEL_WINDOW_MS,
  STRIKE_EXPIRY_MS,
  LATE_CANCEL_STRIKE_THRESHOLD,
} = trustSystem;

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const DAY_MS = 24 * 60 * 60 * 1000;
const HOUR_MS = 60 * 60 * 1000;

/** Returns epoch ms for N days ago relative to a base time. */
function daysAgo(base, days) {
  return base - days * DAY_MS;
}

/** Returns epoch ms for N hours in the future relative to a base time. */
function hoursFromNow(base, hours) {
  return base + hours * HOUR_MS;
}

/** Returns epoch ms for N hours in the past relative to a base time. */
function hoursAgo(base, hours) {
  return base - hours * HOUR_MS;
}

/** Creates a mock player DocumentReference. */
function playerRef(id) {
  return { id, path: `users/${id}` };
}

/** Creates a mock game DocumentReference. */
function gameRef(id) {
  return { id, path: `games/${id}` };
}

/**
 * Seeds a cancellation_records document with tier='late' in the mock DB.
 * cancelledAtMs defaults to nowMs.
 */
function seedLateCancel(db, playerId, gameId, cancelledAtMs) {
  const id = `cancel_${playerId}_${gameId}_${cancelledAtMs}`;
  db.seedDoc("cancellation_records", id, {
    player_ref: playerRef(playerId),
    game_ref: gameRef(gameId),
    tier: "late",
    cancelled_at: MockTimestamp.fromMillis(cancelledAtMs),
    is_ghost: false,
  });
  return id;
}

let _strikeSeq = 0;

/**
 * Seeds a strike document in the mock DB with a guaranteed-unique ID.
 */
function seedStrike(db, playerId, reason, createdAtMs, expiresAtMs) {
  _strikeSeq += 1;
  const id = `strike_${playerId}_${reason}_${createdAtMs}_${_strikeSeq}`;
  db.seedDoc("strikes", id, {
    player_ref: playerRef(playerId),
    game_ref: gameRef("game1"),
    reason,
    created_at: MockTimestamp.fromMillis(createdAtMs),
    expires_at: MockTimestamp.fromMillis(expiresAtMs),
    is_expired: false,
    cancellation_record_id: null,
  });
  return id;
}

// ─────────────────────────────────────────────────────────────────────────────
// TEST SUITE
// ─────────────────────────────────────────────────────────────────────────────

// Reset the DB and sequence counter before each test.
beforeEach(() => {
  mockDb.reset();
  _strikeSeq = 0;
});

// ─── calculateCancellationTier ────────────────────────────────────────────────

describe("calculateCancellationTier", () => {
  const baseMs = 1_700_000_000_000; // Fixed anchor for determinism

  test("exactly 36 hours before → early", () => {
    const teeTimeMs = hoursFromNow(baseMs, 36);
    const { tier, hoursBeforeTeeTime } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("early");
    expect(hoursBeforeTeeTime).toBe(36);
  });

  test("36.001 hours before → early", () => {
    const teeTimeMs = baseMs + 36 * HOUR_MS + 3_600; // 36h + 1s
    const { tier } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("early");
  });

  test("35.999 hours before → late", () => {
    const teeTimeMs = baseMs + 36 * HOUR_MS - 3_600; // 36h - 1s
    const { tier } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("late");
  });

  test("exactly 12 hours before → late", () => {
    const teeTimeMs = hoursFromNow(baseMs, 12);
    const { tier, hoursBeforeTeeTime } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("late");
    expect(hoursBeforeTeeTime).toBe(12);
  });

  test("12.001 hours before → late", () => {
    const teeTimeMs = baseMs + 12 * HOUR_MS + 3_600;
    const { tier } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("late");
  });

  test("11.999 hours before → day_of", () => {
    const teeTimeMs = baseMs + 12 * HOUR_MS - 3_600;
    const { tier } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("day_of");
  });

  test("1 hour before → day_of", () => {
    const teeTimeMs = hoursFromNow(baseMs, 1);
    const { tier } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("day_of");
  });

  test("0 hours (right at tee time) → day_of", () => {
    const { tier, hoursBeforeTeeTime } = calculateCancellationTier(baseMs, baseMs);
    expect(tier).toBe("day_of");
    expect(hoursBeforeTeeTime).toBe(0);
  });

  test("after tee time (negative hours) → day_of", () => {
    const teeTimeMs = hoursAgo(baseMs, 2);
    const { tier, hoursBeforeTeeTime } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("day_of");
    expect(hoursBeforeTeeTime).toBe(-2);
  });

  test("5 days before → early", () => {
    const teeTimeMs = hoursFromNow(baseMs, 5 * 24);
    const { tier } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(tier).toBe("early");
  });

  test("returns hoursBeforeTeeTime as fractional hours", () => {
    const teeTimeMs = baseMs + 24.5 * HOUR_MS;
    const { hoursBeforeTeeTime } = calculateCancellationTier(baseMs, teeTimeMs);
    expect(hoursBeforeTeeTime).toBeCloseTo(24.5, 3);
  });
});

// ─── getRestrictionForStrikes ─────────────────────────────────────────────────

describe("getRestrictionForStrikes", () => {
  test("0 strikes → none, no restriction, not manual review", () => {
    const r = getRestrictionForStrikes(0);
    expect(r.level).toBe("none");
    expect(r.strikeCount).toBe(0);
    expect(r.durationMs).toBeNull();
    expect(r.requiresManualReview).toBe(false);
  });

  test("negative strikes treated same as 0 → none", () => {
    const r = getRestrictionForStrikes(-1);
    expect(r.level).toBe("none");
  });

  test("1 strike → warning, no durationMs, no manual review", () => {
    const r = getRestrictionForStrikes(1);
    expect(r.level).toBe("warning");
    expect(r.strikeCount).toBe(1);
    expect(r.durationMs).toBeNull();
    expect(r.requiresManualReview).toBe(false);
  });

  test("2 strikes → cooldown, 24 hours, no manual review", () => {
    const r = getRestrictionForStrikes(2);
    expect(r.level).toBe("cooldown");
    expect(r.strikeCount).toBe(2);
    expect(r.durationMs).toBe(24 * 60 * 60 * 1000);
    expect(r.requiresManualReview).toBe(false);
  });

  test("3 strikes → restricted, 7 days, no manual review", () => {
    const r = getRestrictionForStrikes(3);
    expect(r.level).toBe("restricted");
    expect(r.strikeCount).toBe(3);
    expect(r.durationMs).toBe(7 * 24 * 60 * 60 * 1000);
    expect(r.requiresManualReview).toBe(false);
  });

  test("4 strikes → restricted, 30 days, manual review required", () => {
    const r = getRestrictionForStrikes(4);
    expect(r.level).toBe("restricted");
    expect(r.strikeCount).toBe(4);
    expect(r.durationMs).toBe(30 * 24 * 60 * 60 * 1000);
    expect(r.requiresManualReview).toBe(true);
  });

  test("5 strikes → suspended, no duration, manual review", () => {
    const r = getRestrictionForStrikes(5);
    expect(r.level).toBe("suspended");
    expect(r.strikeCount).toBe(5);
    expect(r.durationMs).toBeNull();
    expect(r.requiresManualReview).toBe(true);
  });

  test("6 strikes → suspended", () => {
    const r = getRestrictionForStrikes(6);
    expect(r.level).toBe("suspended");
    expect(r.strikeCount).toBe(6);
  });

  test("10 strikes → suspended with correct count in message", () => {
    const r = getRestrictionForStrikes(10);
    expect(r.level).toBe("suspended");
    expect(r.message).toContain("10");
  });

  test("each level has a non-empty message string", () => {
    for (let i = 0; i <= 6; i++) {
      const r = getRestrictionForStrikes(i);
      expect(typeof r.message).toBe("string");
      expect(r.message.length).toBeGreaterThan(0);
    }
  });
});

// ─── recordStrike ─────────────────────────────────────────────────────────────

describe("recordStrike", () => {
  const nowMs = 1_700_000_000_000;

  test("writes a strike document and returns a DocumentReference with id", async () => {
    const pRef = playerRef("user1");
    const gRef = gameRef("game1");
    const ref = await recordStrike(mockDb, {
      playerRef: pRef,
      gameRef: gRef,
      reason: "day_of_cancel",
      cancellationRecordId: "cancel1",
      nowMs,
    });
    expect(ref).toBeDefined();
    expect(typeof ref.id).toBe("string");
    expect(ref.id.length).toBeGreaterThan(0);
  });

  test("stores expires_at 6 months (180 days) after created_at", async () => {
    const pRef = playerRef("user1");
    const gRef = gameRef("game1");
    const ref = await recordStrike(mockDb, {
      playerRef: pRef,
      gameRef: gRef,
      reason: "day_of_cancel",
      cancellationRecordId: null,
      nowMs,
    });
    const storedData = mockDb._collections["strikes"][ref.id];
    expect(storedData.expires_at.toMillis()).toBe(nowMs + STRIKE_EXPIRY_MS);
    expect(storedData.created_at.toMillis()).toBe(nowMs);
  });

  test("stores reason correctly", async () => {
    const ref = await recordStrike(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game1"),
      reason: "ghost_no_show",
      cancellationRecordId: "cancelXYZ",
      nowMs,
    });
    const storedData = mockDb._collections["strikes"][ref.id];
    expect(storedData.reason).toBe("ghost_no_show");
    expect(storedData.cancellation_record_id).toBe("cancelXYZ");
    expect(storedData.is_expired).toBe(false);
  });

  test("null cancellationRecordId stored as null", async () => {
    const ref = await recordStrike(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game1"),
      reason: "late_cancel_pattern",
      cancellationRecordId: null,
      nowMs,
    });
    const storedData = mockDb._collections["strikes"][ref.id];
    expect(storedData.cancellation_record_id).toBeNull();
  });

  test("two strikes written in parallel get different IDs", async () => {
    const pRef = playerRef("user1");
    const gRef = gameRef("game1");
    const [ref1, ref2] = await Promise.all([
      recordStrike(mockDb, { playerRef: pRef, gameRef: gRef, reason: "ghost_no_show", cancellationRecordId: null, nowMs }),
      recordStrike(mockDb, { playerRef: pRef, gameRef: gRef, reason: "ghost_no_show", cancellationRecordId: null, nowMs }),
    ]);
    expect(ref1.id).not.toBe(ref2.id);
  });
});

// ─── getActiveStrikeCount ──────────────────────────────────────────────────────

describe("getActiveStrikeCount", () => {
  const nowMs = 1_700_000_000_000;

  test("returns 0 when no strikes exist", async () => {
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("counts active (non-expired) strike", async () => {
    // Strike expires 1 day in the future
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - DAY_MS, nowMs + DAY_MS);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(1);
  });

  test("does not count expired strike (expires_at <= nowMs)", async () => {
    // Strike expired 1 second ago
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 10 * DAY_MS, nowMs - 1_000);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("does not count strike expiring exactly at nowMs", async () => {
    // expires_at == nowMs: the filter is > so this should NOT be counted
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - DAY_MS, nowMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("counts multiple active strikes", async () => {
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 1 * DAY_MS, nowMs + 30 * DAY_MS);
    seedStrike(mockDb, "user1", "late_cancel_pattern", nowMs - 2 * DAY_MS, nowMs + 60 * DAY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - 3 * DAY_MS, nowMs + 90 * DAY_MS);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(3);
  });

  test("only counts strikes for the correct player", async () => {
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - DAY_MS, nowMs + DAY_MS);
    seedStrike(mockDb, "user2", "day_of_cancel", nowMs - DAY_MS, nowMs + DAY_MS);
    const count1 = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    const count2 = await getActiveStrikeCount(mockDb, playerRef("user2"), nowMs);
    expect(count1).toBe(1);
    expect(count2).toBe(1);
  });

  test("6-month rolling window: strike just within 180 days counts", async () => {
    const createdAtMs = nowMs - STRIKE_EXPIRY_MS + 1_000; // 1 second before expiry
    const expiresAtMs = createdAtMs + STRIKE_EXPIRY_MS;
    seedStrike(mockDb, "user1", "day_of_cancel", createdAtMs, expiresAtMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(1);
  });

  test("6-month rolling window: strike exactly at 180-day expiry does not count", async () => {
    const createdAtMs = nowMs - STRIKE_EXPIRY_MS;
    const expiresAtMs = nowMs; // Exactly at now
    seedStrike(mockDb, "user1", "day_of_cancel", createdAtMs, expiresAtMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("mix of active and expired strikes → only active counted", async () => {
    // 2 active
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 1 * DAY_MS, nowMs + 10 * DAY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - 2 * DAY_MS, nowMs + 20 * DAY_MS);
    // 3 expired
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 200 * DAY_MS, nowMs - 20 * DAY_MS);
    seedStrike(mockDb, "user1", "late_cancel_pattern", nowMs - 190 * DAY_MS, nowMs - 10 * DAY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - 181 * DAY_MS, nowMs - 1 * DAY_MS);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(2);
  });
});

// ─── checkLateCancelPattern ───────────────────────────────────────────────────

describe("checkLateCancelPattern", () => {
  const nowMs = 1_700_000_000_000;

  test("1 late cancel in window → no strike", async () => {
    seedLateCancel(mockDb, "user1", "game1", nowMs - 1 * DAY_MS);
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game1"),
      cancellationRecordId: "cancel1",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("2 late cancels in window → no strike", async () => {
    seedLateCancel(mockDb, "user1", "game1", nowMs - 10 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game2", nowMs - 5 * DAY_MS);
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game3"),
      cancellationRecordId: "cancel3",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("exactly 3 late cancels in 90-day window → 1 strike issued", async () => {
    seedLateCancel(mockDb, "user1", "game1", nowMs - 80 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game2", nowMs - 40 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game3", nowMs - 1 * DAY_MS);
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game4"),
      cancellationRecordId: "cancel4",
      nowMs,
    });
    expect(result).not.toBeNull();
    expect(typeof result.id).toBe("string");
    const strike = mockDb._collections["strikes"][result.id];
    expect(strike.reason).toBe("late_cancel_pattern");
  });

  test("3rd late cancel lands exactly on 90-day boundary (inclusive) → strike", async () => {
    const windowStart = nowMs - LATE_CANCEL_WINDOW_MS;
    seedLateCancel(mockDb, "user1", "game1", windowStart); // exactly at boundary
    seedLateCancel(mockDb, "user1", "game2", nowMs - 45 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game3", nowMs - 1 * DAY_MS);
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game4"),
      cancellationRecordId: "cancel4",
      nowMs,
    });
    expect(result).not.toBeNull();
  });

  test("cancel just outside 90-day window → does not count", async () => {
    const justOutside = nowMs - LATE_CANCEL_WINDOW_MS - 1_000; // 1 second before window
    seedLateCancel(mockDb, "user1", "game1", justOutside);
    seedLateCancel(mockDb, "user1", "game2", nowMs - 45 * DAY_MS);
    // Only 2 in window — should not trigger
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game3"),
      cancellationRecordId: "cancel3",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("4th late cancel after a strike was already issued → no new strike (still at 1 batch)", async () => {
    seedLateCancel(mockDb, "user1", "game1", nowMs - 80 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game2", nowMs - 60 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game3", nowMs - 40 * DAY_MS);
    // Simulate the strike that was issued for the 1st batch of 3
    seedStrike(mockDb, "user1", "late_cancel_pattern", nowMs - 40 * DAY_MS, nowMs + 140 * DAY_MS);
    // 4th late cancel — still only 1 complete batch of 3, strike already issued
    seedLateCancel(mockDb, "user1", "game4", nowMs - 1 * DAY_MS);
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game5"),
      cancellationRecordId: "cancel5",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("6 late cancels with 1 prior pattern strike → issues 1 more (covers batch 2)", async () => {
    for (let i = 1; i <= 5; i++) {
      seedLateCancel(mockDb, "user1", `game${i}`, nowMs - i * 10 * DAY_MS);
    }
    // Strike already issued for first batch of 3
    seedStrike(mockDb, "user1", "late_cancel_pattern", nowMs - 30 * DAY_MS, nowMs + 150 * DAY_MS);
    // 6th cancel triggers 2nd batch
    seedLateCancel(mockDb, "user1", "game6", nowMs - 1 * DAY_MS);
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game7"),
      cancellationRecordId: "cancel7",
      nowMs,
    });
    expect(result).not.toBeNull();
    const strike = mockDb._collections["strikes"][result.id];
    expect(strike.reason).toBe("late_cancel_pattern");
  });

  test("early cancels do not count toward the late cancel pattern", async () => {
    // Seed early cancels — these have tier='early', not 'late'
    const ids = ["e1", "e2", "e3"];
    ids.forEach((id, i) => {
      mockDb.seedDoc("cancellation_records", id, {
        player_ref: playerRef("user1"),
        game_ref: gameRef(`game${i}`),
        tier: "early",
        cancelled_at: MockTimestamp.fromMillis(nowMs - (i + 1) * DAY_MS),
        is_ghost: false,
      });
    });
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game4"),
      cancellationRecordId: "cancel4",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("day_of cancels do not count toward the late cancel pattern", async () => {
    const ids = ["d1", "d2", "d3"];
    ids.forEach((id, i) => {
      mockDb.seedDoc("cancellation_records", id, {
        player_ref: playerRef("user1"),
        game_ref: gameRef(`game${i}`),
        tier: "day_of",
        cancelled_at: MockTimestamp.fromMillis(nowMs - (i + 1) * DAY_MS),
        is_ghost: false,
      });
    });
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game4"),
      cancellationRecordId: "cancel4",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("late cancels for different players don't cross-contaminate", async () => {
    // user2 has 3 late cancels
    seedLateCancel(mockDb, "user2", "game1", nowMs - 70 * DAY_MS);
    seedLateCancel(mockDb, "user2", "game2", nowMs - 40 * DAY_MS);
    seedLateCancel(mockDb, "user2", "game3", nowMs - 10 * DAY_MS);
    // user1 has 0
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game4"),
      cancellationRecordId: "cancel1",
      nowMs,
    });
    expect(result).toBeNull();
  });
});

// ─── Strike accumulation scenarios ───────────────────────────────────────────

describe("Strike accumulation — integrated scenarios", () => {
  const nowMs = 1_700_000_000_000;

  test("Scenario: ghost no-show → 2 strikes → restriction = restricted (3+ not hit, but 2 = cooldown)", async () => {
    // Fresh player, gets 2 ghost strikes
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - HOUR_MS, nowMs + STRIKE_EXPIRY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - HOUR_MS, nowMs + STRIKE_EXPIRY_MS);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(2);
    const r = getRestrictionForStrikes(count);
    expect(r.level).toBe("cooldown");
  });

  test("Scenario: day-of cancel + ghost no-show → 3 strikes → 7-day restriction", async () => {
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 2 * DAY_MS, nowMs + 178 * DAY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - HOUR_MS, nowMs + STRIKE_EXPIRY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - HOUR_MS, nowMs + STRIKE_EXPIRY_MS);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(3);
    const r = getRestrictionForStrikes(count);
    expect(r.level).toBe("restricted");
    expect(r.durationMs).toBe(7 * DAY_MS);
  });

  test("Scenario: 4 strikes → 30-day restriction and manual review", async () => {
    for (let i = 0; i < 4; i++) {
      seedStrike(mockDb, "user1", "day_of_cancel", nowMs - i * DAY_MS, nowMs + STRIKE_EXPIRY_MS);
    }
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(4);
    const r = getRestrictionForStrikes(count);
    expect(r.level).toBe("restricted");
    expect(r.durationMs).toBe(30 * DAY_MS);
    expect(r.requiresManualReview).toBe(true);
  });

  test("Scenario: 5 strikes → suspended", async () => {
    for (let i = 0; i < 5; i++) {
      seedStrike(mockDb, "user1", "ghost_no_show", nowMs - i * DAY_MS, nowMs + STRIKE_EXPIRY_MS);
    }
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(5);
    const r = getRestrictionForStrikes(count);
    expect(r.level).toBe("suspended");
    expect(r.requiresManualReview).toBe(true);
  });

  test("Scenario: strikes expire over time → player returns to good standing", async () => {
    // All strikes expired
    for (let i = 0; i < 5; i++) {
      seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 200 * DAY_MS, nowMs - 20 * DAY_MS);
    }
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
    const r = getRestrictionForStrikes(count);
    expect(r.level).toBe("none");
  });

  test("Scenario: partial expiry — 3 active, 2 expired → restricted (7-day)", async () => {
    // 3 active
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 1 * DAY_MS, nowMs + 179 * DAY_MS);
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 2 * DAY_MS, nowMs + 178 * DAY_MS);
    seedStrike(mockDb, "user1", "late_cancel_pattern", nowMs - 3 * DAY_MS, nowMs + 177 * DAY_MS);
    // 2 expired
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - 200 * DAY_MS, nowMs - 20 * DAY_MS);
    seedStrike(mockDb, "user1", "ghost_no_show", nowMs - 190 * DAY_MS, nowMs - 10 * DAY_MS);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(3);
    const r = getRestrictionForStrikes(count);
    expect(r.level).toBe("restricted");
    expect(r.durationMs).toBe(7 * DAY_MS);
  });
});

// ─── Restriction window timing ─────────────────────────────────────────────────

describe("Restriction timing", () => {
  test("2-strike cooldown: 24-hour duration is correct in ms", () => {
    const r = getRestrictionForStrikes(2);
    expect(r.durationMs).toBe(86_400_000); // 24 * 60 * 60 * 1000
  });

  test("3-strike restriction: 7-day duration is correct in ms", () => {
    const r = getRestrictionForStrikes(3);
    expect(r.durationMs).toBe(604_800_000); // 7 * 24 * 60 * 60 * 1000
  });

  test("4-strike restriction: 30-day duration is correct in ms", () => {
    const r = getRestrictionForStrikes(4);
    expect(r.durationMs).toBe(2_592_000_000); // 30 * 24 * 60 * 60 * 1000
  });
});

// ─── STRIKE_EXPIRY_MS constant ────────────────────────────────────────────────

describe("Constants", () => {
  test("STRIKE_EXPIRY_MS is 180 days", () => {
    expect(STRIKE_EXPIRY_MS).toBe(180 * 24 * 60 * 60 * 1000);
  });

  test("LATE_CANCEL_WINDOW_MS is 90 days", () => {
    expect(LATE_CANCEL_WINDOW_MS).toBe(90 * 24 * 60 * 60 * 1000);
  });

  test("LATE_CANCEL_STRIKE_THRESHOLD is 3", () => {
    expect(LATE_CANCEL_STRIKE_THRESHOLD).toBe(3);
  });
});

// ─── Edge cases and boundary conditions ───────────────────────────────────────

describe("Edge cases", () => {
  const nowMs = 1_700_000_000_000;

  test("Late cancel window boundary: cancel at exactly window start is included", () => {
    // The window filter is >= windowStart. Cancel exactly at windowStart should be in window.
    const windowStart = nowMs - LATE_CANCEL_WINDOW_MS;
    const result = MockTimestamp.fromMillis(windowStart);
    // Verify that >= check includes the boundary
    expect(result.toMillis() >= MockTimestamp.fromMillis(windowStart).toMillis()).toBe(true);
  });

  test("recordStrike: expires_at is strictly after created_at", async () => {
    const ref = await recordStrike(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game1"),
      reason: "day_of_cancel",
      cancellationRecordId: null,
      nowMs,
    });
    const data = mockDb._collections["strikes"][ref.id];
    expect(data.expires_at.toMillis()).toBeGreaterThan(data.created_at.toMillis());
  });

  test("getActiveStrikeCount: strike expiring 1ms in the future counts", async () => {
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - DAY_MS, nowMs + 1);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(1);
  });

  test("getActiveStrikeCount: strike expiring exactly now does NOT count (> not >=)", async () => {
    seedStrike(mockDb, "user1", "day_of_cancel", nowMs - DAY_MS, nowMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("Player with no cancellation records → checkLateCancelPattern returns null", async () => {
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("new_user"),
      gameRef: gameRef("game1"),
      cancellationRecordId: "cancel1",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("Ghost no-show does not affect late cancel pattern count", async () => {
    // Seed 2 late + 2 ghost cancels (ghosts have tier='day_of')
    seedLateCancel(mockDb, "user1", "game1", nowMs - 20 * DAY_MS);
    seedLateCancel(mockDb, "user1", "game2", nowMs - 10 * DAY_MS);
    mockDb.seedDoc("cancellation_records", "ghost1", {
      player_ref: playerRef("user1"),
      game_ref: gameRef("game3"),
      tier: "day_of",
      cancelled_at: MockTimestamp.fromMillis(nowMs - 5 * DAY_MS),
      is_ghost: true,
    });
    mockDb.seedDoc("cancellation_records", "ghost2", {
      player_ref: playerRef("user1"),
      game_ref: gameRef("game4"),
      tier: "day_of",
      cancelled_at: MockTimestamp.fromMillis(nowMs - 2 * DAY_MS),
      is_ghost: true,
    });
    // Only 2 late cancels — should not trigger strike
    const result = await checkLateCancelPattern(mockDb, {
      playerRef: playerRef("user1"),
      gameRef: gameRef("game5"),
      cancellationRecordId: "cancel5",
      nowMs,
    });
    expect(result).toBeNull();
  });

  test("getRestrictionForStrikes: transitions are exact (no off-by-one at boundaries)", () => {
    expect(getRestrictionForStrikes(0).level).toBe("none");
    expect(getRestrictionForStrikes(1).level).toBe("warning");
    expect(getRestrictionForStrikes(2).level).toBe("cooldown");
    expect(getRestrictionForStrikes(3).level).toBe("restricted");
    expect(getRestrictionForStrikes(4).level).toBe("restricted");
    expect(getRestrictionForStrikes(5).level).toBe("suspended");
  });

  test("Strike from 181 days ago (just past 180-day window) is expired", async () => {
    const createdAtMs = nowMs - 181 * DAY_MS;
    const expiresAtMs = createdAtMs + STRIKE_EXPIRY_MS; // nowMs - 1 day
    seedStrike(mockDb, "user1", "day_of_cancel", createdAtMs, expiresAtMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("Strike from exactly 180 days ago expires exactly now — does NOT count", async () => {
    const createdAtMs = nowMs - 180 * DAY_MS;
    const expiresAtMs = createdAtMs + STRIKE_EXPIRY_MS; // == nowMs
    seedStrike(mockDb, "user1", "day_of_cancel", createdAtMs, expiresAtMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(0);
  });

  test("Strike from 179 days ago expires in 1 day — DOES count", async () => {
    const createdAtMs = nowMs - 179 * DAY_MS;
    const expiresAtMs = createdAtMs + STRIKE_EXPIRY_MS; // nowMs + 1 day
    seedStrike(mockDb, "user1", "day_of_cancel", createdAtMs, expiresAtMs);
    const count = await getActiveStrikeCount(mockDb, playerRef("user1"), nowMs);
    expect(count).toBe(1);
  });
});
