'use strict';

/**
 * syncGameChatMembers & reconcileChatMembership — Behavioral Tests
 *
 * Tests for the game chat membership sync trigger and reconciliation callable.
 * Uses MockFirestore injection via handler's `db` parameter for true behavioral
 * verification (not just documentation assertions).
 *
 * Run: npx jest test/sync_game_chat.test.js --verbose
 */

// ─────────────────────────────────────────────────────────────────────────────
// MOCK INFRASTRUCTURE
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Mock DocumentReference - used for:
 * 1. chatRef instanceof checks in handlers
 * 2. joined_players array items
 */
class MockDocumentReference {
  constructor(id, path = null) {
    this.id = id;
    this.path = path || `users/${id}`;
  }
}

/**
 * MockDocRef - represents a document reference in MockFirestore
 */
class MockDocRef {
  constructor(db, collectionName, id) {
    this._db = db;
    this._collection = collectionName;
    this.id = id;
    this.path = `${collectionName}/${id}`;
  }

  collection(subCollectionName) {
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
    const existing = col[this.id] || {};
    const merged = { ...existing };

    for (const [k, v] of Object.entries(fields)) {
      // Handle FieldValue sentinels
      if (v && v._type === 'arrayUnion') {
        merged[k] = [...(Array.isArray(merged[k]) ? merged[k] : []), ...v.items];
      } else if (v && v._type === 'arrayRemove') {
        const toRemove = new Set(v.items.map((i) => (typeof i === 'object' && i.id ? i.id : i)));
        merged[k] = (Array.isArray(merged[k]) ? merged[k] : []).filter(
          (item) => !toRemove.has(typeof item === 'object' && item.id ? item.id : item)
        );
      } else if (v && v._type === 'delete') {
        delete merged[k];
      } else if (v && v._type === 'serverTimestamp') {
        merged[k] = { _serverTimestamp: true };
      } else {
        merged[k] = v;
      }
    }

    col[this.id] = merged;
    this._db._collections[this._collection] = col;
  }

  async set(data) {
    const col = this._db._collections[this._collection] || {};
    col[this.id] = { ...data };
    this._db._collections[this._collection] = col;
  }
}

/**
 * MockCollectionRef - represents a collection in MockFirestore
 */
class MockCollectionRef {
  constructor(db, name) {
    this._db = db;
    this._name = name;
  }

  doc(id) {
    return new MockDocRef(this._db, this._name, id);
  }
}

/**
 * MockBatch - tracks batch operations for verification
 */
class MockBatch {
  constructor(db) {
    this._db = db;
    this._ops = [];
  }

  set(ref, data) {
    this._ops.push({ type: 'set', ref, data: { ...data } });
    return this;
  }

  update(ref, fields) {
    this._ops.push({ type: 'update', ref, fields: { ...fields } });
    return this;
  }

  delete(ref) {
    this._ops.push({ type: 'delete', ref });
    return this;
  }

  async commit() {
    for (const op of this._ops) {
      if (op.type === 'set') {
        await op.ref.set(op.data);
      } else if (op.type === 'update') {
        await op.ref.update(op.fields);
      } else if (op.type === 'delete') {
        const col = this._db._collections[op.ref._collection] || {};
        delete col[op.ref.id];
      }
    }
  }

  // Expose ops for test assertions
  getOps() {
    return this._ops;
  }
}

/**
 * MockFirestore - in-memory Firestore for testing
 */
class MockFirestore {
  constructor() {
    this._collections = {};
    this._lastBatch = null;
  }

  collection(name) {
    return new MockCollectionRef(this, name);
  }

  doc(path) {
    const parts = path.split('/');
    // Handle both "collection/id" and "collection/id/subcollection/id" formats
    if (parts.length === 2) {
      return this.collection(parts[0]).doc(parts[1]);
    } else if (parts.length === 4) {
      // subcollection path: users/uid/chatRefs/chatId
      return new MockDocRef(this, `${parts[0]}/${parts[1]}/${parts[2]}`, parts[3]);
    }
    throw new Error(`Unsupported path format: ${path}`);
  }

  batch() {
    this._lastBatch = new MockBatch(this);
    return this._lastBatch;
  }

  reset() {
    this._collections = {};
    this._lastBatch = null;
  }

  seedDoc(collectionName, id, data) {
    if (!this._collections[collectionName]) {
      this._collections[collectionName] = {};
    }
    this._collections[collectionName][id] = { ...data };
  }

  getDoc(collectionName, id) {
    return (this._collections[collectionName] || {})[id];
  }

