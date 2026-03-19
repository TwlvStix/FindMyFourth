import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '/core/exceptions/app_exceptions.dart';
import '/core/utils/app_log.dart';
import '/core/utils/input_sanitizer.dart';

class ChatLifecycleService {
  ChatLifecycleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference _userChatRef(String uid, String chatId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chatRefs')
        .doc(chatId);
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
      AppLog.d('❌ ChatLifecycleService.createOrGetDirectChat error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatLifecycleService.createOrGetDirectChat stackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<DocumentReference> createGameChat({
    required String createdByUid,
    required String gameId,
    required String gameName,
  }) async {
    final sanitizedGameName = InputSanitizer.gameName(gameName) ?? '';
    final chatRef = _firestore.collection('chats').doc();
    await chatRef.set({
      'memberIds': [createdByUid],
      'users': [_firestore.collection('users').doc(createdByUid)],
      'type': 'game',
      'gameId': gameId,
      'gameName': sanitizedGameName,
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
      AppLog.d('✅ ChatLifecycleService.addMember: Added $uid to chat $chatId');
    } on FirebaseException catch (e) {
      AppLog.d('❌ ChatLifecycleService.addMember error: ${e.code} - ${e.message}');
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
          '✅ ChatLifecycleService.ensureGameChatMembership: Synced $uid → chat $chatId');
    } catch (e) {
      AppLog.d('⚠️ ChatLifecycleService.ensureGameChatMembership failed: $e');
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
      AppLog.d('✅ ChatLifecycleService.removeMember: Removed $uid from chat $chatId');
    } on FirebaseException catch (e) {
      AppLog.d('❌ ChatLifecycleService.removeMember error: ${e.code} - ${e.message}');
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
        AppLog.d('✅ ChatLifecycleService.leaveChat: deleted chat $chatId (last member)');
      } else {
        // Others remain - just remove this user
        await removeMember(chatId: chatId, uid: uid);
        AppLog.d('✅ ChatLifecycleService.leaveChat: removed user $uid from chat $chatId');
      }
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ ChatLifecycleService.leaveChat error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatLifecycleService.leaveChat stackTrace: $stackTrace');
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
      AppLog.d('❌ ChatLifecycleService.deleteChat error: ${e.code} - ${e.message}');
      AppLog.d('❌ ChatLifecycleService.deleteChat stackTrace: $stackTrace');
      rethrow;
    }
  }
}
