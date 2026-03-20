import 'package:flutter/material.dart';

import 'motion_tokens.dart';
import 'reduced_motion.dart';

/// Reusable press-to-scale feedback widget.
///
/// Checks [ReducedMotionService.shouldScale] internally:
/// - Reduced motion ON: plain GestureDetector, no scale transform
///   (still forwards tap callbacks for pressed-state color changes)
/// - Reduced motion OFF: AnimationController + ScaleTransition on press
class AnimatedScaleTap extends StatefulWidget {
  const AnimatedScaleTap({
    super.key,
    required this.child,
    required this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.scaleFactor = MotionTokens.pressScale,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  /// Scale-down factor on press. Default 0.96; cards use [MotionTokens.pressScaleSubtle] (0.982).
  final double scaleFactor;

  /// When false, disables interaction but still renders child.
  final bool enabled;

  @override
  State<AnimatedScaleTap> createState() => _AnimatedScaleTapState();
}

class _AnimatedScaleTapState extends State<AnimatedScaleTap>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (ReducedMotionService.shouldScale) {
      _controller = AnimationController(
        duration: MotionTokens.microInteraction,
        vsync: this,
      );
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.scaleFactor,
      ).animate(CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOut,
      ));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller?.forward();
    widget.onTapDown?.call(details);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _controller?.reverse();
    widget.onTapUp?.call(details);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _controller?.reverse();
    widget.onTapCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: widget.child,
    );

    if (_scaleAnimation != null) {
      child = ScaleTransition(
        scale: _scaleAnimation!,
        child: child,
      );
    }

    return child;
  }
}
