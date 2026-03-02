import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import 'onboarding_feature_row.dart';

/// Welcome step of progressive onboarding.
///
/// Displays app introduction and key feature highlights.
class ProgressiveWelcomeStep extends StatelessWidget {
  const ProgressiveWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to\nFind My Fourth',
            style: AppTypography.displaySmallSans.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.0,
            ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.sm),
            child: Text(
              'Connect with golfers, join games, and never play alone again.',
              style: AppTypography.bodyLarge,
            ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: const [
                OnboardingFeatureRow(
                  icon: AppPhosphorIcons.golfCourse,
                  title: 'Find games near you',
                  description:
                      'Browse available tee times and join rounds in your area.',
                ),
                OnboardingFeatureRow(
                  icon: AppPhosphorIcons.golfers,
                  title: 'Connect with players',
                  description:
                      'Meet new golfers and build your network on the course.',
                ),
                OnboardingFeatureRow(
                  icon: AppPhosphorIcons.chat,
                  title: 'Group messaging',
                  description:
                      'Coordinate games with built-in chat for every round.',
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
