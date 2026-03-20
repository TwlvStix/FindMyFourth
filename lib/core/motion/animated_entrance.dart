import 'package:flutter/material.dart';

import 'motion_tokens.dart';
import 'reduced_motion.dart';

/// Reusable stagger-entrance animation: fade + slide from bottom on mount.
///
/// Checks [ReducedMotionService] internally:
/// - Reduced motion ON: child appears instantly (no animation)
/// - Reduced motion OFF: fade + slide with stagger delay based on [animationIndex]
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.animationIndex = 0,
    this.duration,
    this.slideOffset = const Offset(0, 0.08),
  });

  final Widget child;

  /// Stagger position, clamped to [MotionTokens.staggerMaxItems] - 1.
  final int animationIndex;

  /// Override for [MotionTokens.contentReveal] (160ms).
  final Duration? duration;

  /// Initial slide offset (fractional, relative to widget size).
  final Offset slideOffset;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final baseDuration = widget.duration ?? MotionTokens.contentReveal;
    final adjustedDuration = ReducedMotionService.adjust(baseDuration);

    _controller = AnimationController(
      duration: adjustedDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionTokens.curveEnter),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionTokens.curveEnter),
    );

    if (ReducedMotionService.isEnabled) {
      _controller.value = 1.0;
    } else {
      final clampedIndex =
          widget.animationIndex.clamp(0, MotionTokens.staggerMaxItems - 1);
      final staggerDelay = MotionTokens.staggerDelay * clampedIndex;

      if (staggerDelay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(staggerDelay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
