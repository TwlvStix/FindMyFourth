import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Navigation buttons for progressive onboarding steps.
///
/// Shows Back/Next or Back/Complete depending on current step.
/// Uses primary variant for "Next" and premium variant only for "Complete".
class ProgressiveNavigationButtons extends StatelessWidget {
  const ProgressiveNavigationButtons({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    required this.onNext,
    required this.onPrevious,
  });

  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  bool get _isLastStep => currentStep == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: AppButtonEnhanced(
                text: 'Back',
                onPressed: isLoading ? null : onPrevious,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                fullWidth: true,
              ),
            ),
          if (currentStep > 0) SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButtonEnhanced(
              text: _isLastStep ? 'Complete' : 'Next',
              onPressed: isLoading ? null : onNext,
              // Use primary for "Next" steps, premium only for final "Complete"
              variant: _isLastStep
                  ? AppButtonVariant.premium
                  : AppButtonVariant.primary,
              size: AppButtonSize.medium,
              fullWidth: true,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
