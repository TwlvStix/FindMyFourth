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
    friend_game: 'Public',
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
