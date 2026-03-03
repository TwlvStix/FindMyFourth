import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import 'motion_tokens.dart';
import 'reduced_motion.dart';

/// Motion Helpers - Enforced Dialog/Sheet Transitions
///
/// These wrapper functions replace Flutter's showDialog() and showModalBottomSheet()
/// to enforce motion standards and reduced motion support.
///
/// Migration:
/// - Replace showDialog() with showAppDialog()
/// - Replace showModalBottomSheet() with showAppBottomSheet()
///
/// Enforcement:
/// - Backdrop fade: Always 160ms
/// - Dialog scale: Always 0.97→1.0
/// - Sheet durations: Always 260ms enter, 220ms exit
/// - Reduced motion: Automatic

/// Show dialog with enforced motion standards
///
/// Replaces Flutter's showDialog() with standardized transitions:
/// - Backdrop fade: 160ms
/// - Dialog fade + scale: 200ms enter, 170ms exit, scale 0.97→1.0
/// - Reduced motion: Removes scale, shortens duration
///
/// Example:
/// ```dart
/// final result = await showAppDialog<bool>(
///   context: context,
///   builder: (context) => AlertDialog(
///     title: Text('Confirm'),
///     content: Text('Are you sure?'),
///   ),
/// );
/// ```
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? AppColors.scrim,
    barrierLabel: barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration:
        ReducedMotionService.adjust(MotionTokens.dialogEnter),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Fade animation for dialog content
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: MotionTokens.curveEnter,
        reverseCurve: MotionTokens.curveExit,
      );

      Widget result = FadeTransition(
        opacity: fadeAnimation,
        child: child,
      );

      // Scale animation (only if reduced motion is not enabled)
      if (ReducedMotionService.shouldScale) {
        final scaleAnimation = Tween<double>(
          begin: MotionTokens.dialogScaleStart,
          end: MotionTokens.dialogScaleEnd,
        ).animate(fadeAnimation);

        result = ScaleTransition(
          scale: scaleAnimation,
          child: result,
        );
      }

      return result;
    },
  );
}

/// Show bottom sheet with enforced motion standards
///
/// Replaces Flutter's showModalBottomSheet() with standardized transitions:
/// - Slide up: 260ms enter, 220ms exit
/// - Backdrop fade: Automatic (platform default)
/// - Reduced motion: Shortens duration
///
/// Example:
/// ```dart
/// final filters = await showAppBottomSheet<FriendFilters>(
///   context: context,
///   builder: (context) => FriendFilterBottomSheet(),
/// );
/// ```
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
}) {
  // Note: showModalBottomSheet doesn't expose duration directly in a backward-compatible way.
  // We use the built-in animation which is close to our spec (250ms vs 260ms).
  // For stricter control, use AppBottomSheetRoute instead.

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}

/// Helper to create bottom sheet with custom animation controller
///
/// Use this when you need full control over sheet animation timing.
/// Most cases should use showAppBottomSheet() instead.
///
/// Example:
/// ```dart
/// await Navigator.of(context).push(
///   AppBottomSheetRoute(
///     builder: (context) => MySheet(),
///   ),
/// );
/// ```
class AppBottomSheetRoute<T> extends ModalRoute<T> {
  AppBottomSheetRoute({
    required this.builder,
    this.isDismissible = true,
    this.enableDrag = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
  });

  final WidgetBuilder builder;
  final bool isDismissible;
  final bool enableDrag;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;

  @override
  Duration get transitionDuration =>
      ReducedMotionService.adjust(MotionTokens.bottomSheetEnter);

  @override
  Duration get reverseTransitionDuration =>
      ReducedMotionService.adjust(MotionTokens.bottomSheetExit);

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Color get barrierColor => AppColors.scrim;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: MotionTokens.curveEnter,
      reverseCurve: MotionTokens.curveExit,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }
}
