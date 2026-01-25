const path = require('node:path');
const fs = require('node:fs');
const { test, before, after, beforeEach } = require('node:test');

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  arrayUnion,
  arrayRemove,
  Timestamp,
} = require('firebase/firestore');

const projectId = 'demo-findmyfourth';
const rules = fs.readFileSync(
  path.join(__dirname, '../firestore.rules'),
  'utf8',
);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthDb() {
  return testEnv.unauthenticatedContext().firestore();
}

function buildGameData(db, {
  ownerUid,
  joinedUids = [ownerUid],
  maxPlayers = 4,
  status = 'active',
  isCancelled = false,
  friendGame = 'Public',
} = {}) {
  const ownerRef = doc(db, 'users', ownerUid);
  return {
    uid: ownerUid,
    userRef: ownerRef,
    name_game: 'Test Game',
    date: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
    num_players: 1,
    style_game: 'Stroke',
    game_type: 'Scramble',
    course_play: 'Test Course',
    member_discount: 'None',
    scoring: 'Gross',
    friend_game: friendGame,
    max_players: maxPlayers,
    rules_setting: 'Standard',
    created_time: Timestamp.fromMillis(Date.now()),
    chatRef: doc(db, 'chats', 'chat1'),
    courseRef: doc(db, 'course', 'course1'),
    isCancelled,
    status,
    joined_players: joinedUids.map((uid) => doc(db, 'users', uid)),
    guest_players: [],
  };
}

async function seedGame(gameId, dataOverrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const data = buildGameData(db, dataOverrides);
    await setDoc(doc(db, 'games', gameId), data);
  });
}

async function seedUser(uid, { friends = [], friendRequests = [] } = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', uid), {
      uid,
      friends: friends.map((friendUid) => doc(db, 'users', friendUid)),
      friend_requests: friendRequests,
    });
  });
}

async function seedChat(chatId, {
  memberIds = ['userA', 'userB'],
  type = 'direct',
  gameId = null,
  gameName = null,
} = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const sortedMembers = [...memberIds].sort();
    const users = memberIds.map((uid) => doc(db, 'users', uid));
    const data = {
      memberIds,
      users,
      type,
      directKey: type === 'direct' ? sortedMembers.join('_') : null,
      gameId: type === 'game' ? gameId : null,
      gameName: type === 'game' ? (gameName ?? 'Test Game') : null,
      last_message: '',
      isReadOnly: false,
      pinnedMessage: '',
      pinnedAt: null,
      archivedAt: null,
      lastMessageAt: Timestamp.fromMillis(Date.now()),
      lastMessageSenderId: memberIds[0],
      unreadCountByUser: Object.fromEntries(
        memberIds.map((uid) => [uid, 0]),
      ),
      createdAt: Timestamp.fromMillis(Date.now()),
      updatedAt: Timestamp.fromMillis(Date.now()),
    };
    await setDoc(doc(db, 'chats', chatId), data);
  });
}

async function seedMessage(chatId, messageId, {
  senderId = 'userA',
  text = 'Hello',
} = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'chats', chatId, 'messages', messageId), {
      senderId,
      text,
      imageUrl: '',
      videoUrl: '',
      createdAt: Timestamp.fromMillis(Date.now()),
      reactions: {},
      readBy: [senderId],
    });
  });
}

test('userA can create their own game', async () => {
  const db = authedDb('userA');
  const data = buildGameData(db, { ownerUid: 'userA' });
  await assertSucceeds(setDoc(doc(db, 'games', 'game1'), data));
});

test('unauthenticated users cannot read games', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = unauthDb();
  await assertFails(getDoc(doc(db, 'games', 'game1')));
});

test('userB cannot update userA game', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userB');
  await assertFails(updateDoc(doc(db, 'games', 'game1'), {
    scoring: 'Net',
  }));
});

test('userB cannot delete userA game', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userB');
  await assertFails(deleteDoc(doc(db, 'games', 'game1')));
});

test('owner can update allowed fields', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userA');
  await assertSucceeds(updateDoc(doc(db, 'games', 'game1'), {
    scoring: 'Stableford',
    status: 'completed',
  }));
});

test('participant can join by adding only self', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'games', 'game1'), {
    joined_players: arrayUnion(doc(db, 'users', 'userB')),
  }));
});

