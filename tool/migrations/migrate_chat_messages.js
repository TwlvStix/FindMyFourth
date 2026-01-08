/* eslint-disable no-console */
const admin = require('firebase-admin');

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

function extractMemberIds(data) {
  if (Array.isArray(data.memberIds) && data.memberIds.length > 0) {
    return data.memberIds.filter((id) => typeof id === 'string');
  }
  if (Array.isArray(data.users)) {
    const ids = data.users
      .map((ref) => (ref && ref.id ? ref.id : null))
      .filter(Boolean);
    if (ids.length > 0) {
      return ids;
    }
  }
  const fallback = [];
  if (data.user_a && data.user_a.id) {
    fallback.push(data.user_a.id);
  }
  if (data.user_b && data.user_b.id) {
    fallback.push(data.user_b.id);
  }
  return fallback;
}

async function backfillChats(db, dryRun) {
  const snapshot = await db.collection('chats').get();
  let updated = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const memberIds = extractMemberIds(data);
    const updates = {};

    if (!data.memberIds && memberIds.length > 0) {
      updates.memberIds = memberIds;
    }

    if (!data.type) {
      updates.type = memberIds.length === 2 ? 'direct' : 'game';
    }

    if (memberIds.length === 2 && !data.directKey) {
      const sorted = [...memberIds].sort();
      updates.directKey = `${sorted[0]}_${sorted[1]}`;
    }

    if (!data.lastMessage && typeof data.last_message === 'string') {
      updates.lastMessage = data.last_message;
    }
    if (!data.lastMessageAt && data.last_message_time) {
      updates.lastMessageAt = data.last_message_time;
    }
    if (!data.lastMessageSenderId && data.last_message_sent_by?.id) {
      updates.lastMessageSenderId = data.last_message_sent_by.id;
    }
    if (!data.unreadCountByUser && memberIds.length > 0) {
      const unread = {};
      memberIds.forEach((id) => {
        unread[id] = 0;
      });
      updates.unreadCountByUser = unread;
    }
    if (!data.createdAt) {
      updates.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }

    if (Object.keys(updates).length > 0) {
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      if (dryRun) {
        console.log(`[dry-run] Would update chat ${doc.id}`, updates);
      } else {
        await doc.ref.update(updates);
      }
      updated += 1;
    }
  }
  console.log(`Chats updated: ${updated}`);
}

async function migrateMessages(db, dryRun) {
  const batchSize = 400;
  let lastDoc = null;
  let total = 0;
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
          const data = doc.data();
          const chatRef = data.chat;
          const userRef = data.user;
          if (!chatRef || !userRef) {
            console.log(`[dry-run] Skipping message ${doc.id} (missing refs)`);
            return;
          }
          console.log(
            `[dry-run] Would migrate message ${doc.id} -> chats/${chatRef.id}/messages/${doc.id}`,
          );
        });
        total += batchDocs.length;
        continue;
      }

      const batch = db.batch();
      batchDocs.forEach((doc) => {
        const data = doc.data();
        const chatRef = data.chat;
        const userRef = data.user;
        if (!chatRef || !userRef) {
          return;
        }
        const targetRef = db
          .collection('chats')
          .doc(chatRef.id)
          .collection('messages')
          .doc(doc.id);
        batch.set(
          targetRef,
          {
            senderId: userRef.id,
            text: data.text || '',
            imageUrl: data.image || '',
            videoUrl: data.video || '',
            createdAt: data.timestamp || admin.firestore.FieldValue.serverTimestamp(),
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });
      await batch.commit();
      total += batchDocs.length;
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }
  console.log(`Messages migrated: ${total}`);
}

async function main() {
  initAdmin();
  const db = admin.firestore();
  const dryRun = process.env.DRY_RUN === '1';
  console.log(`Starting chat migration (dryRun=${dryRun})...`);
  await backfillChats(db, dryRun);
  await migrateMessages(db, dryRun);
  console.log('Done.');
}

main().catch((error) => {
  console.error('Migration failed:', error);
  process.exit(1);
});
