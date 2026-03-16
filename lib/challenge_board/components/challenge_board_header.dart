import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Header for the Challenge Board page showing a progress ring.
///
/// Displays a circular progress indicator with completed/total count
/// and a label below.
class ChallengeBoardHeader extends StatelessWidget {
  const ChallengeBoardHeader({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progressValue = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 6,
                    backgroundColor: AppColors.navyLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.green),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: AppTypography.monoDisplay.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '/ $total',
                      style: AppTypography.monoLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Challenges Completed',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
