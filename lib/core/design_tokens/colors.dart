import 'package:flutter/material.dart';

/// "The Clubhouse" Color System — Premium Edition
/// A trust-first golf matchmaking palette
///
/// Color Hierarchy:
/// - GREEN (Primary Accent): All CTAs, active states, Join Game, scores, links
///   Darker, richer "fairway at dusk" greens for premium feel
/// - DEEP TEAL-NAVY (Structural): Headers, card backgrounds, secondary buttons, nav bar
///   Navy with green undertones — masculine, athletic, grounded
/// - GOLD (Secondary Accent — demoted): Trust tiers, achievements, premium
///   Deeper gold used sparingly — accent only, never dominant
/// - NEUTRALS: Cool-tinted darks and refined lights for cohesion
/// - SEMANTIC: Green=success, Gold=warning, plus error and info

class AppColors {
  // ==========================================================================
  // PRIMARY ACCENT — Fairway Green (Every interactive element)
  // Darker, richer greens — "fairway at dusk, not neon grass"
  // ==========================================================================

  /// Dark green - pressed states, deep accents
  static const Color greenDark = Color(0xFF18543E);

  /// Main green - primary CTAs, Join Game, active nav, links
  static const Color green = Color(0xFF1F6B4E);

  /// Light green - hover highlights, score accents, birdie/eagle
  static const Color greenLight = Color(0xFF2E8B68);

  // ==========================================================================
  // STRUCTURAL — Deep Teal-Navy (Headers, cards, navigation, surfaces)
  // Navy with green undertones for depth and groundedness
  // ==========================================================================

  /// Darkest background - app bar backgrounds, deep gradients
  static const Color navyDark = Color(0xFF0E1C26);

  /// Main structural - card headers, secondary buttons, structural fills
  static const Color navy = Color(0xFF142A36);

  /// Light structural - hover accents on navy elements, borders
  static const Color navyLight = Color(0xFF1A2F3A);

  // ==========================================================================
  // SECONDARY ACCENT — Prestige Gold (Tiers, achievements, premium)
  // Deeper gold — accent only, never dominant
  // ==========================================================================

  /// Dark gold - pressed states on gold elements
  static const Color goldDark = Color(0xFF9A7E2A);

  /// Main gold - trust badges, upgrade CTAs, star ratings
  static const Color gold = Color(0xFFC9A24D);

  /// Light gold - hover highlights on gold elements
  static const Color goldLight = Color(0xFFD4B060);

  // ==========================================================================
  // NEUTRALS (Light theme - cool-tinted for cohesion)
  // ==========================================================================

  /// Pure white - card backgrounds
  static const Color pure = Color(0xFFFFFFFF);

  /// Off-white - subtle background variation
  static const Color sand = Color(0xFFF8FAFB);

  /// Light cool grey - page backgrounds
  static const Color cloud = Color(0xFFF2F5F7);

  /// Mid cool grey - borders and dividers
  static const Color mist = Color(0xFFD5DCE1);

  /// Blue-grey - secondary text, icons
  static const Color stone = Color(0xFF7F98A6);

  /// Dark blue-grey - primary body text
  static const Color slate = Color(0xFF556275);

  /// Near black - headings and important text
  static const Color onyx = Color(0xFF141A24);

  // ==========================================================================
  // SEMANTIC COLORS
  // ==========================================================================

  /// Success - reuses green (golf-positive: birdies, confirmations)
  static const Color success = Color(0xFF1F6B4E);

  /// Warning - reuses gold for consistency
  static const Color warning = Color(0xFFC9A24D);

  /// Error red - hazards, failed actions, cancellations
  static const Color error = Color(0xFFD64545);

  /// Info blue - informational messages, tips
  static const Color info = Color(0xFF5B8DBE);

  // ==========================================================================
  // INTERACTION STATES
  // ==========================================================================

  // Green (Primary Actions)
  static const Color greenHovered = Color(0xFF2E8B68);
  static const Color greenPressed = Color(0xFF18543E);

  // Navy (Secondary Actions)
  static const Color navyHovered = Color(0xFF1A2F3A);
  static const Color navyPressed = Color(0xFF0A1219);

  // Gold (Premium Actions)
  static const Color goldHovered = Color(0xFFD4B060);
  static const Color goldPressed = Color(0xFF9A7E2A);

  // Error
  static const Color errorHovered = Color(0xFFE05555);
  static const Color errorPressed = Color(0xFFC03838);

  // Success (mirrors green)
  static const Color successHovered = Color(0xFF2E8B68);
  static const Color successPressed = Color(0xFF18543E);

  // ==========================================================================
  // TRUST TIER PALETTE (Light theme)
  // Platinum = icy cool blue, Gold = warm yellow, Silver = neutral grey,
  // Bronze = rich warm brown, Copper = distinct reddish-rust
  // ==========================================================================

