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
import '/providers/block_provider.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import 'components/chat_details_actions.dart';
import 'components/chat_details_body.dart';
import 'components/chat_header_title.dart';
import 'components/chat_image_viewer.dart';
import 'controllers/chat_details_controller.dart';
import 'controllers/chat_details_side_effects.dart';
import 'controllers/chat_image_upload_controller.dart';
import 'controllers/chat_stream_controller.dart';
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

  // Pagination
  static const int _initialPageSize = 40;
  final List<ChatMessageViewModel> _latestMessageVMs = [];
  final ChatDetailsController<DocumentSnapshot> _detailsController =
      ChatDetailsController<DocumentSnapshot>();

  // UI state
  bool _showScrollToBottom = false;
  ChatMessage? _replyToMessage;
  bool _isLeavingChat = false;

  // Extracted controllers/helpers
  late ChatTypingHelper _typingHelper;
  late ChatImageUploadController _imageUploadController;
  late ChatStreamController _streamController;

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
    final profileProvider = context.read<ProfileProvider>();

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
    _streamController = ChatStreamController(
      chatId: widget.chatId,
      chatProvider: chatProvider,
      profileProvider: profileProvider,
      getCurrentUserId: () => _currentUserId,
      onStateChanged: () => updateState(this, () {}),
      isMounted: () => mounted,
      isLeavingChat: () => _isLeavingChat,
      initialPageSize: _initialPageSize,
      detailsController: _detailsController,
    );
    _streamController.initialize();

    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (kDebugMode) {
      AppLog.d('📨 UI: Disposing ChatDetails for chatId=${widget.chatId}');
    }
    _typingHelper.dispose();
    _streamController.dispose();
    _detailsController.reset();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _typingHelper.onTextChanged(_messageController.text);
  }

  String? _typingTextForChat(Chat chat) {
    return _typingHelper.getTypingText(chat, context.read<ProfileProvider>());
  }

  void _onScroll() {
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

    ChatDetailsSideEffects.showReactionPicker(
      context: context,
      outerContext: context,
      message: message,
      currentUserId: currentUserId,
      chatId: widget.chatId,
      onReactionToggled: _handleReaction,
    );
  }

  void _showImageFullscreen(String imageUrl) {
    showAppDialog(
      context: context,
      barrierColor: AppColors.dialogBarrier,
      builder: (BuildContext dialogContext) => ChatImageViewer(
        imageUrl: imageUrl,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _showReportUser() {
    final otherUid = ChatDetailsSideEffects.otherUserIdInDirectChat(
      _streamController.chatUi,
      _currentUserId,
    );
    if (otherUid == null || otherUid.isEmpty) return;
    ChatDetailsSideEffects.showReportUser(
      context: context,
      otherUid: otherUid,
      chatId: widget.chatId,
    );
  }

  Future<void> _handleBlockUser() async {
    final otherUid = ChatDetailsSideEffects.otherUserIdInDirectChat(
      _streamController.chatUi,
      _currentUserId,
    );
    if (otherUid == null || otherUid.isEmpty) return;
    final currentUid = _currentUserId;
    if (currentUid == null) return;

    if (!mounted) return;
    await ChatDetailsSideEffects.handleBlockUser(
      context: context,
      otherUid: otherUid,
      currentUid: currentUid,
      blockProvider: context.read<BlockProvider>(),
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
    final statusFuture = _detailsController.loadOlderMessagesFromProviders(
      startAfterCursor: _streamController.lastStreamDoc,
      chatProvider: chatProvider,
      profileProvider: profileProvider,
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
        'chatLoaded=${_streamController.chatLoaded} chatUi=${_streamController.chatUi?.id} '
        'chatError=${_streamController.chatError?.runtimeType} '
        'msgCtrl=${_messageController.hashCode} '
        'focus=${_messageFocusNode.hashCode} '
        'msgStream=${identityHashCode(_streamController.messagesStream ?? this)}',
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
            title: _streamController.chatUi != null
                ? ChatHeaderTitle(
                    chat: _streamController.chatUi!,
                    currentUserId: _currentUserId,
                  )
                : AppText.cardTitle('Chat'),
            centerTitle: false,
            actions: _streamController.chatUi == null
                ? const []
                : [
                    ChatDetailsActions(
                      onLeaveSelected: _showLeaveConfirmation,
                      isDirect: _streamController.chatUi?.type == 'direct',
                      onReportSelected: _showReportUser,
                      onBlockSelected: _handleBlockUser,
                    ),
                  ],
          ),
          body: FairwayBackgroundDark(
            child: ChatDetailsBody(
              chatId: widget.chatId,
              chatStream: _streamController.chatStream,
              chatError: _streamController.chatError,
              chatLoaded: _streamController.chatLoaded,
              chatUi: _streamController.chatUi,
              bannerText: _streamController.bannerText,
              isArchived: _streamController.isArchived,
              currentUserId: _currentUserId,
              scrollController: _scrollController,
              messageController: _messageController,
              messageFocusNode: _messageFocusNode,
              messageViewModelsStream:
                  _streamController.messageViewModelsStream,
              cachedLatestMessageVMs: _latestMessageVMs,
              detailsController: _detailsController,
              pendingUploads: _imageUploadController.pendingUploads,
              canSend: _streamController.canSend,
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
                  (_streamController.canSend && _streamController.chatUi != null)
                      ? _showImageSourceSheet
                      : null,
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
