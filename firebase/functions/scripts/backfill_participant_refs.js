/**
 * Backfill participant_refs on round_records.
 *
 * For each round_records doc missing participant_refs, find the associated
 * round_jobs doc (via game_ref match) and copy app_user_refs → participant_refs.
 *
 * Usage:
 *   node firebase/functions/scripts/backfill_participant_refs.js [--dry-run]
 */
const admin = require("firebase-admin");
const path = require("path");

const serviceAccountPath = path.join(
  __dirname,
  "..",
  "..",
  "..",
  "keys",
  "find-my-fourth-firebase-adminsdk-qmz8q-0d658a8ace.json",
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
});

const db = admin.firestore();
const DRY_RUN = process.argv.includes("--dry-run");
const BATCH_LIMIT = 400;

async function backfill() {
  console.log(`Backfilling participant_refs on round_records${DRY_RUN ? " (DRY RUN)" : ""}...\n`);

  // Load all round_records
  const roundSnap = await db.collection("round_records").get();
  console.log(`Found ${roundSnap.size} round_records docs total.`);

  // Filter to those missing participant_refs
  const toBackfill = [];
  for (const doc of roundSnap.docs) {
    const data = doc.data();
    if (!data.participant_refs || !Array.isArray(data.participant_refs) || data.participant_refs.length === 0) {
      toBackfill.push(doc);
    }
  }
  console.log(`${toBackfill.length} docs need backfill.\n`);

  if (toBackfill.length === 0) {
    console.log("Nothing to do.");
    return;
  }

  // Pre-load all round_jobs indexed by game_ref path for fast lookup
  const jobsSnap = await db.collection("round_jobs").get();
  const jobsByGamePath = new Map();
  for (const jobDoc of jobsSnap.docs) {
    const jobData = jobDoc.data();
    if (jobData.game_ref && jobData.app_user_refs) {
      const gamePath = jobData.game_ref.path;
      // If multiple jobs per game, prefer the one with more refs
      const existing = jobsByGamePath.get(gamePath);
      if (!existing || (jobData.app_user_refs.length > existing.app_user_refs.length)) {
        jobsByGamePath.set(gamePath, jobData);
      }
    }
  }
  console.log(`Loaded ${jobsByGamePath.size} round_jobs indexed by game_ref.\n`);

  let updated = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of toBackfill) {
    const data = doc.data();
    const gameRef = data.game_ref;

    if (!gameRef) {
      console.warn(`  ⚠️  ${doc.id}: no game_ref, skipping`);
      skipped++;
      continue;
    }

    const jobData = jobsByGamePath.get(gameRef.path);
    if (!jobData || !Array.isArray(jobData.app_user_refs) || jobData.app_user_refs.length === 0) {
      console.warn(`  ⚠️  ${doc.id}: no matching round_job with app_user_refs for game ${gameRef.path}, skipping`);
      skipped++;
      continue;
    }

    console.log(`  ✅ ${doc.id}: setting participant_refs (${jobData.app_user_refs.length} refs) from round_job`);

    if (!DRY_RUN) {
      batch.update(doc.ref, { participant_refs: jobData.app_user_refs });
      batchCount++;

      if (batchCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
    updated++;
  }

  if (!DRY_RUN && batchCount > 0) {
    await batch.commit();
  }

  console.log(`\nDone. Updated: ${updated}, Skipped: ${skipped}${DRY_RUN ? " (dry run — no writes)" : ""}`);
}

backfill().catch((err) => {
  console.error("Backfill failed:", err);
  process.exit(1);
});
