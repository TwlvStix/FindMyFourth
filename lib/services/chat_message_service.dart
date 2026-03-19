import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '/core/utils/app_log.dart';
import '/core/utils/input_sanitizer.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';

class ChatMessageService {
  ChatMessageService({FirebaseFirestore? firestore})
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

  /// Helper: Chunk a list into batches of specified size
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
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
          '[ChatMessageService] Batching ${chatIds.length} chats into ${batches.length} queries (${batches.map((b) => b.length).join(", ")} per batch)',
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
              .doOnError((error, stackTrace) {
                AppLog.d('❌ ChatMessageService.getChatListStream batch error: $error');
              });
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

  /// Send a system message to a chat
  ///
  /// System messages have no sender and are styled differently in the UI.
  /// They bypass the read-only check since they're used for chat lifecycle
  /// notifications (e.g., game cancellation).
  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
  }) async {
    final sanitizedText = InputSanitizer.chatMessage(text) ?? '';
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);
      final data = chatSnapshot.data() ?? <String, dynamic>{};
      final memberIds =
          (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
              <String>[];

      // Create the system message
      transaction.set(messageRef, {
        'senderId': '',
        'text': sanitizedText,
        'imageUrl': '',
        'videoUrl': '',
        'type': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'reactions': <String, List<String>>{},
        'readBy': <String>[],
      });

      // Update chat metadata (don't update lastMessage for system messages
      // to keep user messages visible in chat list preview)
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update chatRefs for all members so they see the chat activity
      for (final memberId in memberIds) {
        transaction.set(
          _userChatRef(memberId, chatId),
          {
            'chatId': chatId,
            'lastMessageAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      transaction.update(chatRef, updates);
    });

    AppLog.d('✅ ChatMessageService.sendSystemMessage: sent to chat $chatId');
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
    String type = 'text',
    String thumbnailUrl = '',
    double? imageWidth,
    double? imageHeight,
  }) async {
    final sanitizedText = InputSanitizer.chatMessage(text) ?? '';
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);
      final data =
          chatSnapshot.data() ?? <String, dynamic>{};
      final isReadOnly = data['isReadOnly'] == true;
      if (isReadOnly) {
        throw Exception('Chat is read-only');
      }
      final memberIds =
          (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
              <String>[];

      final updates = <String, dynamic>{
        'lastMessage': type == 'image' ? '📷 Photo' : sanitizedText,
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
        'text': sanitizedText,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'type': type,
        if (thumbnailUrl.isNotEmpty) 'thumbnailUrl': thumbnailUrl,
        if (imageWidth != null) 'imageWidth': imageWidth,
        if (imageHeight != null) 'imageHeight': imageHeight,
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

  /// Marks all chat_message notifications for this chat as read.
  /// Called when user opens and reads the chat directly (not via notification tap).
  /// This syncs notification read status with chat read status.
  Future<void> markChatNotificationsAsRead({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Query unread chat_message notifications, then filter client-side by threadId.
      // This avoids needing a composite Firestore index on (type, data.threadId, read).
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('type', isEqualTo: 'chat_message')
          .where('read', isEqualTo: false)
          .get();

      // Client-side filter for matching chatId
      final matchingDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final nestedData = data['data'];
        if (nestedData is Map) {
          final threadId = nestedData['threadId'];
          return threadId == chatId;
        }
        return false;
      }).toList();

      if (matchingDocs.isEmpty) return;

      // Batch update all to read: true
      final batch = _firestore.batch();
      for (final doc in matchingDocs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      AppLog.d(
          '✅ ChatMessageService.markChatNotificationsAsRead: marked ${matchingDocs.length} notifications as read for chat $chatId');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ ChatMessageService.markChatNotificationsAsRead error: ${e.code} - ${e.message}');
      rethrow;
    }
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
            '📖 ChatMessageService: No unread messages found for chatId=$chatId uid=$uid');
        return {
          'unreadCount': 0,
          'batchCount': 0,
          'updatedCount': 0,
        };
      }

      AppLog.d(
          '📖 ChatMessageService: Found ${unreadDocs.length} unread messages for chatId=$chatId uid=$uid');

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
            '📖 ChatMessageService: Committed batch $batchCount with ${end - i} updates');
      }

      AppLog.d(
          '✅ ChatMessageService: markMessagesAsReadBatch complete - $updatedCount messages updated in $batchCount batch(es)');

      return {
        'unreadCount': unreadDocs.length,
        'batchCount': batchCount,
        'updatedCount': updatedCount,
      };
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ ChatMessageService.markMessagesAsReadBatch error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatMessageService.markMessagesAsReadBatch stackTrace: $stackTrace');
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

  void logError(String message, Object error, StackTrace stackTrace) {
    AppLog.d('ChatMessageService: $message $error');
    AppLog.d('ChatMessageService stack trace: $stackTrace');
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
