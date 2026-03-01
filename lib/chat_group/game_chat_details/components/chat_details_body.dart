import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_text.dart';
import '/models/chat.dart';
import '/models/chat_message.dart';
import '/models/chat_message_view_model.dart';
import '/providers/profile_provider.dart';
import 'chat_info_banner.dart';
import 'chat_input_bar.dart';
import 'chat_message_list.dart';
import 'chat_pending_upload_bubble.dart';
import 'chat_pending_upload_stack.dart';
import 'chat_scroll_fab.dart';
import 'chat_typing_indicator.dart';
import '../controllers/chat_details_controller.dart';

class ChatDetailsBody extends StatelessWidget {
  const ChatDetailsBody({
    super.key,
    required this.chatId,
    required this.chatStream,
    required this.chatError,
    required this.chatLoaded,
    required this.chatUi,
    required this.bannerText,
    required this.isArchived,
    required this.currentUserId,
    required this.scrollController,
    required this.messageController,
    required this.messageFocusNode,
    required this.messageViewModelsStream,
    required this.cachedLatestMessageVMs,
    required this.detailsController,
    required this.pendingUploads,
    required this.canSend,
    required this.replyToMessage,
    required this.showScrollToBottom,
    required this.onLoadOlderMessages,
    required this.onMessageLongPress,
    required this.onReplySwipe,
    required this.onImageTap,
    required this.onReactionTap,
    required this.onSendMessage,
    required this.onCancelReply,
    required this.onAttachImage,
    required this.onScrollToBottom,
    required this.typingTextForChat,
    required this.onCacheLatestMessageVMs,
  });

