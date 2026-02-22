import 'package:flutter/material.dart';

/// "Elevated Country Club Modernism" Elevation System
///
/// Design Philosophy:
/// Elevation creates visual hierarchy and depth through shadows. In golf/country
/// club aesthetics, elevation signals importance and premium quality - like how
/// the clubhouse sits elevated above the fairways, or how scorecards are presented
/// on raised surfaces.
///
/// Our shadows are subtle and refined, never harsh. We use soft, natural shadows
/// that suggest depth without overwhelming. Special glows (gold, green) add
/// premium accent for key moments.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: [AppElevation.md],
///   ),
/// )
/// ```
class AppElevation {
  AppElevation._(); // Private constructor to prevent instantiation

  // ============================================================================
  // STANDARD ELEVATION LEVELS
  // ============================================================================

  /// No elevation - completely flat surface
  /// Usage: Backgrounds, embedded content, zero-depth elements
  static const BoxShadow none = BoxShadow(
    color: Colors.transparent,
    blurRadius: 0,
    offset: Offset(0, 0),
  );

  /// Extra small elevation - barely-there lift
  /// Usage: Hover states, subtle separation, delicate components
  /// Shadow: offset (0, 1), blur 2, opacity 0.08
  static const BoxShadow xs = BoxShadow(
    color: Color(0x141C1C16), // onyx with 0.08 opacity
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  /// Small elevation - standard card depth
  /// Usage: Cards, tiles, list items, default elevated surfaces
  /// Shadow: offset (0, 2), blur 4, opacity 0.10
  /// Golf aesthetic: Like scorecards resting on a table
  static const BoxShadow sm = BoxShadow(
    color: Color(0x1A1C1C16), // onyx with 0.10 opacity
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  /// Medium elevation - elevated cards and panels
  /// Usage: Prominent cards, raised panels, important containers
  /// Shadow: offset (0, 4), blur 8, opacity 0.12
  /// Golf aesthetic: Premium yardage books with substantial presence
  static const BoxShadow md = BoxShadow(
    color: Color(0x1F1C1C16), // onyx with 0.12 opacity
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  /// Large elevation - floating panels
  /// Usage: Dropdown menus, popovers, floating action buttons
  /// Shadow: offset (0, 8), blur 16, opacity 0.15
  /// Golf aesthetic: Menu boards floating above the pro shop counter
  static const BoxShadow lg = BoxShadow(
    color: Color(0x261C1C16), // onyx with 0.15 opacity
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  /// Extra large elevation - modals and major overlays
  /// Usage: Modal dialogs, drawers, overlays, critical UI
  /// Shadow: offset (0, 12), blur 24, opacity 0.18
  /// Golf aesthetic: Championship trophy display case - commanding presence
  static const BoxShadow xl = BoxShadow(
    color: Color(0x2E1C1C16), // onyx with 0.18 opacity
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  // ============================================================================
  // SPECIALTY GLOWS (COLORED SHADOWS FOR PREMIUM ACCENTS)
  // ============================================================================

  /// Green glow - primary accent shadow for golf/active elements
  /// Usage: Success states, active selections, CTAs, achievements, golf elements
  /// Shadow: offset (0, 4), blur 12, color: green with 0.30 opacity
  /// Golf aesthetic: The rich green glow of a pristine fairway at dusk
  static const BoxShadow glowGreen = BoxShadow(
    color: Color(0x4D1F6B4E), // AppColors.green (#1F6B4E) with 0.30 opacity
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  /// Gold glow - secondary accent shadow for trust/premium elements
  /// Usage: Trust badges, premium features, achievements (use sparingly)
  /// Shadow: offset (0, 4), blur 12, color: gold with 0.25 opacity
  /// Golf aesthetic: Subtle prestige accent, never dominant
  static const BoxShadow glowGold = BoxShadow(
    color: Color(0x40C9A24D), // AppColors.gold (#C9A24D) with 0.25 opacity
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // ============================================================================
  // SEMANTIC SHORTCUTS (COMPONENT-SPECIFIC)
  // ============================================================================

  /// Button shadow - subtle elevation for interactive elements (sm)
  static const BoxShadow button = sm;

  /// Card shadow - standard card elevation (sm)
  static const BoxShadow card = sm;

  /// Modal shadow - prominent overlay elevation (xl)
  static const BoxShadow modal = xl;

  /// Dropdown shadow - floating menu elevation (lg)
  static const BoxShadow dropdown = lg;

  /// Tooltip shadow - small floating element (md)
  static const BoxShadow tooltip = md;
}
