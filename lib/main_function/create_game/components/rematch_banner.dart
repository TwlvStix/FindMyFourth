import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';

/// Rematch banner shown when creating a game from a previous round.
///
/// Styled like DraftBanner but indicates rematch context.
class RematchBanner extends StatelessWidget {
  const RematchBanner({
    super.key,
    required this.courseName,
    required this.onDismiss,
  });

  final String? courseName;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final subtitle = courseName != null && courseName!.isNotEmpty
        ? 'Rematch from $courseName'
        : 'Settings from your last round';

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
                  'Play Again',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          AppButtonEnhanced(
            text: 'Clear',
            variant: AppButtonVariant.ghostDark,
            size: AppButtonSize.small,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
