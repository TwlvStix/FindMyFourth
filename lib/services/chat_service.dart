import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/models/chat.dart';
import '/models/chat_message.dart';
import '/services/firestore_repository.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, Map<String, dynamic>> _userCache = {};

  Stream<List<Chat>> getChatListStream({
    required String uid,
    int limit = 50,
  }) {
    final query = _firestore
        .collection('chats')
        .where('memberIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .limit(limit);

    return const FirestoreRepository()
        .queryCollectionPage<Chat>(
          query,
          (doc) => Chat.fromDoc(doc),
          pageSize: limit,
          isStream: true,
        )
        .asStream()
        .asyncExpand((page) => page.dataStream ?? Stream.value(page.data))
        .map((chats) => chats);
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
  }) {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map(ChatMessage.fromDoc).toList(),
        );
  }

  Stream<QuerySnapshot> getMessagesSnapshotStream({
    required String chatId,
    int limit = 50,
  }) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<MessagesPage> getMessagesPage({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit);

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
        if (chatSnapshot.exists) {
          return;
        }
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
          'last_message': '',
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
      });

      return chatRef;
    } catch (e, stackTrace) {
      debugPrint('❌ ChatService: ERROR in createOrGetDirectChat: $e');
      debugPrint('❌ ChatService: Stack trace: $stackTrace');
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
      'last_message': '',
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
    return chatRef;
  }

  Future<void> addMember({
    required String chatId,
    required String uid,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'users': FieldValue.arrayUnion(
        [_firestore.collection('users').doc(uid)],
      ),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCountByUser.$uid': 0,
    });
  }

  Future<void> removeMember({
    required String chatId,
    required String uid,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'users': FieldValue.arrayRemove(
        [_firestore.collection('users').doc(uid)],
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send a message to a chat
  ///
  /// Uses Firestore transaction to atomically create message and update chat's
  /// last_message field. This prevents race conditions where concurrent sends
  /// could overwrite each other's last_message updates (Phase 10-03 A-RACE-004).
  ///
  /// Transaction ensures:
  /// - Message document created in messages subcollection
  /// - Chat's last_message field always reflects latest message
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
          chatSnapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final isReadOnly = data['isReadOnly'] == true;
      final archivedAt =
          (data['archivedAt'] as Timestamp?)?.toDate();
      if (isReadOnly ||
          (archivedAt != null && archivedAt.isBefore(DateTime.now()))) {
        throw Exception('Chat is read-only');
      }
      final memberIds =
          (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
              <String>[];

      final updates = <String, dynamic>{
        'last_message': text,
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
      final chatRef = _firestore.collection('chats').doc(chatId);

      // First, verify the user is a member of this chat
      final chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatSnapshot.data() as Map<String, dynamic>?;
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
        final end = (i + batchSize < totalMessages) ? i + batchSize : totalMessages;

        for (var j = i; j < end; j++) {
          batch.delete(messagesSnapshot.docs[j].reference);
        }

        await batch.commit();
      }

      // Delete the chat document itself
      await chatRef.delete();
    } catch (e, stackTrace) {
      debugPrint('❌ ChatService: Error deleting chat: $e');
      debugPrint('❌ ChatService: StackTrace: $stackTrace');
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
      debugPrint('ChatService: Error updating typing status: $e');
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
      final reactions = Map<String, dynamic>.from(data['reactions'] as Map<String, dynamic>? ?? {});

      if (reactions.containsKey(emoji)) {
        final users = List<String>.from(reactions[emoji] as List<dynamic>? ?? []);
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
      final reactions = Map<String, dynamic>.from(data['reactions'] as Map<String, dynamic>? ?? {});

      if (reactions.containsKey(emoji)) {
        final users = List<String>.from(reactions[emoji] as List<dynamic>? ?? []);
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

  void logError(String message, Object error, StackTrace stackTrace) {
    debugPrint('ChatService: $message $error');
    debugPrintStack(stackTrace: stackTrace);
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
