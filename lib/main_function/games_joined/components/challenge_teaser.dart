import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/models/challenge.dart';
import '/models/challenge_progress.dart';
import '/providers/provider_extensions.dart';

/// 2x2 teaser widget showing closest-to-completion challenge per category.
///
/// Displayed on the My Games tab between Upcoming and Recent Rounds sections.
/// Tapping "View all challenges" navigates to the full Challenge Board.
class ChallengeTeaser extends StatelessWidget {
  const ChallengeTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watchChallengeProvider;
    final progress = provider.currentProgress;
    final completed = provider.completedCount;
    final total = provider.visibleCount;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Challenges',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.button),
                  ),
                  child: Text(
                    '$completed/$total',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (!provider.hasAnyProgress) ...[
              Text(
                'Complete your first round to start earning challenges.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
            ] else
              SizedBox(height: AppSpacing.xs),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 3.2,
              children: [
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeCourseExplorer,
                  label: ChallengeCategory.courseExplorer.label,
                  progress: progress,
                  category: ChallengeCategory.courseExplorer,
                  accentColor: AppColors.challengeCourseExplorer,
                  closestProgress: provider.closestToCompletion(
                      ChallengeCategory.courseExplorer),
                ),
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeStreaks,
                  label: ChallengeCategory.streaks.label,
                  progress: progress,
                  category: ChallengeCategory.streaks,
                  accentColor: AppColors.challengeStreaks,
                  closestProgress:
                      provider.closestToCompletion(ChallengeCategory.streaks),
                ),
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeSocial,
                  label: ChallengeCategory.social.label,
                  progress: progress,
                  category: ChallengeCategory.social,
                  accentColor: AppColors.challengeSocial,
                  closestProgress:
                      provider.closestToCompletion(ChallengeCategory.social),
                ),
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeFormats,
                  label: ChallengeCategory.formats.label,
                  progress: progress,
                  category: ChallengeCategory.formats,
                  accentColor: AppColors.challengeFormats,
                  closestProgress:
                      provider.closestToCompletion(ChallengeCategory.formats),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Center(
              child: AppButtonEnhanced(
                text: 'View all challenges',
                variant: AppButtonVariant.ghostDark,
                size: AppButtonSize.small,
                trailingPhosphorIcon: AppPhosphorIcons.chevronRight,
                onPressed: () => context.pushChallengeBoard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.icon,
    required this.label,
    required this.progress,
    required this.category,
    required this.accentColor,
    this.closestProgress,
  });

  final PhosphorIconData icon;
  final String label;
  final Map<String, ChallengeProgress> progress;
  final ChallengeCategory category;
  final Color accentColor;
  final ChallengeProgress? closestProgress;

  @override
  Widget build(BuildContext context) {
    final visibleInCat = Challenge.visible.where((c) => c.category == category);
    final completedInCat = visibleInCat
        .where((c) => progress[c.id]?.isCompleted ?? false)
        .length;
    final totalInCat = visibleInCat.length;

    final statusText = closestProgress != null
        ? '${closestProgress!.current}/${closestProgress!.target}'
        : '$completedInCat/$totalInCat';

    return Row(
      children: [
        AppIcon(
          icon: icon,
          size: AppIconSize.sm,
          color: accentColor,
        ),
        SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    statusText,
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxs),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppBorderRadius.xxs),
                child: LinearProgressIndicator(
                  value: closestProgress?.progressPercent ?? 0.0,
                  minHeight: 3,
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
