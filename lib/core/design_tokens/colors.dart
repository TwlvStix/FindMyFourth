import 'package:flutter/material.dart';

/// "Fairway Sunset" Color System
/// A golf-inspired palette blending deep forest greens with warm sunset accents
///
/// Design Philosophy:
/// - PRIMARY: Deep forest greens evoke golf fairways and natural landscapes
/// - ACCENT: Sunset glow colors (gold, peach, rose) add warmth and energy
/// - NEUTRALS: Crisp, clean whites and warm greys for readability
/// - SEMANTIC: Clear meaning for success, warning, error states

class AppColors {
  // PRIMARY PALETTE - Deep Forest Greens (Golf Fairways)
  /// Deep forest green - primary dark color for headers and emphasis
  static const Color fairwayDark = Color(0xFF1B3A2F);

  /// Rich green - main brand color
  static const Color fairway = Color(0xFF2D5F4C);

  /// Lighter green - for hover states and accents
  static const Color fairwayLight = Color(0xFF4A8B6F);

  // ACCENT - Sunset Glow (Golden Hour on the Course)
  /// Warm gold - primary accent for CTAs and highlights
  static const Color sunsetGold = Color(0xFFE8B44C);

  /// Soft peach - secondary accent
  static const Color sunsetPeach = Color(0xFFE89E71);

  /// Muted coral/rose - tertiary accent
  static const Color sunsetRose = Color(0xFFD97D70);

  // NEUTRALS - Crisp & Clean (Golf Ball White + Sand Traps)
  /// Off-white - not harsh pure white, warmer for backgrounds
  static const Color pure = Color(0xFFFFFEFA);

  /// Warm neutral - subtle background variation
  static const Color sand = Color(0xFFF4F1E8);

  /// Light grey - borders and dividers
  static const Color cloud = Color(0xFFE5E3DA);

  /// Mid grey - secondary text
  static const Color stone = Color(0xFF9B9A91);

  /// Dark grey - primary text on light backgrounds
  static const Color slate = Color(0xFF4A4A42);

  /// Near black - headings and important text
  static const Color onyx = Color(0xFF1C1C16);

  // SEMANTIC COLORS
  /// Success green - birdies, successful actions
  static const Color success = Color(0xFF3FA876);

  /// Warning - same as sunset gold for consistency
  static const Color warning = Color(0xFFE8B44C);

  /// Error red - hazards, failed actions
  static const Color error = Color(0xFFD64545);

  /// Info blue - water hazards, informational messages
  static const Color info = Color(0xFF5B8DBE);

  // GRADIENTS & MESHES
  /// Fairway gradient - dark to light green
  static const LinearGradient fairwayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fairwayDark, fairway, fairwayLight],
    stops: [0.0, 0.5, 1.0],
  );

  /// Sunset gradient - warm accent colors
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [sunsetGold, sunsetPeach, sunsetRose],
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

/// Dark Theme Color Variant
/// Inverted palette for dark mode support
class AppColorsDark {
  // PRIMARY PALETTE (Darker variants)
  static const Color fairwayDark = Color(0xFF0F1F19);
  static const Color fairway = Color(0xFF1B3A2F);
  static const Color fairwayLight = Color(0xFF2D5F4C);

  // ACCENT (Slightly muted for dark backgrounds)
  static const Color sunsetGold = Color(0xFFDBA943);
  static const Color sunsetPeach = Color(0xFFD98F68);
  static const Color sunsetRose = Color(0xFFCE7166);

  // NEUTRALS (Inverted)
  static const Color pure = Color(0xFF1C1C16);
  static const Color sand = Color(0xFF2A2A24);
  static const Color cloud = Color(0xFF3A3A32);
  static const Color stone = Color(0xFF9B9A91);
  static const Color slate = Color(0xFFE5E3DA);
  static const Color onyx = Color(0xFFFFFEFA);

  // SEMANTIC COLORS (Adjusted for dark backgrounds)
  static const Color success = Color(0xFF4DB887);
  static const Color warning = Color(0xFFDBA943);
  static const Color error = Color(0xFFE85555);
  static const Color info = Color(0xFF6B9DCE);

  // GRADIENTS
  static const LinearGradient fairwayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fairwayDark, fairway, fairwayLight],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [sunsetGold, sunsetPeach, sunsetRose],
    stops: [0.0, 0.5, 1.0],
  );
}
