import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// Action state for mutual card buttons.
enum MutualActionState {
  /// Default state - action not yet taken
  idle,

  /// Action in progress
  loading,

  /// Action completed successfully
  completed,
}

/// Action buttons for mutual friend game cards.
///
/// Displays "Ask to Chat" and "Add Friend" buttons side by side.
/// Each button transitions to a completed state after the action is taken.
class MutualCardActions extends StatelessWidget {
  const MutualCardActions({
    super.key,
    required this.onAskToChat,
    required this.onAddFriend,
    this.chatState = MutualActionState.idle,
    this.friendState = MutualActionState.idle,
  });

  /// Callback when "Ask to Chat" is tapped
  final VoidCallback onAskToChat;

  /// Callback when "Add Friend" is tapped
  final VoidCallback onAddFriend;

  /// Current state of the chat action
  final MutualActionState chatState;

  /// Current state of the friend request action
  final MutualActionState friendState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ask to Chat button
        Expanded(
          child: _MutualActionButton(
            icon: AppPhosphorIcons.chat,
            label: 'Message',
            completedLabel: 'Sent',
            state: chatState,
            onTap: onAskToChat,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        // Add Friend button
        Expanded(
          child: _MutualActionButton(
            icon: AppPhosphorIcons.addPlayer,
            label: 'Add Friend',
            completedLabel: 'Requested',
            state: friendState,
            onTap: onAddFriend,
          ),
        ),
      ],
    );
  }
}

class _MutualActionButton extends StatefulWidget {
  const _MutualActionButton({
    required this.icon,
    required this.label,
    required this.completedLabel,
    required this.state,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final String label;
  final String completedLabel;
  final MutualActionState state;
  final VoidCallback onTap;

  @override
  State<_MutualActionButton> createState() => _MutualActionButtonState();
}

class _MutualActionButtonState extends State<_MutualActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.state == MutualActionState.completed;
    final isLoading = widget.state == MutualActionState.loading;
    final isDisabled = isCompleted || isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.mutualButtonSelectedBg
              : (_isPressed
                  ? AppColors.mutualButtonSelectedBg
                  : AppColors.mutualButtonBg),
          borderRadius: BorderRadius.circular(AppBorderRadius.button),
          border: Border.all(
            color: isCompleted
                ? AppColors.mutualButtonSelectedBorder
                : (_isPressed
                    ? AppColors.mutualButtonSelectedBorder
                    : AppColors.mutualButtonBorder),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mutualAccent,
                ),
              ),
            ] else ...[
              AppIcon(
                icon: isCompleted
                    ? AppPhosphorIcons.check
                    : widget.icon,
                size: 14,
                color: isCompleted
                    ? AppColors.mutualAccent
                    : AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                isCompleted ? widget.completedLabel : widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: isCompleted
                      ? AppColors.mutualAccent
                      : AppColors.textSecondary,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
