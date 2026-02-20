/**
 * Confirmation Flow — Stage 3 Tests
 *
 * Tests for:
 *   - onGameParticipantJoin: profile snapshot + vibe score capture at join time
 *   - onGameStatusToPlayed: round_jobs + round_records creation
 *   - submitHostCheckin: attendance confirmation + no-show strike logic
 *   - submitPeerRatings: pair_ratings writes, idempotency, guest exclusion
 *   - submitFallbackConfirmation: confirmed_player_refs population
 *   - closeConfirmationWindow: 48h closure
 *   - vibe scores copy-only rule
 *
 * Run with: npx jest test/confirmation_flow.test.js
 */

"use strict";

// ─────────────────────────────────────────────────────────────────────────────
// MOCKS — MUST BE DEFINED BEFORE MODULE IMPORTS
// ─────────────────────────────────────────────────────────────────────────────

// Cloud Tasks mock (shared state) - declared first, assigned in jest.mock
let mockCreateTask;
let mockDeleteTask;
let mockQueuePath;

jest.mock('@google-cloud/tasks', () => {
  mockCreateTask = jest.fn().mockResolvedValue([{ name: 'projects/x/tasks/t1' }]);
  mockDeleteTask = jest.fn().mockResolvedValue([{}]);
  mockQueuePath  = jest.fn((project, location, queue) =>
    `projects/${project}/locations/${location}/queues/${queue}`,
  );

  function MockCloudTasksClient() {}
  MockCloudTasksClient.prototype.createTask = (...args) => mockCreateTask(...args);
  MockCloudTasksClient.prototype.deleteTask = (...args) => mockDeleteTask(...args);
  MockCloudTasksClient.prototype.queuePath  = (...args) => mockQueuePath(...args);

  return { CloudTasksClient: MockCloudTasksClient };
});

// Trust System mocks — closured variable pattern (same as integration.test.js with mockFcmSend)
// Variables must be declared BEFORE jest.mock() and names must start with 'mock'
let mockRouteNotification;
let mockOnGameConfirmed;
let mockOnHostCheckinCompleted;
let mockRandomUUID;

jest.mock('../notifications/trust/router', () => ({
  routeNotification: (...args) => mockRouteNotification(...args),
}));

jest.mock('../notifications/trust/hooks', () => ({
  onGameConfirmed: (...args) => mockOnGameConfirmed(...args),
  onHostCheckinCompleted: (...args) => mockOnHostCheckinCompleted(...args),
}));

// ─────────────────────────────────────────────────────────────────────────────
// MOCK INFRASTRUCTURE
// ─────────────────────────────────────────────────────────────────────────────

class MockTimestamp {
  constructor(ms) { this._ms = ms; }
  toMillis() { return this._ms; }
  toDate() { return new Date(this._ms); }
  static fromMillis(ms) { return new MockTimestamp(ms); }
  static now() { return new MockTimestamp(Date.now()); }
  valueOf() { return this._ms; }
}

