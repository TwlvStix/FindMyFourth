import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';

/// Draft continuation banner for game creation
///
/// Displays a green gradient banner with restore icon and message
/// when user has a saved draft. Includes clear action button.
class DraftBanner extends StatelessWidget {
  const DraftBanner({
    super.key,
    required this.onClear,
  });

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green.withValues(alpha: 0.15),
            AppColors.greenLight.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.greenLight],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: AppIcon(
              icon: AppPhosphorIcons.refresh,
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
                  'Continue where you left off',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Your draft has been restored',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          AppButtonEnhanced(
            text: 'Clear',
            variant: AppButtonVariant.ghostDark,
            size: AppButtonSize.small,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
