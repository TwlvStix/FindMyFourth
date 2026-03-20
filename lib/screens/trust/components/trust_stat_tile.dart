import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';

class TrustStatTile extends StatelessWidget {
  const TrustStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final PhosphorIconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isZero = value == '0';
    final displayValue = isZero ? '\u2014' : value;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xxs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            icon: icon,
            color: AppColors.textMuted.withValues(alpha: 0.7),
            size: AppIconSize.md,
          ),
          SizedBox(height: AppSpacing.xxs),
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            displayValue,
            style: isZero
                ? AppTypography.monoLarge.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w300,
                  )
                : AppTypography.monoLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
