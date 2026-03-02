import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/services/vibe_group_matcher.dart';

/// Group vibe match visualization displaying overall group compatibility score
class GroupVibeSummary extends StatelessWidget {
  const GroupVibeSummary({
    super.key,
    required this.groupVibeMatch,
    required this.onViewBreakdown,
  });

  final GroupVibeMatchResult? groupVibeMatch;
  final VoidCallback onViewBreakdown;

  @override
  Widget build(BuildContext context) {
    final result = groupVibeMatch;
    final groupScore = result?.groupFitScore.round() ?? 0;
    final hasResult = result != null;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.4),
            AppColors.navyDark.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                icon: AppPhosphorIcons.brain,
                color: AppColors.textSecondary,
                size: AppIconSize.section,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Vibe Match',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasResult ? 'Your fit with this group' : 'Calculating...',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Score badge - analytical, not emotional
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: hasResult
                      ? (groupScore >= 80
                          ? AppColors.green.withValues(alpha: 0.15)
                          : AppColors.navyLight.withValues(alpha: 0.3))
                      : AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: hasResult
                    ? Text(
                        '$groupScore%',
                        style: AppTypography.titleSmall.copyWith(
                          color: groupScore >= 80
                              ? AppColors.green
                              : groupScore >= 40
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ],
          ),
          if (hasResult) ...[
            // Cohesion warning banner
            if (result.hasCohesionIssue && result.cohesionWarning != null) ...[
              SizedBox(height: AppSpacing.sm),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    AppIcon(
                      icon: AppPhosphorIcons.info,
                      color: AppColors.pure,
                      size: AppIconSize.button,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        result.cohesionWarning!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: onViewBreakdown,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(
                      icon: AppPhosphorIcons.insights,
                      color: AppColors.textSecondary,
                      size: AppIconSize.button,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'View Detailed Breakdown',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    AppIcon(
                      icon: AppPhosphorIcons.chevronRight,
                      color: AppColors.textSecondary,
                      size: AppIconSize.button,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
