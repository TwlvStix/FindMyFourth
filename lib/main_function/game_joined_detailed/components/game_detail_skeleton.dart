import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_shimmer_box.dart';

/// Skeleton loading state for Game Details screen.
///
/// Mimics the layout of [PremiumHeroSection] + player list + action button
/// using [AppShimmerBox] shapes. Reduced motion is handled automatically
/// by [AppShimmerBox].
class GameDetailSkeleton extends StatelessWidget {
  const GameDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.lg),
          // Hero section: course name, date, action button
          _buildHeroSection(),
          SizedBox(height: AppSpacing.xl),
          // Player list section
          _buildPlayerSection(),
          SizedBox(height: AppSpacing.xl),
          // Action button
          AppShimmerBox(
            height: 48,
            borderRadius: AppBorderRadius.button,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course name
        AppShimmerBox(width: 200, height: 20),
        SizedBox(height: AppSpacing.sm),
        // Date/time
        AppShimmerBox(width: 150, height: 16),
        SizedBox(height: AppSpacing.md),
        // Hero button
        AppShimmerBox(
          height: 44,
          borderRadius: AppBorderRadius.button,
        ),
      ],
    );
  }

  Widget _buildPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        AppShimmerBox(width: 100, height: 16),
        SizedBox(height: AppSpacing.md),
        // Player rows
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppShimmerBox(
                width: 40,
                height: 40,
                isCircular: true,
              ),
              SizedBox(width: AppSpacing.sm),
              AppShimmerBox(width: 120, height: 16),
            ],
          ),
        ],
      ],
    );
  }
}
