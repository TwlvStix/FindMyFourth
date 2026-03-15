import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_helpers.dart';
import '/models/vibe_labels.dart';
import '/services/vibe_group_matcher.dart';
import '/vibe/vibe_recommendation_rank.dart';

class GroupVibeBreakdownSheet extends StatelessWidget {
  const GroupVibeBreakdownSheet({
    super.key,
    required this.result,
  });

  final GroupVibeMatchResult result;

  static Future<void> show({
    required BuildContext context,
    required GroupVibeMatchResult result,
  }) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => GroupVibeBreakdownSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Group Fit',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.pure,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                '${result.groupFitScore.round()}%',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              if (result.conflicts.isNotEmpty) ...[
                Text(
                  'Potential conflicts',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                ...result.conflicts.map(
                  (conflict) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '${VibeLabels.titleFor(conflict.category)} with ${conflict.memberName}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
              Text(
                'Top differences vs group avg',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.pure,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: result.topDifferences.map((difference) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      border: Border.all(
                        color: AppColors.navyLight,
                      ),
                    ),
                    child: Text(
                      '${VibeLabels.titleFor(difference.category)} • gap ${difference.distance.toStringAsFixed(1)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: AppTypography.letterSpacingNormal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (result.softRisks.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                ...result.softRisks.map(
                  (risk) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      risk.reason,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              Text(
                'Player matches',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.pure,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              ..._sortedMemberResults(result).map((memberResult) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _GroupMatchRow(memberResult: memberResult),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<GroupVibeMemberResult> _sortedMemberResults(
    GroupVibeMatchResult matchResult,
  ) {
    final sorted = matchResult.memberResults.toList()
      ..sort((a, b) {
        final rankA = recommendationRank(a.matchResult.recommendation);
        final rankB = recommendationRank(b.matchResult.recommendation);
        if (rankA != rankB) {
          return rankA.compareTo(rankB);
        }
        return b.displayScore.compareTo(a.displayScore);
      });
    return sorted;
  }
}

class _GroupMatchRow extends StatelessWidget {
  const _GroupMatchRow({
    required this.memberResult,
  });

  final GroupVibeMemberResult memberResult;

  @override
  Widget build(BuildContext context) {
    final matchScore = memberResult.displayScore.round();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              memberResult.member.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Text(
            '$matchScore%',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}
