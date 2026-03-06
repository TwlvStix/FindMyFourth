import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Footer action buttons for the friend card.
///
/// Two-button layout with:
/// - Message button (left)
/// - Action button (right) - configurable for Add/Cancel/Accept/etc.
/// - Center divider
class FriendCardFooter extends StatelessWidget {
  const FriendCardFooter({
    super.key,
    this.onMessage,
    this.onAction,
    this.messageLabel = 'Message',
    this.messageIcon = AppPhosphorIcons.chat,
    this.actionLabel = 'Add',
    this.actionIcon = AppPhosphorIcons.addPlayer,
    this.actionIsPrimary = true,
    this.isLoading = false,
    this.showMessageButton = true,
    this.showActionButton = true,
  });

  final VoidCallback? onMessage;
  final VoidCallback? onAction;
  final String messageLabel;
  final PhosphorIconData? messageIcon;
  final String actionLabel;
  final PhosphorIconData? actionIcon;
  final bool actionIsPrimary;
  final bool isLoading;
  final bool showMessageButton;
  final bool showActionButton;

  @override
  Widget build(BuildContext context) {
    // Hide footer if both buttons are hidden
    if (!showMessageButton && !showActionButton) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.navyLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (showMessageButton) ...[
              Expanded(
                child: _FooterButton(
                  label: messageLabel,
                  icon: messageIcon,
                  onPressed: onMessage,
                  isPrimary: false,
                ),
              ),
            ],
            if (showMessageButton && showActionButton)
              Container(
                width: 1,
                color: AppColors.navyLight.withValues(alpha: 0.3),
              ),
            if (showActionButton) ...[
              Expanded(
                child: _FooterButton(
                  label: actionLabel,
                  icon: actionIcon,
                  onPressed: onAction,
                  isPrimary: actionIsPrimary,
                  isLoading: isLoading,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    this.icon,
    required this.onPressed,
    required this.isPrimary,
    this.isLoading = false,
  });

  final String label;
  final PhosphorIconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textColor = isPrimary ? AppColors.green : AppColors.textSecondary;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.xl - 1),
          bottomRight: Radius.circular(AppBorderRadius.xl - 1),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
              ] else ...[
                if (icon != null) ...[
                  AppIcon(
                    icon: icon!,
                    size: 16,
                    color: textColor,
                  ),
                  AppSpacing.horizontalXsBox,
                ],
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
