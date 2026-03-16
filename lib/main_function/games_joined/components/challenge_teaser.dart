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
    final total = provider.totalCount;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Column(
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
            SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 2.4,
              children: [
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeCourseExplorer,
                  label: ChallengeCategory.courseExplorer.label,
                  progress: progress,
                  category: ChallengeCategory.courseExplorer,
                  closestProgress: provider.closestToCompletion(
                      ChallengeCategory.courseExplorer),
                ),
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeStreaks,
                  label: ChallengeCategory.streaks.label,
                  progress: progress,
                  category: ChallengeCategory.streaks,
                  closestProgress:
                      provider.closestToCompletion(ChallengeCategory.streaks),
                ),
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeSocial,
                  label: ChallengeCategory.social.label,
                  progress: progress,
                  category: ChallengeCategory.social,
                  closestProgress:
                      provider.closestToCompletion(ChallengeCategory.social),
                ),
                _CategoryCell(
                  icon: AppPhosphorIcons.challengeFormats,
                  label: ChallengeCategory.formats.label,
                  progress: progress,
                  category: ChallengeCategory.formats,
                  closestProgress:
                      provider.closestToCompletion(ChallengeCategory.formats),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Center(
              child: AppButtonEnhanced(
                text: 'View all challenges',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
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
    this.closestProgress,
  });

  final PhosphorIconData icon;
  final String label;
  final Map<String, ChallengeProgress> progress;
  final ChallengeCategory category;
  final ChallengeProgress? closestProgress;

  @override
  Widget build(BuildContext context) {
    final completedInCat = Challenge.all
        .where((c) => c.category == category)
        .where((c) => progress[c.id]?.isCompleted ?? false)
        .length;
    final totalInCat =
        Challenge.all.where((c) => c.category == category).length;

    final statusText = closestProgress != null
        ? '${closestProgress!.current}/${closestProgress!.target}'
        : '$completedInCat/$totalInCat';

    return Row(
      children: [
        AppIcon(
          icon: icon,
          size: AppIconSize.sm,
          color: AppColors.green,
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xxs),
              if (closestProgress != null)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppBorderRadius.xxs),
                  child: LinearProgressIndicator(
                    value: closestProgress!.progressPercent,
                    minHeight: 3,
                    backgroundColor: AppColors.navyLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.green),
                  ),
                )
              else
                SizedBox(height: 3),
              SizedBox(height: AppSpacing.xxs),
              Text(
                statusText,
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
