import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/reduced_motion.dart';
import '/core/widgets/app_icon.dart';
import '/models/challenge.dart';
import '/models/challenge_progress.dart';

/// Card displaying a single challenge with state-based visual hierarchy.
///
/// States:
/// - Hidden + not completed: ghostly mystery card with "???"
/// - Completed: gold border, glow, gradient icon box
/// - In-progress: subtle green accent, gradient progress bar
/// - Not started: most subdued glass-morphic appearance
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
        nameLetterSpacing: 2.0,
        description: 'Hidden challenge',
        progress: null,
        isCompleted: false,
        isHidden: true,
      );
    }

    return _buildCard(
      icon: _iconForCategory(challenge.category),
      iconColor: isCompleted ? AppColors.gold : AppColors.textSecondary,
      name: challenge.name,
      description: challenge.description,
      progress: progress,
      isCompleted: isCompleted,
      isHidden: false,
    );
  }

  Widget _buildCard({
    required PhosphorIconData icon,
    required Color iconColor,
    required String name,
    required String description,
    required ChallengeProgress? progress,
    required bool isCompleted,
    required bool isHidden,
    double? nameLetterSpacing,
  }) {
    final hasProgress = progress != null && progress.target > 0 && !isCompleted;

    // State-based decoration
    final Color bgColor;
    final Color borderColor;
    final List<BoxShadow>? shadows;

    if (isCompleted) {
      bgColor = AppColors.navy.withValues(alpha: 0.4);
      borderColor = AppColors.gold.withValues(alpha: 0.20);
      shadows = [AppElevation.glowGold];
    } else if (hasProgress) {
      bgColor = AppColors.navy.withValues(alpha: 0.3);
      borderColor = AppColors.green.withValues(alpha: 0.15);
      shadows = null;
    } else if (isHidden) {
      bgColor = AppColors.navy.withValues(alpha: 0.15);
      borderColor = AppColors.glassSurface;
      shadows = null;
    } else {
      bgColor = AppColors.navy.withValues(alpha: 0.2);
      borderColor = AppColors.glassSurface;
      shadows = null;
    }

    Widget card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: borderColor),
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          _buildIconWidget(icon, iconColor, isCompleted),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: nameLetterSpacing,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (hasProgress) ...[
                  SizedBox(height: AppSpacing.xs),
                  _buildGradientProgressBar(progress.progressPercent),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          if (isCompleted)
            Text(
              _formatDate(progress?.completedAt),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.gold,
              ),
            )
          else if (progress != null && progress.target > 0)
            Text(
              '${progress.current}/${progress.target}',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );

    // Subtle entrance animation for completed cards
    if (isCompleted && !ReducedMotionService.isEnabled) {
      card = card
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic);
    }

    return card;
  }

  Widget _buildIconWidget(
    PhosphorIconData icon,
    Color iconColor,
    bool isCompleted,
  ) {
    if (isCompleted) {
      return GradientIconBox(
        icon: AppPhosphorIcons.success,
        gradientColors: const [AppColors.gold, AppColors.goldLight],
        size: 36,
        iconSize: 18,
        borderRadius: 10,
        withShadow: false,
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Center(
        child: AppIcon(
          icon: icon,
          size: AppIconSize.button,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildGradientProgressBar(double percent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.green, AppColors.greenLight],
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
