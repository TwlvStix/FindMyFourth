/* eslint-disable no-console */
const admin = require('firebase-admin');
const fs = require('fs');

function initAdmin() {
  const serviceAccountPath = process.env.SERVICE_ACCOUNT_PATH;
  if (serviceAccountPath) {
    // eslint-disable-next-line global-require, import/no-dynamic-require
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    return;
  }
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

function chunkArray(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

function assertVerificationReport() {
  const reportPath = process.env.VERIFICATION_REPORT;
  if (!reportPath) {
    throw new Error(
      'VERIFICATION_REPORT is required before deletion. Run verify_chat_messages.js first.',
    );
  }
  if (!fs.existsSync(reportPath)) {
    throw new Error(`Verification report not found at ${reportPath}`);
  }
  const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  const totals = report.totals || {};
  const hasIssues =
    (totals.missingMigrated || 0) > 0 ||
    (totals.hashMismatches || 0) > 0 ||
    (totals.chatCountMismatch || 0) > 0 ||
    (totals.chatTimeMismatch || 0) > 0;
  if (hasIssues) {
    throw new Error(
      'Verification report indicates mismatches. Aborting deletion.',
    );
  }
  console.log(`Verification report OK: ${reportPath}`);
}

async function deleteLegacyMessages(db, dryRun) {
  const batchSize = 400;
  let lastDoc = null;
  let deleted = 0;

  while (true) {
    let query = db
      .collection('chat_messages')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batches = chunkArray(snapshot.docs, batchSize);
    for (const batchDocs of batches) {
      if (dryRun) {
        batchDocs.forEach((doc) => {
          console.log(`[dry-run] Would delete chat_messages/${doc.id}`);
        });
        deleted += batchDocs.length;
        continue;
      }

      const batch = db.batch();
      batchDocs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      deleted += batchDocs.length;
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  console.log(`Legacy chat_messages deleted: ${deleted}`);
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const dryRun = process.env.DRY_RUN === '1';
  if (!dryRun) {
    assertVerificationReport();
  }
  console.log(`Starting cleanup (dryRun=${dryRun})...`);
  await deleteLegacyMessages(db, dryRun);
  console.log('Done.');
}

main().catch((error) => {
  console.error('Cleanup failed:', error);
  process.exit(1);
});
