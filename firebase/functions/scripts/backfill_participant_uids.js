/**
 * Backfill host_uid and participant_uids on round_jobs.
 *
 * For each round_jobs doc missing participant_uids, extract UIDs from
 * host_ref.id and app_user_refs[].id and write string fields.
 *
 * Usage:
 *   node firebase/functions/scripts/backfill_participant_uids.js [--dry-run]
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
  console.log(`Backfilling host_uid + participant_uids on round_jobs${DRY_RUN ? " (DRY RUN)" : ""}...\n`);

  const snap = await db.collection("round_jobs").get();
  console.log(`Found ${snap.size} round_jobs docs total.`);

  // Filter to those missing participant_uids
  const toBackfill = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    if (!data.participant_uids || !Array.isArray(data.participant_uids) || data.participant_uids.length === 0) {
      toBackfill.push(doc);
    }
  }
  console.log(`${toBackfill.length} docs need backfill.\n`);

  if (toBackfill.length === 0) {
    console.log("Nothing to do.");
    return;
  }

  let updated = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of toBackfill) {
    const data = doc.data();

    if (!data.app_user_refs || !Array.isArray(data.app_user_refs) || data.app_user_refs.length === 0) {
      console.warn(`  ⚠️  ${doc.id}: no app_user_refs, skipping`);
      skipped++;
      continue;
    }

    const participantUids = data.app_user_refs.map((ref) => ref.id);
    const hostUid = data.host_ref ? data.host_ref.id : participantUids[0];

    console.log(`  ✅ ${doc.id}: setting host_uid=${hostUid}, participant_uids=[${participantUids.join(", ")}]`);

    if (!DRY_RUN) {
      batch.update(doc.ref, {
        host_uid: hostUid,
        participant_uids: participantUids,
      });
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
