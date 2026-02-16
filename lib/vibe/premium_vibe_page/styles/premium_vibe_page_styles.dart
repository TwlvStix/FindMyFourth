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

  /// Strength chip decoration - soft green with subtle border
  static BoxDecoration get strengthChipDecoration => BoxDecoration(
        color: AppColors.fairwayLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.fairway.withOpacity(0.3),
          width: 1,
        ),
      );

  /// Watch point card decoration - warm background with light border
  static BoxDecoration get watchPointCardDecoration => BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.cloud,
          width: 1,
        ),
      );

  /// Dealbreaker watch point card - emphasizes severity with warm accent
  static BoxDecoration get dealbreakerCardDecoration => BoxDecoration(
        color: AppColors.sunsetRose.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.sunsetRose.withOpacity(0.3),
          width: 1,
        ),
      );

  /// Primary archetype card (current user) - green accent
  static BoxDecoration get archetypeCardPrimary => BoxDecoration(
        color: AppColors.fairwayLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.fairway.withOpacity(0.25),
          width: 1,
        ),
      );

  /// Secondary archetype card (matched user) - neutral
  static BoxDecoration get archetypeCardSecondary => BoxDecoration(
        color: AppColors.sand.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.cloud,
          width: 1,
        ),
      );

  /// Breakdown section background
  static BoxDecoration get breakdownSectionDecoration => const BoxDecoration(
        color: AppColors.pure,
      );

  // ============================================================================
  // COLORS
  // ============================================================================

  /// Hero score color - primary dark green
  static const Color heroScoreColor = AppColors.fairwayDark;

  /// Verdict text color - muted secondary
  static const Color verdictTextColor = AppColors.slate;

  /// Section title color - strong onyx
  static const Color sectionTitleColor = AppColors.onyx;

  /// Aligned category icon color
  static const Color alignedIconColor = AppColors.fairway;

  /// Watch point icon color
  static const Color watchPointIconColor = AppColors.stone;

  /// Dealbreaker icon color
  static const Color dealbreakerIconColor = AppColors.error;

  /// "You" spectrum dot color
  static const Color youDotColor = AppColors.fairwayDark;

  /// "Them" spectrum dot color
  static const Color themDotColor = AppColors.slate;

  /// Spectrum bar background color
  static const Color spectrumBarColor = AppColors.cloud;

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