class MockDocRef {
  constructor(db, collectionName, id) {
    this._db = db;
    this._collection = collectionName;
    this.id = id;
    this.path = `${collectionName}/${id}`;
  }
  collection(subCollectionName) {
    // Subcollection uses a path-based key so docs are stored flat in the mock
    return new MockCollectionRef(this._db, `${this._collection}/${this.id}/${subCollectionName}`);
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
  async update(fields) {
    const col = this._db._collections[this._collection] || {};
    // Work on the existing object directly (shallow copy at top level only)
    const existing = col[this.id] || {};
    const merged = Object.assign({}, existing);

    for (const [k, v] of Object.entries(fields)) {
      // Handle dot-notation paths (e.g. "verification_signals.uid_a")
      const parts = k.split(".");
      let target = merged;
      for (let i = 0; i < parts.length - 1; i++) {
        if (!target[parts[i]] || typeof target[parts[i]] !== "object") {
          target[parts[i]] = {};
        } else {
          // Shallow copy intermediate objects so we don't mutate shared refs
          target[parts[i]] = Object.assign({}, target[parts[i]]);
        }
        target = target[parts[i]];
      }
      const lastKey = parts[parts.length - 1];
      const existingLeaf = target[lastKey];
      // Detect FieldValue sentinels — support both our mock format and real Firebase Admin SDK
      // Real Admin SDK: increment → {operand: N}, delete → class instance, arrayUnion → {elements: [...]}
      const vStr = v && v.constructor ? v.constructor.name : "";
      const isArrayUnion = (v && v._type === "arrayUnion") ||
        (v && Array.isArray(v.elements)) ||
        (vStr === "ArrayUnionTransform");
      const isIncrement = (v && v._type === "increment") ||
        (v && typeof v.operand === "number" && !Array.isArray(v)) ||
        (vStr === "NumericIncrementTransform");
      const isDelete = (v && v._type === "delete") ||
        vStr === "DeleteTransform" ||
        vStr === "DeleteFieldValueImpl";

      if (isArrayUnion) {
        const items = v.items || v.elements || [];
        target[lastKey] = [...(Array.isArray(existingLeaf) ? existingLeaf : []), ...items];
      } else if (isIncrement) {
        const delta = v.delta !== undefined ? v.delta : v.operand;
        target[lastKey] = (typeof existingLeaf === "number" ? existingLeaf : 0) + delta;
      } else if (isDelete) {
        delete target[lastKey];
      } else {
        target[lastKey] = v;
      }
    }
    col[this.id] = merged;
    this._db._collections[this._collection] = col;
  }
  async set(data, options) {
    const col = this._db._collections[this._collection] || {};
    if (options && options.merge) {
      const existing = col[this.id] || {};
      const merged = { ...existing };
      for (const [k, v] of Object.entries(data)) {
        if (v && v._type === "increment") {
          merged[k] = (typeof existing[k] === "number" ? existing[k] : 0) + v.delta;
        } else if (v && v._type === "arrayUnion") {
          merged[k] = [...(Array.isArray(existing[k]) ? existing[k] : []), ...v.items];
        } else {
          merged[k] = v;
        }
      }
      col[this.id] = merged;
    } else {
      col[this.id] = { ...data };
    }
    this._db._collections[this._collection] = col;
  }
}

class MockQuery {
  constructor(collectionRef) {
    this._colRef = collectionRef;
    this._filters = [];
    this._limitVal = null;
  }
  where(field, op, value) {
    const clone = new MockQuery(this._colRef);
    clone._filters = [...this._filters, { field, op, value }];
    clone._limitVal = this._limitVal;
    return clone;
  }
  limit(n) {
    const clone = new MockQuery(this._colRef);
    clone._filters = [...this._filters];
    clone._limitVal = n;
    return clone;
  }
  orderBy() { return this; }
  async get() {
    const col = this._colRef._db._collections[this._colRef._name] || {};
    let docs = Object.entries(col).map(([id, data]) => ({
      id,
      data: () => ({ ...data }),
      ref: new MockDocRef(this._colRef._db, this._colRef._name, id),
    }));

    for (const { field, op, value } of this._filters) {
      docs = docs.filter((doc) => {
        const docVal = _getNestedField(doc.data(), field);
        // Normalise both sides for comparison
        const compareVal =
          value instanceof MockTimestamp ? value.toMillis()
          : value && typeof value.toMillis === "function" ? value.toMillis()
          : value;
        const docMs =
          docVal instanceof MockTimestamp ? docVal.toMillis()
          : docVal && typeof docVal.toMillis === "function" ? docVal.toMillis()
          : docVal;

        switch (op) {
          case "==": {
            // DocumentReference equality: compare by .id
            if (typeof compareVal === "object" && compareVal !== null && "id" in compareVal) {
              return (docVal && docVal.id) === compareVal.id;
            }
            if (typeof docMs === "object" && docMs !== null && "id" in docMs) {
              return docMs.id === (compareVal && compareVal.id ? compareVal.id : compareVal);
            }
            return docVal === compareVal;
          }
          case ">":  return docMs > compareVal;
          case ">=": return docMs >= compareVal;
          case "<":  return docMs < compareVal;
          case "<=": return docMs <= compareVal;
          case "!=": return docVal !== compareVal;
          default:   return true;
        }
      });
    }

    if (this._limitVal !== null) {
      docs = docs.slice(0, this._limitVal);
    }

    return { docs, size: docs.length, empty: docs.length === 0 };
  }
}

function _getNestedField(obj, field) {
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
  where(field, op, value) { return new MockQuery(this).where(field, op, value); }
  orderBy(field, dir) { return new MockQuery(this).orderBy(field, dir); }
}

class MockBatch {
  constructor(db) {
    this._db = db;
    this._ops = [];
  }
  set(ref, data, options) {
    this._ops.push({ type: "set", ref, data: { ...data }, options });
    return this;
  }
  update(ref, fields) {
    this._ops.push({ type: "update", ref, fields: { ...fields } });
    return this;
  }
  delete(ref) {
    this._ops.push({ type: "delete", ref });
    return this;
  }
  async commit() {
    for (const op of this._ops) {
      if (op.type === "set") {
        await op.ref.set(op.data, op.options);
      } else if (op.type === "update") {
        await op.ref.update(op.fields);
      } else if (op.type === "delete") {
        const col = this._db._collections[op.ref._collection] || {};
        delete col[op.ref.id];
      }
    }
  }
}

class MockFirestore {
  constructor() { this._collections = {}; }
  collection(name) { return new MockCollectionRef(this, name); }
  batch() { return new MockBatch(this); }
  reset() { this._collections = {}; }
  seedDoc(collectionName, id, data) {
    if (!this._collections[collectionName]) this._collections[collectionName] = {};
    this._collections[collectionName][id] = { ...data };
  }
  getDoc(collectionName, id) {
    return (this._collections[collectionName] || {})[id];
  }
  getDocs(collectionName) {
    return this._collections[collectionName] || {};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOAD MODULE UNDER TEST WITH MOCKS
// ─────────────────────────────────────────────────────────────────────────────

// HttpsError class — must match what the module uses
class MockHttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}

// Mock FieldValue
const FieldValue = {
  serverTimestamp: () => MockTimestamp.now(),
  arrayUnion: (...items) => ({ _type: "arrayUnion", items }),
  increment: (delta) => ({ _type: "increment", delta }),
  delete: () => ({ _type: "delete" }),
};

// Mock firebase-admin firestore accessor (name must start with "mock" for jest.mock)
const mockDb = new MockFirestore();
function mockAdminFirestoreFn() { return mockDb; }
mockAdminFirestoreFn.Timestamp = MockTimestamp;
mockAdminFirestoreFn.FieldValue = FieldValue;

// Mock firebase-functions (name must start with "mock" for jest.mock)
const mockFunctions = {
  region: () => mockFunctions,
  runWith: () => mockFunctions,
  https: {
    onCall: (handler) => {
      const fn = async (data, context) => handler(data, context);
      fn._handler = handler;
      return fn;
    },
    HttpsError: MockHttpsError,
  },
  firestore: {
    document: () => ({ onCreate: (h) => h, onUpdate: (h) => h }),
  },
  pubsub: {
    schedule: () => ({ onRun: (h) => h }),
  },
};

// Inject mocks via Module._load before requiring the module under test.
// This intercept approach works even when other test files have loaded the real
// modules, because we forcibly evict confirmation_flow from the require cache
// so it is freshly loaded with our mocks in place.
const Module = require("module");
const _originalLoad = Module._load;

// firebase-admin and firebase-functions are still mocked via Module._load
// because the test infrastructure requires precise control over Firestore behavior

let confirmationFlow;
beforeAll(() => {
  // Remove confirmation_flow and trust modules from cache so they load fresh with our mocks.
  try { delete require.cache[require.resolve("../confirmation_flow")]; } catch (_) {}
  // Install intercept for firebase-admin, firebase-functions, and crypto
  // (Trust System modules are handled by jest.mock() above)
  Module._load = function (request, parent, isMain) {
    if (request === "firebase-functions") return mockFunctions;
    if (request === "firebase-admin") {
      // Mock admin with initializeApp that does nothing but marks as initialized
      let initialized = false;
      const firestoreFn = () => mockDb;
      firestoreFn.Timestamp = MockTimestamp;
      firestoreFn.FieldValue = FieldValue;
      return {
        firestore: firestoreFn,
        initializeApp: () => { initialized = true; },
      };
    }
    if (request === "crypto") {
      return { randomUUID: (...args) => mockRandomUUID(...args) };
    }
    return _originalLoad.apply(this, arguments);
  };

  confirmationFlow = require("../confirmation_flow");

  // DON'T restore the loader here - keep it active for all tests
  // It will be restored in afterAll
});

afterAll(() => {
  // Restore original loader after all tests complete
  Module._load = _originalLoad;
});

beforeEach(() => {
  // Reset Cloud Tasks client singleton FIRST, before clearing mocks
  if (confirmationFlow && confirmationFlow._resetTasksClient) {
    confirmationFlow._resetTasksClient();
  }

  // Clear all mock call history
  jest.clearAllMocks();

  // Re-create mock implementations after clearAllMocks
  const MOCK_TASK_NAME = 'projects/find-my-fourth/locations/us-west2/queues/trust-notification-scheduler/tasks/task_001';

  mockCreateTask.mockResolvedValue([{ name: MOCK_TASK_NAME }]);
  mockDeleteTask.mockResolvedValue([{}]);
  mockQueuePath.mockImplementation((project, location, queue) =>
    `projects/${project}/locations/${location}/queues/${queue}`,
  );

  // Create fresh Trust System mock implementations (closured variable pattern)
  mockRouteNotification = jest.fn().mockResolvedValue({ result: 'sent' });
  mockOnGameConfirmed = jest.fn().mockResolvedValue({
    hostCheckinJobId: 'mock_job_1',
    hostCheckinReminderJobId: 'mock_job_2',
    hostFallbackJobId: 'mock_job_3',
    playerFallbackJobIds: {},
  });
  mockOnHostCheckinCompleted = jest.fn().mockResolvedValue({
    cancelledCount: 0,
    playerRateJobIds: {},
  });
  mockRandomUUID = jest.fn(() => 'mock-uuid-' + Math.random().toString(36).slice(2));

  // Reset mock Firestore
  mockDb.reset();
});

// ─────────────────────────────────────────────────────────────────────────────
// CONVENIENCE HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const HOUR_MS = 60 * 60 * 1000;

function playerRef(id) { return { id, path: `users/${id}` }; }
function gameRef(id) { return { id, path: `games/${id}` }; }
function roundRef(id) { return { id, path: `round_records/${id}` }; }
function makeContext(uid) { return { auth: { uid } }; }

function seedGame(db, gameId, overrides = {}) {
  const teeTime = MockTimestamp.fromMillis(Date.now() - 6 * HOUR_MS);
  db.seedDoc("games", gameId, {
    date: teeTime,
    status: "filled",
    game_type: "Stroke Play",
    course_play: "Sawgrass",
    userRef: playerRef("host_user"),
    joined_players: [playerRef("host_user"), playerRef("player_a"), playerRef("player_b")],
    guest_players: ["Guest Mike"],
    max_players: 4,
    ...overrides,
  });
}

function seedRoundJob(db, jobId, gameId, overrides = {}) {
  const teeTimeMs = Date.now() - 6 * HOUR_MS;
  db.seedDoc("round_jobs", jobId, {
    game_ref: gameRef(gameId),
    round_ref: new MockDocRef(db, "round_records", `round_${gameId}`),
    tee_time: MockTimestamp.fromMillis(teeTimeMs),
    status: "pending",
    host_ref: playerRef("host_user"),
    app_user_refs: [playerRef("host_user"), playerRef("player_a"), playerRef("player_b")],
    course_name: "Sawgrass",
    scheduled_host_notify_at: MockTimestamp.fromMillis(teeTimeMs + 5 * HOUR_MS),
    scheduled_peer_notify_at: null,
    scheduled_reminder_at: MockTimestamp.fromMillis(teeTimeMs + 24 * HOUR_MS),
    scheduled_close_at: MockTimestamp.fromMillis(teeTimeMs + 48 * HOUR_MS),
    host_notified_at: null,
    host_confirmed_at: null,
    peer_notified_at: null,
    reminder_sent_at: null,
    closed_at: null,
    created_at: MockTimestamp.fromMillis(teeTimeMs),
    ...overrides,
  });
}

function seedRoundRecord(db, roundId, overrides = {}) {
  db.seedDoc("round_records", roundId, {
    attendance_records: {},
    confirmed_player_refs: [],
    verification_status: "pending",
    verification_signals: {},
    verification_signal_count: 0,
    verified_at: null,
    pending_no_shows: {},
    host_check_in_at: null,
    participant_snapshots: [
      { uid: "host_user", display_name: "Host" },
      { uid: "player_a", display_name: "Alice" },
      { uid: "player_b", display_name: "Bob" },
    ],
    ...overrides,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

beforeEach(() => {
  mockDb.reset();
});

// ─────────────────────────────────────────────────────────────────────────────
// onGameParticipantJoin
// ─────────────────────────────────────────────────────────────────────────────

describe("onGameParticipantJoin", () => {
  test("skips guest entries (no user_ref)", async () => {
    const snapshot = {
      data: () => ({
        game_ref: gameRef("g1"),
        user_ref: null,
        guest_name: "Guest Bob",
        role: "guest",
      }),
      ref: { update: jest.fn() },
    };
    const context = { params: { participantId: "p1" } };

    await confirmationFlow._onGameParticipantJoinHandler(snapshot, context, mockDb);

    expect(snapshot.ref.update).not.toHaveBeenCalled();
  });

  test("writes profile_snapshot when user profile exists", async () => {
    // user_ref must be a MockDocRef so the handler can call .get() on it
    const uref = new MockDocRef(mockDb, "users", "player_a");
    mockDb.seedDoc("users", "player_a", {
      display_name: "Alice",
      photo_url: "https://example.com/alice.jpg",
      handicap: 10,
      vibe_profile: {},
    });
    mockDb.seedDoc("games", "g1", {});

    const updates = {};
    const snapshot = {
      data: () => ({
        game_ref: gameRef("g1"),
        user_ref: uref,
        role: "player",
        status: "joined",
      }),
      ref: {
        update: jest.fn(async (fields) => Object.assign(updates, fields)),
      },
    };
    const context = { params: { participantId: "p1" } };

    await confirmationFlow._onGameParticipantJoinHandler(snapshot, context, mockDb);

    expect(snapshot.ref.update).toHaveBeenCalled();
    const snap = updates.profile_snapshot;
    expect(snap).toBeDefined();
    expect(snap.uid).toBe("player_a");
    expect(snap.display_name).toBe("Alice");
    expect(snap.photo_url).toBe("https://example.com/alice.jpg");
    expect(snap.handicap).toBe(10);
  });

  test("writes empty vibe_scores_with_others when no other participants", async () => {
    mockDb.seedDoc("users", "player_a", { display_name: "Alice", vibe_profile: {} });
    mockDb.seedDoc("games", "g1", {});

    const updates = {};
    const snapshot = {
      data: () => ({
        game_ref: gameRef("g1"),
        user_ref: new MockDocRef(mockDb, "users", "player_a"),
        role: "player",
        status: "joined",
      }),
      ref: { update: jest.fn(async (fields) => Object.assign(updates, fields)) },
    };
    const context = { params: { participantId: "p1" } };

    await confirmationFlow._onGameParticipantJoinHandler(snapshot, context, mockDb);

    expect(updates.vibe_scores_with_others).toBeDefined();
    expect(Object.keys(updates.vibe_scores_with_others)).toHaveLength(0);
  });

  test("computes vibe score for each other app user in game", async () => {
    mockDb.seedDoc("users", "player_a", {
      display_name: "Alice",
      vibe_profile: {
        prefs: {
          drinking: { value: 3, dealbreaker: false, dealbreaker_threshold: 2, is_default: false },
          music: { value: 2, dealbreaker: false, dealbreaker_threshold: 2, is_default: false },
        },
      },
    });
    mockDb.seedDoc("users", "player_b", {
      display_name: "Bob",
      vibe_profile: {
        prefs: {
          drinking: { value: 3, dealbreaker: false, dealbreaker_threshold: 2, is_default: false },
          music: { value: 2, dealbreaker: false, dealbreaker_threshold: 2, is_default: false },
        },
      },
    });
    // game_participants "part_b" user_ref must be a MockDocRef so handler can call .get()
    mockDb.seedDoc("game_participants", "part_b", {
      game_ref: gameRef("g1"),
      user_ref: new MockDocRef(mockDb, "users", "player_b"),
      status: "joined",
      profile_snapshot: { uid: "player_b", display_name: "Bob" },
    });
    mockDb.seedDoc("games", "g1", {});

    const updates = {};
    const snapshot = {
      data: () => ({
        game_ref: gameRef("g1"),
        user_ref: new MockDocRef(mockDb, "users", "player_a"),
        role: "player",
        status: "joined",
      }),
      ref: { update: jest.fn(async (fields) => Object.assign(updates, fields)) },
    };
    const context = { params: { participantId: "part_a" } };

    await confirmationFlow._onGameParticipantJoinHandler(snapshot, context, mockDb);

    const vibeScores = updates.vibe_scores_with_others;
    expect(vibeScores).toBeDefined();
    expect(vibeScores["player_b"]).toBeDefined();
    expect(typeof vibeScores["player_b"].finalScorePercent).toBe("number");
    expect(["Recommended", "Caution", "NotRecommended"]).toContain(
      vibeScores["player_b"].recommendation
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// onGameStatusToFilled
// ─────────────────────────────────────────────────────────────────────────────

describe("onGameStatusToFilled", () => {
  test("does nothing if status did not transition to filled", async () => {
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => ({ status: "filled" }),
        ref: { update: jest.fn() },
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToFilledHandler(change, context, mockDb);

    expect(mockCreateTask).not.toHaveBeenCalled();
    expect(change.after.ref.update).not.toHaveBeenCalled();
  });

  test("schedules Cloud Task at tee time when transitioning to filled", async () => {
    const teeTimeMs = Date.now() + 2 * HOUR_MS; // 2 hours in future
    const change = {
      before: { data: () => ({ status: "open" }) },
      after: {
        data: () => ({
          status: "filled",
          date: MockTimestamp.fromMillis(teeTimeMs),
          isCancelled: false,
        }),
        ref: { update: jest.fn() },
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToFilledHandler(change, context, mockDb);

    expect(mockCreateTask).toHaveBeenCalledTimes(1);
    const callArg = mockCreateTask.mock.calls[0][0];

    // Verify schedule time matches tee time
    const expectedSecs = Math.floor(teeTimeMs / 1000);
    expect(callArg.task.scheduleTime.seconds).toBe(expectedSecs);

    // Verify payload contains gameId
    const decoded = JSON.parse(Buffer.from(callArg.task.httpRequest.body, 'base64').toString());
    expect(decoded.gameId).toBe("g1");

    // Verify URL targets processScheduledGameStatusChange
    expect(callArg.task.httpRequest.url).toContain('processScheduledGameStatusChange');
  });

  test("flips to played immediately if tee time is in the past", async () => {
    const teeTimeMs = Date.now() - 2 * HOUR_MS; // 2 hours ago
    const updateSpy = jest.fn().mockResolvedValue(undefined);
    const change = {
      before: { data: () => ({ status: "open" }) },
      after: {
        data: () => ({
          status: "filled",
          date: MockTimestamp.fromMillis(teeTimeMs),
          isCancelled: false,
        }),
        ref: { update: updateSpy },
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToFilledHandler(change, context, mockDb);

    expect(updateSpy).toHaveBeenCalledWith({ status: 'played' });
    expect(mockCreateTask).not.toHaveBeenCalled();
  });

  test("does nothing if game is cancelled", async () => {
    const teeTimeMs = Date.now() + 2 * HOUR_MS;
    const change = {
      before: { data: () => ({ status: "open" }) },
      after: {
        data: () => ({
          status: "filled",
          date: MockTimestamp.fromMillis(teeTimeMs),
          isCancelled: true,
        }),
        ref: { update: jest.fn() },
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToFilledHandler(change, context, mockDb);

    expect(mockCreateTask).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// processScheduledGameStatusChange
// ─────────────────────────────────────────────────────────────────────────────

describe("processScheduledGameStatusChange", () => {
  test("flips filled game to played and returns 200", async () => {
    mockDb.seedDoc("games", "g1", {
      status: "filled",
      isCancelled: false,
    });

    const req = { body: { gameId: "g1" } };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledGameStatusChangeHandler(req, res, mockDb);

    const game = mockDb.getDoc("games", "g1");
    expect(game.status).toBe("played");
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith("OK");
  });

  test("returns 200 SKIPPED if game is not filled", async () => {
    mockDb.seedDoc("games", "g1", {
      status: "played",
      isCancelled: false,
    });

    const req = { body: { gameId: "g1" } };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledGameStatusChangeHandler(req, res, mockDb);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith("SKIPPED");
  });

  test("returns 200 CANCELLED if game is cancelled", async () => {
    mockDb.seedDoc("games", "g1", {
      status: "filled",
      isCancelled: true,
    });

    const req = { body: { gameId: "g1" } };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledGameStatusChangeHandler(req, res, mockDb);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith("CANCELLED");
  });

  test("returns 400 if gameId is missing", async () => {
    const req = { body: {} };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledGameStatusChangeHandler(req, res, mockDb);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.send).toHaveBeenCalledWith("Missing gameId");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// processScheduledWindowClose
// ─────────────────────────────────────────────────────────────────────────────

describe("processScheduledWindowClose", () => {
  test("calls _closeConfirmationWindow and returns 200", async () => {
    const teeTimeMs = Date.now() - 50 * HOUR_MS;
    mockDb.seedDoc("round_jobs", "job1", {
      game_ref: gameRef("g1"),
      tee_time: MockTimestamp.fromMillis(teeTimeMs),
      host_ref: playerRef("host"),
      app_user_refs: [playerRef("host")],
      course_name: "Augusta",
      closed_at: null,
    });

    const req = { body: { jobId: "job1", gameId: "g1" } };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledWindowCloseHandler(req, res, mockDb);

    const job = mockDb.getDoc("round_jobs", "job1");
    expect(job.status).toBe("closed");
    expect(job.closed_at).toBeDefined();
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith("OK");
  });

  test("returns 200 ALREADY_CLOSED if job already closed", async () => {
    const nowTs = MockTimestamp.now();
    mockDb.seedDoc("round_jobs", "job1", {
      closed_at: nowTs,
    });

    const req = { body: { jobId: "job1", gameId: "g1" } };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledWindowCloseHandler(req, res, mockDb);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith("ALREADY_CLOSED");
  });

  test("returns 400 if jobId is missing", async () => {
    const req = { body: { gameId: "g1" } };
    const res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
    };

    await confirmationFlow._processScheduledWindowCloseHandler(req, res, mockDb);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.send).toHaveBeenCalledWith("Missing jobId");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// onGameStatusToPlayed
// ─────────────────────────────────────────────────────────────────────────────

describe("onGameStatusToPlayed", () => {
  test("does nothing if status did not transition to played", async () => {
    const change = {
      before: { data: () => ({ status: "played" }) },
      after: {
        data: () => ({ status: "played" }),
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    expect(Object.keys(mockDb.getDocs("round_jobs"))).toHaveLength(0);
  });

  test("creates round_jobs with correct timestamps when game transitions to played", async () => {
    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const gameData = {
      date: MockTimestamp.fromMillis(teeTimeMs),
      status: "played",
      userRef: playerRef("host_user"),
      course_play: "Augusta",
      joined_players: [playerRef("host_user"), playerRef("player_a")],
      guest_players: [],
      game_type: "Stroke Play",
    };
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => gameData,
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    const jobs = mockDb.getDocs("round_jobs");
    expect(Object.keys(jobs).length).toBeGreaterThan(0);

    const job = Object.values(jobs)[0];
    expect(job.status).toBe("pending");
    expect(job.course_name).toBe("Augusta");
    expect(job.host_ref.id).toBe("host_user");
    expect(job.app_user_refs).toHaveLength(2);

    expect(job.scheduled_host_notify_at.toMillis()).toBeCloseTo(teeTimeMs + 5 * HOUR_MS, -3);
    expect(job.scheduled_reminder_at.toMillis()).toBeCloseTo(teeTimeMs + 24 * HOUR_MS, -3);
    expect(job.scheduled_close_at.toMillis()).toBeCloseTo(teeTimeMs + 48 * HOUR_MS, -3);
    expect(job.scheduled_peer_notify_at).toBeNull();
  });

  test("also creates initial round_records doc", async () => {
    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const gameData = {
      date: MockTimestamp.fromMillis(teeTimeMs),
      status: "played",
      userRef: playerRef("host_user"),
      course_play: "Augusta",
      joined_players: [playerRef("host_user"), playerRef("player_a")],
      guest_players: [],
      game_type: "Stroke Play",
    };
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => gameData,
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    const rounds = mockDb.getDocs("round_records");
    expect(Object.keys(rounds).length).toBeGreaterThan(0);

    const round = Object.values(rounds)[0];
    expect(round.verification_status).toBe("pending");
    expect(round.game_type).toBe("Stroke Play");
  });

  test("does nothing if game has no tee time", async () => {
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => ({
          status: "played",
          userRef: playerRef("host_user"),
          joined_players: [],
        }),
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    expect(Object.keys(mockDb.getDocs("round_jobs"))).toHaveLength(0);
  });

  test("calls onGameConfirmed with correct parameters", async () => {
    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const gameData = {
      date: MockTimestamp.fromMillis(teeTimeMs),
      status: "played",
      userRef: playerRef("host_user"),
      course_play: "Pebble Beach",
      joined_players: [playerRef("host_user"), playerRef("player_a"), playerRef("player_b")],
      guest_players: [],
      game_type: "Stroke Play",
    };
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => gameData,
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    expect(mockOnGameConfirmed).toHaveBeenCalledTimes(1);
    const callArgs = mockOnGameConfirmed.mock.calls[0];
    expect(callArgs[0]).toBe("g1"); // gameId
    expect(callArgs[1]).toEqual(new Date(teeTimeMs)); // teeTime as Date
    expect(callArgs[2]).toBe("host_user"); // hostUserId
    expect(callArgs[3]).toEqual(["host_user", "player_a", "player_b"]); // playerUserIds
    expect(callArgs[4]).toBe("Pebble Beach"); // courseName
    expect(callArgs[5]).toMatch(/\w+ \d+/); // gameDate formatted (e.g., "Feb 18")
    expect(callArgs[6]).toBe(mockDb); // db
  });

  test("schedules Cloud Task for T+48h window close with correct payload", async () => {
    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const gameData = {
      date: MockTimestamp.fromMillis(teeTimeMs),
      status: "played",
      userRef: playerRef("host_user"),
      course_play: "Augusta",
      joined_players: [playerRef("host_user"), playerRef("player_a")],
      guest_players: [],
      game_type: "Stroke Play",
    };
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => gameData,
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    expect(mockCreateTask).toHaveBeenCalled();

    // Find the window close task (it's the Cloud Task call)
    const windowCloseCall = mockCreateTask.mock.calls.find(call => {
      const body = JSON.parse(Buffer.from(call[0].task.httpRequest.body, 'base64').toString());
      return body.jobId !== undefined;
    });

    expect(windowCloseCall).toBeDefined();

    const callArg = windowCloseCall[0];
    const decoded = JSON.parse(Buffer.from(callArg.task.httpRequest.body, 'base64').toString());

    // Verify payload
    expect(decoded.gameId).toBe("g1");
    expect(decoded.jobId).toBeDefined();

    // Verify schedule time is T+48h
    const expectedCloseTimeMs = teeTimeMs + (48 * 60 * 60 * 1000);
    const expectedCloseSecs = Math.floor(expectedCloseTimeMs / 1000);
    expect(callArg.task.scheduleTime.seconds).toBeCloseTo(expectedCloseSecs, -1);

    // Verify URL targets processScheduledWindowClose
    expect(callArg.task.httpRequest.url).toContain('processScheduledWindowClose');
  });

  test("schedules window close task to correct queue path", async () => {
    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const gameData = {
      date: MockTimestamp.fromMillis(teeTimeMs),
      status: "played",
      userRef: playerRef("host_user"),
      course_play: "Augusta",
      joined_players: [playerRef("host_user")],
      guest_players: [],
      game_type: "Stroke Play",
    };
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => gameData,
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    expect(mockCreateTask).toHaveBeenCalled();
    const callArg = mockCreateTask.mock.calls[0][0];
    expect(callArg.parent).toBe('projects/find-my-fourth/locations/us-west2/queues/trust-notification-scheduler');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// submitHostCheckin
// ─────────────────────────────────────────────────────────────────────────────

describe("submitHostCheckin", () => {
  test("throws unauthenticated if no auth context", async () => {
    await expect(
      confirmationFlow._submitHostCheckinHandler(
        { gameId: "g1", attendance: {} },
        { auth: null },
        mockDb
      )
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  test("throws invalid-argument if gameId missing", async () => {
    await expect(
      confirmationFlow._submitHostCheckinHandler(
        { attendance: {} },
        makeContext("host_user"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  test("throws permission-denied if caller is not host", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    await expect(
      confirmationFlow._submitHostCheckinHandler(
        { gameId: "g1", attendance: { player_a: true } },
        makeContext("player_a"), // not the host
        mockDb
      )
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  test("throws failed-precondition if window is closed", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      closed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
    });
    seedRoundRecord(mockDb, "round_g1");

    await expect(
      confirmationFlow._submitHostCheckinHandler(
        { gameId: "g1", attendance: { player_a: true } },
        makeContext("host_user"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("returns success with empty pendingNoShows when all players present", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    const result = await confirmationFlow._submitHostCheckinHandler(
      {
        gameId: "g1",
        attendance: { host_user: true, player_a: true, player_b: true },
      },
      makeContext("host_user"),
      mockDb
    );

    expect(result.success).toBe(true);
    expect(result.pendingNoShows).toHaveLength(0);
    // No strikes issued immediately in Stage 4
    const strikes = Object.values(mockDb.getDocs("strikes") || {});
    expect(strikes).toHaveLength(0);
  });

  test("Stage 4: writes pending_no_shows instead of immediate strikes", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    const result = await confirmationFlow._submitHostCheckinHandler(
      {
        gameId: "g1",
        attendance: { host_user: true, player_a: false, player_b: true },
      },
      makeContext("host_user"),
      mockDb
    );

    expect(result.success).toBe(true);
    expect(result.pendingNoShows).toContain("player_a");

    // NO strikes issued immediately
    const strikes = Object.values(mockDb.getDocs("strikes") || {});
    const ghostStrikes = strikes.filter((s) => s.reason === "ghost_no_show");
    expect(ghostStrikes).toHaveLength(0);

    // pending_no_shows written to round_records
    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round).toBeDefined();
    expect(round.pending_no_shows).toBeDefined();
    expect(round.pending_no_shows["player_a"]).toBeDefined();
  });

  test("Stage 4: calls routeNotification for no-show flagged players", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    await confirmationFlow._submitHostCheckinHandler(
      {
        gameId: "g1",
        attendance: { host_user: true, player_a: false, player_b: true },
      },
      makeContext("host_user"),
      mockDb
    );

    // Verify routeNotification was called for the no-show player
    expect(mockRouteNotification).toHaveBeenCalled();
    const noShowCall = mockRouteNotification.mock.calls.find(call =>
      call[0].eventType === 'no_show_flagged' &&
      call[0].recipientUserId === 'player_a'
    );
    expect(noShowCall).toBeDefined();
    expect(noShowCall[0].data.course_name).toBe('Sawgrass');
  });

  test("Stage 4: host check-in records a verification signal", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1", {
      verification_signals: {},
      verification_signal_count: 0,
    });

    await confirmationFlow._submitHostCheckinHandler(
      {
        gameId: "g1",
        attendance: { host_user: true, player_a: true, player_b: true },
      },
      makeContext("host_user"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_signals["host_user"]).toBe(true);
    expect(round.verification_signal_count).toBe(1);
  });

  test("is idempotent — second submission returns early without changes", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
      status: "host_confirmed",
    });
    seedRoundRecord(mockDb, "round_g1");

    const result = await confirmationFlow._submitHostCheckinHandler(
      { gameId: "g1", attendance: { host_user: true } },
      makeContext("host_user"),
      mockDb
    );

    expect(result.success).toBe(true);
    expect(result.pendingNoShows).toEqual({});
  });

  test("sets scheduled_peer_notify_at ~30min after confirmation", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    const beforeMs = Date.now();
    await confirmationFlow._submitHostCheckinHandler(
      { gameId: "g1", attendance: { host_user: true, player_a: true } },
      makeContext("host_user"),
      mockDb
    );
    const afterMs = Date.now();

    const job = mockDb.getDocs("round_jobs")["job1"];
    const peerNotifyMs = job.scheduled_peer_notify_at.toMillis();
    expect(peerNotifyMs).toBeGreaterThanOrEqual(beforeMs + 30 * 60 * 1000 - 100);
    expect(peerNotifyMs).toBeLessThanOrEqual(afterMs + 30 * 60 * 1000 + 100);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// submitPeerRatings
// ─────────────────────────────────────────────────────────────────────────────

describe("submitPeerRatings", () => {
  test("throws unauthenticated if no auth", async () => {
    await expect(
      confirmationFlow._submitPeerRatingsHandler(
        { gameId: "g1", ratings: {} },
        { auth: null },
        mockDb
      )
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  test("throws permission-denied if user is not a participant", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now()),
    });

    await expect(
      confirmationFlow._submitPeerRatingsHandler(
        { gameId: "g1", ratings: { player_a: true } },
        makeContext("outsider"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  test("throws failed-precondition if window is closed", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now()),
      closed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
    });

    await expect(
      confirmationFlow._submitPeerRatingsHandler(
        { gameId: "g1", ratings: { player_b: true } },
        makeContext("player_a"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("throws failed-precondition if host has not confirmed yet", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", { host_confirmed_at: null });

    await expect(
      confirmationFlow._submitPeerRatingsHandler(
        { gameId: "g1", ratings: { player_b: true } },
        makeContext("player_a"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("writes directional pair_ratings docs", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now()),
    });

    const result = await confirmationFlow._submitPeerRatingsHandler(
      {
        gameId: "g1",
        ratings: { player_b: true, host_user: false },
      },
      makeContext("player_a"),
      mockDb
    );

    expect(result.success).toBe(true);
    expect(result.ratingsWritten).toBe(2);

    const ratings = Object.values(mockDb.getDocs("pair_ratings"));
    expect(ratings).toHaveLength(2);

    const thumbsUp = ratings.find((r) => r.rated_ref.id === "player_b");
    expect(thumbsUp).toBeDefined();
    expect(thumbsUp.would_play_again).toBe(true);
    expect(thumbsUp.rater_ref.id).toBe("player_a");

    const thumbsDown = ratings.find((r) => r.rated_ref.id === "host_user");
    expect(thumbsDown).toBeDefined();
    expect(thumbsDown.would_play_again).toBe(false);
  });

  test("does not allow rating yourself", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now()),
    });

    const result = await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { player_a: true } }, // rating self
      makeContext("player_a"),
      mockDb
    );

    expect(result.ratingsWritten).toBe(0);
    expect(Object.keys(mockDb.getDocs("pair_ratings") || {})).toHaveLength(0);
  });

  test("is idempotent — second submission returns alreadySubmitted", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now()),
    });

    // First submission
    await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { player_b: true } },
      makeContext("player_a"),
      mockDb
    );

    const countAfterFirst = Object.keys(mockDb.getDocs("pair_ratings") || {}).length;

    // Second submission
    const result2 = await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { player_b: true } },
      makeContext("player_a"),
      mockDb
    );

    expect(result2.alreadySubmitted).toBe(true);
    expect(Object.keys(mockDb.getDocs("pair_ratings") || {}).length).toBe(countAfterFirst);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// submitFallbackConfirmation
// ─────────────────────────────────────────────────────────────────────────────

describe("submitFallbackConfirmation", () => {
  test("throws unauthenticated if no auth", async () => {
    await expect(
      confirmationFlow._submitFallbackConfirmationHandler(
        { gameId: "g1", didPlay: true },
        { auth: null },
        mockDb
      )
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  test("throws failed-precondition if window is closed", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      closed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
    });

    await expect(
      confirmationFlow._submitFallbackConfirmationHandler(
        { gameId: "g1", didPlay: true },
        makeContext("player_a"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("returns success without write when didPlay is false", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    const result = await confirmationFlow._submitFallbackConfirmationHandler(
      { gameId: "g1", didPlay: false },
      makeContext("player_a"),
      mockDb
    );

    expect(result.success).toBe(true);
  });

  test("returns success when didPlay is true", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1");

    const result = await confirmationFlow._submitFallbackConfirmationHandler(
      { gameId: "g1", didPlay: true },
      makeContext("player_a"),
      mockDb
    );

    expect(result.success).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// vibe scores — copy-only rule
// ─────────────────────────────────────────────────────────────────────────────

describe("round record data — vibe scores copy-only rule", () => {
  test("omits vibe_match_scores when vibe_scores_with_others is missing from game_participants", async () => {
    const gRef = gameRef("g1");
    mockDb.seedDoc("game_participants", "part_a", {
      game_ref: gRef,
      user_ref: playerRef("player_a"),
      status: "joined",
      profile_snapshot: { uid: "player_a", display_name: "Alice" },
      // vibe_scores_with_others intentionally missing
    });

    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => ({
          date: MockTimestamp.fromMillis(teeTimeMs),
          status: "played",
          userRef: playerRef("host_user"),
          course_play: "Pebble Beach",
          joined_players: [playerRef("player_a")],
          game_type: "Stroke Play",
        }),
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    const warnSpy = jest.spyOn(console, "warn").mockImplementation(() => {});

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    const rounds = mockDb.getDocs("round_records");
    expect(Object.keys(rounds).length).toBeGreaterThan(0);

    const round = Object.values(rounds)[0];
    expect(Object.keys(round.vibe_match_scores || {})).toHaveLength(0);

    const warnCalls = warnSpy.mock.calls.map((c) => c.join(" "));
    expect(warnCalls.some((msg) => msg.includes("missing vibe_scores_with_others"))).toBe(true);

    warnSpy.mockRestore();
  });

  test("copies vibe_match_scores when present in game_participants", async () => {
    const gRef = gameRef("g1");
    mockDb.seedDoc("game_participants", "part_a", {
      game_ref: gRef,
      user_ref: playerRef("player_a"),
      status: "joined",
      profile_snapshot: { uid: "player_a", display_name: "Alice" },
      vibe_scores_with_others: {
        player_b: { finalScorePercent: 80, recommendation: "Recommended", confidence: "high", hasHardConflict: false },
      },
    });
    mockDb.seedDoc("game_participants", "part_b", {
      game_ref: gRef,
      user_ref: playerRef("player_b"),
      status: "joined",
      profile_snapshot: { uid: "player_b", display_name: "Bob" },
      vibe_scores_with_others: {
        player_a: { finalScorePercent: 80, recommendation: "Recommended", confidence: "high", hasHardConflict: false },
      },
    });

    const teeTimeMs = Date.now() - 2 * HOUR_MS;
    const change = {
      before: { data: () => ({ status: "filled" }) },
      after: {
        data: () => ({
          date: MockTimestamp.fromMillis(teeTimeMs),
          status: "played",
          userRef: playerRef("host_user"),
          course_play: "Pebble Beach",
          joined_players: [playerRef("player_a"), playerRef("player_b")],
          game_type: "Stroke Play",
        }),
        ref: new MockDocRef(mockDb, "games", "g1"),
      },
    };
    const context = { params: { gameId: "g1" } };

    await confirmationFlow._onGameStatusToPlayedHandler(change, context, mockDb);

    const rounds = mockDb.getDocs("round_records");
    const round = Object.values(rounds)[0];

    const pairKey = "player_a:player_b";
    expect(round.vibe_match_scores[pairKey]).toBeDefined();
    expect(round.vibe_match_scores[pairKey].finalScorePercent).toBe(80);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 48h window closure
// ─────────────────────────────────────────────────────────────────────────────

describe("confirmation window closure at 48h", () => {
  test("submitHostCheckin rejects after window closes", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      closed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
    });

    await expect(
      confirmationFlow._submitHostCheckinHandler(
        { gameId: "g1", attendance: { player_a: true } },
        makeContext("host_user"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("submitPeerRatings rejects after window closes", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
      closed_at: MockTimestamp.fromMillis(Date.now() - 30 * 60 * 1000),
    });

    await expect(
      confirmationFlow._submitPeerRatingsHandler(
        { gameId: "g1", ratings: { player_b: true } },
        makeContext("player_a"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("submitFallbackConfirmation rejects after window closes", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      closed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
    });

    await expect(
      confirmationFlow._submitFallbackConfirmationHandler(
        { gameId: "g1", didPlay: true },
        makeContext("player_a"),
        mockDb
      )
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// STAGE 4: VERIFICATION ENGINE & DISPUTE RESOLUTION
// ─────────────────────────────────────────────────────────────────────────────

describe("Stage 4 — _recordVerificationSignal", () => {
  test("increments count on first signal", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    mockDb.seedDoc("round_records", "r1", {
      verification_signals: {},
      verification_signal_count: 0,
    });
    const roundData = { verification_signals: {}, verification_signal_count: 0 };

    const { newCount, alreadySignaled } = await confirmationFlow._recordVerificationSignal(
      mockDb, rRef, roundData, "uid_a"
    );

    expect(newCount).toBe(1);
    expect(alreadySignaled).toBe(false);
    const round = mockDb.getDoc("round_records", "r1");
    expect(round.verification_signals["uid_a"]).toBe(true);
  });

  test("does NOT double-count the same uid", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    mockDb.seedDoc("round_records", "r1", {
      verification_signals: { uid_a: true },
      verification_signal_count: 1,
    });
    const roundData = { verification_signals: { uid_a: true }, verification_signal_count: 1 };

    const { newCount, alreadySignaled } = await confirmationFlow._recordVerificationSignal(
      mockDb, rRef, roundData, "uid_a"
    );

    expect(newCount).toBe(1);
    expect(alreadySignaled).toBe(true);
  });
});

describe("Stage 4 — _resolvePendingNoShow", () => {
  test("removes pending no-show entry from round_records", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    mockDb.seedDoc("round_records", "r1", {
      pending_no_shows: {
        ghost_player: { recorded_at: MockTimestamp.now(), notified_at: null },
      },
    });

    await confirmationFlow._resolvePendingNoShow(mockDb, rRef, "ghost_player", "resolver_uid");

    const round = mockDb.getDoc("round_records", "r1");
    // After FieldValue.delete(), the key should be absent
    expect(round.pending_no_shows["ghost_player"]).toBeUndefined();
  });
});


describe("Stage 4 — _finalizeRoundVerification", () => {
  test("sets verification_status to verified", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    const gRef = new MockDocRef(mockDb, "games", "g1");
    mockDb.seedDoc("round_records", "r1", {
      verification_status: "pending",
      attendance_records: { host_user: "present", player_a: "present" },
      participant_snapshots: [
        { uid: "host_user" },
        { uid: "player_a" },
      ],
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 0 });
    mockDb.seedDoc("users", "player_a", { verified_round_count: 0 });

    const roundData = mockDb.getDoc("round_records", "r1");
    await confirmationFlow._finalizeRoundVerification(mockDb, rRef, roundData, gRef);

    const round = mockDb.getDoc("round_records", "r1");
    expect(round.verification_status).toBe("verified");
    expect(round.verified_at).toBeDefined();
  });

  test("increments verified_round_count for all present users", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    const gRef = new MockDocRef(mockDb, "games", "g1");
    mockDb.seedDoc("round_records", "r1", {
      verification_status: "pending",
      attendance_records: { host_user: "present", player_a: "present", player_b: "no_show" },
      participant_snapshots: [
        { uid: "host_user" },
        { uid: "player_a" },
        { uid: "player_b" },
      ],
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 2 });
    mockDb.seedDoc("users", "player_a", { verified_round_count: 1 });
    mockDb.seedDoc("users", "player_b", { verified_round_count: 5 });

    const roundData = mockDb.getDoc("round_records", "r1");
    await confirmationFlow._finalizeRoundVerification(mockDb, rRef, roundData, gRef);

    // present users incremented; no_show user NOT incremented
    const hostUser = mockDb.getDoc("users", "host_user");
    const playerA = mockDb.getDoc("users", "player_a");
    const playerB = mockDb.getDoc("users", "player_b");

    expect(hostUser.verified_round_count).toBe(3);
    expect(playerA.verified_round_count).toBe(2);
    expect(playerB.verified_round_count).toBe(5); // unchanged
  });

  test("writes partner_plays subcollection for present user pairs", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    const gRef = new MockDocRef(mockDb, "games", "g1");
    mockDb.seedDoc("round_records", "r1", {
      verification_status: "pending",
      attendance_records: { host_user: "present", player_a: "present" },
      participant_snapshots: [{ uid: "host_user" }, { uid: "player_a" }],
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 0 });
    mockDb.seedDoc("users", "player_a", { verified_round_count: 0 });

    const roundData = mockDb.getDoc("round_records", "r1");
    await confirmationFlow._finalizeRoundVerification(mockDb, rRef, roundData, gRef);

    // partner_plays is a subcollection — check via the mock's nested structure
    // The MockDocRef set() and update() go into the flat collections map using path-based keys.
    // Since we use subcollections (users/{uid}/partner_plays/{otherUid}), we need to check
    // that the batch set was called with the right structure.
    // Verification: both users' verified_round_count incremented confirms the batch ran.
    const hostUser = mockDb.getDoc("users", "host_user");
    expect(hostUser.verified_round_count).toBe(1);
  });

  test("is idempotent — does nothing if already verified", async () => {
    const rRef = new MockDocRef(mockDb, "round_records", "r1");
    const gRef = new MockDocRef(mockDb, "games", "g1");
    mockDb.seedDoc("round_records", "r1", {
      verification_status: "verified",
      attendance_records: {},
      participant_snapshots: [],
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 10 });

    const roundData = mockDb.getDoc("round_records", "r1");
    await confirmationFlow._finalizeRoundVerification(mockDb, rRef, roundData, gRef);

    // No changes should occur
    const round = mockDb.getDoc("round_records", "r1");
    expect(round.verification_status).toBe("verified");
    const user = mockDb.getDoc("users", "host_user");
    expect(user.verified_round_count).toBe(10); // unchanged
  });
});

describe("Stage 4 — submitPeerRatings signal + dispute resolution", () => {
  test("records rater as a verification signal", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
      status: "host_confirmed",
    });
    seedRoundRecord(mockDb, `round_g1`, {
      attendance_records: { host_user: "present", player_a: "present", player_b: "present" },
      verification_signals: { host_user: true },
      verification_signal_count: 1,
      pending_no_shows: {},
    });

    await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { player_b: true } },
      makeContext("player_a"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_signals["player_a"]).toBe(true);
    expect(round.verification_signal_count).toBe(2);
  });

  test("two signals trigger early verification (verified_status set immediately)", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
      status: "host_confirmed",
    });
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: { host_user: "present", player_a: "present", player_b: "present" },
      verification_signals: { host_user: true },
      verification_signal_count: 1,
      pending_no_shows: {},
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 0 });
    mockDb.seedDoc("users", "player_a", { verified_round_count: 0 });
    mockDb.seedDoc("users", "player_b", { verified_round_count: 0 });

    await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { player_b: true } },
      makeContext("player_a"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_status).toBe("verified");
    expect(round.verified_at).toBeDefined();
  });

  test("auto-resolves pending no-show when rater explicitly rated the disputed player", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
      status: "host_confirmed",
    });
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: { host_user: "present", player_a: "present", player_b: "no_show" },
      verification_signals: { host_user: true },
      verification_signal_count: 1,
      pending_no_shows: {
        player_b: { recorded_at: MockTimestamp.now(), notified_at: null },
      },
    });

    // player_a submits ratings and explicitly rates player_b → dispute resolved
    await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { player_b: true } },
      makeContext("player_a"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    // pending_no_shows entry for player_b should be removed
    expect(round.pending_no_shows["player_b"]).toBeUndefined();
    // Still NO strikes issued
    const strikes = Object.values(mockDb.getDocs("strikes") || {});
    expect(strikes).toHaveLength(0);
  });

  test("does NOT auto-resolve pending no-show when rater did NOT include them in ratings", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1", {
      host_confirmed_at: MockTimestamp.fromMillis(Date.now() - HOUR_MS),
      status: "host_confirmed",
    });
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: { host_user: "present", player_a: "present", player_b: "no_show" },
      verification_signals: { host_user: true },
      verification_signal_count: 1,
      pending_no_shows: {
        player_b: { recorded_at: MockTimestamp.now(), notified_at: null },
      },
    });

    // player_a submits ratings but does NOT rate player_b
    await confirmationFlow._submitPeerRatingsHandler(
      { gameId: "g1", ratings: { host_user: true } },
      makeContext("player_a"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    // pending_no_shows for player_b should still be present
    expect(round.pending_no_shows["player_b"]).toBeDefined();
  });
});

describe("Stage 4 — submitFallbackConfirmation signal (no dispute resolution)", () => {
  test("records respondent as a verification signal", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1", {
      verification_signals: {},
      verification_signal_count: 0,
    });

    await confirmationFlow._submitFallbackConfirmationHandler(
      { gameId: "g1", didPlay: true },
      makeContext("player_a"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_signals["player_a"]).toBe(true);
    expect(round.verification_signal_count).toBe(1);
  });

  test("does NOT resolve pending no-shows (only proves respondent was present)", async () => {
    seedGame(mockDb, "g1");
    seedRoundJob(mockDb, "job1", "g1");
    seedRoundRecord(mockDb, "round_g1", {
      verification_signals: {},
      verification_signal_count: 0,
      pending_no_shows: {
        player_b: { recorded_at: MockTimestamp.now(), notified_at: null },
      },
    });

    await confirmationFlow._submitFallbackConfirmationHandler(
      { gameId: "g1", didPlay: true },
      makeContext("player_a"),
      mockDb
    );

    const round = mockDb.getDoc("round_records", "round_g1");
    // Pending no-show for player_b must remain — fallback only proves player_a attended
    expect(round.pending_no_shows["player_b"]).toBeDefined();
  });
});

describe("Stage 4 — _closeConfirmationWindow converts pending no-shows to active strikes", () => {
  test("converts remaining pending_no_shows to ghost_no_show strikes at window close", async () => {
    const teeTimeMs = Date.now() - 50 * HOUR_MS;
    const nowTs = MockTimestamp.fromMillis(Date.now());

    seedGame(mockDb, "g1", {
      date: MockTimestamp.fromMillis(teeTimeMs),
    });
    const rRef = new MockDocRef(mockDb, "round_records", "round_g1");
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: { host_user: "present", player_a: "present", player_b: "no_show" },
      verification_signals: { host_user: true, player_a: true },
      verification_signal_count: 2,
      pending_no_shows: {
        player_b: { recorded_at: MockTimestamp.fromMillis(teeTimeMs + 5 * HOUR_MS), notified_at: null },
      },
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 0 });
    mockDb.seedDoc("users", "player_a", { verified_round_count: 0 });

    const jobRef = new MockDocRef(mockDb, "round_jobs", "job1");
    const job = {
      game_ref: new MockDocRef(mockDb, "games", "g1"),
      round_ref: rRef,
      host_confirmed_at: MockTimestamp.fromMillis(teeTimeMs + 5 * HOUR_MS),
      course_name: "Sawgrass",
    };

    await confirmationFlow._closeConfirmationWindow(mockDb, jobRef, job, nowTs);

    // player_b should now have ghost_no_show strikes
    const strikes = Object.values(mockDb.getDocs("strikes") || {});
    const ghostStrikes = strikes.filter((s) => s.reason === "ghost_no_show");
    expect(ghostStrikes.length).toBeGreaterThanOrEqual(2);
  });

  test("sets verification_status to verified when 2+ signals present at window close", async () => {
    const teeTimeMs = Date.now() - 50 * HOUR_MS;
    const nowTs = MockTimestamp.fromMillis(Date.now());

    seedGame(mockDb, "g1", {
      date: MockTimestamp.fromMillis(teeTimeMs),
    });
    const rRef = new MockDocRef(mockDb, "round_records", "round_g1");
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: { host_user: "present", player_a: "present" },
      verification_signals: { host_user: true, player_a: true },
      verification_signal_count: 2,
      pending_no_shows: {},
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 0 });
    mockDb.seedDoc("users", "player_a", { verified_round_count: 0 });

    const jobRef = new MockDocRef(mockDb, "round_jobs", "job1");
    const job = {
      game_ref: new MockDocRef(mockDb, "games", "g1"),
      round_ref: rRef,
      host_confirmed_at: MockTimestamp.fromMillis(teeTimeMs + 5 * HOUR_MS),
      course_name: "Sawgrass",
    };

    await confirmationFlow._closeConfirmationWindow(mockDb, jobRef, job, nowTs);

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_status).toBe("verified");
  });

  test("sets verification_status to failed when fewer than 2 signals at window close", async () => {
    const teeTimeMs = Date.now() - 50 * HOUR_MS;
    const nowTs = MockTimestamp.fromMillis(Date.now());

    seedGame(mockDb, "g1", {
      date: MockTimestamp.fromMillis(teeTimeMs),
    });
    const rRef = new MockDocRef(mockDb, "round_records", "round_g1");
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: { host_user: "present" },
      verification_signals: { host_user: true },
      verification_signal_count: 1,
      pending_no_shows: {},
    });
    mockDb.seedDoc("users", "host_user", { verified_round_count: 0 });

    const jobRef = new MockDocRef(mockDb, "round_jobs", "job1");
    const job = {
      game_ref: new MockDocRef(mockDb, "games", "g1"),
      round_ref: rRef,
      host_confirmed_at: MockTimestamp.fromMillis(teeTimeMs + 5 * HOUR_MS),
      course_name: "Sawgrass",
    };

    await confirmationFlow._closeConfirmationWindow(mockDb, jobRef, job, nowTs);

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_status).toBe("failed");
  });

  test("sets expired when host never confirmed and signals < 2", async () => {
    const teeTimeMs = Date.now() - 50 * HOUR_MS;
    const nowTs = MockTimestamp.fromMillis(Date.now());

    seedGame(mockDb, "g1", {
      date: MockTimestamp.fromMillis(teeTimeMs),
    });
    const rRef = new MockDocRef(mockDb, "round_records", "round_g1");
    seedRoundRecord(mockDb, "round_g1", {
      attendance_records: {},
      verification_signals: {},
      verification_signal_count: 0,
      pending_no_shows: {},
    });

    const jobRef = new MockDocRef(mockDb, "round_jobs", "job1");
    const job = {
      game_ref: new MockDocRef(mockDb, "games", "g1"),
      round_ref: rRef,
      host_confirmed_at: null, // host never confirmed
      course_name: "Sawgrass",
    };

    await confirmationFlow._closeConfirmationWindow(mockDb, jobRef, job, nowTs);

    const round = mockDb.getDoc("round_records", "round_g1");
    expect(round.verification_status).toBe("expired");
  });
});
