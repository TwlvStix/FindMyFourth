/**
 * behavioral_dataset_test.js
 *
 * Integration test for the Behavioral Dataset functions using Firebase Emulator.
 *
 * Prerequisites:
 *   1. Start the emulator: firebase emulators:start --only firestore,functions
 *   2. Run this test: node test/behavioral_dataset_test.js
 *
 * This test:
 *   1. Seeds two test users in the "users" collection
 *   2. Calls createNewRound (host creates a round)
 *   3. Calls joinRound (second user joins)
 *   4. Calls finalizeAndScore (generates pairwise matches)
 *   5. Verifies all expected documents were created
 *
 * NOTE: player_rounds documents are created by the onParticipantWrite Firestore
 * trigger, which only fires when deployed functions are running. When calling
 * modules directly in this test script, player_rounds will be empty. This is
 * expected behavior, not a test failure.
 */

'use strict';

// ── Configure for Emulator ───────────────────────────────────────────────────
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FUNCTIONS_EMULATOR = 'true';

const admin = require('firebase-admin');

// Initialize with emulator settings
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'find-my-fourth',
  });
}

const db = admin.firestore();

// Import the behavioral dataset modules directly
const { createRound, addParticipant, finalizeGroup } = require('../src/booking');
const { generatePairwiseMatches } = require('../src/matching');

// ── Test Data ────────────────────────────────────────────────────────────────

const TEST_USER_1 = {
  id: 'test-host-user-001',
  data: {
    display_name: 'Test Host',
    first_name: 'Test',
    last_name: 'Host',
    handicap: 12.5,
    vibe_profile: {
      pace_of_play: 'moderate',
      music_on_course: true,
      drinks: 'social',
      importance: { pace_of_play: 0.8, music_on_course: 0.5, drinks: 0.3 },
    },
    badge_level: 'silver',
    photo_url: 'https://example.com/host.jpg',
  },
};

const TEST_USER_2 = {
  id: 'test-join-user-002',
  data: {
    display_name: 'Test Joiner',
    first_name: 'Test',
    last_name: 'Joiner',
    handicap: 18.0,
    vibe_profile: {
      pace_of_play: 'fast',
      music_on_course: false,
      drinks: 'none',
      importance: { pace_of_play: 0.9, music_on_course: 0.2, drinks: 0.1 },
    },
    badge_level: 'bronze',
    photo_url: 'https://example.com/joiner.jpg',
  },
};

const TEST_ROUND_DATA = {
  game_type: 'stroke_play',
  game_settings: { format: '18_holes', betting: false },
  tee_time: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
  course_id: 'test-course-001',
  weather_snapshot: { temp: 72, conditions: 'sunny' },
  match_source: 'manual',
  group_size: 4,
};

// ── Helper Functions ─────────────────────────────────────────────────────────

async function cleanup() {
  console.log('\n🧹 Cleaning up previous test data...');

  const collections = ['users', 'rounds', 'player_rounds', 'round_events'];

  for (const collectionName of collections) {
    const snapshot = await db.collection(collectionName).get();
    const batch = db.batch();
    let count = 0;

    for (const doc of snapshot.docs) {
      if (doc.id.startsWith('test-') || doc.id.includes('test-host') || doc.id.includes('test-join')) {
        batch.delete(doc.ref);
        count++;
      }

      // For rounds, also delete subcollections
      if (collectionName === 'rounds') {
        const subcollections = ['participants', 'pairwiseMatches', 'feedback'];
        for (const sub of subcollections) {
          const subSnap = await doc.ref.collection(sub).get();
          subSnap.docs.forEach(subDoc => batch.delete(subDoc.ref));
          count += subSnap.size;
        }
      }
    }

    if (count > 0) {
      await batch.commit();
      console.log(`   Deleted ${count} documents from ${collectionName}`);
    }
  }

  // Also clean up any rounds created during test (not starting with test-)
  const roundsSnap = await db.collection('rounds')
    .where('host_player_id', 'in', [TEST_USER_1.id, TEST_USER_2.id])
    .get();

  for (const doc of roundsSnap.docs) {
    const subcollections = ['participants', 'pairwiseMatches', 'feedback'];
    for (const sub of subcollections) {
      const subSnap = await doc.ref.collection(sub).get();
      for (const subDoc of subSnap.docs) {
        await subDoc.ref.delete();
      }
    }
    await doc.ref.delete();
  }
}

async function seedUsers() {
  console.log('\n📝 Seeding test users...');

  await db.collection('users').doc(TEST_USER_1.id).set(TEST_USER_1.data);
  console.log(`   Created user: ${TEST_USER_1.id} (handicap: ${TEST_USER_1.data.handicap}, badge: ${TEST_USER_1.data.badge_level})`);

  await db.collection('users').doc(TEST_USER_2.id).set(TEST_USER_2.data);
  console.log(`   Created user: ${TEST_USER_2.id} (handicap: ${TEST_USER_2.data.handicap}, badge: ${TEST_USER_2.data.badge_level})`);
}

async function verifyDocument(path, description) {
  const doc = await db.doc(path).get();
  if (doc.exists) {
    console.log(`   ✅ ${description}: ${path}`);
    return { exists: true, data: doc.data() };
  } else {
    console.log(`   ❌ ${description}: ${path} — NOT FOUND`);
    return { exists: false, data: null };
  }
}

async function verifyCollection(path, expectedCount, description, isOptional = false) {
  const snapshot = await db.collection(path).get();
  const actual = snapshot.size;
  const pass = actual >= expectedCount;

  if (isOptional && actual === 0) {
    console.log(`   ⚠️  ${description}: ${path} — found ${actual} (expected ${expectedCount}, but this is trigger-based, OK to be 0)`);
    return { count: actual, expected: expectedCount, pass: true, skipped: true };
  }

  const status = pass ? '✅' : '❌';
  console.log(`   ${status} ${description}: ${path} — found ${actual}, expected ${expectedCount}`);
  return { count: actual, expected: expectedCount, pass };
}

