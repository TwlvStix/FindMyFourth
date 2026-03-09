import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/motion/motion_helpers.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import 'components/chat_details_actions.dart';
import 'components/chat_details_body.dart';
import 'components/chat_header_title.dart';
import 'components/chat_image_viewer.dart';
import 'components/chat_reaction_picker.dart';
import 'controllers/chat_details_controller.dart';
import 'controllers/chat_details_side_effects.dart';
import 'controllers/chat_image_upload_controller.dart';
import 'helpers/chat_typing_helper.dart';

class GameChatDetailsWidget extends StatefulWidget {
  const GameChatDetailsWidget({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  State<GameChatDetailsWidget> createState() => _GameChatDetailsWidgetState();
}

class _GameChatDetailsWidgetState extends State<GameChatDetailsWidget>
    with TickerProviderStateMixin {
  // Input controllers
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Stream state
  late Stream<Chat?> _chatStream;
  late Stream<Chat?> _chatUiStream;
  Stream<QuerySnapshot>? _messagesStream;
  Stream<List<ChatMessageViewModel>>? _messageViewModelsStream;
  StreamSubscription<Chat?>? _chatUiSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSnapshotSubscription;
  DateTime? _visibleAfter;
  bool _streamsInitialized = false;

  // Pagination
  static const int _initialPageSize = 40;
  static const int _pageSize = 30;
  final List<ChatMessageViewModel> _latestMessageVMs = [];
  DocumentSnapshot? _lastStreamDoc;
  final ChatDetailsController<DocumentSnapshot> _detailsController =
      ChatDetailsController<DocumentSnapshot>();

  // UI state
  bool _showScrollToBottom = false;
  ChatMessage? _replyToMessage;
  Chat? _chatUi;
  bool _chatLoaded = false;
  Object? _chatError;
  bool _canSend = false;
  bool _isArchived = false;
  String _bannerText = '';
  bool _didMarkSeen = false;
  bool _isLeavingChat = false;
  bool _hasRetriedPermission = false;

  // Extracted controllers/helpers
  late ChatTypingHelper _typingHelper;
  late ChatImageUploadController _imageUploadController;

  String? get _currentUserId {
    final uid = currentUserUid;
    return uid.isEmpty ? null : uid;
  }

  @override
  void initState() {
    super.initState();
    AppLog.d('📨 UI: Chat page loaded for chatId: ${widget.chatId}');
    AppLog.d('📨 UI: Current user ID: $_currentUserId');

    final chatProvider = context.read<ChatProvider>();

    // Initialize extracted helpers
    _typingHelper = ChatTypingHelper(
      chatId: widget.chatId,
      chatProvider: chatProvider,
      getCurrentUserId: () => _currentUserId,
    );
    _imageUploadController = ChatImageUploadController(
      chatId: widget.chatId,
      chatProvider: chatProvider,
      onStateChanged: () => updateState(this, () {}),
      isMounted: () => mounted,
      getCurrentUserId: () => _currentUserId,
    );

    _chatStream = chatProvider.chatStream(widget.chatId);
    _chatUiStream = _chatStream.distinct(_chatUiEquals);
    // Message streams are initialized lazily in _updateChatUiState on the first
    // chat event, so that we can read memberJoinedAt[uid] for fresh-start filtering.
    _chatUiSubscription = _chatUiStream.listen(
      (chat) {
        if (!mounted) return;
        _updateChatUiState(chat);
      },
      onError: (error) {
        if (!mounted) return;

        // Suppress errors during intentional leave operation
        if (_isLeavingChat) {
          AppLog.d('📱 UI: Ignoring chat stream error during leave operation');
          return;
        }

        // Retry once on permission-denied — handles race condition where
        // syncGameChatMembers Cloud Function hasn't completed yet.
        if (!_hasRetriedPermission && _isPermissionDenied(error)) {
          _hasRetriedPermission = true;
          AppLog.d(
              '📱 UI: Permission denied on chat stream, retrying in 2s');
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            _restartChatStream();
          });
          return;
        }

        if (kDebugMode) {
          AppLog.d(
              '❌ UI: Chat stream error for chatId=${widget.chatId}: $error');
        }
        updateState(this, () {
          _chatError = error;
          _chatLoaded = true;
          _chatUi = null;
          _canSend = false;
          _bannerText = '';
          _isArchived = false;
        });
      },
    );
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (kDebugMode) {
      AppLog.d('📨 UI: Disposing ChatDetails for chatId=${widget.chatId}');
    }
    _typingHelper.dispose();
    _chatUiSubscription?.cancel();
    _messagesSnapshotSubscription?.cancel();
    _detailsController.reset();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isPermissionDenied(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    return error.toString().contains('permission-denied');
  }

  void _restartChatStream() {
    _chatUiSubscription?.cancel();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.invalidateChatCache(widget.chatId);
    _chatStream = chatProvider.chatStream(widget.chatId);
    _chatUiStream = _chatStream.distinct(_chatUiEquals);
    _chatUiSubscription = _chatUiStream.listen(
      (chat) {
        if (!mounted) return;
        _updateChatUiState(chat);
      },
      onError: (error) {
        if (!mounted) return;
        if (_isLeavingChat) return;
        if (kDebugMode) {
          AppLog.d(
              '❌ UI: Chat stream error for chatId=${widget.chatId}: $error');
        }
        updateState(this, () {
          _chatError = error;
          _chatLoaded = true;
          _chatUi = null;
          _canSend = false;
          _bannerText = '';
          _isArchived = false;
        });
      },
    );
  }

  void _onTextChanged() {
    _typingHelper.onTextChanged(_messageController.text);
  }

  String? _typingTextForChat(Chat chat) {
    return _typingHelper.getTypingText(chat, context.read<ProfileProvider>());
  }

  void _showImageFullscreen(String imageUrl) {
    showAppDialog(
      context: context,
      barrierColor: Colors.black87, // Keep: no 87% token
      builder: (BuildContext dialogContext) => ChatImageViewer(
        imageUrl: imageUrl,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _handleReaction(
      ChatMessage message, String emoji, bool hasReacted) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    if (hasReacted) {
      await context.read<ChatProvider>().removeReaction(
            chatId: widget.chatId,
            messageId: message.id,
            emoji: emoji,
            uid: currentUserId,
          );
    } else {
      await context.read<ChatProvider>().addReaction(
            chatId: widget.chatId,
            messageId: message.id,
            emoji: emoji,
            uid: currentUserId,
          );
    }
  }

  void _showReactionPicker(ChatMessage message) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    showAppBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) => ChatReactionPicker(
        message: message,
        currentUserId: currentUserId,
        onReactionToggled: (emoji, hasReacted) =>
            _handleReaction(message, emoji, hasReacted),
      ),
    );
  }

