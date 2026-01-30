import 'package:flutter/widgets.dart';
import 'motion_tokens.dart';

/// Reduced Motion Service - Accessibility Support
///
/// Detects platform-level reduced motion preference and applies motion adjustments.
/// All animations should respect reduced motion by calling adjust() or checking flags.
///
/// Platform Detection:
/// - iOS: Settings > Accessibility > Motion > Reduce Motion
/// - Android: Settings > Accessibility > Remove animations
///
/// Adjustments Applied:
/// - Durations reduced by ~35% (faster completion)
/// - All scale animations disabled
/// - All stagger animations disabled
/// - Fades still work (essential for readability)
class ReducedMotionService {
  ReducedMotionService._(); // Static class, prevent instantiation

  /// Check if reduced motion is enabled on the platform
  ///
  /// Returns true if user has enabled reduce motion in system settings.
  /// Always check this before applying motion effects.
  static bool get isEnabled {
    final window = WidgetsBinding.instance.platformDispatcher;
    return window.accessibilityFeatures.reduceMotion;
  }

  /// Adjust duration based on reduced motion setting
  ///
  /// If reduced motion is enabled, returns duration scaled down by 35%.
  /// Otherwise, returns original duration.
  ///
  /// Example:
  /// ```dart
  /// AnimationController(
  ///   duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
  ///   vsync: this,
  /// );
  /// ```
  static Duration adjust(Duration original) {
    if (!isEnabled) return original;

    return Duration(
      milliseconds:
          (original.inMilliseconds * MotionTokens.reducedMotionDurationScale)
              .round(),
    );
  }

  /// Whether stagger animations should be applied
  ///
  /// Returns false if reduced motion is enabled (disables stagger).
  /// Check this before applying stagger delays.
  ///
  /// Example:
  /// ```dart
  /// if (ReducedMotionService.shouldStagger) {
  ///   // Apply stagger animation
  /// }
  /// ```
  static bool get shouldStagger => !isEnabled;

  /// Whether scale animations should be applied
  ///
  /// Returns false if reduced motion is enabled (disables scale).
  /// Check this before applying scale transforms.
  ///
  /// Example:
  /// ```dart
  /// if (ReducedMotionService.shouldScale) {
  ///   return ScaleTransition(...);
  /// }
  /// ```
  static bool get shouldScale => !isEnabled;
}
