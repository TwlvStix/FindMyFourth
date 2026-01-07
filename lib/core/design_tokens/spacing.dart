import 'package:flutter/widgets.dart';

/// Spacing design tokens for "Elevated Country Club Modernism"
///
/// Provides a consistent 8-point grid system with 4px increments for flexibility.
/// All spacing values follow a mathematical scale for visual harmony.
///
/// Usage:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.md),
///   child: Column(
///     spacing: AppSpacing.sm,
///     children: [...],
///   ),
/// )
/// ```
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // ============================================================================
  // BASE SPACING SCALE
  // ============================================================================

  /// 4px - Minimum spacing unit, icon padding, micro adjustments
  static const double xxs = 4.0;

  /// 8px - Tight spacing between closely related elements
  static const double xs = 8.0;

  /// 12px - Compact lists, chip gaps, small component padding
  static const double sm = 12.0;

  /// 16px - Default spacing, comfortable element separation
  static const double md = 16.0;

  /// 20px - Medium-large spacing, comfortable breathing room
  static const double lg = 20.0;

  /// 24px - Section spacing, card padding, list item padding
  static const double xl = 24.0;

  /// 32px - Major section separation, screen margins
  static const double xxl = 32.0;

  /// 48px - Large section breaks, hero padding
  static const double xxxl = 48.0;

  /// 64px - Hero sections, full-screen padding
  static const double xxxxl = 64.0;

  // ============================================================================
  // SEMANTIC SPACING (NAMED PATTERNS)
  // ============================================================================

  /// Spacing between list items (16px)
  static const double listItemGap = md;

  /// Spacing within a list item (12px)
  static const double listItemPadding = sm;

  /// Padding inside cards (20px)
  static const double cardPadding = lg;

  /// Gap between cards (16px)
  static const double cardGap = md;

  /// Padding for buttons (internal spacing)
  static const double buttonPadding = md;

  /// Gap between buttons in a row (12px)
  static const double buttonGap = sm;

  /// Default screen edge padding (20px)
  static const double screenPadding = lg;

  /// Section header spacing (bottom margin)
  static const double sectionHeaderGap = md;

  /// Spacing between form fields (16px)
  static const double formFieldGap = md;

  /// Padding inside form fields (12px)
  static const double formFieldPadding = sm;

  /// Spacing around modals/dialogs (24px)
  static const double modalPadding = xl;

  /// Gap between icon and text (8px)
  static const double iconTextGap = xs;

  /// Chip spacing in chip groups (8px)
  static const double chipGap = xs;

  // ============================================================================
  // EDGE INSETS SHORTCUTS
  // ============================================================================

  /// All sides: 4px
  static const EdgeInsets allXxs = EdgeInsets.all(xxs);

  /// All sides: 8px
  static const EdgeInsets allXs = EdgeInsets.all(xs);

  /// All sides: 12px
  static const EdgeInsets allSm = EdgeInsets.all(sm);

  /// All sides: 16px
  static const EdgeInsets allMd = EdgeInsets.all(md);

  /// All sides: 20px
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  /// All sides: 24px
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  /// All sides: 32px
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  /// All sides: 48px
  static const EdgeInsets allXxxl = EdgeInsets.all(xxxl);

  /// Horizontal: 16px, Vertical: 0
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);

  /// Horizontal: 20px, Vertical: 0
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// Horizontal: 24px, Vertical: 0
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  /// Horizontal: 0, Vertical: 8px
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);

  /// Horizontal: 0, Vertical: 12px
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);

  /// Horizontal: 0, Vertical: 16px
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);

  /// Horizontal: 0, Vertical: 20px
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  /// Horizontal: 0, Vertical: 24px
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  /// Screen padding: Horizontal 20px, Vertical 20px
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: screenPadding,
    vertical: screenPadding,
  );

  /// Screen padding horizontal only: 20px
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );

  /// Screen padding vertical only: 20px
  static const EdgeInsets screenVertical = EdgeInsets.symmetric(
    vertical: screenPadding,
  );

  /// Card padding: 20px all sides
  static const EdgeInsets card = EdgeInsets.all(cardPadding);

  /// Modal/Dialog padding: 24px all sides
  static const EdgeInsets modal = EdgeInsets.all(modalPadding);

  // ============================================================================
  // SIZED BOX SHORTCUTS (For Column/Row spacing)
  // ============================================================================

  /// Vertical spacing: 4px
  static const Widget verticalXxs = SizedBox(height: xxs);

  /// Vertical spacing: 8px
  static const Widget verticalXsBox = SizedBox(height: xs);

  /// Vertical spacing: 12px
  static const Widget verticalSmBox = SizedBox(height: sm);

  /// Vertical spacing: 16px
  static const Widget verticalMdBox = SizedBox(height: md);

  /// Vertical spacing: 20px
  static const Widget verticalLgBox = SizedBox(height: lg);

  /// Vertical spacing: 24px
  static const Widget verticalXlBox = SizedBox(height: xl);

  /// Vertical spacing: 32px
  static const Widget verticalXxlBox = SizedBox(height: xxl);

  /// Vertical spacing: 48px
  static const Widget verticalXxxlBox = SizedBox(height: xxxl);

  /// Horizontal spacing: 4px
  static const Widget horizontalXxs = SizedBox(width: xxs);

  /// Horizontal spacing: 8px
  static const Widget horizontalXsBox = SizedBox(width: xs);

  /// Horizontal spacing: 12px
  static const Widget horizontalSmBox = SizedBox(width: sm);

  /// Horizontal spacing: 16px
  static const Widget horizontalMdBox = SizedBox(width: md);

  /// Horizontal spacing: 20px
  static const Widget horizontalLgBox = SizedBox(width: lg);

  /// Horizontal spacing: 24px
  static const Widget horizontalXlBox = SizedBox(width: xl);

  /// Horizontal spacing: 32px
  static const Widget horizontalXxlBox = SizedBox(width: xxl);

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Create symmetric EdgeInsets
  static EdgeInsets symmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }

  /// Create EdgeInsets with only specified sides
  static EdgeInsets only({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// Create custom vertical spacing widget
  static Widget vertical(double height) => SizedBox(height: height);

  /// Create custom horizontal spacing widget
  static Widget horizontal(double width) => SizedBox(width: width);
}

/// Extension methods for convenient spacing usage
extension SpacingListExtension<T extends Widget> on List<T> {
  /// Add spacing between list items
  ///
  /// Usage:
  /// ```dart
  /// Column(
  ///   children: [
  ///     Widget1(),
  ///     Widget2(),
  ///     Widget3(),
  ///   ].withSpacing(AppSpacing.md),
  /// )
  /// ```
  List<Widget> withSpacing(double spacing) {
    if (isEmpty) return this;

    final result = <Widget>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(SizedBox(height: spacing, width: spacing));
      }
    }
    return result;
  }

  /// Add vertical spacing between list items
  List<Widget> withVerticalSpacing(double spacing) {
    if (isEmpty) return this;

    final result = <Widget>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }

  /// Add horizontal spacing between list items
  List<Widget> withHorizontalSpacing(double spacing) {
    if (isEmpty) return this;

    final result = <Widget>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }
}
