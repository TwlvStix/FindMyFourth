import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

/// Compact vibe ring badge for game cards.
///
/// Displays a circular progress ring with the vibe match score (0-100)
/// and "VIBE" label in the center. Color varies based on score threshold:
/// - >= 90: AppColors.green (excellent match)
/// - >= 80: AppColors.greenLight (good match)
/// - < 80: AppColors.info (moderate match)
class GameCardVibeRing extends StatefulWidget {
  const GameCardVibeRing({
    super.key,
    required this.vibeScore,
    this.size = 52,
    this.strokeWidth = 3.5,
    this.animationDelay = Duration.zero,
  });

  /// Vibe match score from 0-100
  final double vibeScore;

  /// Diameter of the ring
  final double size;

  /// Width of the ring stroke
  final double strokeWidth;

  /// Delay before starting animation (for stagger effects)
  final Duration animationDelay;

  @override
  State<GameCardVibeRing> createState() => _GameCardVibeRingState();
}

class _GameCardVibeRingState extends State<GameCardVibeRing>
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
        const Duration(milliseconds: 600),
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
  void didUpdateWidget(GameCardVibeRing oldWidget) {
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

  Color _getRingColor() {
    if (widget.vibeScore >= 90) {
      return AppColors.green;
    } else if (widget.vibeScore >= 80) {
      return AppColors.greenLight;
    } else {
      return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.vibeScore / 100).clamp(0.0, 1.0);
    final ringColor = _getRingColor();
    final trackColor = AppColors.pure.withValues(alpha: 0.08);

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
          // Center content: score + VIBE label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.vibeScore.round().toString(),
                style: AppTypography.monoMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ringColor,
                  height: 1,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'VIBE',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.04,
                ),
              ),
            ],
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
