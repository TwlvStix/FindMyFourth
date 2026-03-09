import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '/core/exceptions/app_exceptions.dart';
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
            'deletesAt': null,
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
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ ChatService.createOrGetDirectChat error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatService.createOrGetDirectChat stackTrace: $stackTrace');
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
      'deletesAt': null,
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

  /// Add a member to a chat (for non-game chats like direct messages).
  ///
  /// Note: For game chats, membership is managed by the syncGameChatMembers
  /// Cloud Function trigger which watches games/{gameId}.joined_players.
  ///
  /// Updates chat.memberIds and creates users/{uid}/chatRefs/{chatId}.
  /// Uses sequential writes due to Firestore rules requiring membership first.
  Future<void> addMember({
    required String chatId,
    required String uid,
  }) async {
    try {
      // Sequential writes - rules require memberIds update before chatRef creation
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
      AppLog.d('✅ ChatService.addMember: Added $uid to chat $chatId');
    } on FirebaseException catch (e) {
      AppLog.d('❌ ChatService.addMember error: ${e.code} - ${e.message}');
      throw ChatOperationException(
        'Failed to add member to chat',
        code: e.code,
        cause: e,
      );
    }
  }

  /// Eagerly sync chat membership after joining a game.
  ///
  /// Called client-side immediately after joinGame() to prevent a race condition
  /// where the user opens the chat before the syncGameChatMembers Cloud Function
  /// completes. Uses arrayUnion so it's idempotent with the Cloud Function.
  ///
  /// Non-critical — catches all errors so the join flow isn't blocked.
  Future<void> ensureGameChatMembership({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'memberIds': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCountByUser.$uid': 0,
        'memberJoinedAt.$uid': FieldValue.serverTimestamp(),
      });
      await _userChatRef(uid, chatId).set({
        'chatId': chatId,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLog.d(
          '✅ ChatService.ensureGameChatMembership: Synced $uid → chat $chatId');
    } catch (e) {
      AppLog.d('⚠️ ChatService.ensureGameChatMembership failed: $e');
    }
  }

  /// Remove a member from a chat (for non-game chats like direct messages).
  ///
  /// Note: For game chats, membership is managed by the syncGameChatMembers
  /// Cloud Function trigger which watches games/{gameId}.joined_players.
  ///
  /// Updates chat.memberIds and deletes users/{uid}/chatRefs/{chatId}.
  Future<void> removeMember({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'memberIds': FieldValue.arrayRemove([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _userChatRef(uid, chatId).delete();
      AppLog.d('✅ ChatService.removeMember: Removed $uid from chat $chatId');
    } on FirebaseException catch (e) {
      AppLog.d('❌ ChatService.removeMember error: ${e.code} - ${e.message}');
      throw ChatOperationException(
        'Failed to remove member from chat',
        code: e.code,
        cause: e,
      );
    }
  }

  /// Check if a user is the last member of a chat
  ///
  /// Returns true if the user is the only remaining member, meaning
  /// leaving would delete the chat entirely.
  Future<bool> isLastMember({
    required String chatId,
    required String uid,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      return false;
    }

    final data = chatSnapshot.data() ?? <String, dynamic>{};
    final memberIds =
        (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
            <String>[];

    return memberIds.length == 1 && memberIds.contains(uid);
  }

  /// Leave a chat
  ///
  /// If the user is the last member, this will delete the chat and all messages.
  /// If other members remain, this will just remove the user from the chat.
  ///
  /// Call [isLastMember] first to check if a warning should be shown.
  Future<void> leaveChat({
    required String chatId,
    required String uid,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnapshot = await chatRef.get();

      if (!chatSnapshot.exists) {
        throw Exception('Chat not found');
      }

      final data = chatSnapshot.data() ?? <String, dynamic>{};
      final memberIds =
          (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
              <String>[];

      if (!memberIds.contains(uid)) {
        throw Exception('User is not a member of this chat');
      }

      if (memberIds.length == 1) {
        // Last member - delete the entire chat
        await _deleteChatAndMessages(chatId);
        AppLog.d('✅ ChatService.leaveChat: deleted chat $chatId (last member)');
      } else {
        // Others remain - just remove this user
        await removeMember(chatId: chatId, uid: uid);
        AppLog.d('✅ ChatService.leaveChat: removed user $uid from chat $chatId');
      }
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ ChatService.leaveChat error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatService.leaveChat stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Delete a chat and all its messages
  ///
  /// Internal helper used by [leaveChat] when the last member leaves.
  Future<void> _deleteChatAndMessages(String chatId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    // Get all members to clean up their chatRefs
    final chatSnapshot = await chatRef.get();
    final data = chatSnapshot.data() ?? <String, dynamic>{};
    final memberIds =
        (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
            <String>[];

    // Delete all messages in batches
    final messagesRef = chatRef.collection('messages');
    final messagesSnapshot = await messagesRef.get();

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

    // Delete chatRefs for all members
    final batch = _firestore.batch();
    for (final memberId in memberIds) {
      batch.delete(_userChatRef(memberId, chatId));
    }
    await batch.commit();

    // Delete the chat document
    await chatRef.delete();
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
        'text': text,
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

    AppLog.d('✅ ChatService.sendSystemMessage: sent to chat $chatId');
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
        'lastMessage': type == 'image' ? '📷 Photo' : text,
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
          '✅ ChatService.markChatNotificationsAsRead: marked ${matchingDocs.length} notifications as read for chat $chatId');
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ ChatService.markChatNotificationsAsRead error: ${e.code} - ${e.message}');
      rethrow;
    }
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
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ ChatService.deleteChat error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatService.deleteChat stackTrace: $stackTrace');
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
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ ChatService.markMessagesAsReadBatch error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatService.markMessagesAsReadBatch stackTrace: $stackTrace');
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
