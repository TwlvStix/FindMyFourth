import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/models/chat.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import 'chat_details_controller.dart';
import 'chat_details_side_effects.dart';

/// Manages all chat and message stream lifecycle for GameChatDetailsWidget.
///
/// Follows the ChatImageUploadController callback pattern: constructor-injected
/// deps, `onStateChanged` callback, `isMounted` check.
class ChatStreamController {
  ChatStreamController({
    required this.chatId,
    required this.chatProvider,
    required this.profileProvider,
    required this.getCurrentUserId,
    required this.onStateChanged,
    required this.isMounted,
    required this.isLeavingChat,
    required this.initialPageSize,
    required this.detailsController,
  });

  final String chatId;
  final ChatProvider chatProvider;
  final ProfileProvider profileProvider;
  final String? Function() getCurrentUserId;
  final VoidCallback onStateChanged;
  final bool Function() isMounted;
  final bool Function() isLeavingChat;
  final int initialPageSize;
  final ChatDetailsController<DocumentSnapshot> detailsController;

  // Stream state
  late Stream<Chat?> _chatStream;
  late Stream<Chat?> _chatUiStream;
  Stream<QuerySnapshot>? _messagesStream;
  Stream<List<ChatMessageViewModel>>? _messageViewModelsStream;
  StreamSubscription<Chat?>? _chatUiSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSnapshotSubscription;
  DateTime? _visibleAfter;
  bool _streamsInitialized = false;
  DocumentSnapshot? _lastStreamDoc;

  // Chat document state
  Chat? _chatUi;
  bool _chatLoaded = false;
  Object? _chatError;

  // Derived UI state
  bool _canSend = false;
  bool _isArchived = false;
  String _bannerText = '';

  // One-shot guards
  bool _didMarkSeen = false;
  bool _hasRetriedPermission = false;

  // Public getters
  Stream<Chat?> get chatStream => _chatStream;
  Chat? get chatUi => _chatUi;
  bool get chatLoaded => _chatLoaded;
  Object? get chatError => _chatError;
  bool get canSend => _canSend;
  bool get isArchived => _isArchived;
  String get bannerText => _bannerText;
  Stream<List<ChatMessageViewModel>>? get messageViewModelsStream =>
      _messageViewModelsStream;
  DocumentSnapshot? get lastStreamDoc => _lastStreamDoc;
  DateTime? get visibleAfter => _visibleAfter;
  Stream<QuerySnapshot>? get messagesStream => _messagesStream;

  /// Initializes streams and starts listening to the chat document.
  void initialize() {
    _chatStream = chatProvider.chatStream(chatId);
    _chatUiStream = _chatStream.distinct(_chatUiEquals);
    _chatUiSubscription = _chatUiStream.listen(
      (chat) {
        if (!isMounted()) return;
        _updateChatUiState(chat);
      },
      onError: (error) {
        if (!isMounted()) return;

        if (isLeavingChat()) {
          AppLog.d('📱 UI: Ignoring chat stream error during leave operation');
          return;
        }

        if (!_hasRetriedPermission && _isPermissionDenied(error)) {
          _hasRetriedPermission = true;
          AppLog.d('📱 UI: Permission denied on chat stream, retrying in 2s');
          Future.delayed(const Duration(seconds: 2), () {
            if (!isMounted()) return;
            _restartChatStream();
          });
          return;
        }

        if (kDebugMode) {
          AppLog.d(
              '❌ UI: Chat stream error for chatId=$chatId: $error');
        }
        _chatError = error;
        _chatLoaded = true;
        _chatUi = null;
        _canSend = false;
        _bannerText = '';
        _isArchived = false;
        onStateChanged();
      },
    );
  }

  void dispose() {
    _chatUiSubscription?.cancel();
    _messagesSnapshotSubscription?.cancel();
  }

  bool _isPermissionDenied(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    return error.toString().contains('permission-denied');
  }