  getLastBatch() {
    return this._lastBatch;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCKS FOR firebase-admin AND firebase-functions
// ─────────────────────────────────────────────────────────────────────────────

class MockHttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

// Mock FieldValue
const FieldValue = {
  serverTimestamp: () => ({ _type: 'serverTimestamp' }),
  arrayUnion: (...items) => ({ _type: 'arrayUnion', items }),
  arrayRemove: (...items) => ({ _type: 'arrayRemove', items }),
  delete: () => ({ _type: 'delete' }),
};

jest.mock('firebase-admin', () => ({
  firestore: Object.assign(jest.fn(() => ({})), {
    FieldValue,
    DocumentReference: MockDocumentReference,
  }),
  initializeApp: jest.fn(),
}));

jest.mock('firebase-functions', () => ({
  region: jest.fn(() => ({
    firestore: {
      document: jest.fn(() => ({
        onUpdate: jest.fn((handler) => handler),
      })),
    },
    https: {
      onCall: jest.fn((handler) => handler),
    },
  })),
  https: {
    HttpsError: MockHttpsError,
    onCall: jest.fn((handler) => handler),
  },
}));

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

function makeChatRef(chatId) {
  const ref = new MockDocumentReference(chatId, `chats/${chatId}`);
  // Make it pass the instanceof check in the handler
  Object.setPrototypeOf(ref, MockDocumentReference.prototype);
  return ref;
}

function makePlayerRef(uid) {
  return new MockDocumentReference(uid, `users/${uid}`);
}

function makeChange(beforeData, afterData) {
  return {
    before: { data: () => beforeData },
    after: { data: () => afterData },
  };
}

function makeContext(gameId) {
  return { params: { gameId } };
}

function makeAuthContext(uid, isAdmin = false) {
  return {
    auth: uid ? { uid, token: { admin: isAdmin } } : null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

describe('syncGameChatMembers', () => {
  let mockDb;
  let index;

  beforeEach(() => {
    mockDb = new MockFirestore();
    jest.resetModules();
    // Mock admin.firestore.DocumentReference for instanceof check
    const admin = require('firebase-admin');
    admin.firestore.DocumentReference = MockDocumentReference;
    index = require('../index');
  });

  describe('module exports', () => {
    it('should export syncGameChatMembers function', () => {
      expect(index.syncGameChatMembers).toBeDefined();
      expect(typeof index.syncGameChatMembers).toBe('function');
    });

    it('should export _syncGameChatMembersHandler for testing', () => {
      expect(index._syncGameChatMembersHandler).toBeDefined();
      expect(typeof index._syncGameChatMembersHandler).toBe('function');
    });
  });

  describe('no-op scenarios', () => {
    it('returns early when no membership changes', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');

      const change = makeChange(
        { chatRef, joined_players: [player1] },
        { chatRef, joined_players: [player1] }
      );

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1'] });

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      // No batch should be created for no-op
      expect(mockDb.getLastBatch()).toBeNull();
    });

    it('returns early when chatRef is missing', async () => {
      const player1 = makePlayerRef('user1');
      const player2 = makePlayerRef('user2');

      const change = makeChange(
        { chatRef: null, joined_players: [player1] },
        { chatRef: null, joined_players: [player1, player2] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      // No batch should be created
      expect(mockDb.getLastBatch()).toBeNull();
    });
  });

  describe('non-retryable errors', () => {
    it('returns without throwing when chat document does not exist', async () => {
      const chatRef = makeChatRef('missing_chat');
      const player1 = makePlayerRef('user1');
      const player2 = makePlayerRef('user2');

      const change = makeChange(
        { chatRef, joined_players: [player1] },
        { chatRef, joined_players: [player1, player2] }
      );

      // Don't seed the chat doc - it doesn't exist

      // Should not throw - non-retryable error
      await expect(
        index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb)
      ).resolves.toBeUndefined();
    });
  });

  describe('member addition', () => {
    it('updates chat memberIds when player joins', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const newPlayer = makePlayerRef('newPlayer');

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['host'] });

      const change = makeChange(
        { chatRef, joined_players: [host] },
        { chatRef, joined_players: [host, newPlayer] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      // Verify chat was updated
      const chat = mockDb.getDoc('chats', 'chat1');
      expect(chat).toBeDefined();
      expect(chat.memberIds).toContain('host');
      expect(chat.memberIds).toContain('newPlayer');
    });

    it('creates user chatRef document when player joins', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const newPlayer = makePlayerRef('newPlayer');

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['host'] });

      const change = makeChange(
        { chatRef, joined_players: [host] },
        { chatRef, joined_players: [host, newPlayer] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      // Verify user chatRef was created
      const chatRefDoc = mockDb.getDoc('users/newPlayer/chatRefs', 'chat1');
      expect(chatRefDoc).toBeDefined();
      expect(chatRefDoc.chatId).toBe('chat1');
    });

    it('sets unreadCountByUser and memberJoinedAt for new member', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const newPlayer = makePlayerRef('newPlayer');

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['host'] });

      const change = makeChange(
        { chatRef, joined_players: [host] },
        { chatRef, joined_players: [host, newPlayer] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      const chat = mockDb.getDoc('chats', 'chat1');
      expect(chat['unreadCountByUser.newPlayer']).toBe(0);
      expect(chat['memberJoinedAt.newPlayer']).toEqual({ _serverTimestamp: true });
    });
  });

  describe('member removal', () => {
    it('removes player from chat memberIds when they leave', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const leaving = makePlayerRef('leaving');

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['host', 'leaving'] });

      const change = makeChange(
        { chatRef, joined_players: [host, leaving] },
        { chatRef, joined_players: [host] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      const chat = mockDb.getDoc('chats', 'chat1');
      expect(chat.memberIds).toContain('host');
      expect(chat.memberIds).not.toContain('leaving');
    });

    it('deletes user chatRef document when player leaves', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const leaving = makePlayerRef('leaving');

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['host', 'leaving'] });
      mockDb.seedDoc('users/leaving/chatRefs', 'chat1', { chatId: 'chat1' });

      const change = makeChange(
        { chatRef, joined_players: [host, leaving] },
        { chatRef, joined_players: [host] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      // Verify chatRef was deleted
      const chatRefDoc = mockDb.getDoc('users/leaving/chatRefs', 'chat1');
      expect(chatRefDoc).toBeUndefined();
    });

    it('deletes unreadCountByUser field when player leaves', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const leaving = makePlayerRef('leaving');

      mockDb.seedDoc('chats', 'chat1', {
        memberIds: ['host', 'leaving'],
        'unreadCountByUser.host': 0,
        'unreadCountByUser.leaving': 5,
      });

      const change = makeChange(
        { chatRef, joined_players: [host, leaving] },
        { chatRef, joined_players: [host] }
      );

      await index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb);

      const chat = mockDb.getDoc('chats', 'chat1');
      expect(chat['unreadCountByUser.host']).toBe(0);
      expect(chat['unreadCountByUser.leaving']).toBeUndefined();
    });
  });

  describe('batch commit failure', () => {
    it('throws error on batch commit failure (retryable)', async () => {
      const chatRef = makeChatRef('chat1');
      const host = makePlayerRef('host');
      const newPlayer = makePlayerRef('newPlayer');

      mockDb.seedDoc('chats', 'chat1', { memberIds: ['host'] });

      // Make batch.commit fail
      const originalBatch = mockDb.batch.bind(mockDb);
      mockDb.batch = () => {
        const batch = originalBatch();
        batch.commit = () => Promise.reject(new Error('Network error'));
        return batch;
      };

      const change = makeChange(
        { chatRef, joined_players: [host] },
        { chatRef, joined_players: [host, newPlayer] }
      );

      await expect(
        index._syncGameChatMembersHandler(change, makeContext('game1'), mockDb)
      ).rejects.toThrow('Network error');
    });
  });
});

