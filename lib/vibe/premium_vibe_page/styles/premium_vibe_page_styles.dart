import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/border_radius.dart';
import 'package:find_my_fourth/core/design_tokens/colors.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';

/// Style constants for the Premium Vibe Page.
///
/// Provides reusable decorations, colors, and spacing for consistent styling
/// across all components of the premium vibe match experience.
class PremiumVibePageStyles {
  PremiumVibePageStyles._(); // Private constructor to prevent instantiation

  // ============================================================================
  // SECTION PADDING
  // ============================================================================

  /// Standard padding for most sections
  static const EdgeInsets sectionPadding = AppSpacing.allLg;

  /// Medium padding for compact sections
  static const EdgeInsets sectionPaddingMedium = AppSpacing.allMd;

  /// Horizontal-only padding for full-width sections
  static const EdgeInsets sectionPaddingHorizontal = AppSpacing.horizontalLg;

  // ============================================================================
  // CARD DECORATIONS
  // ============================================================================

  /// Strength chip decoration - navy background with subtle border for dark theme
  static BoxDecoration get strengthChipDecoration => BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      );

  /// Watch point card decoration - navy background for dark theme
  static BoxDecoration get watchPointCardDecoration => BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      );

  /// Dealbreaker watch point card - error tint on dark base
  static BoxDecoration get dealbreakerCardDecoration => BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1,
        ),
      );

  /// Primary archetype card (current user) - navy background with green accent border
  static BoxDecoration get archetypeCardPrimary => BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.4),
          width: 1,
        ),
      );

  /// Secondary archetype card (matched user) - navy background
  static BoxDecoration get archetypeCardSecondary => BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      );

  /// Breakdown section background
  static BoxDecoration get breakdownSectionDecoration => const BoxDecoration(
        color: AppColors.navyDark,
      );

  // ============================================================================
  // COLORS (Dark theme)
  // ============================================================================

  /// Hero score color - light text on dark background
  static const Color heroScoreColor = AppColors.textPrimary;

  /// Verdict text color - secondary text for dark theme
  static const Color verdictTextColor = AppColors.textSecondary;

  /// Section title color - primary text for dark theme
  static const Color sectionTitleColor = AppColors.textPrimary;

  /// Aligned category icon color - green accent for success
  static const Color alignedIconColor = AppColors.green;

  /// Watch point icon color - muted for dark theme
  static const Color watchPointIconColor = AppColors.textMuted;

  /// Dealbreaker icon color
  static const Color dealbreakerIconColor = AppColors.error;

  /// "You" spectrum dot color - green accent
  static const Color youDotColor = AppColors.green;

  /// "Them" spectrum dot color - secondary text
  static const Color themDotColor = AppColors.textSecondary;

  /// Spectrum bar background color - navy light for dark theme
  static const Color spectrumBarColor = AppColors.navyLight;

  // ============================================================================
  // SPACING
  // ============================================================================

  /// Spacing between major sections
  static const double sectionSpacing = AppSpacing.xxl;

  /// Spacing between watch point cards
  static const double watchPointCardSpacing = AppSpacing.sm;

  /// Spacing between categories in full breakdown
  static const double categoryBreakdownSpacing = AppSpacing.xl;

  /// Internal padding for watch point cards
  static const EdgeInsets watchPointCardPadding = AppSpacing.allSm;

  /// Internal padding for archetype cards
  static const EdgeInsets archetypeCardPadding = AppSpacing.allSm;

  /// Chip padding (horizontal + vertical)
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Small icon size for chips
  static const double chipIconSize = 14.0;

  /// Medium icon size for watch points
  static const double watchPointIconSize = 18.0;

  /// Chevron icon size for expand/collapse
  static const double chevronIconSize = 24.0;

  // ============================================================================
  // TEXT STYLES
  // ============================================================================
  // Note: These are helpers/guidelines. Actual styles should use Theme.of(context).textTheme
  // with color/weight overrides as needed.

  /// Hero score should use displayLarge with heroScoreColor
  static const FontWeight heroScoreFontWeight = FontWeight.bold;

  /// Verdict text should use bodyLarge with verdictTextColor
  static const double verdictLineHeight = 1.4;

  /// Section titles should use titleSmall with sectionTitleColor
  static const FontWeight sectionTitleFontWeight = FontWeight.w600;

  /// Watch point category name font weight
  static const FontWeight watchPointNameFontWeight = FontWeight.w600;
}
