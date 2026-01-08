/* eslint-disable no-console */
const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

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

function updateSummary(summary, chatId, timestamp) {
  const current = summary.get(chatId) || {
    count: 0,
    oldest: null,
    newest: null,
  };
  current.count += 1;
  if (timestamp) {
    const millis = timestamp.toMillis ? timestamp.toMillis() : timestamp;
    if (current.oldest === null || millis < current.oldest) {
      current.oldest = millis;
    }
    if (current.newest === null || millis > current.newest) {
      current.newest = millis;
    }
  }
  summary.set(chatId, current);
}

function hashMessage({
  senderId,
  text,
  imageUrl,
  videoUrl,
  createdAt,
}) {
  const timestamp = createdAt?.toMillis
    ? createdAt.toMillis()
    : createdAt || 0;
  const payload = [
    senderId || '',
    text || '',
    imageUrl || '',
    videoUrl || '',
    timestamp,
  ].join('|');
  return crypto.createHash('sha256').update(payload).digest('hex');
}

function writeReport({ jsonPath, csvPath, report }) {
  if (jsonPath) {
    fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));
  }
  if (csvPath) {
    const headers = [
      'chatId',
      'legacyCount',
      'migratedCount',
      'legacyOldest',
      'legacyNewest',
      'migratedOldest',
      'migratedNewest',
      'status',
    ];
    const lines = [headers.join(',')];
    report.perChat.forEach((entry) => {
      lines.push(
        [
          entry.chatId,
          entry.legacy.count,
          entry.migrated.count,
          entry.legacy.oldest || '',
          entry.legacy.newest || '',
          entry.migrated.oldest || '',
          entry.migrated.newest || '',
          entry.status,
        ].join(','),
      );
    });
    fs.writeFileSync(csvPath, lines.join('\n'));
  }
}

async function verifyMessages(db) {
  const batchSize = 300;
  const fullCompare = process.env.FULL_COMPARE === '1';
  const sampleSize = Number(process.env.SAMPLE_SIZE || 50);
  const legacySummary = new Map();
  const migratedSummary = new Map();
  const mismatches = [];
  const sampleMismatches = [];
  let totalLegacy = 0;
  let missing = 0;
  let fieldMismatch = 0;
  let lastDoc = null;
  let sampleCounter = 0;

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

    for (const doc of snapshot.docs) {
      totalLegacy += 1;
      const data = doc.data();
      const chatRef = data.chat;
      const userRef = data.user;
      if (!chatRef || !userRef) {
        missing += 1;
        mismatches.push({
          id: doc.id,
          reason: 'Missing chat/user reference',
        });
        continue;
      }

      updateSummary(legacySummary, chatRef.id, data.timestamp);

      const shouldCompare = fullCompare || sampleCounter < sampleSize;
      if (shouldCompare) {
        sampleCounter += 1;
        const targetRef = db
          .collection('chats')
          .doc(chatRef.id)
          .collection('messages')
          .doc(doc.id);
        const migrated = await targetRef.get();
        if (!migrated.exists) {
          missing += 1;
          sampleMismatches.push({
            id: doc.id,
            reason: `Missing migrated message chats/${chatRef.id}/messages/${doc.id}`,
          });
          continue;
        }
        const migratedData = migrated.data() || {};
        const legacyHash = hashMessage({
          senderId: userRef.id,
          text: data.text || '',
          imageUrl: data.image || '',
          videoUrl: data.video || '',
          createdAt: data.timestamp || null,
        });
        const migratedHash = hashMessage({
          senderId: migratedData.senderId,
          text: migratedData.text || '',
          imageUrl: migratedData.imageUrl || '',
          videoUrl: migratedData.videoUrl || '',
          createdAt: migratedData.createdAt || null,
        });
        if (legacyHash !== migratedHash) {
          fieldMismatch += 1;
          sampleMismatches.push({
            id: doc.id,
            reason: 'Hash mismatch',
            legacyHash,
            migratedHash,
          });
        }
      }
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  let migratedLastDoc = null;
  while (true) {
    let query = db
      .collectionGroup('messages')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batchSize);
    if (migratedLastDoc) {
      query = query.startAfter(migratedLastDoc);
    }
    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }
    for (const doc of snapshot.docs) {
      const chatId = doc.ref.parent.parent.id;
      updateSummary(migratedSummary, chatId, doc.data().createdAt);
    }
    migratedLastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  const perChat = [];
  const chatIds = new Set([
    ...legacySummary.keys(),
    ...migratedSummary.keys(),
  ]);
  let chatCountMismatch = 0;
  let chatTimeMismatch = 0;
  chatIds.forEach((chatId) => {
    const legacy = legacySummary.get(chatId) || {
      count: 0,
      oldest: null,
      newest: null,
    };
    const migrated = migratedSummary.get(chatId) || {
      count: 0,
      oldest: null,
      newest: null,
    };
    let status = 'ok';
    if (legacy.count !== migrated.count) {
      status = 'count_mismatch';
      chatCountMismatch += 1;
    } else if (
      legacy.oldest !== migrated.oldest ||
      legacy.newest !== migrated.newest
    ) {
      status = 'timestamp_mismatch';
      chatTimeMismatch += 1;
    }
    perChat.push({
      chatId,
      legacy,
      migrated,
      status,
    });
  });

  const report = {
    totals: {
      legacyMessages: totalLegacy,
      missingMigrated: missing,
      hashMismatches: fieldMismatch,
      chatCountMismatch,
      chatTimeMismatch,
    },
    sampleMismatches,
    perChat,
  };

  const reportPath =
    process.env.REPORT_PATH ||
    path.join(process.cwd(), 'chat_migration_report.json');
  const csvPath =
    process.env.REPORT_CSV_PATH ||
    path.join(process.cwd(), 'chat_migration_report.csv');
  writeReport({ jsonPath: reportPath, csvPath, report });

  console.log('Verification summary:');
  console.log(JSON.stringify(report.totals, null, 2));
  console.log(`Report written to ${reportPath}`);
  console.log(`CSV written to ${csvPath}`);
  if (
    report.totals.missingMigrated > 0 ||
    report.totals.hashMismatches > 0 ||
    report.totals.chatCountMismatch > 0 ||
    report.totals.chatTimeMismatch > 0
  ) {
    process.exitCode = 2;
  }
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  console.log('Starting verification...');
  await verifyMessages(db);
  console.log('Done.');
}

main().catch((error) => {
  console.error('Verification failed:', error);
  process.exit(1);
});
