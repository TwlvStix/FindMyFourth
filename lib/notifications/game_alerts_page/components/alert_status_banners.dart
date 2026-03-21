import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/services/notification_permission_service.dart';

/// Error message banner for alert subscription errors.
class AlertErrorBanner extends StatelessWidget {
  const AlertErrorBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.error,
            color: AppColors.error,
            size: AppIconSize.md,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.pure,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning banner shown when notification permissions are denied.
class AlertPermissionWarning extends StatelessWidget {
  const AlertPermissionWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final status = NotificationPermissionService().cachedStatus;

    if (status != NotificationPermissionStatus.permanentlyDenied) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.settings,
            size: AppIconSize.xl,
            color: AppColors.warning,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Notification permission required',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.pure,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Please enable notifications in Settings',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          AppButtonEnhanced(
            onPressed: () async {
              await NotificationPermissionService().openSystemSettings();
            },
            text: 'Open Settings',
            trailingIcon: AppPhosphorIcons.externalLink,
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}