  void _onScroll() {
    // Show FAB when scrolled up more than 200 pixels from bottom
    final showFab =
        _scrollController.hasClients && _scrollController.offset > 200;
    if (showFab != _showScrollToBottom) {
      updateState(this, () {
        _showScrollToBottom = showFab;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

  /// Resets all chat state when chat becomes null.
  void _resetChatState() {
    _messagesSnapshotSubscription?.cancel();
    _messagesSnapshotSubscription = null;
    _detailsController.reset();
    _lastStreamDoc = null;
    _streamsInitialized = false;
    updateState(this, () {
      _chatLoaded = true;
      _chatError = null;
      _chatUi = null;
      _canSend = false;
      _bannerText = '';
      _isArchived = false;
    });
  }

  /// Initializes message streams on the first valid chat event.
  /// Uses memberJoinedAt visibility cutoff for fresh-start-on-rejoin.
  void _initializeMessageStreamsIfNeeded(Chat chat) {
    if (_streamsInitialized) return;

    _streamsInitialized = true;
    final currentUserId = _currentUserId;
    _visibleAfter =
        currentUserId != null ? chat.memberJoinedAt[currentUserId] : null;

    _detailsController.initializeSession(
      chatId: widget.chatId,
      pageSize: _pageSize,
      visibleAfterCutoff: _visibleAfter,
    );

    final chatProvider = context.read<ChatProvider>();
    final profileProvider = context.read<ProfileProvider>();

    _messagesStream = chatProvider.messagesSnapshotStream(
      chatId: widget.chatId,
      limit: _initialPageSize,
      visibleAfter: _visibleAfter,
    );
    _messagesSnapshotSubscription?.cancel();
    _messagesSnapshotSubscription = _messagesStream!.listen(
      (snapshot) {
        _lastStreamDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      },
    );
    _messageViewModelsStream = chatProvider.gameChatMessageViewModelsStream(
      chatId: widget.chatId,
      limit: _initialPageSize,
      profileProvider: profileProvider,
      visibleAfter: _visibleAfter,
    );
  }

  /// Derives UI state from chat and updates widget state.
  void _applyChatUiState(Chat chat) {
    final isArchived = chat.isReadOnly;
    final bannerText = chat.pinnedMessage.isNotEmpty
        ? chat.pinnedMessage
        : chat.isReadOnly
            ? 'This chat is read-only.'
            : '';
    final canSend = !chat.isReadOnly;

    updateState(this, () {
      _chatLoaded = true;
      _chatError = null;
      _chatUi = chat;
      _isArchived = isArchived;
      _bannerText = bannerText;
      _canSend = canSend;
    });
  }

  /// Marks chat as seen once when user is a member.
  void _markSeenIfNeeded(Chat chat) {
    final currentUserId = _currentUserId;
    if (!_didMarkSeen &&
        currentUserId != null &&
        chat.memberIds.contains(currentUserId)) {
      _didMarkSeen = true;
      _markChatSeen();
    }
  }

  Future<void> _markChatSeen() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;
    await ChatDetailsSideEffects.markChatSeen(
      chatProvider: context.read<ChatProvider>(),
      chatId: widget.chatId,
      uid: currentUserId,
      visibleAfter: _visibleAfter,
      isMounted: () => mounted,
    );
  }

  Future<void> _showLeaveConfirmation() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || !mounted) return;
    await ChatDetailsSideEffects.showLeaveConfirmation(
      context: context,
      chatId: widget.chatId,
      uid: currentUserId,
      chatProvider: context.read<ChatProvider>(),
      onLeaveStarted: () => _isLeavingChat = true,
      onLeaveFailed: () => _isLeavingChat = false,
    );
  }

  void _showImageSourceSheet() {
    _imageUploadController.showImageSourceSheet(context);
  }

  Future<void> _sendMessage() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _messageController.clear();
    final replyTo = _replyToMessage;
    updateState(this, () {
      _replyToMessage = null;
    });
    try {
      await context.read<ChatProvider>().sendMessage(
            chatId: widget.chatId,
            senderId: currentUserId,
            text: text,
          );
      // TODO: In a full implementation, we would store the replyTo message ID
      // in the message document and display it in the message bubble
    } catch (error, stackTrace) {
      if (!mounted) return;
      context
          .read<ChatProvider>()
          .logError('sendMessage failed', error, stackTrace);
      if (!mounted) {
        return;
      }
      _messageController.text = text;
      updateState(this, () {
        _replyToMessage = replyTo;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _sendMessage,
          ),
        ),
      );
    }
  }

  Future<void> _loadOlderMessages() async {
    final chatProvider = context.read<ChatProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final statusFuture = _detailsController.loadOlderMessages(
      startAfterCursor: _lastStreamDoc,
      fetchPage: ({
        required String chatId,
        required int pageSize,
        required DateTime? visibleAfter,
        required DocumentSnapshot? startAfter,
      }) async {
        final page = await chatProvider.messagesPage(
          chatId: chatId,
          limit: pageSize,
          startAfter: startAfter,
          visibleAfter: visibleAfter,
        );
        final pageVMs = page.messages.map((message) {
          final profile = profileProvider.getCachedProfile(message.senderId);
          return ChatMessageViewModel(
            message: message,
            senderDisplayName: profile?.displayName ?? '',
            senderPhotoUrl: profile?.photoUrl ?? '',
          );
        }).toList();
        return OlderPageData<DocumentSnapshot>(
          messages: pageVMs,
          hasMore: page.messages.length >= pageSize,
          lastCursor: page.lastDoc,
        );
      },
    );
    if (!mounted) return;
    updateState(this, () {});

    final status = await statusFuture;
    if (!mounted) return;

    if (status.isError) {
      chatProvider.logError(
        'loadOlderMessages failed',
        status.error ?? Exception(status.errorMessage ?? 'Unknown error'),
        status.stackTrace ?? StackTrace.current,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load older messages.'),
        ),
      );
    }

    if (mounted) {
      updateState(this, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGreen = AppColors.navy;
    if (kDebugMode) {
      AppLog.d(
        '🧱 UI: ChatDetails build chatId=${widget.chatId} '
        'chatLoaded=$_chatLoaded chatUi=${_chatUi?.id} '
        'chatError=${_chatError?.runtimeType} '
        'msgCtrl=${_messageController.hashCode} '
        'focus=${_messageFocusNode.hashCode} '
        'msgStream=${identityHashCode(_messagesStream ?? this)}',
      );
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: backgroundGreen,
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            surfaceTintColor: AppColors.transparent,
            scrolledUnderElevation: 0,
            foregroundColor: AppColors.pure,
            elevation: 0.0,
            shadowColor: AppColors.transparent,
            leading: PremiumBackButton(
              onTap: () => Navigator.of(context).maybePop(),
            ),
            title: _chatUi != null
                ? ChatHeaderTitle(
                    chat: _chatUi!,
                    currentUserId: _currentUserId,
                  )
                : AppText.cardTitle('Chat'),
            centerTitle: false,
            actions: _chatUi == null
                ? const []
                : [
                    ChatDetailsActions(
                      onLeaveSelected: _showLeaveConfirmation,
                    ),
                  ],
          ),
          body: FairwayBackgroundDark(
            child: ChatDetailsBody(
              chatId: widget.chatId,
              chatStream: _chatStream,
              chatError: _chatError,
              chatLoaded: _chatLoaded,
              chatUi: _chatUi,
              bannerText: _bannerText,
              isArchived: _isArchived,
              currentUserId: _currentUserId,
              scrollController: _scrollController,
              messageController: _messageController,
              messageFocusNode: _messageFocusNode,
              messageViewModelsStream: _messageViewModelsStream,
              cachedLatestMessageVMs: _latestMessageVMs,
              detailsController: _detailsController,
              pendingUploads: _imageUploadController.pendingUploads,
              canSend: _canSend,
              replyToMessage: _replyToMessage,
              showScrollToBottom: _showScrollToBottom,
              onLoadOlderMessages: _loadOlderMessages,
              onMessageLongPress: _showReactionPicker,
              onReplySwipe: (message) {
                updateState(this, () {
                  _replyToMessage = message;
                });
                _messageFocusNode.requestFocus();
              },
              onImageTap: _showImageFullscreen,
              onReactionTap: _handleReaction,
              onSendMessage: _sendMessage,
              onCancelReply: () {
                updateState(this, () {
                  _replyToMessage = null;
                });
              },
              onAttachImage:
                  (_canSend && _chatUi != null) ? _showImageSourceSheet : null,
              onScrollToBottom: _scrollToBottom,
              typingTextForChat: _typingTextForChat,
              onCacheLatestMessageVMs: (latestVMs) {
                _latestMessageVMs
                  ..clear()
                  ..addAll(latestVMs);
              },
            ),
          ),
        ),
      ),
    );
  }
}
