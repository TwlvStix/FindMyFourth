import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/chat_message_view_model.dart';
import '/providers/chat_provider.dart';
import '/providers/profile_provider.dart';
import 'components/chat_details_actions.dart';
import 'components/chat_details_body.dart';
import 'components/chat_header_title.dart';
import 'controllers/chat_details_controller.dart';
import 'controllers/chat_image_upload_controller.dart';
import 'controllers/chat_message_actions_controller.dart';
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

  // Extracted controllers/helpers
  late ChatTypingHelper _typingHelper;
  late ChatImageUploadController _imageUploadController;
  late ChatMessageActionsController _messageActionsController;
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
    _messageActionsController = ChatMessageActionsController(
      chatId: widget.chatId,
      getCurrentUserId: () => _currentUserId,
      onStateChanged: () => updateState(this, () {}),
      isMounted: () => mounted,
      getChatUi: () => _streamController.chatUi,
      getLastStreamDoc: () => _streamController.lastStreamDoc,
      detailsController: _detailsController,
    );
    _streamController = ChatStreamController(
      chatId: widget.chatId,
      chatProvider: chatProvider,
      profileProvider: profileProvider,
      getCurrentUserId: () => _currentUserId,
      onStateChanged: () => updateState(this, () {}),
      isMounted: () => mounted,
      isLeavingChat: () => _messageActionsController.isLeavingChat,
      initialPageSize: _initialPageSize,
      detailsController: _detailsController,
    );
    _streamController.initialize();

    _messageController.addListener(() =>
        _typingHelper.onTextChanged(_messageController.text));
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
                      onLeaveSelected: () =>
                          _messageActionsController.showLeaveConfirmation(context),
                      isDirect: _streamController.chatUi?.type == 'direct',
                      onReportSelected: () =>
                          _messageActionsController.showReportUser(context),
                      onBlockSelected: () =>
                          _messageActionsController.handleBlockUser(context),
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
              replyToMessage: _messageActionsController.replyToMessage,
              showScrollToBottom: _showScrollToBottom,
              onLoadOlderMessages: () =>
                  _messageActionsController.loadOlderMessages(context),
              onMessageLongPress: (msg) =>
                  _messageActionsController.showReactionPicker(context, msg),
              onReplySwipe: (message) {
                _messageActionsController.setReplyTo(message);
                _messageFocusNode.requestFocus();
              },
              onImageTap: (url) =>
                  _messageActionsController.showImageFullscreen(context, url),
              onReactionTap: (msg, emoji, hasReacted) =>
                  _messageActionsController.handleReaction(
                      context, msg, emoji, hasReacted),
              onSendMessage: () => _messageActionsController.sendMessage(
                  context, _messageController),
              onCancelReply: _messageActionsController.clearReply,
              onAttachImage:
                  (_streamController.canSend && _streamController.chatUi != null)
                      ? () => _imageUploadController.showImageSourceSheet(context)
                      : null,
              onScrollToBottom: _scrollToBottom,
              typingTextForChat: (chat) => _typingHelper.getTypingText(
                  chat, context.read<ProfileProvider>()),
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