// ── Main Test ────────────────────────────────────────────────────────────────

async function runTest() {
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('  BEHAVIORAL DATASET INTEGRATION TEST');
  console.log('  Using Firebase Emulator');
  console.log('═══════════════════════════════════════════════════════════════');

  let roundId = null;
  const results = {
    passed: 0,
    failed: 0,
    skipped: 0,
    errors: [],
  };

  try {
    // ── Step 0: Cleanup ──
    await cleanup();

    // ── Step 1: Seed Users ──
    await seedUsers();

    // ── Step 2: Create Round ──
    console.log('\n🎯 Step 2: Creating round (host: test-host-user-001)...');
    roundId = await createRound({
      ...TEST_ROUND_DATA,
      host_player_id: TEST_USER_1.id,
    });
    console.log(`   Round created with ID: ${roundId}`);

    // ── Step 3: Join Round ──
    console.log('\n🎯 Step 3: Second user joining round...');
    await addParticipant({
      round_id: roundId,
      player_id: TEST_USER_2.id,
      role: 'joined',
    });
    console.log(`   User ${TEST_USER_2.id} joined round ${roundId}`);

    // ── Step 4: Finalize and Score ──
    console.log('\n🎯 Step 4: Finalizing group and generating pairwise matches...');
    const playerIds = await finalizeGroup(roundId);
    console.log(`   Group finalized with ${playerIds.length} players: ${playerIds.join(', ')}`);

    const pairCount = await generatePairwiseMatches(roundId);
    console.log(`   Generated ${pairCount} pairwise match(es)`);

    // ── Step 5: Verify Results ──
    console.log('\n🔍 Step 5: Verifying Firestore documents...');

    // Check rounds collection
    const roundResult = await verifyDocument(`rounds/${roundId}`, 'Round document');
    if (roundResult.exists) results.passed++; else results.failed++;

    // Check participants subcollection
    const participantsResult = await verifyCollection(
      `rounds/${roundId}/participants`,
      2,
      'Participants (host + joiner)'
    );
    if (participantsResult.pass) results.passed++; else results.failed++;

    // Check pairwiseMatches subcollection
    const matchesResult = await verifyCollection(
      `rounds/${roundId}/pairwiseMatches`,
      1,
      'Pairwise matches'
    );
    if (matchesResult.pass) results.passed++; else results.failed++;

    // Check round_events collection
    const eventsResult = await verifyCollection(
      'round_events',
      1,
      'Round events (at least 1)'
    );
    if (eventsResult.pass) results.passed++; else results.failed++;

    // Check player_rounds collection (OPTIONAL - trigger-based, may be 0)
    const playerRoundsResult = await verifyCollection(
      'player_rounds',
      2,
      'Player rounds (trigger-based)',
      true // isOptional = true
    );
    if (playerRoundsResult.skipped) {
      results.skipped++;
    } else if (playerRoundsResult.pass) {
      results.passed++;
    } else {
      results.failed++;
    }

    // ── Detailed Output ──
    console.log('\n📊 Detailed Document Data:');

    if (roundResult.exists) {
      console.log('\n   Round document:');
      console.log(`     - game_type: ${roundResult.data.game_type}`);
      console.log(`     - match_source: ${roundResult.data.match_source}`);
      console.log(`     - group_size: ${roundResult.data.group_size}`);
      console.log(`     - round_status: ${roundResult.data.round_status}`);
      console.log(`     - host_player_id: ${roundResult.data.host_player_id}`);
    }

    // Show participant snapshots
    const participantDocs = await db.collection(`rounds/${roundId}/participants`).get();
    for (const doc of participantDocs.docs) {
      const p = doc.data();
      console.log(`\n   Participant ${doc.id}:`);
      console.log(`     - role: ${p.role}`);
      console.log(`     - handicap_at_booking: ${p.handicap_at_booking}`);
      console.log(`     - experience_level_snapshot: ${p.experience_level_snapshot}`);
      console.log(`     - participation_status: ${p.participation_status}`);
    }

    // Show pairwise match
    const matchDocs = await db.collection(`rounds/${roundId}/pairwiseMatches`).get();
    for (const doc of matchDocs.docs) {
      const m = doc.data();
      console.log(`\n   Pairwise Match ${doc.id}:`);
      console.log(`     - player_a_id: ${m.player_a_id}`);
      console.log(`     - player_b_id: ${m.player_b_id}`);
      console.log(`     - predicted_compatibility: ${m.predicted_compatibility}`);
      console.log(`     - handicap_delta: ${m.handicap_delta}`);
    }

  } catch (error) {
    console.error('\n❌ TEST ERROR:', error.message);
    console.error(error.stack);
    results.failed++;
    results.errors.push(error.message);
  }

  // ── Summary ──
  console.log('\n═══════════════════════════════════════════════════════════════');
  console.log('  TEST SUMMARY');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log(`  ✅ Passed: ${results.passed}`);
  console.log(`  ⚠️  Skipped (trigger-based): ${results.skipped}`);
  console.log(`  ❌ Failed: ${results.failed}`);
  if (results.errors.length > 0) {
    console.log(`  Errors: ${results.errors.join(', ')}`);
  }
  console.log('═══════════════════════════════════════════════════════════════\n');

  // Exit with appropriate code
  process.exit(results.failed > 0 ? 1 : 0);
}

// ── Run ──────────────────────────────────────────────────────────────────────
runTest();
