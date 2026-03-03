import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Authentic multicolor Google "G" logo widget
///
/// Renders the official Google logo colors:
/// - Blue (#4285F4) - right side + crossbar
/// - Red (#EA4335) - top
/// - Yellow (#FBBC05) - left
/// - Green (#34A853) - bottom
///
/// Example:
/// ```dart
/// GoogleLogo(size: 24)
/// ```
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({
    super.key,
    this.size = 24.0,
  });

  /// Size of the logo (width and height)
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  // Official Google brand colors - DO NOT replace with design tokens.
  // These are mandated by Google's brand guidelines.
  // See: https://developers.google.com/identity/branding-guidelines
  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.55; // The hole in the G

    final paint = Paint()..style = PaintingStyle.fill;

    // Helper to create an arc segment (pie slice with hole)
    Path createArcSegment(double startAngle, double sweepAngle) {
      final path = Path();
      final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

      // Start at inner arc start point
      final innerStartX = center.dx + innerRadius * math.cos(startAngle);
      final innerStartY = center.dy + innerRadius * math.sin(startAngle);
      path.moveTo(innerStartX, innerStartY);

      // Line to outer arc start
      final outerStartX = center.dx + outerRadius * math.cos(startAngle);
      final outerStartY = center.dy + outerRadius * math.sin(startAngle);
      path.lineTo(outerStartX, outerStartY);

      // Outer arc
      path.arcTo(outerRect, startAngle, sweepAngle, false);

      // Line to inner arc end
      final endAngle = startAngle + sweepAngle;
      final innerEndX = center.dx + innerRadius * math.cos(endAngle);
      final innerEndY = center.dy + innerRadius * math.sin(endAngle);
      path.lineTo(innerEndX, innerEndY);

      // Inner arc (reverse direction)
      path.arcTo(innerRect, endAngle, -sweepAngle, false);

      path.close();
      return path;
    }

    // Convert degrees to radians for clarity
    double deg(double degrees) => degrees * math.pi / 180;

    // The Google G color segments (going clockwise from the gap):
    // Gap is at top-right: from about -35° to 0°
    // Blue: right side from 0° to about 65°
    // Green: bottom from about 65° to about 145°
    // Yellow: left side from about 145° to about 215°
    // Red: top from about 215° to about 325° (where gap starts)

    // Blue segment: right side (0° to 65°)
    paint.color = _blue;
    canvas.drawPath(createArcSegment(deg(0), deg(65)), paint);

    // Green segment: bottom (65° to 145°)
    paint.color = _green;
    canvas.drawPath(createArcSegment(deg(65), deg(80)), paint);

    // Yellow segment: left (145° to 215°)
    paint.color = _yellow;
    canvas.drawPath(createArcSegment(deg(145), deg(70)), paint);

    // Red segment: top (215° to 325°, i.e., -145° to -35°)
    paint.color = _red;
    canvas.drawPath(createArcSegment(deg(215), deg(110)), paint);

    // Blue crossbar (the horizontal bar that makes it a "G")
    paint.color = _blue;
    final barHeight = outerRadius - innerRadius;
    final barLeft = center.dx;
    final barRight = center.dx + outerRadius;
    final barTop = center.dy - barHeight / 2;

    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barTop + barHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
