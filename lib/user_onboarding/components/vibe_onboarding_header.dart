import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Header section for vibe onboarding.
///
/// Displays title, step counter, and progress bar.
/// Stateless widget — receives current step state via constructor.
class VibeOnboardingHeader extends StatelessWidget {
  const VibeOnboardingHeader({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
  });

  final int currentIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and step counter
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell us how you like to play.',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColorsDark.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Step ${currentIndex + 1} of $totalSteps',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColorsDark.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Semantics(
          label: 'Progress: step ${currentIndex + 1} of $totalSteps',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              child: LinearProgressIndicator(
                value: (currentIndex + 1) / totalSteps,
                backgroundColor: AppColorsDark.navyLight,
                valueColor: AlwaysStoppedAnimation<Color>(AppColorsDark.green),
                minHeight: 6,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
