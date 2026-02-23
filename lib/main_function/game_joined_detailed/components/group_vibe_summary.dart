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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: AppIcon(icon: AppPhosphorIcons.brain, color: AppColors.pure, size: AppIconSize.md),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Vibe Match',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasResult ? 'Your fit with this group' : 'Calculating...',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Score badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: hasResult
                      ? LinearGradient(
                          colors: groupScore >= 70
                              ? [AppColors.navyLight, AppColors.navy]
                              : groupScore >= 40
                                  ? [AppColors.gold, AppColors.goldLight]
                                  : [AppColors.error, AppColors.error],
                        )
                      : null,
                  color: hasResult ? null : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: hasResult
                    ? Text(
                        '$groupScore%',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
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
                          color: Colors.white.withValues(alpha: 0.9),
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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(
                      icon: AppPhosphorIcons.insights,
                      color: AppColors.gold,
                      size: AppIconSize.button,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'View Detailed Breakdown',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    AppIcon(
                      icon: AppPhosphorIcons.chevronRight,
                      color: Colors.white.withValues(alpha: 0.6),
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