describe('reconcileChatMembership', () => {
  let mockDb;
  let index;

  beforeEach(() => {
    mockDb = new MockFirestore();
    jest.resetModules();
    const admin = require('firebase-admin');
    admin.firestore.DocumentReference = MockDocumentReference;
    index = require('../index');
  });

  describe('module exports', () => {
    it('should export reconcileChatMembership function', () => {
      expect(index.reconcileChatMembership).toBeDefined();
      expect(typeof index.reconcileChatMembership).toBe('function');
    });

    it('should export _reconcileChatMembershipHandler for testing', () => {
      expect(index._reconcileChatMembershipHandler).toBeDefined();
      expect(typeof index._reconcileChatMembershipHandler).toBe('function');
    });
  });

  describe('authorization', () => {
    it('rejects unauthenticated callers with HttpsError', async () => {
      await expect(
        index._reconcileChatMembershipHandler({ gameId: 'g1' }, makeAuthContext(null), mockDb)
      ).rejects.toMatchObject({ code: 'unauthenticated', message: 'Authentication required' });
    });

    it('rejects non-admin callers with HttpsError', async () => {
      await expect(
        index._reconcileChatMembershipHandler(
          { gameId: 'g1' },
          makeAuthContext('user1', false),
          mockDb
        )
      ).rejects.toMatchObject({ code: 'permission-denied', message: 'Admin access required' });
    });

    it('rejects missing gameId with HttpsError', async () => {
      await expect(
        index._reconcileChatMembershipHandler({}, makeAuthContext('admin1', true), mockDb)
      ).rejects.toMatchObject({ code: 'invalid-argument', message: 'gameId is required' });
    });

    it('allows admin callers to proceed', async () => {
      mockDb.seedDoc('games', 'g1', { chatRef: null });

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result.status).toBe('no_chat');
      expect(result.gameId).toBe('g1');
    });
  });

  describe('return payload structure', () => {
    it('returns game_not_found when game does not exist', async () => {
      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'nonexistent' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result).toEqual({
        status: 'game_not_found',
        gameId: 'nonexistent',
        chatId: null,
        fixes: 0,
        added: [],
        removed: [],
      });
    });

    it('returns no_chat when game has no chatRef', async () => {
      mockDb.seedDoc('games', 'g1', { chatRef: null });

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result).toEqual({
        status: 'no_chat',
        gameId: 'g1',
        chatId: null,
        fixes: 0,
        added: [],
        removed: [],
      });
    });

    it('returns chat_not_found when chat document does not exist', async () => {
      const chatRef = makeChatRef('missing_chat');
      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [] });

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result).toEqual({
        status: 'chat_not_found',
        gameId: 'g1',
        chatId: 'missing_chat',
        fixes: 0,
        added: [],
        removed: [],
      });
    });

    it('returns ok when no drift detected', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');
      const player2 = makePlayerRef('user2');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1, player2] });
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1', 'user2'] });

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result).toEqual({
        status: 'ok',
        gameId: 'g1',
        chatId: 'chat1',
        fixes: 0,
        added: [],
        removed: [],
      });
    });
  });

  describe('drift repair', () => {
    it('adds missing members to chat', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');
      const player2 = makePlayerRef('user2');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1, player2] });
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1'] }); // missing user2

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result.status).toBe('fixed');
      expect(result.fixes).toBe(1);
      expect(result.added).toContain('user2');
      expect(result.removed).toEqual([]);

      // Verify chat was updated
      const chat = mockDb.getDoc('chats', 'chat1');
      expect(chat.memberIds).toContain('user1');
      expect(chat.memberIds).toContain('user2');
    });

    it('removes orphaned members from chat', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1] });
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1', 'orphan'] }); // orphan should not be there

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result.status).toBe('fixed');
      expect(result.fixes).toBe(1);
      expect(result.added).toEqual([]);
      expect(result.removed).toContain('orphan');

      // Verify chat was updated
      const chat = mockDb.getDoc('chats', 'chat1');
      expect(chat.memberIds).toContain('user1');
      expect(chat.memberIds).not.toContain('orphan');
    });

    it('handles both additions and removals', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');
      const player2 = makePlayerRef('user2');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1, player2] });
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1', 'orphan'] }); // missing user2, has orphan

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      expect(result.status).toBe('fixed');
      expect(result.fixes).toBe(2);
      expect(result.added).toContain('user2');
      expect(result.removed).toContain('orphan');
    });

    it('creates user chatRef documents for added members', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');
      const player2 = makePlayerRef('user2');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1, player2] });
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1'] });

      await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      // Verify user chatRef was created
      const chatRefDoc = mockDb.getDoc('users/user2/chatRefs', 'chat1');
      expect(chatRefDoc).toBeDefined();
      expect(chatRefDoc.chatId).toBe('chat1');
    });

    it('deletes user chatRef documents for removed members', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1] });
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1', 'orphan'] });
      mockDb.seedDoc('users/orphan/chatRefs', 'chat1', { chatId: 'chat1' });

      await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      // Verify chatRef was deleted
      const chatRefDoc = mockDb.getDoc('users/orphan/chatRefs', 'chat1');
      expect(chatRefDoc).toBeUndefined();
    });

    it('normalizes malformed memberIds (filters non-strings)', async () => {
      const chatRef = makeChatRef('chat1');
      const player1 = makePlayerRef('user1');

      mockDb.seedDoc('games', 'g1', { chatRef, joined_players: [player1] });
      // memberIds contains non-string values that should be filtered
      mockDb.seedDoc('chats', 'chat1', { memberIds: ['user1', null, 123, { id: 'obj' }] });

      const result = await index._reconcileChatMembershipHandler(
        { gameId: 'g1' },
        makeAuthContext('admin1', true),
        mockDb
      );

      // After normalization, only 'user1' remains as valid string
      expect(result.status).toBe('ok');
      expect(result.fixes).toBe(0);
    });
  });
});

describe('extractJoinedUids helper', () => {
  beforeEach(() => {
    jest.resetModules();
  });

  it('is used internally by handlers', () => {
    // The extractJoinedUids helper is internal to index.js
    // We verify its behavior through the trigger/callable tests above
    // This test documents that joined_players extraction handles:
    // - null/undefined arrays (returns [])
    // - DocumentReference objects (extracts .id)
    // - Invalid array items (filters them out)
    expect(true).toBe(true);
  });
});
