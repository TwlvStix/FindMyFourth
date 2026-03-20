import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import 'badge_info.dart';

class BadgeProgressCard extends StatelessWidget {
  const BadgeProgressCard({super.key, required this.standing});

  final Map<String, dynamic> standing;

  @override
  Widget build(BuildContext context) {
    final currentBadge = (standing['currentBadge'] as String?) ?? 'new';
    final nextBadge = standing['nextBadge'] as String?;
    final weighted =
        (standing['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final info = badgeInfo(currentBadge);
    final nextInfo = nextBadge != null ? badgeInfo(nextBadge) : null;

    final nextReqs =
        standing['nextBadgeRequirements'] as Map<String, dynamic>?;
    final roundsNeeded =
        (nextReqs?['weightedRoundsNeeded'] as num?)?.toDouble() ?? 0.0;
    final progress = roundsNeeded > 0
        ? (weighted / (weighted + roundsNeeded)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [info.gradientStart, info.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: info.gradientStart.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                child: AppIcon(
                    icon: info.icon,
                    color: AppColors.pure,
                    size: AppIconSize.md),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.pure,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Current badge',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.glassTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                weighted.toStringAsFixed(1),
                style: AppTypography.monoMedium.copyWith(
                  color: AppColors.pure,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (nextInfo != null) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to ${nextInfo.label}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.glassTextSecondary,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.pure,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.xs),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glassBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.pure),
                minHeight: 6,
              ),
            ),
            if (nextReqs != null) ...[
              SizedBox(height: AppSpacing.sm),
              _buildProgressGaps(nextReqs),
            ],
          ] else ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              'Top tier — you\'re an Anchor.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.glassTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressGaps(Map<String, dynamic> nextReqs) {
    final parts = <String>[];
    final rw =
        (nextReqs['weightedRoundsNeeded'] as num?)?.toDouble() ?? 0.0;
    final ru = (nextReqs['uniquePlayersNeeded'] as num?)?.toInt() ?? 0;
    final rh = (nextReqs['hostedNeeded'] as num?)?.toInt() ?? 0;
    if (rw > 0) parts.add('${rw.toStringAsFixed(1)} more weighted rounds');
    if (ru > 0) parts.add('$ru more new playing partners');
    if (rh > 0) parts.add('$rh more hosted games');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.glassTextSecondary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
