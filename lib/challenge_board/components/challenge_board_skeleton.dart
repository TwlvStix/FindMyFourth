import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/reduced_motion.dart';

/// Skeleton loading state for the Challenge Board initial load.
///
/// Replicates the header + 2 category section layout with placeholder shapes
/// and a subtle pulse animation.
class ChallengeBoardSkeleton extends StatelessWidget {
  const ChallengeBoardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final animate = !ReducedMotionService.isEnabled;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.xl),

          // Header placeholder (progress ring area)
          Center(
            child: _shimmer(
              animate: animate,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Header text placeholder
          Center(
            child: _shimmer(
              animate: animate,
              child: Container(
                height: 20,
                width: 160,
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // Category section 1
          _buildCategoryPlaceholder(animate: animate),

          SizedBox(height: AppSpacing.lg),

          // Category section 2
          _buildCategoryPlaceholder(animate: animate),
        ],
      ),
    );
  }

  Widget _buildCategoryPlaceholder({required bool animate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _shimmer(
          animate: animate,
          child: Container(
            height: 20,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.xs),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        // Card placeholders
        for (var i = 0; i < 3; i++) ...[
          _shimmer(
            animate: animate,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _shimmer({required bool animate, required Widget child}) {
    if (!animate) return child;
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 800.ms)
        .then()
        .fadeOut(duration: 800.ms);
  }
}
