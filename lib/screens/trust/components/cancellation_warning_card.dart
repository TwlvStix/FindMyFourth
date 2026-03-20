import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_icon.dart';

class CancellationWarningCard extends StatelessWidget {
  const CancellationWarningCard({
    super.key,
    required this.warningCount,
    required this.isOwnProfile,
  });

  final int warningCount;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showWarningBottomSheet(context);
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          boxShadow: [AppElevation.sm],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warning, AppColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.warning,
                color: AppColors.pure,
                size: AppIconSize.button,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation History',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Tap for details',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppIconSize.button,
            ),
          ],
        ),
      ),
    );
  }

  void _showWarningBottomSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      enableDrag: true,
      builder: (context) => _WarningDetailSheet(
        warningCount: warningCount,
        isOwnProfile: isOwnProfile,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Warning Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WarningDetailSheet extends StatelessWidget {
  const _WarningDetailSheet({
    required this.warningCount,
    required this.isOwnProfile,
  });

  final int warningCount;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final countLabel = warningCount == 1
        ? '1 late or same-day cancellation'
        : '$warningCount late or same-day cancellations';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
        border: Border.all(color: AppColors.navyLight),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              AppIcon(
                icon: AppPhosphorIcons.warning,
                color: AppColors.warning,
                size: AppIconSize.md,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Cancellation Notice',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '$countLabel in the last 90 days.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            isOwnProfile
                ? 'Late cancellations and no-shows in the last 90 days trigger this notice. '
                    'It clears automatically once the 90-day window passes.'
                : 'This player has had recent late or same-day cancellations. '
                    'This notice clears automatically once the 90-day window passes.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