  /// Platinum tier — highest trust (cool blue-silver)
  static const Color trustPlatinumFg = Color(0xFF4A6580);
  static const Color trustPlatinumBg = Color(0xFFE8EDF4);

  /// Gold tier — established trust (warm gold)
  static const Color trustGoldFg = Color(0xFF9A7B1E);
  static const Color trustGoldBg = Color(0xFFFDF5E1);

  /// Silver tier — growing trust (neutral grey)
  static const Color trustSilverFg = Color(0xFF6E7582);
  static const Color trustSilverBg = Color(0xFFEDEEF0);

  /// Bronze tier — early trust (rich warm brown)
  static const Color trustBronzeFg = Color(0xFF7D5520);
  static const Color trustBronzeBg = Color(0xFFF5EDE4);

  /// Copper tier — new/unverified (reddish-rust)
  static const Color trustCopperFg = Color(0xFF8C4432);
  static const Color trustCopperBg = Color(0xFFF2E6DD);

  // ==========================================================================
  // INPUT FIELD TOKENS (Premium contrast for form elements)
  // ==========================================================================

  /// Input field background
  static const Color inputBackground = Color(0xFF1A2F3A);

  /// Input border - idle state
  static const Color inputBorderIdle = Color(0xFF274453);

  /// Input border - focused state (ties back to green accent)
  static const Color inputBorderFocused = Color(0xFF2E8B68);

  // ==========================================================================
  // TEXT HIERARCHY TOKENS (Premium polish — avoid pure white)
  // ==========================================================================

  /// Primary text on dark backgrounds
  static const Color textPrimary = Color(0xFFF2F6F8);

  /// Secondary text on dark backgrounds
  static const Color textSecondary = Color(0xFFA7BCC9);

  /// Muted / helper text on dark backgrounds
  static const Color textMuted = Color(0xFF7F98A6);

  // ==========================================================================
  // GLASS / OVERLAY PRESETS (Pre-computed for performance + consistency)
  // ==========================================================================

  /// Glass border - white at 20% (frosted panel edges)
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Glass surface - white at 10% (frosted card fill)
  static const Color glassSurface = Color(0x1AFFFFFF);

  /// Glass text secondary - white at 70%
  static const Color glassTextSecondary = Color(0xB3FFFFFF);

  /// Glass text tertiary - white at 50%
  static const Color glassTextTertiary = Color(0x80FFFFFF);

  /// Dark overlay - black at 40% (bottom sheet shadows)
  static const Color overlayDark = Color(0x66000000);

  /// Scrim - black at 60% (modal backdrops)
  static const Color scrim = Color(0x99000000);

  // ==========================================================================
  // GRADIENTS
  // ==========================================================================

  /// Navy gradient - structural headers and card tops
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navy],
  );

  /// Green gradient - accent headers, achievement cards
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDark, green, greenLight],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gold gradient - premium/upgrade elements
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [goldDark, gold, goldLight],
    stops: [0.0, 0.5, 1.0],
  );

  /// Subtle overlay gradient for backgrounds (darker anchor at bottom)
  static const LinearGradient subtleOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x1A000000),
    ],
  );

  /// Background gradient - primary screen background with depth
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyDark, navy, Color(0xFF0B1920)],
    stops: [0.0, 0.65, 1.0],
  );
}

// ============================================================================
// DARK THEME (Default theme for The Clubhouse)
// ============================================================================

/// Dark Theme Color Variant
/// Deep teal-navy surfaces with premium green and gold accents
class AppColorsDark {
  // ==========================================================================
  // PRIMARY ACCENT — Fairway Green (Dark)
  // ==========================================================================

  static const Color greenDark = Color(0xFF134232);
  static const Color green = Color(0xFF1F6B4E);
  static const Color greenLight = Color(0xFF2E8B68);

  // ==========================================================================
  // STRUCTURAL — Deep Teal-Navy (Dark)
  // ==========================================================================

  static const Color navyDark = Color(0xFF091318);
  static const Color navy = Color(0xFF0E1C26);
  static const Color navyLight = Color(0xFF142A36);

  // ==========================================================================
  // SECONDARY ACCENT — Prestige Gold (Dark - slightly brighter for dark bg)
  // ==========================================================================

  static const Color goldDark = Color(0xFFB18A3A);
  static const Color gold = Color(0xFFC9A24D);
  static const Color goldLight = Color(0xFFD4B060);

  // ==========================================================================
  // NEUTRALS (Dark theme - teal-navy-tinted dark surfaces)
  // ==========================================================================

  /// Deepest background
  static const Color pure = Color(0xFF091318);

  /// Card background
  static const Color sand = Color(0xFF0E1C26);

