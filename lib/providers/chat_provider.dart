import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/core/request_manager.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? service})
      : _service = service ?? ChatService();

  final ChatService _service;

  // ========================================
  // STATE FIELDS
  // ========================================

  // Chat cache (by chat ID)
  final Map<String, Chat> _chatCache = {};

  // Messages cache (by chat ID)
  final Map<String, List<ChatMessage>> _messagesCache = {};

  // StreamRequestManagers for message streams (by chat ID)
  final Map<String, StreamRequestManager<List<ChatMessage>>> _messageStreamManagers = {};

  // Cache timestamps for TTL tracking
  final Map<String, DateTime> _chatCacheTimestamps = {};
  final Map<String, DateTime> _messagesCacheTimestamps = {};

  // Cache TTL duration
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Debounce timer for notifyListeners
  Timer? _notifyTimer;

  // ========================================
  // CACHE GETTERS
  // ========================================

  /// Get cached chat by ID
  Chat? getCachedChat(String chatId) => _chatCache[chatId];

  /// Get cached messages by chat ID
  List<ChatMessage>? getCachedMessages(String chatId) => _messagesCache[chatId];

  /// Check if chat cache is valid (within TTL)
  bool isChatCacheValid(String chatId) {
    final timestamp = _chatCacheTimestamps[chatId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  /// Check if messages cache is valid (within TTL)
  bool isMessagesCacheValid(String chatId) {
    final timestamp = _messagesCacheTimestamps[chatId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTTL;
  }

  Stream<List<Chat>> chatListStream({
    required String uid,
    int limit = 50,
  }) {
    return _service.getChatListStream(uid: uid, limit: limit);
  }

  Stream<Chat?> chatStream(String chatId) {
    return _service.getChatStream(chatId: chatId).map((chat) {
      if (chat != null) {
        // Cache the chat when it comes through the stream
        _chatCache[chatId] = chat;
        _chatCacheTimestamps[chatId] = DateTime.now();
        _scheduleNotify();
      }
      return chat;
    });
  }

  Stream<List<ChatMessage>> messagesStream({
    required String chatId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    // Use StreamRequestManager for caching message streams (5-minute TTL)
    if (!_messageStreamManagers.containsKey(chatId)) {
      _messageStreamManagers[chatId] = StreamRequestManager<List<ChatMessage>>(5);
    }

    return _messageStreamManagers[chatId]!.performRequest(
      uniqueQueryKey: 'messages_${chatId}_$limit',
      requestFn: () => _service.getMessagesStream(
        chatId: chatId,
        limit: limit,
        startAfter: startAfter,
      ).map((messages) {
        // Cache messages when they come through the stream
        _messagesCache[chatId] = messages;
        _messagesCacheTimestamps[chatId] = DateTime.now();
        _scheduleNotify();
        return messages;
      }),
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
  }) async {
    try {
      await _service.sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
      // Invalidate messages cache after sending to force refresh
      _messagesCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markChatRead({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _service.markChatRead(chatId: chatId, uid: uid);
      // Invalidate chat cache to refresh read status
      _chatCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteChat({
    required String chatId,
    required String uid,
  }) async {
    debugPrint('📱 ChatProvider: deleteChat called');
    debugPrint('📱 ChatProvider: chatId=$chatId, uid=$uid');

    try {
      await _service.deleteChat(chatId: chatId, uid: uid);
      // Remove from caches
      _chatCache.remove(chatId);
      _chatCacheTimestamps.remove(chatId);
      _messagesCache.remove(chatId);
      _messagesCacheTimestamps.remove(chatId);
      _messageStreamManagers[chatId]?.clear();
      _messageStreamManagers.remove(chatId);
      debugPrint('📱 ChatProvider: Delete successful');
      _scheduleNotify();
    } catch (e, stackTrace) {
      debugPrint('📱 ChatProvider: Error deleting chat: $e');
      debugPrint('📱 ChatProvider: StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addMember({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _service.addMember(chatId: chatId, uid: uid);
      // Invalidate chat cache to refresh member list
      _chatCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember({
    required String chatId,
    required String uid,
  }) async {
    try {
      await _service.removeMember(chatId: chatId, uid: uid);
      // Invalidate chat cache to refresh member list
      _chatCacheTimestamps.remove(chatId);
      _scheduleNotify();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String uid) {
    return _service.getUserProfile(uid);
  }

  void clearUserCache() {
    _service.clearUserCache();
  }

  // ========================================
  // CACHE INVALIDATION METHODS
  // ========================================

  /// Invalidate cache for a specific chat
  void invalidateChatCache(String chatId) {
    _chatCache.remove(chatId);
    _chatCacheTimestamps.remove(chatId);
    _scheduleNotify();
  }

  /// Invalidate messages cache for a specific chat
  void invalidateMessagesCache(String chatId) {
    _messagesCache.remove(chatId);
    _messagesCacheTimestamps.remove(chatId);
    _messageStreamManagers[chatId]?.clear();
    _scheduleNotify();
  }

  /// Invalidate all chat caches
  void invalidateAllChatCache() {
    _chatCache.clear();
    _chatCacheTimestamps.clear();
    _messagesCache.clear();
    _messagesCacheTimestamps.clear();
    for (final manager in _messageStreamManagers.values) {
      manager.clear();
    }
    _messageStreamManagers.clear();
    _scheduleNotify();
  }

  /// Refresh a specific chat (invalidate and refetch)
  Future<void> refreshChat(String chatId) async {
    invalidateChatCache(chatId);
    // Stream will automatically refetch on next subscription
  }

  /// Refresh messages for a specific chat
  Future<void> refreshMessages(String chatId) async {
    invalidateMessagesCache(chatId);
    // Stream will automatically refetch on next subscription
  }

  // ========================================
  // INTERNAL HELPERS
  // ========================================

  /// Debounced notifyListeners to avoid excessive rebuilds
  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // Track disposal state for safe async operations
  bool _disposed = false;

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

  // ========================================
  // DISPOSE CLEANUP
  // ========================================

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();

    // Clear all stream request managers
    for (final manager in _messageStreamManagers.values) {
      manager.clear();
    }
    _messageStreamManagers.clear();

    // Clear all caches
    _chatCache.clear();
    _chatCacheTimestamps.clear();
    _messagesCache.clear();
    _messagesCacheTimestamps.clear();

    super.dispose();
  }
}
