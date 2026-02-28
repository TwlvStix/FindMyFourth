import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';

/// Shows a help dialog with the given title and message.
void showCreateGameHelpDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  HapticFeedback.lightImpact();
  showAppDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyLight, AppColors.navy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
          boxShadow: [AppElevation.xl],
        ),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.help,
                color: AppColors.pure,
                size: AppIconSize.lg,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.headlineMediumSans.copyWith(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: AppButtonEnhanced(
                text: 'Got it',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
