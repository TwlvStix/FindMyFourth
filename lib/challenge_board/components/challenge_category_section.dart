import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/challenge.dart';
import '/models/challenge_progress.dart';
import 'challenge_card.dart';

/// Section displaying all challenges in a category with header and progress count.
class ChallengeCategorySection extends StatelessWidget {
  const ChallengeCategorySection({
    super.key,
    required this.category,
    required this.icon,
    required this.challenges,
    required this.progress,
    this.isFirst = false,
  });

  final ChallengeCategory category;
  final PhosphorIconData icon;
  final List<Challenge> challenges;
  final Map<String, ChallengeProgress> progress;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final completedInCategory = challenges
        .where((c) => progress[c.id]?.isCompleted ?? false)
        .length;

    // Sort: completed first (by completedAt desc), then by progressPercent desc
    final sorted = List<Challenge>.from(challenges)
      ..sort((a, b) {
        final aProgress = progress[a.id];
        final bProgress = progress[b.id];
        final aCompleted = aProgress?.isCompleted ?? false;
        final bCompleted = bProgress?.isCompleted ?? false;

        if (aCompleted && !bCompleted) return -1;
        if (!aCompleted && bCompleted) return 1;

        if (aCompleted && bCompleted) {
          final aDate = aProgress!.completedAt ?? DateTime(2000);
          final bDate = bProgress!.completedAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        }

        final aPercent = aProgress?.progressPercent ?? 0.0;
        final bPercent = bProgress?.progressPercent ?? 0.0;
        return bPercent.compareTo(aPercent);
      });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFirst)
            Container(
              height: 1,
              color: AppColors.glassSurface,
              margin: EdgeInsets.only(bottom: AppSpacing.md),
            ),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              GradientIconBox(
                icon: icon,
                gradientColors: _gradientForCategory(category),
                size: 36,
                iconSize: 18,
                borderRadius: 10,
                withShadow: false,
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  category.label,
                  style: AppTypography.titleLarge.copyWith(
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
                  color: AppColors.navy.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
                child: Text(
                  '$completedInCategory/${challenges.length}',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ...sorted.map((challenge) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: ChallengeCard(
                  challenge: challenge,
                  progress: progress[challenge.id],
                ),
              )),
        ],
      ),
    );
  }

  static List<Color> _gradientForCategory(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.courseExplorer:
        return [AppColors.green, AppColors.greenLight];
      case ChallengeCategory.streaks:
        return [AppColors.gold, AppColors.goldLight];
      case ChallengeCategory.social:
        return [AppColors.info, AppColors.info];
      case ChallengeCategory.formats:
        return [AppColors.warning, AppColors.warning];
    }
  }
}
