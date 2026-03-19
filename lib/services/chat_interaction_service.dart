import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';

class ChatInteractionService {
  ChatInteractionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
      AppLog.d('ChatInteractionService: Error updating typing status: $e');
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
}