  void _restartChatStream() {
    _chatUiSubscription?.cancel();
    chatProvider.invalidateChatCache(chatId);
    _chatStream = chatProvider.chatStream(chatId);
    _chatUiStream = _chatStream.distinct(_chatUiEquals);
    _chatUiSubscription = _chatUiStream.listen(
      (chat) {
        if (!isMounted()) return;
        _updateChatUiState(chat);
      },
      onError: (error) {
        if (!isMounted()) return;
        if (isLeavingChat()) return;
        if (kDebugMode) {
          AppLog.d(
              '❌ UI: Chat stream error for chatId=$chatId: $error');
        }
        _chatError = error;
        _chatLoaded = true;
        _chatUi = null;
        _canSend = false;
        _bannerText = '';
        _isArchived = false;
        onStateChanged();
      },
    );
  }

  bool _chatUiEquals(Chat? previous, Chat? next) {
    if (identical(previous, next)) {
      return true;
    }
    if (previous == null || next == null) {
      return previous == next;
    }
    return previous.id == next.id &&
        previous.type == next.type &&
        previous.gameName == next.gameName &&
        listEquals(previous.memberIds, next.memberIds) &&
        previous.isReadOnly == next.isReadOnly &&
        previous.pinnedMessage == next.pinnedMessage &&
        previous.deletesAt == next.deletesAt;
  }

  void _updateChatUiState(Chat? chat) {
    if (chat == null) {
      _resetChatState();
      return;
    }

    _initializeMessageStreamsIfNeeded(chat);
    _applyChatUiState(chat);
    _markSeenIfNeeded(chat);
  }

  void _resetChatState() {
    _messagesSnapshotSubscription?.cancel();
    _messagesSnapshotSubscription = null;
    detailsController.reset();
    _lastStreamDoc = null;
    _streamsInitialized = false;
    _chatLoaded = true;
    _chatError = null;
    _chatUi = null;
    _canSend = false;
    _bannerText = '';
    _isArchived = false;
    onStateChanged();
  }

  void _initializeMessageStreamsIfNeeded(Chat chat) {
    if (_streamsInitialized) return;

    _streamsInitialized = true;
    final currentUserId = getCurrentUserId();
    _visibleAfter =
        currentUserId != null ? chat.memberJoinedAt[currentUserId] : null;

    detailsController.initializeSession(
      chatId: chatId,
      pageSize: 30,
      visibleAfterCutoff: _visibleAfter,
    );

    _messagesStream = chatProvider.messagesSnapshotStream(
      chatId: chatId,
      limit: initialPageSize,
      visibleAfter: _visibleAfter,
    );
    _messagesSnapshotSubscription?.cancel();
    _messagesSnapshotSubscription = _messagesStream!.listen(
      (snapshot) {
        _lastStreamDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      },
    );
    _messageViewModelsStream = chatProvider.gameChatMessageViewModelsStream(
      chatId: chatId,
      limit: initialPageSize,
      profileProvider: profileProvider,
      visibleAfter: _visibleAfter,
    );
  }

  void _applyChatUiState(Chat chat) {
    final isArchived = chat.isReadOnly;
    final bannerText = chat.pinnedMessage.isNotEmpty
        ? chat.pinnedMessage
        : chat.isReadOnly
            ? 'This chat is read-only.'
            : '';
    final canSend = !chat.isReadOnly;

    _chatLoaded = true;
    _chatError = null;
    _chatUi = chat;
    _isArchived = isArchived;
    _bannerText = bannerText;
    _canSend = canSend;
    onStateChanged();
  }

  void _markSeenIfNeeded(Chat chat) {
    final currentUserId = getCurrentUserId();
    if (!_didMarkSeen &&
        currentUserId != null &&
        chat.memberIds.contains(currentUserId)) {
      _didMarkSeen = true;
      _markChatSeen();
    }
  }

  Future<void> _markChatSeen() async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;
    await ChatDetailsSideEffects.markChatSeen(
      chatProvider: chatProvider,
      chatId: chatId,
      uid: currentUserId,
      visibleAfter: _visibleAfter,
      isMounted: isMounted,
    );
  }
}
