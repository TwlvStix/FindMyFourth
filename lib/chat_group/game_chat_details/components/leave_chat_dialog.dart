import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Shows a confirmation dialog when the user is the last member of a chat.
///
/// Returns `true` if the user confirms leaving (and deleting the chat),
/// `false` if they cancel.
Future<bool> showLeaveChatDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text(
          "You're the last person in this chat",
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Leaving will permanently delete the chat and all messages. This cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButtonEnhanced(
                text: 'Cancel',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              SizedBox(width: AppSpacing.sm),
              AppButtonEnhanced(
                text: 'Leave & Delete',
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.small,
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
        ],
      );
    },
  );

  return result ?? false;
}
