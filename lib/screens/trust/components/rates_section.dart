import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import 'standing_section_card.dart';

class RatesSection extends StatelessWidget {
  const RatesSection({super.key, required this.standing});

  final Map<String, dynamic> standing;

  @override
  Widget build(BuildContext context) {
    final showUpRate = (standing['showUpRate'] as num?)?.toDouble();
    final showUpDenom =
        (standing['showUpRateDenominator'] as num?)?.toInt() ?? 0;
    final cancelRate =
        (standing['cancellationRate'] as num?)?.toDouble();
    final cancelNum =
        (standing['cancellationRateNumerator'] as num?)?.toInt() ?? 0;
    final cancelDenom =
        (standing['cancellationRateDenominator'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: StandingSectionCard(
            child: _buildRateTile(
              label: 'Show-Up Rate',
              icon: AppPhosphorIcons.success,
              rate: showUpRate,
              denominator: showUpDenom,
              highIsGood: true,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StandingSectionCard(
            child: _buildRateTile(
              label: 'Cancel Rate',
              icon: AppPhosphorIcons.xCircle,
              rate: cancelRate,
              numerator: cancelNum,
              denominator: cancelDenom,
              highIsGood: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateTile({
    required String label,
    required PhosphorIconData icon,
    required double? rate,
    int? numerator,
    required int denominator,
    required bool highIsGood,
  }) {
    Color color;
    if (rate == null) {
      color = AppColors.textMuted;
    } else if (highIsGood) {
      color = rate >= 0.9
          ? AppColors.success
          : rate >= 0.75
              ? AppColors.warning
              : AppColors.error;
    } else {
      color = rate <= 0.10
          ? AppColors.success
          : rate <= 0.20
              ? AppColors.warning
              : AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(icon: icon, color: color, size: AppIconSize.xs),
            SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        rate == null
            ? Text(
                'N/A',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: AppTypography.monoMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          rate == null
              ? 'Need 5+ rounds'
              : '$denominator game${denominator == 1 ? "" : "s"}',
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