  final String chatId;
  final Stream<Chat?> chatStream;
  final Object? chatError;
  final bool chatLoaded;
  final Chat? chatUi;
  final String bannerText;
  final bool isArchived;
  final String? currentUserId;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final Stream<List<ChatMessageViewModel>>? messageViewModelsStream;
  final List<ChatMessageViewModel> cachedLatestMessageVMs;
  final ChatDetailsController<DocumentSnapshot> detailsController;
  final List<PendingUploadItem> pendingUploads;
  final bool canSend;
  final ChatMessage? replyToMessage;
  final bool showScrollToBottom;
  final Future<void> Function() onLoadOlderMessages;
  final void Function(ChatMessage message) onMessageLongPress;
  final void Function(ChatMessage message) onReplySwipe;
  final void Function(String imageUrl) onImageTap;
  final Future<void> Function(
    ChatMessage message,
    String emoji,
    bool hasReacted,
  ) onReactionTap;
  final Future<void> Function() onSendMessage;
  final VoidCallback onCancelReply;
  final VoidCallback? onAttachImage;
  final VoidCallback onScrollToBottom;
  final String? Function(Chat chat) typingTextForChat;
  final void Function(List<ChatMessageViewModel> latestVMs)
      onCacheLatestMessageVMs;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                ChatInfoBanner(
                  bannerText: bannerText,
                  isArchived: isArchived,
                ),
                StreamBuilder<Chat?>(
                  stream: chatStream,
                  builder: (context, chatSnapshot) {
                    final typingText = chatSnapshot.hasData
                        ? typingTextForChat(chatSnapshot.data!)
                        : null;
                    return ChatTypingIndicator(typingText: typingText);
                  },
                ),
                Expanded(
                  child: _buildMessageRegion(context),
                ),
                ChatPendingUploadStack(
                  pendingUploads: pendingUploads,
                ),
                ChatInputBar(
                  messageController: messageController,
                  messageFocusNode: messageFocusNode,
                  enabled: canSend && chatUi != null && chatError == null,
                  onSendMessage: onSendMessage,
                  replyToMessage: replyToMessage,
                  onCancelReply: onCancelReply,
                  onAttachImage: onAttachImage,
                ),
              ],
            ),
            if (showScrollToBottom)
              Positioned(
                bottom: 90,
                right: 16,
                child: ChatScrollFab(onPressed: onScrollToBottom),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRegion(BuildContext context) {
    if (chatError != null) {
      return Center(
        child: AppText.body(
          'Unable to load chat.',
          color: AppColors.pure,
        ),
      );
    }

    if (!chatLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatUi == null) {
      return Center(
        child: AppText.body(
          'Chat not found.',
          color: AppColors.pure,
        ),
      );
    }

    if (messageViewModelsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<ChatMessageViewModel>>(
      stream: messageViewModelsStream,
      builder: (context, snapshot) {
        if (kDebugMode) {
          AppLog.d('📨 UI: VM StreamBuilder called for chatId: $chatId');
          AppLog.d(
              '📨 UI: snapshot.connectionState = ${snapshot.connectionState}');
          AppLog.d('📨 UI: snapshot.hasError = ${snapshot.hasError}');
          AppLog.d('📨 UI: snapshot.hasData = ${snapshot.hasData}');
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            AppLog.d('❌ UI: VM StreamBuilder error: ${snapshot.error}');
          }
          return Center(
            child: AppText.body(
              'Unable to load messages.',
              color: AppColors.pure,
            ),
          );
        }

        final hasCachedMessages = cachedLatestMessageVMs.isNotEmpty ||
            detailsController.olderMessages.isNotEmpty;

        if (!snapshot.hasData) {
          if (kDebugMode) {
            AppLog.d('📨 UI: No data yet, showing loading indicator');
          }
          if (!hasCachedMessages) {
            return const Center(child: CircularProgressIndicator());
          }
        }

        final latestVMs = snapshot.data ?? [];
        if (kDebugMode) {
          AppLog.d('📨 UI: Received ${latestVMs.length} view model(s)');
        }

        if (latestVMs.isEmpty && !hasCachedMessages) {
          if (kDebugMode) {
            AppLog.d('📨 UI: VM list is empty - showing "No messages yet"');
          }
          return Center(
            child: AppText.body(
              'No messages yet.',
              color: AppColors.pure,
            ),
          );
        }

        if (latestVMs.isNotEmpty) {
          onCacheLatestMessageVMs(latestVMs);
        }

        final profileProvider = context.read<ProfileProvider>();
        final baseLatest =
            latestVMs.isNotEmpty ? latestVMs : cachedLatestMessageVMs;
        final messageVMs = detailsController.mergeMessageVMs(
          latestVMs: baseLatest,
          resolveDisplayName: (uid) {
            final profile = profileProvider.getCachedProfile(uid);
            return profile?.displayName;
          },
        );

        if (kDebugMode) {
          AppLog.d('📨 UI: After merging: ${messageVMs.length} message VMs');
        }

        if (messageVMs.isNotEmpty && kDebugMode) {
          final firstMessageText = messageVMs.first.text;
          final previewLength =
              firstMessageText.length < 30 ? firstMessageText.length : 30;
          AppLog.d(
            '📨 UI: First message text: ${firstMessageText.substring(0, previewLength)}',
          );
        }

        final currentChat = chatUi!;
        return ChatMessageList(
          scrollController: scrollController,
          messageVMs: messageVMs,
          hasMoreOlder: detailsController.hasMoreOlder,
          isLoadingOlder: detailsController.isLoadingOlder,
          currentUserId: currentUserId,
          isGroupChat: currentChat.type == 'game',
          totalMembers: currentChat.memberIds.length,
          onLoadOlderMessages: onLoadOlderMessages,
          onMessageLongPress: onMessageLongPress,
          onReplySwipe: onReplySwipe,
          onImageTap: onImageTap,
          onReactionTap: onReactionTap,
          showDateDivider: detailsController.showDateDivider,
          isFirstInGroup: detailsController.isFirstInGroup,
          isLastInGroup: detailsController.isLastInGroup,
        );
      },
    );
  }
}
