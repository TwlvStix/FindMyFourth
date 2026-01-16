/// "Elevated Country Club Modernism" Opacity System
///
/// Design Philosophy:
/// Opacity creates layering, hierarchy, and visual subtlety. In golf/country club
/// aesthetics, we use transparency to suggest depth, create overlays, and indicate
/// disabled states - like the soft haze of morning fog rolling across the fairway
/// or the translucent glass of the clubhouse windows.
///
/// Usage:
/// ```dart
/// Container(
///   color: AppColors.onyx.withOpacity(AppOpacity.medium),
/// )
/// ```
class AppOpacity {
  AppOpacity._(); // Private constructor to prevent instantiation

  // ============================================================================
  // OPACITY SCALE
  // ============================================================================

  /// 5% opacity - barely visible, subtle background tints
  /// Usage: Hover state backgrounds, extremely subtle overlays
  static const double subtle = 0.05;

  /// 10% opacity - light transparency for delicate effects
  /// Usage: Glass effects, light overlays, subtle backgrounds
  /// Golf aesthetic: Morning mist on the fairway
  static const double light = 0.10;

  /// 20% opacity - medium transparency for disabled states
  /// Usage: Disabled text/icons, secondary overlays, subtle dividers
  /// Golf aesthetic: Faded yardage markers in the distance
  static const double medium = 0.20;

  /// 40% opacity - strong transparency for clear indication
  /// Usage: Modal overlays, prominent disabled states, strong backgrounds
  /// Golf aesthetic: Shaded rest area canopy
  static const double strong = 0.40;

  /// 60% opacity - prominent but still translucent
  /// Usage: Semi-transparent panels, loading overlays, emphasized backgrounds
  /// Golf aesthetic: Clubhouse windows reflecting the course
  static const double prominent = 0.60;

  /// 80% opacity - almost opaque, minimal transparency
  /// Usage: Heavy overlays, near-solid backgrounds, strong emphasis
  /// Golf aesthetic: Thick tournament gallery ropes
  static const double heavy = 0.80;

  // ============================================================================
  // SEMANTIC SHORTCUTS (USE CASE-SPECIFIC)
  // ============================================================================

  /// Disabled state opacity - clear indication of non-interactive elements
  static const double disabled = medium;

  /// Overlay opacity - modal/drawer backgrounds
  static const double overlay = strong;

  /// Hover state opacity - subtle interactive feedback
  static const double hover = subtle;

  /// Glass effect opacity - translucent surfaces
  static const double glass = light;

  /// Loading overlay opacity - semi-transparent loading states
  static const double loading = prominent;
}
