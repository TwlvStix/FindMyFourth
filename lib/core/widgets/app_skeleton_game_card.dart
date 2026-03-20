import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/animated_entrance.dart';
import '/core/widgets/app_shimmer_box.dart';

/// Skeleton placeholder matching [UnifiedGameCard] layout dimensions.
///
/// Shows shimmer shapes for course name, date, detail pills, avatar stack,
/// and spots badge. Wraps in [AnimatedEntrance] for staggered entrance.
class AppSkeletonGameCard extends StatelessWidget {
  const AppSkeletonGameCard({
    super.key,
    this.animationIndex = 0,
  });

  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntrance(
      animationIndex: animationIndex,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: AppColors.navyLight,
            width: 1.0,
          ),
          boxShadow: [AppElevation.card],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: course name + date left, status badge right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmerBox(width: 160, height: 18),
                        SizedBox(height: 4),
                        AppShimmerBox(width: 120, height: 14),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  AppShimmerBox(
                    width: 56,
                    height: 24,
                    borderRadius: AppBorderRadius.md,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              // Detail pills
              Row(
                children: [
                  AppShimmerBox(
                    width: 72,
                    height: 24,
                    borderRadius: AppBorderRadius.chip,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  AppShimmerBox(
                    width: 72,
                    height: 24,
                    borderRadius: AppBorderRadius.chip,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              // Footer row: avatar stack + host name left, spots badge right
              Row(
                children: [
                  // Overlapping avatar circles (3 circles, 8px overlap)
                  SizedBox(
                    width: 26.0 * 3 - 8.0 * 2, // 62px
                    height: 26,
                    child: Stack(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Positioned(
                            left: i * 18.0,
                            child: AppShimmerBox(
                              width: 26,
                              height: 26,
                              isCircular: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  AppShimmerBox(width: 80, height: 14),
                  const Spacer(),
                  AppShimmerBox(
                    width: 64,
                    height: 24,
                    borderRadius: AppBorderRadius.chip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
