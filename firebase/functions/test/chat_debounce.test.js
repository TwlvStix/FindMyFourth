/**
 * Chat Debounce — Tests
 *
 * Tests for:
 *   - scheduleDebouncedChatNotification: task creation, cancellation, race handling
 *   - deliverChatNotificationHandler: payload validation, unread checks, prefs, FCM send
 *
 * Run with: npx jest test/chat_debounce.test.js
 */

'use strict';

// ─────────────────────────────────────────────────────────────────────────────
// MOCKS — MUST BE DEFINED BEFORE MODULE IMPORTS
// ─────────────────────────────────────────────────────────────────────────────

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

let mockSendEachForMulticast;

jest.mock('firebase-admin', () => {
  mockSendEachForMulticast = jest.fn().mockResolvedValue({
    responses: [{ success: true }],
  });

  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(jest.fn(), {
      FieldValue: {
        serverTimestamp: jest.fn(() => ({ _type: 'serverTimestamp' })),
        increment: jest.fn((n) => ({ _type: 'increment', delta: n })),
        delete: jest.fn(() => ({ _type: 'delete' })),
      },
      Timestamp: {
        fromDate: jest.fn((d) => ({ _seconds: Math.floor(d.getTime() / 1000) })),
        now: jest.fn(() => ({ _seconds: Math.floor(Date.now() / 1000) })),
      },
    }),
    messaging: jest.fn(() => ({
      sendEachForMulticast: mockSendEachForMulticast,
    })),
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DB
// ─────────────────────────────────────────────────────────────────────────────

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
      const parts = k.split('.');
      let target = merged;
      for (let i = 0; i < parts.length - 1; i++) {
        if (!target[parts[i]] || typeof target[parts[i]] !== 'object') {
          target[parts[i]] = {};
        } else {
          target[parts[i]] = { ...target[parts[i]] };
        }
        target = target[parts[i]];
      }
      target[parts[parts.length - 1]] = v;
    }
    col[this.id] = merged;
    this._db._collections[this._collection] = col;
  }
  async set(data) {
    const col = this._db._collections[this._collection] || {};
    col[this.id] = { ...data };
    this._db._collections[this._collection] = col;
  }
  async delete() {
    const col = this._db._collections[this._collection] || {};
    delete col[this.id];
    this._db._collections[this._collection] = col;
  }
}

class MockCollectionRef {
  constructor(db, name) {
    this._db = db;
    this._name = name;
  }
  doc(id) {
    return new MockDocRef(this._db, this._name, id || `auto_${Date.now()}`);
  }
  async get() {
    const col = this._db._collections[this._name] || {};
    const docs = Object.entries(col).map(([id, data]) => ({
      id,
      ref: new MockDocRef(this._db, this._name, id),
      data: () => ({ ...data }),
      exists: true,
    }));
    return {
      empty: docs.length === 0,
      docs,
      size: docs.length,
    };
  }
}

