import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../motion/motion_tokens.dart';
import '../motion/reduced_motion.dart';

/// An animated circular progress ring that displays vibe match score.
///
/// The ring animates from 0% to the target [vibeScore] with a fill animation.
/// Color varies based on score threshold:
/// - >= 80%: AppColors.green (excellent match)
/// - >= 65%: AppColors.greenLight (good match)
/// - < 65%: AppColors.info (moderate match)
///
/// Use [animationDelay] to create staggered animations when rendering lists.
class AnimatedVibeRing extends StatefulWidget {
  const AnimatedVibeRing({
    super.key,
    required this.vibeScore,
    required this.child,
    this.size = 56,
    this.strokeWidth = 3,
    this.animationDelay = Duration.zero,
    this.trackColor,
  });

  /// Vibe match score from 0-100
  final double vibeScore;

  /// Content to display inside the ring (typically an avatar)
  final Widget child;

  /// Diameter of the ring
  final double size;

  /// Width of the ring stroke
  final double strokeWidth;

  /// Delay before starting the fill animation (for stagger effects)
  final Duration animationDelay;

  /// Override track color (defaults to AppColors.navyLight)
  final Color? trackColor;

  @override
  State<AnimatedVibeRing> createState() => _AnimatedVibeRingState();
}

class _AnimatedVibeRingState extends State<AnimatedVibeRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ReducedMotionService.adjust(
        const Duration(milliseconds: 1000),
      ),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionTokens.curveEnter),
    );

    _startAnimationWithDelay();
  }

  Future<void> _startAnimationWithDelay() async {
    if (widget.animationDelay > Duration.zero) {
      await Future.delayed(widget.animationDelay);
    }
    if (mounted && !_hasStarted) {
      _hasStarted = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedVibeRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vibeScore != widget.vibeScore) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Determines ring color based on vibe score threshold
  Color _getRingColor() {
    if (widget.vibeScore >= 80) {
      return AppColors.green;
    } else if (widget.vibeScore >= 65) {
      return AppColors.greenLight;
    } else {
      return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.vibeScore / 100).clamp(0.0, 1.0);
    final ringColor = _getRingColor();
    final trackColor = widget.trackColor ?? AppColors.navyLight;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track (background circle)
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingPainter(
              progress: 1.0,
              color: trackColor,
              strokeWidth: widget.strokeWidth,
            ),
          ),
          // Animated progress fill
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: progress * _animation.value,
                  color: ringColor,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          // Child content (avatar)
          Padding(
            padding: EdgeInsets.all(widget.strokeWidth + 2),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Sweep angle
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