test('participant can leave by removing only self', async () => {
  await seedGame('game1', { ownerUid: 'userA', joinedUids: ['userA', 'userB'] });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'games', 'game1'), {
    joined_players: arrayRemove(doc(db, 'users', 'userB')),
  }));
});

test('participant cannot update owner-only fields', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userB');
  await assertFails(updateDoc(doc(db, 'games', 'game1'), {
    status: 'completed',
  }));
});

test('non-participant cannot add someone else', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userB');
  await assertFails(updateDoc(doc(db, 'games', 'game1'), {
    joined_players: arrayUnion(doc(db, 'users', 'userC')),
  }));
});

test('owner cannot change immutable uid', async () => {
  await seedGame('game1', { ownerUid: 'userA' });
  const db = authedDb('userA');
  await assertFails(updateDoc(doc(db, 'games', 'game1'), {
    uid: 'userB',
  }));
});

test('non-friend cannot join friends-only game', async () => {
  await seedUser('userA', { friends: ['userB'] });
  await seedGame('game1', { ownerUid: 'userA', friendGame: 'Friends' });
  const db = authedDb('userC');
  await assertFails(updateDoc(doc(db, 'games', 'game1'), {
    joined_players: arrayUnion(doc(db, 'users', 'userC')),
  }));
});

test('friend can join friends-only game', async () => {
  await seedUser('userA', { friends: ['userB'] });
  await seedGame('game1', { ownerUid: 'userA', friendGame: 'Friends' });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'games', 'game1'), {
    joined_players: arrayUnion(doc(db, 'users', 'userB')),
  }));
});

test('user cannot add someone else to another user friends list', async () => {
  await seedUser('userB', { friends: [] });
  const db = authedDb('userA');
  await assertFails(updateDoc(doc(db, 'users', 'userB'), {
    friends: arrayUnion(doc(db, 'users', 'userC')),
  }));
});

test('user can add themselves to another user friend_requests list', async () => {
  await seedUser('userB', { friendRequests: [] });
  const db = authedDb('userA');
  await assertSucceeds(updateDoc(doc(db, 'users', 'userB'), {
    friend_requests: arrayUnion('userA'),
  }));
});

test('user can add themselves to another user friends list', async () => {
  await seedUser('userA', { friends: [] });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'users', 'userA'), {
    friends: arrayUnion(doc(db, 'users', 'userB')),
  }));
});

test('user cannot remove someone else from another user friends list', async () => {
  await seedUser('userB', { friends: ['userC', 'userA'] });
  const db = authedDb('userA');
  await assertFails(updateDoc(doc(db, 'users', 'userB'), {
    friends: arrayRemove(doc(db, 'users', 'userC')),
  }));
});

test('friend_request doc restricted to sender/recipient', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'friend_request', 'req1'), {
      requester_id: doc(db, 'users', 'userA'),
      receiver_id: doc(db, 'users', 'userB'),
      request_status: 'pending',
    });
  });

  const dbA = authedDb('userA');
  const dbB = authedDb('userB');
  const dbC = authedDb('userC');

  await assertSucceeds(getDoc(doc(dbA, 'friend_request', 'req1')));
  await assertSucceeds(getDoc(doc(dbB, 'friend_request', 'req1')));
  await assertFails(getDoc(doc(dbC, 'friend_request', 'req1')));

  await assertSucceeds(updateDoc(doc(dbA, 'friend_request', 'req1'), {
    request_status: 'accepted',
  }));
  await assertFails(updateDoc(doc(dbC, 'friend_request', 'req1'), {
    request_status: 'accepted',
  }));
});

test('friend_request create requires requester to match auth', async () => {
  const db = authedDb('userA');
  await assertSucceeds(setDoc(doc(db, 'friend_request', 'req2'), {
    requester_id: doc(db, 'users', 'userA'),
    receiver_id: doc(db, 'users', 'userB'),
    request_status: 'pending',
  }));

  const dbC = authedDb('userC');
  await assertFails(setDoc(doc(dbC, 'friend_request', 'req3'), {
    requester_id: doc(dbC, 'users', 'userA'),
    receiver_id: doc(dbC, 'users', 'userB'),
    request_status: 'pending',
  }));
});

