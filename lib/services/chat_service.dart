import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/models/chat.dart';
import '/models/chat_message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, Map<String, dynamic>> _userCache = {};

  Stream<List<Chat>> getChatListStream({
    required String uid,
    int limit = 50,
  }) {
    debugPrint('💬 ChatService: getChatListStream called');
    debugPrint('💬 ChatService: uid=$uid, limit=$limit');
    debugPrint('💬 ChatService: Query: chats where memberIds contains $uid AND type=direct');

    return _firestore
        .collection('chats')
        .where('memberIds', arrayContains: uid)
        .where('type', isEqualTo: 'direct')
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          debugPrint('💬 ChatService: Received snapshot with ${snapshot.docs.length} chats');
          if (snapshot.docs.isNotEmpty) {
            debugPrint('💬 ChatService: First chat ID: ${snapshot.docs.first.id}');
          }
          try {
            final chats = snapshot.docs.map(Chat.fromDoc).toList();
            debugPrint('💬 ChatService: Successfully converted ${chats.length} Chat objects');
            return chats;
          } catch (e, stackTrace) {
            debugPrint('❌ ChatService: Error converting chats: $e');
            debugPrint('❌ ChatService: StackTrace: $stackTrace');
            rethrow;
          }
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
    debugPrint('📨 ChatService: getMessagesSnapshotStream called');
    debugPrint('📨 ChatService: chatId=$chatId, limit=$limit');
    final path = 'chats/$chatId/messages';
    debugPrint('📨 ChatService: Querying path: $path');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          debugPrint('📨 ChatService: Received snapshot with ${snapshot.docs.length} messages');
          if (snapshot.docs.isNotEmpty) {
            final firstMsg = snapshot.docs.first.data();
            debugPrint('📨 ChatService: First message: ${firstMsg['text']?.toString().substring(0, 30) ?? 'no text'}');
          }
          return snapshot;
        });
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
    debugPrint('🔧 ChatService: createOrGetDirectChat START');
    debugPrint('🔧 ChatService: currentUid=$currentUid');
    debugPrint('🔧 ChatService: otherUid=$otherUid');

    final memberIds = [currentUid, otherUid]..sort();
    final directKey = memberIds.join('_');
    debugPrint('🔧 ChatService: directKey=$directKey');
    debugPrint('🔧 ChatService: memberIds=$memberIds');

    final chats = _firestore.collection('chats');

    try {
      // Use directKey as the document ID
      final chatRef = chats.doc(directKey);

      debugPrint('🔧 ChatService: Attempting to create chat document...');
      debugPrint('🔧 ChatService: Chat path: ${chatRef.path}');

      // Try to create the chat document
      // If it already exists, this will fail with 'already-exists' or succeed with merge
      try {
        await chatRef.set({
          'memberIds': memberIds,
          'directKey': directKey,
          'type': 'direct',
          'gameId': null,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUid,
          'unreadCountByUser': {
            currentUid: 0,
            otherUid: 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Merge: won't overwrite if exists

        debugPrint('✅ ChatService: Chat created/updated successfully: ${chatRef.id}');
        return chatRef;
      } catch (setError) {
        debugPrint('⚠️ ChatService: Set operation result: $setError');
        // If set fails, document might already exist and we have permission to read it
        // Try to read it now that we know we should be a member
        try {
          debugPrint('🔧 ChatService: Attempting to read existing chat...');
          final chatSnapshot = await chatRef.get();
          if (chatSnapshot.exists) {
            debugPrint('✅ ChatService: Found existing chat: ${chatRef.id}');
            return chatRef;
          }
        } catch (readError) {
          debugPrint('❌ ChatService: Could not read chat: $readError');
        }
        // If both set and read failed, rethrow the original set error
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ChatService: ERROR in createOrGetDirectChat');
      debugPrint('❌ ChatService: Error type: ${e.runtimeType}');
      debugPrint('❌ ChatService: Error message: $e');
      debugPrint('❌ ChatService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<DocumentReference> createGameChat({
    required String createdByUid,
    required String gameId,
  }) async {
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'memberIds': [createdByUid],
      'type': 'game',
      'gameId': gameId,
      'lastMessage': '',
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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
      }

      transaction.set(messageRef, {
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'createdAt': FieldValue.serverTimestamp(),
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
    debugPrint('🗑️ ChatService: deleteChat called');
    debugPrint('🗑️ ChatService: chatId=$chatId, uid=$uid');

    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      // First, verify the user is a member of this chat
      final chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        debugPrint('❌ ChatService: Chat does not exist');
        throw Exception('Chat not found');
      }

      final chatData = chatSnapshot.data() as Map<String, dynamic>?;
      final memberIds = (chatData?['memberIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          <String>[];

      if (!memberIds.contains(uid)) {
        debugPrint('❌ ChatService: User is not a member of this chat');
        throw Exception('You do not have permission to delete this chat');
      }

      debugPrint('🗑️ ChatService: User verified as member, proceeding with delete');

      // Delete all messages in the subcollection (batch delete)
      final messagesRef = chatRef.collection('messages');
      final messagesSnapshot = await messagesRef.get();

      debugPrint('🗑️ ChatService: Found ${messagesSnapshot.docs.length} messages to delete');

      // Delete messages in batches of 500 (Firestore batch limit)
      const batchSize = 500;
      final totalMessages = messagesSnapshot.docs.length;
      var deletedCount = 0;

      for (var i = 0; i < totalMessages; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < totalMessages) ? i + batchSize : totalMessages;

        for (var j = i; j < end; j++) {
          batch.delete(messagesSnapshot.docs[j].reference);
        }

        await batch.commit();
        deletedCount += (end - i);
        debugPrint('🗑️ ChatService: Deleted $deletedCount/$totalMessages messages');
      }

      // Delete the chat document itself
      await chatRef.delete();
      debugPrint('✅ ChatService: Chat deleted successfully');
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