function createMockDb() {
  const db = {
    _collections: {},
    collection(name) {
      return new MockCollectionRef(db, name);
    },
    async runTransaction(fn) {
      // Simple mock transaction — no real locking
      const transaction = {
        get: async (ref) => ref.get(),
        set: (ref, data) => ref.set(data),
        update: (ref, data) => ref.update(data),
        delete: (ref) => ref.delete(),
      };
      return fn(transaction);
    },
  };
  return db;
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTS (after mocks)
// ─────────────────────────────────────────────────────────────────────────────

const {
  scheduleDebouncedChatNotification,
  deliverChatNotificationHandler,
  PENDING_COLLECTION,
} = require('../notifications/chat_debounce');

// Reset the tasks client singleton before each test
const { _resetTasksClient } = require('../notifications/trust/scheduler');

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

function makeRes() {
  const res = {
    _status: null,
    _body: null,
    status(code) { res._status = code; return res; },
    send(body) { res._body = body; return res; },
  };
  return res;
}

function makeReq(body) {
  return { body };
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS: scheduleDebouncedChatNotification
// ─────────────────────────────────────────────────────────────────────────────

describe('scheduleDebouncedChatNotification', () => {
  let db;

  beforeEach(() => {
    db = createMockDb();
    _resetTasksClient();
    mockCreateTask.mockClear();
    mockDeleteTask.mockClear();
    mockCreateTask.mockResolvedValue([{ name: 'projects/x/tasks/new-task-1' }]);
  });

  const messageData = { text: 'Hello!', senderId: 'sender1' };
  const chatData = { type: 'direct', memberIds: ['sender1', 'recipient1'] };

  it('creates a Cloud Task and writes a tracking doc on first message', async () => {
    await scheduleDebouncedChatNotification(
      'chat1', 'recipient1', messageData, 'Alex', chatData, db,
    );

    // Cloud Task created
    expect(mockCreateTask).toHaveBeenCalledTimes(1);
    const callArgs = mockCreateTask.mock.calls[0][0];
    expect(callArgs.parent).toContain('chat-notification-debounce');

    // Tracking doc written
    const docKey = 'chat_chat1_recipient1';
    const col = db._collections[PENDING_COLLECTION] || {};
    expect(col[docKey]).toBeDefined();
    expect(col[docKey].taskName).toBe('projects/x/tasks/new-task-1');
    expect(col[docKey].chatId).toBe('chat1');
    expect(col[docKey].recipientUid).toBe('recipient1');
    expect(col[docKey].senderName).toBe('Alex');
  });

  it('cancels the old task and creates a new one on second message', async () => {
    // First message
    mockCreateTask.mockResolvedValueOnce([{ name: 'projects/x/tasks/task-1' }]);
    await scheduleDebouncedChatNotification(
      'chat1', 'recipient1', messageData, 'Alex', chatData, db,
    );

    // Second message
    mockCreateTask.mockResolvedValueOnce([{ name: 'projects/x/tasks/task-2' }]);
    await scheduleDebouncedChatNotification(
      'chat1', 'recipient1', { text: 'Follow-up!', senderId: 'sender1' }, 'Alex', chatData, db,
    );

    // Old task cancelled
    expect(mockDeleteTask).toHaveBeenCalledTimes(1);
    expect(mockDeleteTask).toHaveBeenCalledWith({ name: 'projects/x/tasks/task-1' });

    // New task created
    expect(mockCreateTask).toHaveBeenCalledTimes(2);

    // Tracking doc updated with new task
    const col = db._collections[PENDING_COLLECTION] || {};
    expect(col['chat_chat1_recipient1'].taskName).toBe('projects/x/tasks/task-2');
    expect(col['chat_chat1_recipient1'].latestMessagePreview).toBe('Follow-up!');
  });

  it('swallows NOT_FOUND (code 5) when cancelling a task that already executed', async () => {
    // First message
    mockCreateTask.mockResolvedValueOnce([{ name: 'projects/x/tasks/task-old' }]);
    await scheduleDebouncedChatNotification(
      'chat1', 'recipient1', messageData, 'Alex', chatData, db,
    );

    // Second message — delete returns NOT_FOUND
    mockDeleteTask.mockRejectedValueOnce({ code: 5 });
    mockCreateTask.mockResolvedValueOnce([{ name: 'projects/x/tasks/task-new' }]);

    await expect(
      scheduleDebouncedChatNotification(
        'chat1', 'recipient1', messageData, 'Alex', chatData, db,
      ),
    ).resolves.not.toThrow();

    expect(mockCreateTask).toHaveBeenCalledTimes(2);
  });

  it('rethrows non-NOT_FOUND errors when cancelling a task', async () => {
    // First message
    mockCreateTask.mockResolvedValueOnce([{ name: 'projects/x/tasks/task-old' }]);
    await scheduleDebouncedChatNotification(
      'chat1', 'recipient1', messageData, 'Alex', chatData, db,
    );

    // Second message — delete returns a real error
    mockDeleteTask.mockRejectedValueOnce({ code: 13, message: 'Internal' });

    await expect(
      scheduleDebouncedChatNotification(
        'chat1', 'recipient1', messageData, 'Alex', chatData, db,
      ),
    ).rejects.toEqual({ code: 13, message: 'Internal' });
  });

  it('sets chatType to game for game chats', async () => {
    const gameChatData = { type: 'group', memberIds: ['a', 'b', 'c'], gameId: 'game123' };
    await scheduleDebouncedChatNotification(
      'chat2', 'recipient1', messageData, 'Alex', gameChatData, db,
    );

    const col = db._collections[PENDING_COLLECTION] || {};
    expect(col['chat_chat2_recipient1'].chatType).toBe('game');
    expect(col['chat_chat2_recipient1'].gameId).toBe('game123');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// TESTS: deliverChatNotificationHandler
// ─────────────────────────────────────────────────────────────────────────────

describe('deliverChatNotificationHandler', () => {
  let db;

  // Seed a mock db that admin.firestore() returns
  beforeEach(() => {
    db = createMockDb();
    _resetTasksClient();
    mockSendEachForMulticast.mockClear();
    mockSendEachForMulticast.mockResolvedValue({
      responses: [{ success: true }],
    });

    // Patch admin.firestore() to return our mock db
    const admin = require('firebase-admin');
    admin.firestore.mockReturnValue(db);
  });

  const basePayload = {
    chatId: 'chat1',
    recipientUid: 'user1',
    senderId: 'sender1',
    senderName: 'Alex',
    latestMessagePreview: 'Hello!',
    chatType: 'direct',
  };

  function seedUser(uid, prefs = {}) {
    db._collections['users'] = db._collections['users'] || {};
    db._collections['users'][uid] = {
      display_name: 'Test User',
      notification_prefs: {
        push_enabled: true,
        chat_alerts: { enabled: true, direct: true, group: true },
        ...prefs,
      },
    };
  }

  function seedDevice(uid, token = 'fcm-token-1') {
    const devicesCol = `users/${uid}/devices`;
    db._collections[devicesCol] = db._collections[devicesCol] || {};
    db._collections[devicesCol]['device1'] = { fcmToken: token };
  }

  function seedTrackingDoc(chatId, uid) {
    const docKey = `chat_${chatId}_${uid}`;
    db._collections[PENDING_COLLECTION] = db._collections[PENDING_COLLECTION] || {};
    db._collections[PENDING_COLLECTION][docKey] = {
      taskName: 'projects/x/tasks/t1',
      chatId,
      recipientUid: uid,
    };
  }

  function seedChat(chatId, unreadByUser = {}) {
    db._collections['chats'] = db._collections['chats'] || {};
    db._collections['chats'][chatId] = {
      memberIds: ['sender1', 'user1'],
      type: 'direct',
      unreadCountByUser: unreadByUser,
    };
  }

  it('returns 400 when chatId or recipientUid is missing', async () => {
    const res = makeRes();
    await deliverChatNotificationHandler(makeReq({}), res);
    expect(res._status).toBe(400);
  });

  it('returns NOT_FOUND when tracking doc is missing', async () => {
    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);
    expect(res._status).toBe(200);
    expect(res._body).toBe('NOT_FOUND');
  });

  it('returns SKIPPED_READ when unread count is 0', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 0 });
    seedUser('user1');

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);
    expect(res._status).toBe(200);
    expect(res._body).toBe('SKIPPED_READ');

    // Tracking doc should be cleaned up
    expect(db._collections[PENDING_COLLECTION]['chat_chat1_user1']).toBeUndefined();
  });

  it('returns PREFS_DISABLED when push is disabled', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 3 });
    seedUser('user1', { push_enabled: false });

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);
    expect(res._status).toBe(200);
    expect(res._body).toBe('PREFS_DISABLED');
  });

  it('returns PREFS_DISABLED when chat is muted', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 1 });
    seedUser('user1', { muted_threads: ['chat1'] });

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);
    expect(res._status).toBe(200);
    expect(res._body).toBe('PREFS_DISABLED');
  });

  it('sends a single-message notification with preview body', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 1 });
    seedUser('user1');
    seedDevice('user1');

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');
    expect(mockSendEachForMulticast).toHaveBeenCalledTimes(1);

    const msg = mockSendEachForMulticast.mock.calls[0][0];
    expect(msg.notification.title).toBe('Alex');
    expect(msg.notification.body).toBe('Hello!');

    // Tracking doc cleaned up
    expect(db._collections[PENDING_COLLECTION]['chat_chat1_user1']).toBeUndefined();
  });

  it('sends a multi-message notification with count body', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 3 });
    seedUser('user1');
    seedDevice('user1');

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');

    const msg = mockSendEachForMulticast.mock.calls[0][0];
    expect(msg.notification.title).toBe('Alex');
    expect(msg.notification.body).toBe('Alex sent you 3 messages');
  });

  it('uses group chat title and count body for group chats', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 5 });
    seedUser('user1');
    seedDevice('user1');

    // Override chat to be a group
    db._collections['chats']['chat1'].type = 'group';
    db._collections['chats']['chat1'].memberIds = ['sender1', 'user1', 'user2'];

    const groupPayload = { ...basePayload, chatType: 'group' };
    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(groupPayload), res);

    const msg = mockSendEachForMulticast.mock.calls[0][0];
    expect(msg.notification.title).toBe('Group chat');
    expect(msg.notification.body).toBe('5 new messages');
  });

  it('uses game chat title for game chats', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 1 });
    seedUser('user1');
    seedDevice('user1');

    const gamePayload = { ...basePayload, chatType: 'game' };
    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(gamePayload), res);

    const msg = mockSendEachForMulticast.mock.calls[0][0];
    expect(msg.notification.title).toBe('Game chat');
    expect(msg.notification.body).toBe('Alex: Hello!');
  });

  it('cleans up invalid FCM tokens', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 1 });
    seedUser('user1');
    seedDevice('user1', 'invalid-token');

    mockSendEachForMulticast.mockResolvedValueOnce({
      responses: [{
        success: false,
        error: { code: 'messaging/registration-token-not-registered' },
      }],
    });

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');

    // Device doc should be deleted
    const devicesCol = db._collections['users/user1/devices'] || {};
    expect(devicesCol['device1']).toBeUndefined();
  });

  it('writes a notification doc to the user notifications subcollection', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 1 });
    seedUser('user1');
    seedDevice('user1');

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);

    // Check notification was written
    const notifCol = db._collections['users/user1/notifications'] || {};
    const notifKeys = Object.keys(notifCol);
    expect(notifKeys.length).toBe(1);
    expect(notifKeys[0]).toMatch(/^chat_chat1_debounced_/);

    const notif = notifCol[notifKeys[0]];
    expect(notif.type).toBe('chat_message');
    expect(notif.title).toBe('Alex');
    expect(notif.read).toBe(false);
  });

  it('returns OK even when no devices exist (no FCM sent)', async () => {
    seedTrackingDoc('chat1', 'user1');
    seedChat('chat1', { user1: 1 });
    seedUser('user1');
    // No devices seeded

    const res = makeRes();
    await deliverChatNotificationHandler(makeReq(basePayload), res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');
    expect(mockSendEachForMulticast).not.toHaveBeenCalled();
  });
});
