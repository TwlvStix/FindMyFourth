import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/widgets/app_icon.dart';
import '/models/vibe_profile.dart';
import '/profile/edit_vibes/vibe_category_slider.dart';

/// A single step in the vibe onboarding flow.
///
/// Displays info tip, category slider, and help text.
/// Stateless widget — all state is managed by [VibeProvider].
class VibeOnboardingStep extends StatelessWidget {
  const VibeOnboardingStep({
    super.key,
    required this.category,
    required this.pref,
    required this.onValueChanged,
    required this.onValueCommitted,
    required this.onDealbreakerChanged,
  });

  final VibeCategory category;
  final VibePreference pref;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<int> onValueCommitted;
  final ValueChanged<bool> onDealbreakerChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            opacity: 0.2,
            child: Row(
              children: [
                AppIcon(
                  icon: AppPhosphorIcons.lightbulb,
                  size: AppIconSize.md,
                  color: AppColorsDark.green,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    "We'll match you with golfers on the same wavelength.",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Category slider
          VibeCategorySlider(
            category: category,
            pref: pref,
            onValueChanged: onValueChanged,
            onValueCommitted: onValueCommitted,
            onDealbreakerChanged: onDealbreakerChanged,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Help text
          Text(
            'You can adjust this anytime in your profile settings.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColorsDark.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
