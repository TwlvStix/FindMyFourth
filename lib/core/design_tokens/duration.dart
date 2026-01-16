/// "Elevated Country Club Modernism" Animation Duration System
///
/// Design Philosophy:
/// Animation timing creates smoothness and polish. In golf/country club aesthetics,
/// animations should feel refined and purposeful - never rushed or sluggish. Like
/// the smooth swing of a professional golfer or the graceful arc of a ball flight.
///
/// Our durations follow Material Design motion principles with a bias toward
/// slightly faster transitions for modern, responsive feel.
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: AppDuration.normal,
///   curve: Curves.easeOut,
/// )
/// ```
class AppDuration {
  AppDuration._(); // Private constructor to prevent instantiation

  // ============================================================================
  // DURATION SCALE
  // ============================================================================

  /// 50ms - Instant feedback, barely perceptible
  /// Usage: Hover state changes, focus ring appearance, micro-interactions
  /// Golf aesthetic: The instant click of a perfect putt
  static const Duration instant = Duration(milliseconds: 50);

  /// 150ms - Fast animations for immediate feedback
  /// Usage: Button presses, checkbox toggles, switch flips, ripple effects
  /// Golf aesthetic: The quick snap of a chip shot
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms - Normal speed for most UI transitions
  /// Usage: Page transitions, modal appearances, drawer slides, expansions
  /// Golf aesthetic: The smooth tempo of a driver swing
  static const Duration normal = Duration(milliseconds: 250);

  /// 400ms - Slower animations for major changes
  /// Usage: Loading states, complex transitions, multi-step animations
  /// Golf aesthetic: The graceful arc of a long iron shot
  static const Duration slow = Duration(milliseconds: 400);

  // ============================================================================
  // SEMANTIC SHORTCUTS (USE CASE-SPECIFIC)
  // ============================================================================

  /// Hover duration - quick feedback for hover states
  static const Duration hover = instant;

  /// Button duration - snappy button press animations
  static const Duration button = fast;

  /// Page transition duration - smooth page changes
  static const Duration pageTransition = normal;

  /// Modal duration - balanced modal appearance/dismissal
  static const Duration modal = normal;

  /// Loading duration - patient loading state animations
  static const Duration loading = slow;

  /// Expansion duration - accordion/expansion panel animations
  static const Duration expansion = normal;
}
