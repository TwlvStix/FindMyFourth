import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/models/chat.dart';
import '/models/chat_message.dart';
import '/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? service})
      : _service = service ?? ChatService();

  final ChatService _service;

  Stream<List<Chat>> chatListStream({
    required String uid,
    int limit = 50,
  }) {
    return _service.getChatListStream(uid: uid, limit: limit);
  }

  Stream<Chat?> chatStream(String chatId) {
    return _service.getChatStream(chatId: chatId);
  }

  Stream<List<ChatMessage>> messagesStream({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    return _service.getMessagesStream(
      chatId: chatId,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Stream<QuerySnapshot> messagesSnapshotStream({
    required String chatId,
    int limit = 50,
  }) {
    return _service.getMessagesSnapshotStream(
      chatId: chatId,
      limit: limit,
    );
  }

  Future<MessagesPage> messagesPage({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    return _service.getMessagesPage(
      chatId: chatId,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<DocumentReference> createOrGetDirectChat({
    required String currentUid,
    required String otherUid,
  }) async {
    debugPrint('📱 ChatProvider: createOrGetDirectChat called');
    debugPrint('📱 ChatProvider: currentUid=$currentUid, otherUid=$otherUid');

    try {
      final result = await _service.createOrGetDirectChat(
        currentUid: currentUid,
        otherUid: otherUid,
      );
      debugPrint('📱 ChatProvider: Success! Chat ID: ${result.id}');
      return result;
    } catch (e, stackTrace) {
      debugPrint('📱 ChatProvider: ERROR in createOrGetDirectChat');
      debugPrint('📱 ChatProvider: Error: $e');
      debugPrint('📱 ChatProvider: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<DocumentReference> createGameChat({
    required String createdByUid,
    required String gameId,
    required String gameName,
  }) {
    return _service.createGameChat(
      createdByUid: createdByUid,
      gameId: gameId,
      gameName: gameName,
    );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String imageUrl = '',
    String videoUrl = '',
  }) {
    return _service.sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
    );
  }

  Future<void> markChatRead({
    required String chatId,
    required String uid,
  }) {
    return _service.markChatRead(chatId: chatId, uid: uid);
  }

  Future<void> deleteChat({
    required String chatId,
    required String uid,
  }) async {
    debugPrint('📱 ChatProvider: deleteChat called');
    debugPrint('📱 ChatProvider: chatId=$chatId, uid=$uid');

    try {
      await _service.deleteChat(chatId: chatId, uid: uid);
      debugPrint('📱 ChatProvider: Delete successful');
    } catch (e, stackTrace) {
      debugPrint('📱 ChatProvider: Error deleting chat: $e');
      debugPrint('📱 ChatProvider: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addMember({
    required String chatId,
    required String uid,
  }) {
    return _service.addMember(chatId: chatId, uid: uid);
  }

  Future<void> removeMember({
    required String chatId,
    required String uid,
  }) {
    return _service.removeMember(chatId: chatId, uid: uid);
  }

  Future<Map<String, dynamic>> getUserProfile(String uid) {
    return _service.getUserProfile(uid);
  }

  void clearUserCache() {
    _service.clearUserCache();
  }

  Future<void> setTypingStatus({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) {
    return _service.setTypingStatus(
      chatId: chatId,
      uid: uid,
      isTyping: isTyping,
    );
  }

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) {
    return _service.addReaction(
      chatId: chatId,
      messageId: messageId,
      emoji: emoji,
      uid: uid,
    );
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) {
    return _service.removeReaction(
      chatId: chatId,
      messageId: messageId,
      emoji: emoji,
      uid: uid,
    );
  }

  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String uid,
  }) {
    return _service.markMessageAsRead(
      chatId: chatId,
      messageId: messageId,
      uid: uid,
    );
  }

  void logError(String message, Object error, StackTrace stackTrace) {
    _service.logError(message, error, stackTrace);
  }
}
