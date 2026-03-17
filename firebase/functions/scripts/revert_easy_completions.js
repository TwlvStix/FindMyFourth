'use strict';

/**
 * One-time admin script: Revert incorrectly completed challenges.
 *
 * Fixes two challenges that completed too easily during early testing:
 *   - never_miss: Was completing after 1 game with 0 cancellations (should require 4+)
 *   - all_strangers: Was completing in 2-player games (should require 4 players)
 *
 * Usage:
 *   node scripts/revert_easy_completions.js              # dry-run (default)
 *   node scripts/revert_easy_completions.js --commit      # actually write changes
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or Firebase CLI auth.
 */

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const DRY_RUN = !process.argv.includes('--commit');

async function revertNeverMiss() {
  console.log('\n── never_miss ──────────────────────────────────────');
  console.log('Looking for users with never_miss.completedAt...');

  const usersSnap = await db.collection('users').get();
  let checked = 0;
  let reverted = 0;

  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();
    const progress = data.challenge_progress;
    if (!progress || !progress.never_miss || !progress.never_miss.completedAt) continue;

    checked++;
    const neverMiss = progress.never_miss;
    const dataMap = neverMiss.data || {};

    // Check if any month actually had 4+ games
    let metThreshold = false;
    for (const monthKey of Object.keys(dataMap)) {
      if (typeof dataMap[monthKey] === 'number' && dataMap[monthKey] >= 4) {
        metThreshold = true;
        break;
      }
    }

    if (!metThreshold) {
      console.log(`  REVERT ${userDoc.id} — current: ${neverMiss.current}, data: ${JSON.stringify(dataMap)}`);
      reverted++;

      if (!DRY_RUN) {
        // Reset: keep data map for round tracking but remove completedAt
        const resetProgress = { ...neverMiss };
        delete resetProgress.completedAt;
        resetProgress.current = Math.max(...Object.values(dataMap).filter((v) => typeof v === 'number'), 0);

        await db.collection('users').doc(userDoc.id).update({
          [`challenge_progress.never_miss`]: resetProgress,
        });
      }
    }
  }

  console.log(`  Checked: ${checked} users with never_miss completed`);
  console.log(`  Reverted: ${reverted}`);
}

async function revertAllStrangers() {
  console.log('\n── all_strangers ───────────────────────────────────');
  console.log('Resetting ALL all_strangers completions (early testing phase)...');

  const usersSnap = await db.collection('users').get();
  let checked = 0;
  let reverted = 0;

  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();
    const progress = data.challenge_progress;
    if (!progress || !progress.all_strangers || !progress.all_strangers.completedAt) continue;

    checked++;
    reverted++;
    console.log(`  REVERT ${userDoc.id}`);

    if (!DRY_RUN) {
      await db.collection('users').doc(userDoc.id).update({
        [`challenge_progress.all_strangers`]: {
          current: 0,
          completed: false,
        },
      });
    }
  }

  console.log(`  Checked: ${checked} users with all_strangers completed`);
  console.log(`  Reverted: ${reverted}`);
}

async function main() {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  Revert Easy Completions — ${DRY_RUN ? 'DRY RUN' : 'COMMIT MODE'}`);
  console.log(`${'='.repeat(60)}`);

  if (DRY_RUN) {
    console.log('  (pass --commit to actually write changes)');
  }

  await revertNeverMiss();
  await revertAllStrangers();

  console.log(`\n${'='.repeat(60)}`);
  console.log(`  Done. ${DRY_RUN ? 'No changes written (dry run).' : 'Changes committed.'}`);
  console.log(`${'='.repeat(60)}\n`);
}

main().catch((err) => {
  console.error('Script failed:', err);
  process.exit(1);
});
