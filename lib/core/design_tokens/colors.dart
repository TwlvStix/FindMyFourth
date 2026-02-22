import 'package:flutter/material.dart';

/// "The Clubhouse" Color System
/// A trust-first golf matchmaking palette
///
/// Color Hierarchy:
/// - GREEN (Primary Accent): All CTAs, active states, Join Game, scores, links
/// - NAVY (Structural): Headers, card backgrounds, secondary buttons, nav bar
/// - GOLD (Secondary Accent): Trust tiers, upgrades, achievements, premium
/// - NEUTRALS: Navy-tinted darks and warm lights for cohesion
/// - SEMANTIC: Green=success, Gold=warning, plus error and info

class AppColors {
  // ==========================================================================
  // PRIMARY ACCENT — Fairway Green (Every interactive element)
  // ==========================================================================

  /// Dark green - pressed states, deep accents
  static const Color greenDark = Color(0xFF2B7050);

  /// Main green - primary CTAs, Join Game, active nav, links
  static const Color green = Color(0xFF3A8F65);

  /// Light green - hover highlights, score accents, birdie/eagle
  static const Color greenLight = Color(0xFF4EAD7E);

  // ==========================================================================
  // STRUCTURAL — Club Navy (Headers, cards, navigation, surfaces)
  // ==========================================================================

  /// Darkest navy - app bar backgrounds, deep gradients
  static const Color navyDark = Color(0xFF0F1C30);

  /// Main navy - card headers, secondary buttons, structural fills
  static const Color navy = Color(0xFF1B2E4A);

  /// Light navy - hover accents on navy elements, borders
  static const Color navyLight = Color(0xFF2B4A72);

  // ==========================================================================
  // SECONDARY ACCENT — Prestige Gold (Tiers, achievements, premium)
  // ==========================================================================

  /// Dark gold - pressed states on gold elements
  static const Color goldDark = Color(0xFFA6832F);

  /// Main gold - trust badges, upgrade CTAs, star ratings
  static const Color gold = Color(0xFFC49A3D);

  /// Light gold - hover highlights on gold elements
  static const Color goldLight = Color(0xFFD4A84B);

  // ==========================================================================
  // NEUTRALS (Light theme - warm-tinted for cohesion with gold)
  // ==========================================================================

  /// Pure white - card backgrounds
  static const Color pure = Color(0xFFFFFFFF);

  /// Off-white - subtle background variation
  static const Color sand = Color(0xFFFAF9F6);

  /// Light warm grey - page backgrounds
  static const Color cloud = Color(0xFFF4F2EE);

  /// Mid warm grey - borders and dividers
  static const Color mist = Color(0xFFDDD8D0);

  /// Blue-grey - secondary text, icons
  static const Color stone = Color(0xFF8694A8);

  /// Dark blue-grey - primary body text
  static const Color slate = Color(0xFF556275);

  /// Near black - headings and important text
  static const Color onyx = Color(0xFF141A24);

  // ==========================================================================
  // SEMANTIC COLORS
  // ==========================================================================

  /// Success - reuses green (golf-positive: birdies, confirmations)
  static const Color success = Color(0xFF3A8F65);

  /// Warning - reuses gold for consistency
  static const Color warning = Color(0xFFC49A3D);

  /// Error red - hazards, failed actions, cancellations
  static const Color error = Color(0xFFD64545);

  /// Info blue - informational messages, tips
  static const Color info = Color(0xFF5B8DBE);

  // ==========================================================================
  // INTERACTION STATES
  // ==========================================================================

  // Green (Primary Actions)
  static const Color greenHovered = Color(0xFF48A478);
  static const Color greenPressed = Color(0xFF2F7A55);

  // Navy (Secondary Actions)
  static const Color navyHovered = Color(0xFF243D62);
  static const Color navyPressed = Color(0xFF142338);

  // Gold (Premium Actions)
  static const Color goldHovered = Color(0xFFD4AA52);
  static const Color goldPressed = Color(0xFFB08A32);

  // Error
  static const Color errorHovered = Color(0xFFE05555);
  static const Color errorPressed = Color(0xFFC03838);

  // Success (mirrors green)
  static const Color successHovered = Color(0xFF48A478);
  static const Color successPressed = Color(0xFF2F7A55);

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

