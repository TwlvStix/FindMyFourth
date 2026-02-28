import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'motion_tokens.dart';
import 'reduced_motion.dart';

/// Builds a content section with staggered fade-in animation.
///
/// Uses MotionTokens.contentReveal timing with per-section stagger delay
/// and respects reduced motion preferences.
Widget buildAnimatedSection({
  required int sectionIndex,
  required Widget child,
  required bool hasAnimated,
}) {
  final clampedIndex = sectionIndex < MotionTokens.staggerMaxItems
      ? sectionIndex
      : MotionTokens.staggerMaxItems - 1;
  final staggerDelay = ReducedMotionService.shouldStagger
      ? MotionTokens.staggerDelay * clampedIndex
      : Duration.zero;

  return child.animate(target: hasAnimated ? 1 : 0).fadeIn(
        delay: staggerDelay,
        duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
        curve: MotionTokens.curveEnter,
      );
}
