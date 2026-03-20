import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/widgets/app_icon.dart';

class ShowUpRateCard extends StatelessWidget {
  const ShowUpRateCard({
    super.key,
    required this.rate,
    required this.denominator,
  });

  final double rate;
  final int denominator;

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).toStringAsFixed(0);
    final color = rate >= 0.9
        ? AppColors.success
        : rate >= 0.75
            ? AppColors.warning
            : AppColors.error;
    final gradientColors = rate >= 0.9
        ? [AppColors.success, AppColors.navyLight]
        : rate >= 0.75
            ? [AppColors.warning, AppColors.goldLight]
            : [AppColors.error, AppColors.error];

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.navyLight),
        boxShadow: [AppElevation.md],
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
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.successFill,
                  color: AppColors.pure,
                  size: AppIconSize.button,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show-Up Rate',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$denominator game${denominator == 1 ? "" : "s"} played',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: AppTypography.monoLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xs),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppColors.navyLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
