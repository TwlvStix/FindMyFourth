import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/chat_message.dart';

class ChatReactionPicker extends StatelessWidget {
  const ChatReactionPicker({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReactionToggled,
    this.onReportMessage,
  });

  final ChatMessage message;
  final String currentUserId;
  final Future<void> Function(String emoji, bool hasReacted) onReactionToggled;
  final VoidCallback? onReportMessage;

  @override
  Widget build(BuildContext context) {
    const quickReactions = <String>['👍', '❤️', '😂', '😮', '😢', '🙏'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xl),
          topRight: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.whiteHandle,
              borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'React to message',
            style: AppTypography.titleMedium,
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: quickReactions.map((emoji) {
              final hasReacted =
                  message.reactions[emoji]?.contains(currentUserId) ?? false;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onReactionToggled(emoji, hasReacted);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: hasReacted
                        ? AppColors.navyDark.withValues(alpha: 0.3)
                        : AppColors.navy,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: hasReacted
                        ? Border.all(
                            color: AppColors.navyDark,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (onReportMessage != null && message.senderId != currentUserId) ...[
            SizedBox(height: AppSpacing.sm),
            Divider(color: AppColors.navyLight),
            SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onReportMessage!();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  'Report message',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
