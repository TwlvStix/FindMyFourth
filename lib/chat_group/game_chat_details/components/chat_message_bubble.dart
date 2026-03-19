import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
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
  final double? imageWidth;
  final double? imageHeight;
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
    this.imageWidth,
    this.imageHeight,
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
        ? AppColors.navyDark
        : AppColors.navy;
    final textColor = isSentByCurrentUser
        ? AppColors.pure
        : AppColors.pure;

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
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AppIcon(
          icon: AppPhosphorIcons.reply,
          color: AppColors.textSecondary,
          size: AppIconSize.md,
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
                margin: EdgeInsets.only(bottom: AppSpacing.xxs, right: AppSpacing.xs),
                child: isFirstInGroup
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.navyDark
                            .withValues(alpha: 0.3),
                        backgroundImage: senderPhotoUrl != null &&
                                senderPhotoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(senderPhotoUrl!)
                            : null,
                        child: senderPhotoUrl == null || senderPhotoUrl!.isEmpty
                            ? AppIcon(
                                icon: AppPhosphorIcons.profile,
                                size: AppIconSize.button,
                                color: AppColors.textSecondary,
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
                        bottom: AppSpacing.xxs,
                      ),
                      child: Text(
                        senderName!,
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
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
                                  ? AppBorderRadius.lg
                                  : AppBorderRadius.xs),
                          topRight: Radius.circular(
                              !isSentByCurrentUser || !isFirstInGroup
                                  ? AppBorderRadius.lg
                                  : AppBorderRadius.xs),
                          bottomLeft: Radius.circular(AppBorderRadius.lg),
                          bottomRight: Radius.circular(AppBorderRadius.lg),
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
                                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 250,
                                      maxHeight: 300,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) {
                                        // Use stored dimensions for correct aspect-ratio skeleton
                                        final double w = (imageWidth != null &&
                                                imageHeight != null &&
                                                imageWidth! > 0)
                                            ? 220.0
                                            : 200.0;
                                        final double h = (imageWidth != null &&
                                                imageHeight != null &&
                                                imageWidth! > 0)
                                            ? (220.0 * imageHeight! / imageWidth!)
                                                .clamp(80.0, 300.0)
                                            : 200.0;
                                        return Container(
                                          width: w,
                                          height: h,
                                          color: AppColors.stone.withValues(alpha: 0.2),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: isSentByCurrentUser
                                                  ? Colors.white
                                                      .withValues(alpha: 0.8) // Keep: no 80% token
                                                  : AppColors.navyDark,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          height: 150,
                                          width: 200,
                                          color: AppColors.stone.withValues(alpha: 0.2),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              AppIcon(
                                                icon: AppPhosphorIcons.imageBroken,
                                                color: textColor
                                                    .withValues(alpha: 0.6),
                                                size: AppIconSize.xl,
                                              ),
                                              AppSpacing.verticalXsBox,
                                              Text(
                                                'Failed to load',
                                                style: AppTypography.labelMicro
                                                    .copyWith(
                                                  color: textColor
                                                      .withValues(alpha: 0.6),
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
                          if (message.isFlagged)
                            Text(
                              'This message was filtered for inappropriate content.',
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else if (messageText.isNotEmpty)
                            Text(
                              messageText,
                              style: AppTypography.bodyMedium.copyWith(
                                color: textColor,
                              ),
                            ),
                          // Timestamp and read receipts
                          if (timestamp != null && isLastInGroup) ...[
                            AppSpacing.verticalXxs,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dateTimeFormat('jm', timestamp!),
                                  style: AppTypography.labelMicro.copyWith(
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                // Read receipts for sent messages
                                if (isSentByCurrentUser) ...[
                                  AppSpacing.horizontalXxs,
                                  AppIcon(
                                    icon: message.readBy.length > 1
                                        ? AppPhosphorIcons.checks
                                        : AppPhosphorIcons.check,
                                    size: AppIconSize.xs,
                                    color: message.readBy.length > 1
                                        ? AppColors.green
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
                    AppSpacing.verticalXxs,
                    Container(
                      margin: EdgeInsets.only(
                        left: isSentByCurrentUser ? 40 : AppSpacing.md + 40,
                        right: isSentByCurrentUser ? AppSpacing.md : 40,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: message.reactions.entries.map((entry) {
                          final emoji = entry.key;
                          final users = entry.value;
                          final hasReacted = currentUserId != null &&
                              users.contains(currentUserId);

                          return GestureDetector(
                            onTap: () => onReactionTap?.call(emoji, hasReacted),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: hasReacted
                                    ? AppColors.navyDark
                                        .withValues(alpha: 0.3)
                                    : AppColors.pure
                                        .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                border: hasReacted
                                    ? Border.all(
                                        color: AppColors.navyDark,
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
                                    AppSpacing.horizontalXxs,
                                    Text(
                                      '${users.length}',
                                      style: AppTypography.labelMicro.copyWith(
                                        color: AppColors.textSecondary,
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
