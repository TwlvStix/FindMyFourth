/// "Elevated Country Club Modernism" Icon Size System
///
/// Design Philosophy:
/// Icon sizing creates visual rhythm and hierarchy. In golf/country club aesthetics,
/// icons should be crisp and readable without overwhelming - like the precise symbols
/// on a scorecard or the elegant directional markers around the clubhouse.
///
/// Our sizes ensure touch targets meet accessibility standards (minimum 48px interactive
/// area) while maintaining visual balance.
///
/// Usage:
/// ```dart
/// Icon(
///   Icons.golf_course,
///   size: AppIconSize.md,
/// )
/// ```
class AppIconSize {
  AppIconSize._(); // Private constructor to prevent instantiation

  // ============================================================================
  // ICON SIZE SCALE
  // ============================================================================

  /// 16px - Extra small icons for tight UI spaces
  /// Usage: Inline text icons, compact chips, dense tables
  static const double xs = 16.0;

  /// 20px - Small icons for compact components
  /// Usage: List item icons, form field icons, compact buttons
  static const double sm = 20.0;

  /// 24px - Standard icon size for general UI
  /// Usage: Navigation icons, default buttons, standard list items
  /// Golf aesthetic: Clear and readable like scorecard symbols
  static const double md = 24.0;

  /// 32px - Large icons for prominent sections
  /// Usage: Section headers, feature cards, prominent buttons
  /// Golf aesthetic: Bold directional markers around the clubhouse
  static const double lg = 32.0;

  /// 40px - Extra large icons for hero elements
  /// Usage: Feature icons, hero sections, splash screens
  /// Golf aesthetic: Commanding presence like the club logo
  static const double xl = 40.0;

  /// 48px - Extra extra large icons for major features
  /// Usage: App icons, major feature illustrations, hero graphics
  /// Golf aesthetic: Tournament trophy display
  static const double xxl = 48.0;

  // ============================================================================
  // SEMANTIC SHORTCUTS (COMPONENT-SPECIFIC)
  // ============================================================================

  /// Navigation bar icon size - standard for bottom/side nav
  static const double nav = md;

  /// Button icon size - balanced for buttons
  static const double button = sm;

  /// List item icon size - comfortable for list items
  static const double listItem = md;

  /// Section header icon size - prominent for section markers
  static const double section = lg;

  /// Feature icon size - hero features and major elements
  static const double feature = xl;

  /// Avatar icon size - profile pictures and user icons
  static const double avatar = xxl;
}
