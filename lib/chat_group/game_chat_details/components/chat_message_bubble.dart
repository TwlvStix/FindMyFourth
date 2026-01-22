import 'package:flutter/material.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/formatting_utils.dart';
import '/models/chat_message.dart';

/// A reusable message bubble component for chat interfaces.
///
/// Displays messages with different styling for sent vs received messages:
/// - Sent messages: aligned right, primary color background
/// - Received messages: aligned left, surface variant background
///
/// Features:
/// - Avatar display for received messages
/// - Sender name for group chats
/// - Image attachments
/// - Timestamps
/// - Read receipts for sent messages
/// - Reactions display
/// - Swipe-to-reply gesture
class ChatMessageBubble extends StatelessWidget {
  final bool isSentByCurrentUser;
  final String messageText;
  final String imageUrl;
  final DateTime? timestamp;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final bool isGroupChat;
  final ChatMessage message;
  final int totalMembers;
  final String? currentUserId;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplySwipe;
  final VoidCallback? onImageTap;
  final Function(String emoji, bool hasReacted)? onReactionTap;

  const ChatMessageBubble({
    super.key,
    required this.isSentByCurrentUser,
    required this.messageText,
    this.imageUrl = '',
    this.timestamp,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.isGroupChat = false,
    required this.message,
    this.totalMembers = 2,
    this.currentUserId,
    this.onLongPress,
    this.onReplySwipe,
    this.onImageTap,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSentByCurrentUser
        ? AppTheme.of(context).primary
        : AppTheme.of(context).secondaryBackground;
    final textColor = isSentByCurrentUser
        ? AppTheme.of(context).primaryBtnText
        : AppTheme.of(context).primaryText;

    return Dismissible(
      key: Key('message_${message.id}'),
      direction: isSentByCurrentUser
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onReplySwipe?.call();
        return false; // Don't actually dismiss
      },
      background: Container(
        alignment: isSentByCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.reply_rounded,
          color: AppTheme.of(context).primary,
          size: 28,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: isLastInGroup ? AppSpacing.xs : 2,
          bottom: isFirstInGroup ? AppSpacing.xs : 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isSentByCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            // Avatar on left for received messages
            if (!isSentByCurrentUser) ...[
              SizedBox(width: AppSpacing.md),
              Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.only(bottom: 4, right: AppSpacing.xs),
                child: isFirstInGroup
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.of(context)
                            .primary
                            .withValues(alpha: 0.3),
                        backgroundImage: senderPhotoUrl != null &&
                                senderPhotoUrl!.isNotEmpty
                            ? NetworkImage(senderPhotoUrl!)
                            : null,
                        child: senderPhotoUrl == null || senderPhotoUrl!.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.7),
                              )
                            : null,
                      )
                    : SizedBox.shrink(),
              ),
            ],
            // Message bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isSentByCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats (first message only)
                  if (!isSentByCurrentUser &&
                      isGroupChat &&
                      isFirstInGroup &&
                      senderName != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.xs,
                        bottom: 4,
                      ),
                      child: Text(
                        senderName!,
                        style: AppTypography.text11.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  // Message content
                  GestureDetector(
                    onLongPress: onLongPress,
                    child: Container(
                      margin: EdgeInsets.only(
                        left: isSentByCurrentUser ? 40 : 0,
                        right: isSentByCurrentUser ? 0 : 40,
                      ),
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              isSentByCurrentUser || !isFirstInGroup
                                  ? 14.0
                                  : 4.0),
                          topRight: Radius.circular(
                              !isSentByCurrentUser || !isFirstInGroup
                                  ? 14.0
                                  : 4.0),
                          bottomLeft: Radius.circular(14.0),
                          bottomRight: Radius.circular(14.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isSentByCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Image attachment
                          if (imageUrl.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: messageText.isNotEmpty
                                      ? AppSpacing.xs
                                      : 0),
                              child: GestureDetector(
                                onTap: onImageTap,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: 250,
                                      maxHeight: 300,
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          height: 200,
                                          width: 200,
                                          color: Colors.grey
                                              .withValues(alpha: 0.2),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                              color: isSentByCurrentUser
                                                  ? Colors.white
                                                      .withValues(alpha: 0.8)
                                                  : AppTheme.of(context)
                                                      .primary,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 150,
                                          width: 200,
                                          color: Colors.grey
                                              .withValues(alpha: 0.2),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                color: textColor
                                                    .withValues(alpha: 0.6),
                                                size: 40,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Failed to load',
                                                style: AppTypography.text11
                                                    .copyWith(
                                                  color: textColor
                                                      .withValues(alpha: 0.6),
                                                  letterSpacing: 0.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Message text
                          if (messageText.isNotEmpty)
                            Text(
                              messageText,
                              style: AppTypography.bodyMedium.copyWith(
                                color: textColor,
                              ),
                            ),
                          // Timestamp and read receipts
                          if (timestamp != null && isLastInGroup) ...[
                            SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dateTimeFormat('jm', timestamp!),
                                  style: AppTypography.text10.copyWith(
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                // Read receipts for sent messages
                                if (isSentByCurrentUser) ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    message.readBy.length > 1
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 14,
                                    color: message.readBy.length > 1
                                        ? AppTheme.of(context).tertiary
                                        : textColor.withValues(alpha: 0.6),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Reactions
                  if (message.reactions.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Container(
                      margin: EdgeInsets.only(
                        left: isSentByCurrentUser ? 40 : AppSpacing.md + 40,
                        right: isSentByCurrentUser ? AppSpacing.md : 40,
                      ),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: message.reactions.entries.map((entry) {
                          final emoji = entry.key;
                          final users = entry.value;
                          final hasReacted = currentUserId != null &&
                              users.contains(currentUserId);

                          return GestureDetector(
                            onTap: () => onReactionTap?.call(emoji, hasReacted),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: hasReacted
                                    ? AppTheme.of(context)
                                        .primary
                                        .withValues(alpha: 0.3)
                                    : AppTheme.of(context)
                                        .secondaryBackground
                                        .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: hasReacted
                                    ? Border.all(
                                        color: AppTheme.of(context).primary,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    emoji,
                                    style: AppTypography.bodyMedium,
                                  ),
                                  if (users.length > 1) ...[
                                    SizedBox(width: 4),
                                    Text(
                                      '${users.length}',
                                      style: AppTypography.text11.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Spacing on right for sent messages
            if (isSentByCurrentUser) SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
