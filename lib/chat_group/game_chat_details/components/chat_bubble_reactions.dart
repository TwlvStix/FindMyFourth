import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';

/// Reaction chips sub-widget for [ChatMessageBubble].
///
/// Displays a wrapped row of emoji reaction badges with counts and
/// highlights the current user's reactions.
class ChatBubbleReactions extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String? currentUserId;
  final bool isSentByCurrentUser;
  final Function(String emoji, bool hasReacted)? onReactionTap;

  const ChatBubbleReactions({
    super.key,
    required this.reactions,
    this.currentUserId,
    required this.isSentByCurrentUser,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isSentByCurrentUser ? 40 : AppSpacing.md + 40,
        right: isSentByCurrentUser ? AppSpacing.md : 40,
      ),
      child: Wrap(
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        children: reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final hasReacted =
              currentUserId != null && users.contains(currentUserId);

          return GestureDetector(
            onTap: () => onReactionTap?.call(emoji, hasReacted),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: hasReacted
                    ? AppColors.navyDark.withValues(alpha: 0.3)
                    : AppColors.pure.withValues(alpha: 0.6),
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
    );
  }
}
