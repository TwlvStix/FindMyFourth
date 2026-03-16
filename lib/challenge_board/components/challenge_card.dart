import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/models/challenge.dart';
import '/models/challenge_progress.dart';

/// Card displaying a single challenge with progress.
///
/// Handles three states:
/// - Hidden + not completed: mystery card with "???" name
/// - Hidden + completed: revealed card with green checkmark
/// - Normal: category icon, name, description, and progress bar
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    this.progress,
  });

  final Challenge challenge;
  final ChallengeProgress? progress;

  @override
  Widget build(BuildContext context) {
    final isHidden = challenge.hidden;
    final isCompleted = progress?.isCompleted ?? false;

    // Hidden + not completed → mystery card
    if (isHidden && !isCompleted) {
      return _buildCard(
        icon: AppPhosphorIcons.challengeHidden,
        iconColor: AppColors.textMuted,
        name: '???',
        description: 'Hidden challenge',
        progress: null,
        isCompleted: false,
      );
    }

    return _buildCard(
      icon: _iconForCategory(challenge.category),
      iconColor: isCompleted ? AppColors.green : AppColors.textSecondary,
      name: challenge.name,
      description: challenge.description,
      progress: progress,
      isCompleted: isCompleted,
    );
  }

  Widget _buildCard({
    required PhosphorIconData icon,
    required Color iconColor,
    required String name,
    required String description,
    required ChallengeProgress? progress,
    required bool isCompleted,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          isCompleted
              ? AppIcon(
                  icon: AppPhosphorIcons.success,
                  size: AppIconSize.section,
                  color: AppColors.green,
                )
              : AppIcon(
                  icon: icon,
                  size: AppIconSize.section,
                  color: iconColor,
                ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  _descriptionText(description, progress, isCompleted),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!isCompleted && progress != null && progress.target > 0) ...[
                  SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                    child: LinearProgressIndicator(
                      value: progress.progressPercent,
                      minHeight: 4,
                      backgroundColor: AppColors.navyLight,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.green),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          if (isCompleted)
            Text(
              _formatDate(progress?.completedAt),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else if (progress != null && progress.target > 0)
            Text(
              '${progress.current}/${progress.target}',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  String _descriptionText(
    String description,
    ChallengeProgress? progress,
    bool isCompleted,
  ) {
    if (isCompleted && progress?.completedAt != null) {
      return description;
    }
    return description;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d').format(date);
  }

  static PhosphorIconData _iconForCategory(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.courseExplorer:
        return AppPhosphorIcons.challengeCourseExplorer;
      case ChallengeCategory.streaks:
        return AppPhosphorIcons.challengeStreaks;
      case ChallengeCategory.social:
        return AppPhosphorIcons.challengeSocial;
      case ChallengeCategory.formats:
        return AppPhosphorIcons.challengeFormats;
    }
  }
}
