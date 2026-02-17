import 'dart:async';
import 'package:flutter/foundation.dart';

import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/providers/profile_provider.dart';
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

  // StreamRequestManager for chat list streams (by user ID)
  final Map<String, StreamRequestManager<List<Chat>>> _chatListStreamManagers = {};

  // Query result cache for chat lists (by query key)
  final Map<String, List<Chat>> _chatListCache = {};

  // Cache timestamps for TTL tracking
  final Map<String, DateTime> _chatCacheTimestamps = {};
  final Map<String, DateTime> _messagesCacheTimestamps = {};
  final Map<String, DateTime> _chatListCacheTimestamps = {};

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

  /// Check if chat list cache is valid (within TTL)
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

    // Get or create StreamRequestManager for this query
    if (!_chatListStreamManagers.containsKey(queryKey)) {
      _chatListStreamManagers[queryKey] = StreamRequestManager<List<Chat>>(5);
    }

    return _chatListStreamManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      requestFn: () => _service.getChatListStream(uid: uid, limit: limit),
    ).map((chats) {
      // Cache query results when they come through the stream
      _chatListCache[queryKey] = chats;
      _chatListCacheTimestamps[queryKey] = DateTime.now();
      return chats;
    });
  }

  /// Get cached chat list if available (no fetch)
  List<Chat>? getCachedChatList(String uid, {int limit = 50}) {
    final queryKey = 'chat_list_${uid}_$limit';

    // Check query result cache first
    if (isChatListCacheValid(queryKey)) {
      return _chatListCache[queryKey];
    }

    // Fall back to BehaviorSubject cache
    return _chatListStreamManagers[queryKey]?.getLastValue(queryKey);
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
    DateTime? visibleAfter,
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
        visibleAfter: visibleAfter,
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
      // Invalidate chat and messages caches: the new memberJoinedAt timestamp
      // changes the visibility window, so any cached messages are stale.
      _chatCacheTimestamps.remove(chatId);
      _messagesCache.remove(chatId);
      _messagesCacheTimestamps.remove(chatId);
      _messageStreamManagers[chatId]?.clear();
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

  /// Mark multiple unread messages as read in a single batched operation
  ///
  /// This is a performance-optimized alternative to calling markMessageAsRead
  /// in a loop. Returns diagnostic info about the operation.
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

  // ========================================
  // DISPOSE CLEANUP
  // ========================================

  // ========================================
  // VIEW MODEL STREAM (AUDIT #5 FIX)
  // ========================================

  /// Stream of chat message view models with resolved profiles
  ///
  /// This method combines message stream with profile resolution in a single stream,
  /// avoiding nested StreamBuilder/FutureBuilder patterns and repeated profile fetches.
  ///
  /// Uses ProfileProvider's memoized cache to avoid re-fetching profiles on every rebuild.
  Stream<List<ChatMessageViewModel>> gameChatMessageViewModelsStream({
    required String chatId,
    required int limit,
    required ProfileProvider profileProvider,
    DateTime? visibleAfter,
  }) {
    if (kDebugMode) {
      debugPrint('🔵 ChatProvider: Creating VM stream for chatId=$chatId (should happen once per screen)');
    }

    return messagesSnapshotStream(chatId: chatId, limit: limit, visibleAfter: visibleAfter)
        .asyncMap((snapshot) async {
      final docs = snapshot.docs;

      if (docs.isEmpty) {
        return <ChatMessageViewModel>[];
      }

      // Convert docs to ChatMessage objects
      final messages = docs.map(ChatMessage.fromDoc).toList();

      // Derive unique sender IDs
      final senderIds = messages
          .map((msg) => msg.senderId)
          .toSet()
          .toList();

      if (kDebugMode) {
        debugPrint('🔵 ChatProvider: VM stream emit - ${messages.length} messages, ${senderIds.length} unique senders');
      }

      // Fetch profiles using ProfileProvider's memoized cache
      // This will only trigger network fetches for new sender IDs not already cached
      Map<String, UsersRecord> profileMap = {};
      if (senderIds.isNotEmpty) {
        try {
          profileMap = await profileProvider.batchGetProfiles(senderIds);

          // Log which profiles were fetched vs cached
          if (kDebugMode) {
            final newSenderIds = senderIds
                .where((id) => !profileProvider.isProfileCacheValid(id))
                .toList();
            if (newSenderIds.isNotEmpty) {
              debugPrint('🆕 ChatProvider: Profile fetch triggered for new senderIds: $newSenderIds');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ ChatProvider: Failed to fetch profiles: $e');
          }
          // Continue with empty profile map on error
        }
      }

      // Create view models
      return messages.map((msg) {
        final profile = profileMap[msg.senderId];
        return ChatMessageViewModel(
          message: msg,
          senderDisplayName: profile?.displayName ?? '',
          senderPhotoUrl: profile?.photoUrl ?? '',
        );
      }).toList();
    });
  }

  // ========================================
  // CHAT LIST VIEW MODEL STREAM (AUDIT #6 FIX)
  // ========================================

  /// Stream of chat row view models with resolved profiles
  ///
  /// This method combines chat list stream with profile resolution in a single stream,
  /// avoiding nested StreamBuilder/FutureBuilder patterns and repeated profile fetches.
  ///
  /// Uses ProfileProvider's memoized cache to avoid re-fetching profiles on every rebuild.
  Stream<List<ChatRowViewModel>> chatRowsStream({
    required String currentUserId,
    required ProfileProvider profileProvider,
    int limit = 50,
  }) {
    if (kDebugMode) {
      debugPrint('💬 ChatProvider: Creating chat rows VM stream for userId=$currentUserId (should happen once per screen)');
    }

    return chatListStream(uid: currentUserId, limit: limit)
        .asyncMap((chats) async {
      if (chats.isEmpty) {
        return <ChatRowViewModel>[];
      }

      // Collect direct chat user IDs (exclude game chats)
      final directUserIds = <String>{};
      for (final chat in chats) {
        if (chat.type == 'game') continue;
        final otherUserId = chat.memberIds.firstWhere(
          (id) => id != currentUserId,
          orElse: () => currentUserId,
        );
        if (otherUserId.isNotEmpty) {
          directUserIds.add(otherUserId);
        }
      }

      if (kDebugMode) {
        debugPrint('💬 ChatProvider: Chat rows VM emit - ${chats.length} chats, ${directUserIds.length} direct chat profiles needed');
      }

      // Fetch profiles using ProfileProvider's memoized cache
      // This will only trigger network fetches for new user IDs not already cached
      Map<String, UsersRecord> profileMap = {};
      if (directUserIds.isNotEmpty) {
        try {
          profileMap = await profileProvider.batchGetProfiles(directUserIds.toList());

          // Log which profiles were fetched vs cached
          if (kDebugMode) {
            final newUserIds = directUserIds
                .where((id) => !profileProvider.isProfileCacheValid(id))
                .toList();
            if (newUserIds.isNotEmpty) {
              debugPrint('🆕 ChatProvider: Profile fetch triggered for new userIds: $newUserIds');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ ChatProvider: Failed to fetch profiles: $e');
          }
          // Continue with empty profile map on error
        }
      }

      // Create view models
      return chats.map((chat) {
        final unreadCount = chat.unreadCountByUser[currentUserId] ?? 0;

        String displayName;
        String photoUrl = '';

        if (chat.type == 'game') {
          displayName = (chat.gameName ?? '').trim().isNotEmpty
              ? chat.gameName!
              : 'Game Chat';
        } else {
          final otherUserId = chat.memberIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => currentUserId,
          );
          final profile = profileMap[otherUserId];
          displayName = (profile?.displayName ?? '').trim().isNotEmpty
              ? profile!.displayName
              : 'Golfer';
          photoUrl = profile?.photoUrl ?? '';
        }

        return ChatRowViewModel(
          chatId: chat.id,
          displayName: displayName,
          photoUrl: photoUrl,
          lastMessage: chat.lastMessage,
          lastMessageAt: chat.lastMessageAt,
          unreadCount: unreadCount,
        );
      }).toList();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();

    // Clear all stream request managers
    for (final manager in _messageStreamManagers.values) {
      manager.clear();
    }
    _messageStreamManagers.clear();

    for (final manager in _chatListStreamManagers.values) {
      manager.clear();
    }
    _chatListStreamManagers.clear();

    // Clear all caches
    _chatCache.clear();
    _chatCacheTimestamps.clear();
    _messagesCache.clear();
    _messagesCacheTimestamps.clear();
    _chatListCache.clear();
    _chatListCacheTimestamps.clear();

    super.dispose();
  }
}

// ========================================
// VIEW MODEL (AUDIT #5 FIX)
// ========================================

/// View model for chat messages with resolved profile data
///
/// This class combines ChatMessage with resolved user profile data,
/// avoiding the need for nested builders in the UI.
class ChatMessageViewModel {
  ChatMessageViewModel({
    required this.message,
    required this.senderDisplayName,
    required this.senderPhotoUrl,
  });

  final ChatMessage message;
  final String senderDisplayName;
  final String senderPhotoUrl;

  // Convenience getters for common message fields
  String get id => message.id;
  String get senderId => message.senderId;
  String get text => message.text;
  String get imageUrl => message.imageUrl;
  String get videoUrl => message.videoUrl;
  DateTime? get createdAt => message.createdAt;
  Map<String, List<String>> get reactions => message.reactions;
  List<String> get readBy => message.readBy;
}

// ========================================
// CHAT ROW VIEW MODEL (AUDIT #6 FIX)
// ========================================

/// View model for chat list rows with resolved profile data
///
/// This class combines Chat with resolved user profile data,
/// avoiding the need for nested builders in the UI and moving
/// profile fetching out of the build method.
class ChatRowViewModel {
  ChatRowViewModel({
    required this.chatId,
    required this.displayName,
    required this.photoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String chatId;
  final String displayName;
  final String photoUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}
