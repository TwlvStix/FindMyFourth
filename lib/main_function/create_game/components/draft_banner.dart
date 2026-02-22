import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';

/// Draft continuation banner for game creation
///
/// Displays a yellow gradient banner with restore icon and message
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
            AppColors.gold.withValues(alpha: 0.2),
            AppColors.goldLight.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
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
            child: Icon(
              Icons.restore_rounded,
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
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Your draft has been restored',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
