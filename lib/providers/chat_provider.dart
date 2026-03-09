import 'dart:async';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/core/utils/app_log.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_view_model_helpers.dart';
import '/providers/profile_provider.dart';
import '/services/chat_service.dart';

export 'chat_view_model_helpers.dart';

import 'chat_view_model_manager.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  final Map<String, Chat> _chatCache = {};
  final Map<String, List<ChatMessage>> _messagesCache = {};
  final Map<String, StreamRequestManager<List<ChatMessage>>>
      _messageStreamManagers = {};
  final Map<String, StreamRequestManager<List<Chat>>> _chatListStreamManagers =
      {};
  final Map<String, List<Chat>> _chatListCache = {};
  final Map<String, DateTime> _chatCacheTimestamps = {};
  final Map<String, DateTime> _messagesCacheTimestamps = {};
  final Map<String, DateTime> _chatListCacheTimestamps = {};
  final Duration _cacheTTL = const Duration(minutes: 5);
  Timer? _notifyTimer;
  bool _disposed = false;

  late final ChatViewModelManager _viewModelManager =
      ChatViewModelManager(chatProvider: this);

  Chat? getCachedChat(String chatId) => _chatCache[chatId];

  List<ChatMessage>? getCachedMessages(String chatId) => _messagesCache[chatId];

  bool isChatCacheValid(String chatId) {
    final timestamp = _chatCacheTimestamps[chatId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  bool isMessagesCacheValid(String chatId) {
    final timestamp = _messagesCacheTimestamps[chatId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  bool isChatListCacheValid(String queryKey) {
    final timestamp = _chatListCacheTimestamps[queryKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  Stream<List<Chat>> chatListStream({
    required String uid,
    int limit = 50,
  }) {
    final queryKey = 'chat_list_${uid}_$limit';
    if (!_chatListStreamManagers.containsKey(queryKey)) {
      _chatListStreamManagers[queryKey] = StreamRequestManager<List<Chat>>(5);
    }
    return _chatListStreamManagers[queryKey]!
        .performRequest(
      uniqueQueryKey: queryKey,
      requestFn: () => _service.getChatListStream(uid: uid, limit: limit),
    )
        .map((chats) {
      _chatListCache[queryKey] = chats;
      _chatListCacheTimestamps[queryKey] = DateTime.now();
      return chats;
    });
  }

  List<Chat>? getCachedChatList(String uid, {int limit = 50}) {
    final queryKey = 'chat_list_${uid}_$limit';
    if (isChatListCacheValid(queryKey)) {
      return _chatListCache[queryKey];
    }
    return _chatListStreamManagers[queryKey]?.getLastValue(queryKey);
  }

  Stream<Chat?> chatStream(String chatId) {
    return _service.getChatStream(chatId: chatId).map((chat) {
      if (chat != null) {
        _chatCache[chatId] = chat;
        _chatCacheTimestamps[chatId] = DateTime.now();
      }
      return chat;
    });
  }

  Stream<List<ChatMessage>> messagesStream({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
    DateTime? visibleAfter,
  }) {
    if (!_messageStreamManagers.containsKey(chatId)) {
      _messageStreamManagers[chatId] =
          StreamRequestManager<List<ChatMessage>>(5);
    }
    return _messageStreamManagers[chatId]!.performRequest(
      uniqueQueryKey: 'messages_${chatId}_$limit',
      requestFn: () => _service
          .getMessagesStream(
        chatId: chatId,
        limit: limit,
        startAfter: startAfter,
        visibleAfter: visibleAfter,
      )
          .map((messages) {
        _messagesCache[chatId] = messages;
        _messagesCacheTimestamps[chatId] = DateTime.now();
        return messages;
      }),
    );
  }

  Stream<QuerySnapshot> messagesSnapshotStream({
    required String chatId,
    int limit = 50,
    DateTime? visibleAfter,
  }) {
    return _service.getMessagesSnapshotStream(
      chatId: chatId,
      limit: limit,
      visibleAfter: visibleAfter,
    );
  }

  Future<MessagesPage> messagesPage({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
    DateTime? visibleAfter,
  }) {
    return _service.getMessagesPage(
      chatId: chatId,
      limit: limit,
      startAfter: startAfter,
      visibleAfter: visibleAfter,
    );
  }

  Future<DocumentReference> createOrGetDirectChat({
    required String currentUid,
    required String otherUid,
  }) async {
    AppLog.d('📱 ChatProvider: createOrGetDirectChat called');
    AppLog.d('📱 ChatProvider: currentUid=$currentUid, otherUid=$otherUid');
    try {
      final result = await _service.createOrGetDirectChat(
        currentUid: currentUid,
        otherUid: otherUid,
      );
      AppLog.d(
          '✅ ChatProvider: createOrGetDirectChat success, chatId=${result.id}');
      return result;
    } catch (e) {
      AppLog.d('❌ ChatProvider.createOrGetDirectChat error: $e');
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
    String type = 'text',
    String thumbnailUrl = '',
    double? imageWidth,
    double? imageHeight,
  }) async {
    try {
      await _service.sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        type: type,
        thumbnailUrl: thumbnailUrl,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
      _messagesCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String imageUrl,
    String thumbnailUrl = '',
    double? imageWidth,
    double? imageHeight,
  }) =>
      sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: '',
        imageUrl: imageUrl,
        type: 'image',
        thumbnailUrl: thumbnailUrl,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

  Future<void> markChatRead({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _service.markChatRead(chatId: chatId, uid: uid);
      _chatCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  /// Marks all chat_message notifications for this chat as read.
  Future<void> markChatNotificationsAsRead({
    required String chatId,
    required String uid,
  }) async {
    await _service.markChatNotificationsAsRead(chatId: chatId, uid: uid);
  }

  Future<void> deleteChat({
    required String chatId,
    required String uid,
  }) async {
    AppLog.d('📱 ChatProvider: deleteChat called, chatId=$chatId, uid=$uid');
    try {
      await _service.deleteChat(chatId: chatId, uid: uid);
      _chatCache.remove(chatId);
      _chatCacheTimestamps.remove(chatId);
      _messagesCache.remove(chatId);
      _messagesCacheTimestamps.remove(chatId);
      _messageStreamManagers[chatId]?.clear();
      _messageStreamManagers.remove(chatId);
      AppLog.d('✅ ChatProvider: deleteChat successful');
      _scheduleNotify();
    } catch (e) {
      AppLog.d('❌ ChatProvider.deleteChat error: $e');
      rethrow;
    }
  }

  Future<void> addMember({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _service.addMember(chatId: chatId, uid: uid);
      _chatCacheTimestamps.remove(chatId);
      _messagesCache.remove(chatId);
      _messagesCacheTimestamps.remove(chatId);
      _messageStreamManagers[chatId]?.clear();
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  /// Eagerly sync chat membership after joining a game.
  /// Non-critical passthrough — see ChatService.ensureGameChatMembership.
  Future<void> ensureGameChatMembership({
    required String chatId,
    required String uid,
  }) =>
      _service.ensureGameChatMembership(chatId: chatId, uid: uid);

  Future<void> removeMember({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _service.removeMember(chatId: chatId, uid: uid);
      _chatCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  /// Send a system message (no sender, lifecycle notifications).
  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      await _service.sendSystemMessage(chatId: chatId, text: text);
      _messagesCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      AppLog.d('❌ ChatProvider.sendSystemMessage error: $e');
      rethrow;
    }
  }

  /// Check if a user is the last member of a chat.
  Future<bool> isLastMember({
    required String chatId,
    required String uid,
  }) {
    return _service.isLastMember(chatId: chatId, uid: uid);
  }

  /// Leave a chat. Deletes if last member, otherwise just removes user.
  Future<void> leaveChat({
    required String chatId,
    required String uid,
  }) async {
    AppLog.d('📱 ChatProvider: leaveChat called, chatId=$chatId, uid=$uid');
    try {
      await _service.leaveChat(chatId: chatId, uid: uid);
      _chatCache.remove(chatId);
      _chatCacheTimestamps.remove(chatId);
      _messagesCache.remove(chatId);
      _messagesCacheTimestamps.remove(chatId);
      _messageStreamManagers[chatId]?.clear();
      _messageStreamManagers.remove(chatId);
      AppLog.d('✅ ChatProvider: leaveChat successful');
      _scheduleNotify();
    } catch (e) {
      AppLog.d('❌ ChatProvider.leaveChat error: $e');
      rethrow;
    }
  }

  // Cache invalidation

  void invalidateChatCache(String chatId) {
    _chatCache.remove(chatId);
    _chatCacheTimestamps.remove(chatId);
  }

  void invalidateMessagesCache(String chatId) {
    _messagesCache.remove(chatId);
    _messagesCacheTimestamps.remove(chatId);
    _messageStreamManagers[chatId]?.clear();
  }

  void invalidateAllChatCache() {
    _chatCache.clear();
    _chatCacheTimestamps.clear();
    _messagesCache.clear();
    _messagesCacheTimestamps.clear();
    for (final manager in _messageStreamManagers.values) {
      manager.clear();
    }
    _messageStreamManagers.clear();
  }

  Future<void> refreshChat(String chatId) async {
    invalidateChatCache(chatId);
  }

  Future<void> refreshMessages(String chatId) async {
    invalidateMessagesCache(chatId);
  }

  // Internal helpers

  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  Future<void> setTypingStatus({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) {
    return _service.setTypingStatus(
        chatId: chatId, uid: uid, isTyping: isTyping);
  }

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) {
    return _service.addReaction(
        chatId: chatId, messageId: messageId, emoji: emoji, uid: uid);
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String uid,
  }) {
    return _service.removeReaction(
        chatId: chatId, messageId: messageId, emoji: emoji, uid: uid);
  }

  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
    required String uid,
  }) {
    return _service.markMessageAsRead(
        chatId: chatId, messageId: messageId, uid: uid);
  }

  /// Mark multiple unread messages as read in a single batched operation.
  Future<Map<String, int>> markMessagesAsReadBatch({
    required String chatId,
    required String uid,
    int limit = 100,
    DateTime? visibleAfter,
  }) {
    return _service.markMessagesAsReadBatch(
      chatId: chatId,
      uid: uid,
      limit: limit,
      visibleAfter: visibleAfter,
    );
  }

  void logError(String message, Object error, StackTrace stackTrace) {
    _service.logError(message, error, stackTrace);
  }

  // View model streams (delegated to ChatViewModelManager)

  Stream<List<ChatMessageViewModel>> gameChatMessageViewModelsStream({
    required String chatId,
    required int limit,
    required ProfileProvider profileProvider,
    DateTime? visibleAfter,
  }) =>
      _viewModelManager.gameChatMessageViewModelsStream(
        chatId: chatId,
        limit: limit,
        profileProvider: profileProvider,
        visibleAfter: visibleAfter,
      );

  Stream<List<ChatRowViewModel>> chatRowsStream({
    required String currentUserId,
    required ProfileProvider profileProvider,
    int limit = 50,
  }) =>
      _viewModelManager.chatRowsStream(
        currentUserId: currentUserId,
        profileProvider: profileProvider,
        limit: limit,
      );

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _viewModelManager.dispose();
    for (final manager in _messageStreamManagers.values) {
      manager.clear();
    }
    _messageStreamManagers.clear();
    for (final manager in _chatListStreamManagers.values) {
      manager.clear();
    }
    _chatListStreamManagers.clear();
    _chatCache.clear();
    _chatCacheTimestamps.clear();
    _messagesCache.clear();
    _messagesCacheTimestamps.clear();
    _chatListCache.clear();
    _chatListCacheTimestamps.clear();
    super.dispose();
  }
}
