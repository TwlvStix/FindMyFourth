import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '/core/utils/app_log.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, Map<String, dynamic>> _userCache = {};

  DocumentReference _userChatRef(String uid, String chatId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chatRefs')
        .doc(chatId);
  }

  Stream<List<Chat>> getChatListStream({
    required String uid,
    int limit = 50,
  }) {
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null || user.uid != uid) {
        return Stream.value(<Chat>[]);
      }

      final query = _firestore
          .collection('users')
          .doc(uid)
          .collection('chatRefs')
          .orderBy('lastMessageAt', descending: true)
          .limit(limit);

      return query.snapshots().switchMap((snapshot) {
        final chatIds = snapshot.docs.map((doc) => doc.id).toList();
        if (chatIds.isEmpty) {
          return Stream.value(<Chat>[]);
        }

        // ✅ PERFORMANCE: Batch whereIn queries (max 10 per batch)
        // Instead of N listeners (one per chat), create N/10 batched listeners
        final batches = _chunkList(chatIds, 10);
        AppLog.d(
          '[ChatService] Batching ${chatIds.length} chats into ${batches.length} queries (${batches.map((b) => b.length).join(", ")} per batch)',
        );

        final streams = batches.map((batch) {
          return _firestore
              .collection('chats')
              .where(FieldPath.documentId, whereIn: batch)
              .snapshots()
              .map((querySnapshot) {
                return querySnapshot.docs
                    .map((doc) => Chat.fromDoc(doc))
                    .toList();
              })
              .onErrorReturn(<Chat>[]);
        });

        return Rx.combineLatestList<List<Chat>>(streams).map((batchResults) {
          // Flatten all batches into single list
          final allChats = batchResults.expand((batch) => batch).toList();

          // ✅ PERFORMANCE: Sort by lastMessageAt to maintain correct order
          // (whereIn doesn't guarantee order, so we sort client-side)
          allChats.sort((a, b) {
            final aTime = a.lastMessageAt ?? DateTime(1970);
            final bTime = b.lastMessageAt ?? DateTime(1970);
            return bTime.compareTo(aTime); // Descending
          });

          return allChats;
        });
      });
    });
  }

  /// Helper: Chunk a list into batches of specified size
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  Stream<Chat?> getChatStream({
    required String chatId,
  }) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? Chat.fromDoc(snapshot) : null);
  }

  Stream<List<ChatMessage>> getMessagesStream({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
    DateTime? visibleAfter,
  }) {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (visibleAfter != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(visibleAfter),
      );
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromDoc).toList(),
        );
  }

  Stream<QuerySnapshot> getMessagesSnapshotStream({
    required String chatId,
    int limit = 50,
    DateTime? visibleAfter,
  }) {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (visibleAfter != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(visibleAfter),
      );
    }

    return query.snapshots();
  }

  Future<MessagesPage> getMessagesPage({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
    DateTime? visibleAfter,
  }) async {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (visibleAfter != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(visibleAfter),
      );
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return MessagesPage(
      messages: snapshot.docs.map(ChatMessage.fromDoc).toList(),
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  Future<DocumentReference> createOrGetDirectChat({
    required String currentUid,
    required String otherUid,
  }) async {
    final memberIds = [currentUid, otherUid]..sort();
    final directKey = memberIds.join('_');
    final chats = _firestore.collection('chats');

    try {
      // Use directKey as the document ID
      final chatRef = chats.doc(directKey);

      await _firestore.runTransaction((transaction) async {
        final chatSnapshot = await transaction.get(chatRef);
        if (!chatSnapshot.exists) {
          transaction.set(chatRef, {
            'memberIds': memberIds,
            'users': memberIds
                .map((uid) => _firestore.collection('users').doc(uid))
                .toList(),
            'user_a': _firestore.collection('users').doc(currentUid),
            'user_b': _firestore.collection('users').doc(otherUid),
            'directKey': directKey,
            'type': 'direct',
            'gameId': null,
            'lastMessage': '',
            'isReadOnly': false,
            'pinnedMessage': '',
            'pinnedAt': null,
            'archivedAt': null,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'lastMessageSenderId': currentUid,
            'unreadCountByUser': {
              currentUid: 0,
              otherUid: 0,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      final batch = _firestore.batch();
      for (final uid in memberIds) {
        batch.set(
          _userChatRef(uid, directKey),
          {
            'chatId': directKey,
            'lastMessageAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      return chatRef;
    } catch (e, stackTrace) {
      AppLog.d('❌ ChatService: ERROR in createOrGetDirectChat: $e');
      AppLog.d('❌ ChatService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<DocumentReference> createGameChat({
    required String createdByUid,
    required String gameId,
    required String gameName,
  }) async {
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'memberIds': [createdByUid],
      'users': [_firestore.collection('users').doc(createdByUid)],
      'type': 'game',
      'gameId': gameId,
      'gameName': gameName,
      'lastMessage': '',
      'isReadOnly': false,
      'pinnedMessage': '',
      'pinnedAt': null,
      'archivedAt': null,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': createdByUid,
      'unreadCountByUser': {
        createdByUid: 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _userChatRef(createdByUid, chatRef.id).set({
      'chatId': chatRef.id,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatRef;
  }

  Future<void> addMember({
    required String chatId,
    required String uid,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCountByUser.$uid': 0,
      // Record join timestamp so the member sees only messages from this point
      // forward if they previously left and are now rejoining.
      'memberJoinedAt.$uid': FieldValue.serverTimestamp(),
    });
    await _userChatRef(uid, chatId).set({
      'chatId': chatId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeMember({
    required String chatId,
    required String uid,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _userChatRef(uid, chatId).delete();
  }

  /// Send a message to a chat
  ///
  /// Uses Firestore transaction to atomically create message and update chat's
  /// lastMessage field. This prevents race conditions where concurrent sends
  /// could overwrite each other's lastMessage updates (Phase 10-03 A-RACE-004).
  ///
  /// Transaction ensures:
  /// - Message document created in messages subcollection
  /// - Chat's lastMessage field always reflects latest message
  /// - Unread counts updated atomically for all members
  ///
  /// Throws Exception if chat is read-only or archived
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String imageUrl = '',
    String videoUrl = '',
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);
      final data =
          chatSnapshot.data() ?? <String, dynamic>{};
      final isReadOnly = data['isReadOnly'] == true;
      final archivedAt = (data['archivedAt'] as Timestamp?)?.toDate();
      if (isReadOnly ||
          (archivedAt != null && archivedAt.isBefore(DateTime.now()))) {
        throw Exception('Chat is read-only');
      }
      final memberIds =
          (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
              <String>[];

      final updates = <String, dynamic>{
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final memberId in memberIds) {
        if (memberId == senderId) {
          updates['unreadCountByUser.$memberId'] = 0;
        } else {
          updates['unreadCountByUser.$memberId'] = FieldValue.increment(1);
        }

        transaction.set(
          _userChatRef(memberId, chatId),
          {
            'chatId': chatId,
            'lastMessageAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      transaction.set(messageRef, {
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'reactions': <String, List<String>>{},
        'readBy': [senderId],
      });
      transaction.update(chatRef, updates);
    });
  }

  Future<void> markChatRead({
    required String chatId,
    required String uid,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCountByUser.$uid': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChat({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Try Cloud Function first (production-grade, admin privileges)
      try {
        AppLog.d('🔥 Attempting Cloud Function deleteChat for $chatId');
        final functions = FirebaseFunctions.instanceFor(region: 'us-west2');
        final callable = functions.httpsCallable('deleteChat');
        final result = await callable.call({'chatId': chatId});

        AppLog.d('✅ Cloud Function deleteChat succeeded: ${result.data}');
        return; // Success via Cloud Function
      } catch (cloudFunctionError) {
        AppLog.d(
            '⚠️ Cloud Function deleteChat failed, falling back to client-side: $cloudFunctionError');
        // Fall through to client-side deletion
      }

      // Fallback: Client-side deletion (uses security rules)
      AppLog.d('📱 Using client-side deleteChat for $chatId');
      final chatRef = _firestore.collection('chats').doc(chatId);

      // First, verify the user is a member of this chat
      final chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatSnapshot.data();
      final memberIds = (chatData?['memberIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          <String>[];

      if (!memberIds.contains(uid)) {
        throw Exception('You do not have permission to delete this chat');
      }

      // Delete all messages in the subcollection (batch delete)
      final messagesRef = chatRef.collection('messages');
      final messagesSnapshot = await messagesRef.get();

      // Delete messages in batches of 500 (Firestore batch limit)
      const batchSize = 500;
      final totalMessages = messagesSnapshot.docs.length;

      for (var i = 0; i < totalMessages; i += batchSize) {
        final batch = _firestore.batch();
        final end =
            (i + batchSize < totalMessages) ? i + batchSize : totalMessages;

        for (var j = i; j < end; j++) {
          batch.delete(messagesSnapshot.docs[j].reference);
        }

        await batch.commit();
      }

      // Delete the chat document itself
      await chatRef.delete();
      AppLog.d('✅ Client-side deleteChat succeeded for $chatId');
    } catch (e, stackTrace) {
      AppLog.d('❌ ChatService: Error deleting chat: $e');
      AppLog.d('❌ ChatService: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final cached = _userCache[uid];
    if (cached != null) {
      return cached;
    }
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    _userCache[uid] = data;
    return data;
  }

  void clearUserCache() {
    _userCache.clear();
  }

  Future<void> setTypingStatus({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    try {
      if (isTyping) {
        await _firestore.collection('chats').doc(chatId).update({
          'typingUsers.$uid': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('chats').doc(chatId).update({
          'typingUsers.$uid': FieldValue.delete(),
        });
      }
    } catch (e) {
      AppLog.d('ChatService: Error updating typing status: $e');
    }
  }

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final messageDoc = await transaction.get(messageRef);
      final data = messageDoc.data() ?? <String, dynamic>{};
      final reactions = Map<String, dynamic>.from(
          data['reactions'] as Map<String, dynamic>? ?? {});

      if (reactions.containsKey(emoji)) {
        final users =
            List<String>.from(reactions[emoji] as List<dynamic>? ?? []);
        if (!users.contains(uid)) {
          users.add(uid);
          reactions[emoji] = users;
        }
      } else {
        reactions[emoji] = [uid];
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final messageDoc = await transaction.get(messageRef);
      final data = messageDoc.data() ?? <String, dynamic>{};
      final reactions = Map<String, dynamic>.from(
          data['reactions'] as Map<String, dynamic>? ?? {});

      if (reactions.containsKey(emoji)) {
        final users =
            List<String>.from(reactions[emoji] as List<dynamic>? ?? []);
        users.remove(uid);

        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        transaction.update(messageRef, {'reactions': reactions});
      }
    });
  }

  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String uid,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Mark multiple unread messages as read in a single batched operation
  ///
  /// This method queries messages where the current user is NOT in the readBy
  /// array and updates them all in a single WriteBatch (or multiple batches
  /// if > 500 messages). This dramatically reduces network calls and improves
  /// "open chat" performance.
  ///
  /// Returns a map with diagnostic info:
  /// - 'unreadCount': number of unread messages found
  /// - 'batchCount': number of batch commits performed
  /// - 'updatedCount': number of messages updated
  Future<Map<String, int>> markMessagesAsReadBatch({
    required String chatId,
    required String uid,
    int limit = 100,
    DateTime? visibleAfter,
  }) async {
    try {
      // Query messages where user is NOT in readBy array
      // Note: Firestore doesn't support "not contains" queries directly,
      // so we fetch recent messages and filter client-side
      Query query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Only consider messages visible to this user (fresh-start-on-rejoin)
      if (visibleAfter != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(visibleAfter),
        );
      }

      final messagesSnapshot = await query.get();

      // Filter to only unread messages
      final unreadDocs = messagesSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = (data['readBy'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            [];
        return !readBy.contains(uid);
      }).toList();

      if (unreadDocs.isEmpty) {
        AppLog.d(
            '📖 ChatService: No unread messages found for chatId=$chatId uid=$uid');
        return {
          'unreadCount': 0,
          'batchCount': 0,
          'updatedCount': 0,
        };
      }

      AppLog.d(
          '📖 ChatService: Found ${unreadDocs.length} unread messages for chatId=$chatId uid=$uid');

      // Firestore WriteBatch has a limit of 500 operations
      const batchSize = 500;
      final totalMessages = unreadDocs.length;
      int batchCount = 0;
      int updatedCount = 0;

      // Process in chunks of 500
      for (var i = 0; i < totalMessages; i += batchSize) {
        final batch = _firestore.batch();
        final end =
            (i + batchSize < totalMessages) ? i + batchSize : totalMessages;

        for (var j = i; j < end; j++) {
          batch.update(unreadDocs[j].reference, {
            'readBy': FieldValue.arrayUnion([uid]),
          });
          updatedCount++;
        }

        await batch.commit();
        batchCount++;
        AppLog.d(
            '📖 ChatService: Committed batch $batchCount with ${end - i} updates');
      }

      AppLog.d(
          '✅ ChatService: markMessagesAsReadBatch complete - $updatedCount messages updated in $batchCount batch(es)');

      return {
        'unreadCount': unreadDocs.length,
        'batchCount': batchCount,
        'updatedCount': updatedCount,
      };
    } catch (e, stackTrace) {
      AppLog.d('❌ ChatService: ERROR in markMessagesAsReadBatch: $e');
      AppLog.d('❌ ChatService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  void logError(String message, Object error, StackTrace stackTrace) {
    AppLog.d('ChatService: $message $error');
    AppLog.d('ChatService stack trace: $stackTrace');
  }
}

class MessagesPage {
  MessagesPage({
    required this.messages,
    required this.lastDoc,
  });

  final List<ChatMessage> messages;
  final DocumentSnapshot? lastDoc;
}