  /// Subtle overlay gradient for backgrounds
  static const LinearGradient subtleOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x1A000000),
    ],
  );
}

// ============================================================================
// DARK THEME (Default theme for The Clubhouse)
// ============================================================================

/// Dark Theme Color Variant
/// Navy-tinted dark surfaces with adjusted accents for dark backgrounds
class AppColorsDark {
  // ==========================================================================
  // PRIMARY ACCENT — Fairway Green (Dark)
  // ==========================================================================

  static const Color greenDark = Color(0xFF246145);
  static const Color green = Color(0xFF3A8F65);
  static const Color greenLight = Color(0xFF4EAD7E);

  // ==========================================================================
  // STRUCTURAL — Club Navy (Dark)
  // ==========================================================================

  static const Color navyDark = Color(0xFF0A1220);
  static const Color navy = Color(0xFF1B2E4A);
  static const Color navyLight = Color(0xFF2B4A72);

  // ==========================================================================
  // SECONDARY ACCENT — Prestige Gold (Dark - slightly brighter for dark bg)
  // ==========================================================================

  static const Color goldDark = Color(0xFFB8923E);
  static const Color gold = Color(0xFFD4A84B);
  static const Color goldLight = Color(0xFFE0BD6A);

  // ==========================================================================
  // NEUTRALS (Dark theme - navy-tinted dark surfaces)
  // ==========================================================================

  /// Deepest background
  static const Color pure = Color(0xFF0C1018);

  /// Card background
  static const Color sand = Color(0xFF141A24);

  /// Elevated surface (sheets, dialogs)
  static const Color cloud = Color(0xFF1B2230);

  /// Borders and dividers
  static const Color mist = Color(0xFF253042);

  /// Secondary text, icons
  static const Color stone = Color(0xFF556275);

  /// Primary body text on dark
  static const Color slate = Color(0xFF8694A8);

  /// Headings and important text on dark
  static const Color onyx = Color(0xFFE8ECF2);

  // ==========================================================================
  // SEMANTIC COLORS (Dark - slightly brighter for legibility)
  // ==========================================================================

  static const Color success = Color(0xFF4EAD7E);
  static const Color warning = Color(0xFFD4A84B);
  static const Color error = Color(0xFFE85555);
  static const Color info = Color(0xFF6B9DCE);

  // ==========================================================================
  // INTERACTION STATES (Dark)
  // ==========================================================================

  // Green (Primary Actions)
  static const Color greenHovered = Color(0xFF48A478);
  static const Color greenPressed = Color(0xFF2F7A55);

  // Navy (Secondary Actions)
  static const Color navyHovered = Color(0xFF243D62);
  static const Color navyPressed = Color(0xFF142338);

  // Gold (Premium Actions)
  static const Color goldHovered = Color(0xFFE0BD6A);
  static const Color goldPressed = Color(0xFFC09540);

  // Error
  static const Color errorHovered = Color(0xFFF06565);
  static const Color errorPressed = Color(0xFFD14444);

  // Success (mirrors green)
  static const Color successHovered = Color(0xFF5EC08E);
  static const Color successPressed = Color(0xFF3F9A6C);

  // ==========================================================================
  // TRUST TIER PALETTE (Dark)
  // Platinum = icy blue, Gold = warm gold, Silver = neutral grey,
  // Bronze = rich amber, Copper = distinct reddish
  // ==========================================================================

  /// Platinum tier (cool icy blue on dark blue-grey)
  static const Color trustPlatinumFg = Color(0xFF8AACC8);
  static const Color trustPlatinumBg = Color(0xFF1A2535);

  /// Gold tier (warm gold on dark brown)
  static const Color trustGoldFg = Color(0xFFD4A84B);
  static const Color trustGoldBg = Color(0xFF2A2418);

  /// Silver tier (neutral grey on dark grey)
  static const Color trustSilverFg = Color(0xFF8A909A);
  static const Color trustSilverBg = Color(0xFF20242A);

  /// Bronze tier (rich amber on dark warm brown)
  static const Color trustBronzeFg = Color(0xFFC48840);
  static const Color trustBronzeBg = Color(0xFF2A2015);

  /// Copper tier (reddish-rust on dark warm)
  static const Color trustCopperFg = Color(0xFFC46650);
  static const Color trustCopperBg = Color(0xFF2A1C18);

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
