import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Quick create banner for game creation
///
/// Displays an info banner with flash icon promoting quick create feature.
/// Uses fairway gradient with action button.
class QuickCreateBanner extends StatelessWidget {
  const QuickCreateBanner({
    super.key,
    required this.onQuickCreate,
  });

  final VoidCallback onQuickCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyLight.withValues(alpha: 0.2),
            AppColors.navy.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: AppIcon(
              icon: AppPhosphorIcons.lightning,
              color: AppColors.pure,
              size: AppIconSize.md,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Create',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Use smart defaults for faster setup',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          AppButtonEnhanced(
            text: 'Go',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: onQuickCreate,
          ),
        ],
      ),
    );
  }
}
