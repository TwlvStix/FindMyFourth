import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import 'badge_info.dart';
import 'standing_section_card.dart';

class NextBadgeSection extends StatelessWidget {
  const NextBadgeSection({super.key, required this.standing});

  final Map<String, dynamic> standing;

  @override
  Widget build(BuildContext context) {
    final nextBadge = standing['nextBadge'] as String?;
    if (nextBadge == null) return const SizedBox.shrink();

    final nextReqs =
        standing['nextBadgeRequirements'] as Map<String, dynamic>?;
    if (nextReqs == null) return const SizedBox.shrink();

    final weighted =
        (standing['weightedRounds'] as num?)?.toDouble() ?? 0.0;
    final unique = (standing['uniqueCoPlayers'] as num?)?.toInt() ?? 0;
    final hosted = (standing['gamesHosted'] as num?)?.toInt() ?? 0;
    final cancelRate =
        (standing['cancellationRate'] as num?)?.toDouble();

    final nextInfo = badgeInfo(nextBadge);

    final rwNeeded =
        (nextReqs['weightedRoundsNeeded'] as num?)?.toDouble() ?? 0.0;
    final ruNeeded =
        (nextReqs['uniquePlayersNeeded'] as num?)?.toInt() ?? 0;
    final rhNeeded = (nextReqs['hostedNeeded'] as num?)?.toInt() ?? 0;
    final maxCancelRate =
        (nextReqs['maxCancelRate'] as num?)?.toDouble();

    return StandingSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                  icon: nextInfo.icon,
                  color: AppColors.green,
                  size: AppIconSize.button),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Next: ${nextInfo.label}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildRequirementRow(
            label: 'Weighted rounds',
            current: weighted,
            needed: weighted + rwNeeded,
            met: rwNeeded == 0,
            format: (v) => v.toStringAsFixed(1),
          ),
          SizedBox(height: AppSpacing.xs),
          _buildRequirementRow(
            label: 'New playing partners',
            current: unique.toDouble(),
            needed: (unique + ruNeeded).toDouble(),
            met: ruNeeded == 0,
            format: (v) => v.toInt().toString(),
          ),
          if (rhNeeded > 0 || hosted > 0) ...[
            SizedBox(height: AppSpacing.xs),
            _buildRequirementRow(
              label: 'Games hosted',
              current: hosted.toDouble(),
              needed: (hosted + rhNeeded).toDouble(),
              met: rhNeeded == 0,
              format: (v) => v.toInt().toString(),
            ),
          ],
          if (maxCancelRate != null) ...[
            SizedBox(height: AppSpacing.xs),
            _buildCancelRateRequirementRow(
              cancelRate: cancelRate,
              maxCancelRate: maxCancelRate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementRow({
    required String label,
    required double current,
    required double needed,
    required bool met,
    required String Function(double) format,
  }) {
    return Row(
      children: [
        AppIcon(
          icon: met ? AppPhosphorIcons.success : AppPhosphorIcons.circle,
          color: met ? AppColors.success : AppColors.navyLight,
          size: AppIconSize.button,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          '${format(current)} / ${format(needed)}',
          style: AppTypography.labelSmall.copyWith(
            color: met ? AppColors.success : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelRateRequirementRow({
    required double? cancelRate,
    required double maxCancelRate,
  }) {
    final met = cancelRate != null && cancelRate <= maxCancelRate;
    final pct = cancelRate != null
        ? '${(cancelRate * 100).toStringAsFixed(0)}%'
        : 'N/A';
    final maxPct = '${(maxCancelRate * 100).toStringAsFixed(0)}%';
    return Row(
      children: [
        AppIcon(
          icon: met ? AppPhosphorIcons.success : AppPhosphorIcons.circle,
          color: met ? AppColors.success : AppColors.navyLight,
          size: AppIconSize.button,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Cancel rate',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          '$pct (max $maxPct)',
          style: AppTypography.labelSmall.copyWith(
            color: met ? AppColors.success : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
