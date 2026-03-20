import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';

class JourneyProgressBar extends StatelessWidget {
  const JourneyProgressBar({
    super.key,
    required this.verifiedRoundCount,
  });

  final int verifiedRoundCount;

  @override
  Widget build(BuildContext context) {
    final rounds = verifiedRoundCount;
    final progress = rounds <= 0
        ? 0.08
        : rounds >= 10
            ? 1.0
            : 0.08 + (rounds / 10) * 0.92;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          // Track bar with nodes
          SizedBox(
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                Positioned(
                  left: 7,
                  right: 7,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.6),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xxs),
                    ),
                  ),
                ),
                // Progress fill
                Positioned(
                  left: 7,
                  right: 7,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.greenLight,
                                AppColors.green,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xxs),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Nodes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressNode(isActive: true),
                    _buildProgressNode(isActive: rounds >= 5),
                    _buildProgressNode(isActive: rounds >= 10),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Milestone labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'First Tee',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '5 Rounds',
                style: AppTypography.labelSmall.copyWith(
                  color: rounds >= 5
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight: rounds >= 5 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              Text(
                'Trusted',
                style: AppTypography.labelSmall.copyWith(
                  color: rounds >= 10
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight:
                      rounds >= 10 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressNode({required bool isActive}) {
    return Container(
      width: isActive ? 14 : 11,
      height: isActive ? 14 : 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.green : AppColors.navyLight,
        border: Border.all(
          color: isActive ? AppColors.navy : AppColors.navyLight,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}