test('chat member can update chat metadata', async () => {
  await seedChat('chat1', { memberIds: ['userA', 'userB'], type: 'direct' });
  const db = authedDb('userA');
  await assertSucceeds(updateDoc(doc(db, 'chats', 'chat1'), {
    last_message: 'Hello there',
    lastMessageAt: Timestamp.fromMillis(Date.now()),
    lastMessageSenderId: 'userA',
    updatedAt: Timestamp.fromMillis(Date.now()),
  }));
});

test('chat member cannot update disallowed fields', async () => {
  await seedChat('chat1', { memberIds: ['userA', 'userB'], type: 'direct' });
  const db = authedDb('userA');
  await assertFails(updateDoc(doc(db, 'chats', 'chat1'), {
    type: 'game',
  }));
});

test('non-member cannot update chat metadata', async () => {
  await seedChat('chat1', { memberIds: ['userA', 'userB'], type: 'direct' });
  const db = authedDb('userC');
  await assertFails(updateDoc(doc(db, 'chats', 'chat1'), {
    last_message: 'Not allowed',
  }));
});

test('game participant can join game chat by adding self', async () => {
  await seedGame('game1', { ownerUid: 'userA', joinedUids: ['userA', 'userB'] });
  await seedChat('chat1', {
    memberIds: ['userA'],
    type: 'game',
    gameId: 'game1',
  });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'chats', 'chat1'), {
    memberIds: arrayUnion('userB'),
    users: arrayUnion(doc(db, 'users', 'userB')),
    updatedAt: Timestamp.fromMillis(Date.now()),
    'unreadCountByUser.userB': 0,
  }));
});

test('game participant can leave game chat by removing self', async () => {
  await seedGame('game1', { ownerUid: 'userA', joinedUids: ['userA', 'userB'] });
  await seedChat('chat1', {
    memberIds: ['userA', 'userB'],
    type: 'game',
    gameId: 'game1',
  });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'chats', 'chat1'), {
    memberIds: arrayRemove('userB'),
    users: arrayRemove(doc(db, 'users', 'userB')),
    updatedAt: Timestamp.fromMillis(Date.now()),
  }));
});

test('game owner can remove another member from game chat', async () => {
  await seedGame('game1', { ownerUid: 'userA', joinedUids: ['userA', 'userB'] });
  await seedChat('chat1', {
    memberIds: ['userA', 'userB'],
    type: 'game',
    gameId: 'game1',
  });
  const db = authedDb('userA');
  await assertSucceeds(updateDoc(doc(db, 'chats', 'chat1'), {
    memberIds: arrayRemove('userB'),
    users: arrayRemove(doc(db, 'users', 'userB')),
    updatedAt: Timestamp.fromMillis(Date.now()),
  }));
});

test('message sender can update message, non-sender cannot', async () => {
  await seedChat('chat1', { memberIds: ['userA', 'userB'], type: 'direct' });
  await seedMessage('chat1', 'msg1', { senderId: 'userA' });
  const dbA = authedDb('userA');
  const dbB = authedDb('userB');

  await assertSucceeds(updateDoc(doc(dbA, 'chats', 'chat1', 'messages', 'msg1'), {
    text: 'Edited',
  }));
  await assertFails(updateDoc(doc(dbB, 'chats', 'chat1', 'messages', 'msg1'), {
    text: 'Nope',
  }));
});

test('message member can update readBy', async () => {
  await seedChat('chat1', { memberIds: ['userA', 'userB'], type: 'direct' });
  await seedMessage('chat1', 'msg1', { senderId: 'userA' });
  const db = authedDb('userB');
  await assertSucceeds(updateDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1'), {
    readBy: arrayUnion('userB'),
  }));
});

test('message member cannot update reactions', async () => {
  await seedChat('chat1', { memberIds: ['userA', 'userB'], type: 'direct' });
  await seedMessage('chat1', 'msg1', { senderId: 'userA' });
  const db = authedDb('userB');
  await assertFails(updateDoc(doc(db, 'chats', 'chat1', 'messages', 'msg1'), {
    reactions: { '👍': ['userB'] },
  }));
});

test('user_push_notifications cannot be created by clients', async () => {
  const db = authedDb('userA');
  await assertFails(setDoc(doc(db, 'user_push_notifications', 'note1'), {
    sender: doc(db, 'users', 'userA'),
    recipient: doc(db, 'users', 'userB'),
    message: 'Test',
    createdAt: Timestamp.fromMillis(Date.now()),
  }));
});
