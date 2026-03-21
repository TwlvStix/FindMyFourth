import 'package:flutter/material.dart';

import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

/// Animation timeline choreography for the archetype reveal sequence.
///
/// Encapsulates all 10 CurvedAnimation definitions for the 7-phase,
/// 4.5-second cinematic reveal. Phases:
/// 1. Glow (0.0–0.10), 2. Icon (0.10–0.30), 3. Label/Name/Tagline,
/// 4. Rarity (0.55–0.65), 5. Divider/Description, 6. Compatibility,
/// 7. CTAs (0.82–1.0).
class ArchetypeRevealAnimations {
  ArchetypeRevealAnimations({required AnimationController controller})
      : _controller = controller {
    // Phase 1: Glow (0.0 - 0.10)
    glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.10, curve: MotionTokens.curveEnter),
    );

    // Phase 2: Icon (0.10 - 0.30) with elastic bounce
    icon = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.30, curve: Curves.elasticOut),
    );

    // Phase 3a: Label (0.30 - 0.45)
    label = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.45, curve: MotionTokens.curveEnter),
    );

    // Phase 3b: Name (0.38 - 0.53)
    name = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.53, curve: MotionTokens.curveEnter),
    );

    // Phase 3c: Tagline (0.50 - 0.58)
    tagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.58, curve: MotionTokens.curveEnter),
    );

    // Phase 4: Rarity (0.55 - 0.65)
    rarity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.65, curve: MotionTokens.curveEnter),
    );

    // Phase 5a: Divider (0.60 - 0.70)
    divider = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.70, curve: MotionTokens.curveEnter),
    );

    // Phase 5b: Description (0.65 - 0.77)
    desc = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.77, curve: MotionTokens.curveEnter),
    );

    // Phase 6: Compatibility (0.72 - 0.82)
    compatibility = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.82, curve: MotionTokens.curveEnter),
    );

    // Phase 7: CTAs (0.82 - 1.0)
    cta = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: MotionTokens.curveEnter),
    );
  }

  final AnimationController _controller;

  late final Animation<double> glow;
  late final Animation<double> icon;
  late final Animation<double> label;
  late final Animation<double> name;
  late final Animation<double> tagline;
  late final Animation<double> rarity;
  late final Animation<double> divider;
  late final Animation<double> desc;
  late final Animation<double> compatibility;
  late final Animation<double> cta;

  /// Creates the controller with reduced-motion-adjusted duration.
  static AnimationController createController(TickerProvider vsync) {
    final baseDuration = const Duration(milliseconds: 4500);
    final totalDuration = ReducedMotionService.adjust(baseDuration);
    return AnimationController(duration: totalDuration, vsync: vsync);
  }
}
