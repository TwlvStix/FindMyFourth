import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';

/// Progress indicator showing current step in onboarding flow.
///
/// Displays horizontal bars, filled up to the current step.
class ProgressiveProgressIndicator extends StatelessWidget {
  const ProgressiveProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${currentStep + 1} of $totalSteps',
      child: Padding(
        padding: AppSpacing.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalSteps,
            (index) => Container(
              // Intentional fixed width for visual design consistency
              width: 40.0,
              // Intentional fixed height for progress bar
              height: 4.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? AppColors.navyDark
                    : AppColors.navyDark.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
