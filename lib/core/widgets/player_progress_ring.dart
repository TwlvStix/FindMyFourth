import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';

/// A circular progress ring that displays player count as a fill ratio.
/// Used to show how many players have joined relative to the max capacity.
class PlayerProgressRing extends StatelessWidget {
  const PlayerProgressRing({
    super.key,
    required this.current,
    required this.max,
    this.size = 32,
    this.strokeWidth = 3,
    this.showLabel = false,
    this.fillColor,
    this.trackColor,
  });

  /// Current number of players joined
  final int current;

  /// Maximum number of players allowed
  final int max;

  /// Diameter of the ring
  final double size;

  /// Width of the stroke
  final double strokeWidth;

  /// Whether to show the count label in the center
  final bool showLabel;

  /// Override fill color (defaults to AppColors.green)
  final Color? fillColor;

  /// Override track color (defaults to AppColors.navyLight)
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final effectiveFillColor = fillColor ?? AppColors.green;
    final effectiveTrackColor = trackColor ?? AppColors.navyLight;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track (background circle)
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              color: effectiveTrackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Progress fill
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              color: effectiveFillColor,
              strokeWidth: strokeWidth,
            ),
          ),
          // Optional center label
          if (showLabel)
            Text(
              '$current',
              style: AppTypography.labelMicro.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
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
