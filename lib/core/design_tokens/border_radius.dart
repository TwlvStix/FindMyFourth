/// "Elevated Country Club Modernism" Border Radius System
///
/// Design Philosophy:
/// Border radius creates visual softness and premium feel while maintaining
/// sophistication. In golf/country club aesthetics, we favor subtle rounding
/// over harsh corners - like the gentle curves of a fairway or the refined
/// edges of premium card stock.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppBorderRadius.md),
///   ),
/// )
/// ```
class AppBorderRadius {
  AppBorderRadius._(); // Private constructor to prevent instantiation

  // ============================================================================
  // BORDER RADIUS SCALE
  // ============================================================================

  /// 2px - Extra extra small - minimal rounding for subtle softness
  /// Usage: Small chips, tags, minimal UI elements
  static const double xxs = 2.0;

  /// 4px - Extra small - tight rounding for compact elements
  /// Usage: Input fields, small buttons, compact components
  static const double xs = 4.0;

  /// 8px - Small - modern, approachable rounding for interactive elements
  /// Usage: Standard buttons, form inputs, action elements
  /// Golf aesthetic: Modern and inviting, like the welcoming clubhouse entrance
  static const double sm = 8.0;

  /// 12px - Medium - premium card rounding for elevated surfaces
  /// Usage: Cards, panels, elevated containers
  /// Golf aesthetic: Subtle elegance, like premium scorecards with refined edges
  static const double md = 12.0;

  /// 16px - Large - prominent rounding for major UI sections
  /// Usage: Large cards, modal dialogs, feature sections
  /// Golf aesthetic: Sophisticated curvature, balancing modern and traditional
  static const double lg = 16.0;

  /// 24px - Extra large - dramatic rounding for hero elements
  /// Usage: Hero cards, special features, prominent containers
  /// Golf aesthetic: Bold yet refined, like the gentle curve of a sand trap
  static const double xl = 24.0;

  /// 999px - Full - pill/circular shape for avatars and badges
  /// Usage: Avatar images, status badges, pill-shaped buttons, circular icons
  /// Golf aesthetic: Perfect circles, like golf balls and tee markers
  static const double full = 999.0;

  // ============================================================================
  // SEMANTIC SHORTCUTS (COMPONENT-SPECIFIC)
  // ============================================================================

  /// Button corner radius - modern and approachable (8px)
  static const double button = sm;

  /// Input field corner radius - clean and functional (8px)
  static const double input = sm;

  /// Card corner radius - premium and elevated (12px)
  static const double card = md;

  /// Modal/Dialog corner radius - prominent but not excessive (16px)
  static const double modal = lg;

  /// Avatar/Badge corner radius - perfect circle (999px)
  static const double avatar = full;

  /// Chip/Tag corner radius - subtle pill shape (999px)
  static const double chip = full;
}