  /// Elevated surface (sheets, dialogs)
  static const Color cloud = Color(0xFF142A36);

  /// Borders and dividers
  static const Color mist = Color(0xFF274453);

  /// Secondary text, icons
  static const Color stone = Color(0xFF7F98A6);

  /// Primary body text on dark
  static const Color slate = Color(0xFFA7BCC9);

  /// Headings and important text on dark
  static const Color onyx = Color(0xFFF2F6F8);

  // ==========================================================================
  // SEMANTIC COLORS (Dark - slightly brighter for legibility)
  // ==========================================================================

  static const Color success = Color(0xFF2E8B68);
  static const Color warning = Color(0xFFD4B060);
  static const Color error = Color(0xFFE85555);
  static const Color info = Color(0xFF6B9DCE);

  // ==========================================================================
  // INTERACTION STATES (Dark)
  // ==========================================================================

  // Green (Primary Actions)
  static const Color greenHovered = Color(0xFF2E8B68);
  static const Color greenPressed = Color(0xFF18543E);

  // Navy (Secondary Actions)
  static const Color navyHovered = Color(0xFF1A2F3A);
  static const Color navyPressed = Color(0xFF0A1219);

  // Gold (Premium Actions)
  static const Color goldHovered = Color(0xFFD4B060);
  static const Color goldPressed = Color(0xFFB18A3A);

  // Error
  static const Color errorHovered = Color(0xFFF06565);
  static const Color errorPressed = Color(0xFFD14444);

  // Success (mirrors green)
  static const Color successHovered = Color(0xFF3A9D78);
  static const Color successPressed = Color(0xFF1F6B4E);

  // ==========================================================================
  // TRUST TIER PALETTE (Dark)
  // ==========================================================================

  /// Platinum tier (cool icy blue on dark blue-grey)
  static const Color trustPlatinumFg = Color(0xFF8AACC8);
  static const Color trustPlatinumBg = Color(0xFF132028);

  /// Gold tier (warm gold on dark brown)
  static const Color trustGoldFg = Color(0xFFC9A24D);
  static const Color trustGoldBg = Color(0xFF221E12);

  /// Silver tier (neutral grey on dark grey)
  static const Color trustSilverFg = Color(0xFF8A909A);
  static const Color trustSilverBg = Color(0xFF181C22);

  /// Bronze tier (rich amber on dark warm brown)
  static const Color trustBronzeFg = Color(0xFFC48840);
  static const Color trustBronzeBg = Color(0xFF221A10);

  /// Copper tier (reddish-rust on dark warm)
  static const Color trustCopperFg = Color(0xFFC46650);
  static const Color trustCopperBg = Color(0xFF221612);

  // ==========================================================================
  // INPUT FIELD TOKENS (Dark)
  // ==========================================================================

  static const Color inputBackground = Color(0xFF1A2F3A);
  static const Color inputBorderIdle = Color(0xFF274453);
  static const Color inputBorderFocused = Color(0xFF2E8B68);

  // ==========================================================================
  // TEXT HIERARCHY TOKENS (Dark)
  // ==========================================================================

  static const Color textPrimary = Color(0xFFF2F6F8);
  static const Color textSecondary = Color(0xFFA7BCC9);
  static const Color textMuted = Color(0xFF7F98A6);

  // ==========================================================================
  // GLASS / OVERLAY PRESETS (Dark - lower opacity for dark surfaces)
  // ==========================================================================

  /// Glass border - white at 12%
  static const Color glassBorder = Color(0x1FFFFFFF);

  /// Glass surface - white at 5%
  static const Color glassSurface = Color(0x0DFFFFFF);

  /// Glass text secondary - white at 65%
  static const Color glassTextSecondary = Color(0xA6FFFFFF);

  /// Glass text tertiary - white at 40%
  static const Color glassTextTertiary = Color(0x66FFFFFF);

  /// Dark overlay - black at 50%
  static const Color overlayDark = Color(0x80000000);

  /// Scrim - black at 70%
  static const Color scrim = Color(0xB3000000);

  // ==========================================================================
  // GRADIENTS
  // ==========================================================================

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navy],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenDark, green, greenLight],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [goldDark, gold, goldLight],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyDark, navy, Color(0xFF071018)],
    stops: [0.0, 0.65, 1.0],
  );
}

/// Utility for computing interaction states on arbitrary colors.
/// Use for edge cases not covered by the explicit state tokens above.
class AppColorStates {
  /// Pressed = 15% black overlay
  static Color pressed(Color base) => Color.alphaBlend(
        const Color(0x26000000),
        base,
      );

  /// Hovered = 5% white overlay
  static Color hovered(Color base) => Color.alphaBlend(
        const Color(0x0DFFFFFF),
        base,
      );
}
