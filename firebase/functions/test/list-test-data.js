/**
 * Diagnostic Script - Find LOADTEST_ documents
 */

'use strict';

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin with explicit service account
if (!admin.apps.length) {
  const serviceAccountPath = path.join(__dirname, '..', 'service-account.json');
  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`,
  });

  console.log(`Service Account Email: ${serviceAccount.client_email}`);
}

const db = admin.firestore();
const PREFIX = 'LOADTEST_';

async function listDocs() {
  console.log('='.repeat(60));
  console.log('SEARCHING FOR LOADTEST_ DOCUMENTS');
  console.log('='.repeat(60));

  // Get project info
  const projectId = admin.app().options.projectId || process.env.GCLOUD_PROJECT || 'unknown';
  console.log(`\nProject ID: ${projectId}`);

  // Query specifically for LOADTEST_ users
  console.log('\n--- USERS with LOADTEST_ prefix ---');
  try {
    const usersSnap = await db.collection('users')
      .where(admin.firestore.FieldPath.documentId(), '>=', PREFIX)
      .where(admin.firestore.FieldPath.documentId(), '<', PREFIX + '\uf8ff')
      .limit(10)
      .get();
    console.log(`  Found: ${usersSnap.size} documents`);
    usersSnap.docs.forEach(doc => console.log(`    - ${doc.id}`));
  } catch (err) {
    console.log(`  Error: ${err.message}`);
  }

  // Query specifically for LOADTEST_ games
  console.log('\n--- GAMES with LOADTEST_ prefix ---');
  try {
    const gamesSnap = await db.collection('games')
      .where(admin.firestore.FieldPath.documentId(), '>=', PREFIX)
      .where(admin.firestore.FieldPath.documentId(), '<', PREFIX + '\uf8ff')
      .limit(10)
      .get();
    console.log(`  Found: ${gamesSnap.size} documents`);
    gamesSnap.docs.forEach(doc => console.log(`    - ${doc.id}`));
  } catch (err) {
    console.log(`  Error: ${err.message}`);
  }

  // Also try getting a specific document directly
  console.log('\n--- Direct document check ---');
  try {
    const userDoc = await db.collection('users').doc('LOADTEST_user_0001').get();
    console.log(`  LOADTEST_user_0001 exists: ${userDoc.exists}`);
  } catch (err) {
    console.log(`  Error checking user: ${err.message}`);
  }

  try {
    const gameDoc = await db.collection('games').doc('LOADTEST_game_0').get();
    console.log(`  LOADTEST_game_0 exists: ${gameDoc.exists}`);
  } catch (err) {
    console.log(`  Error checking game: ${err.message}`);
  }

  // Total count in collections
  console.log('\n--- Collection sizes (first 200) ---');
  const usersAll = await db.collection('users').limit(200).get();
  const gamesAll = await db.collection('games').limit(200).get();
  console.log(`  users: ${usersAll.size} docs`);
  console.log(`  games: ${gamesAll.size} docs`);

  // List ALL document IDs
  console.log('\n--- ALL USER IDs ---');
  usersAll.docs.forEach(doc => console.log(`  ${doc.id}`));

  console.log('\n--- ALL GAME IDs ---');
  gamesAll.docs.forEach(doc => console.log(`  ${doc.id}`));

  console.log('\n' + '='.repeat(60));
  process.exit(0);
}

listDocs().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
