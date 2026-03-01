import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Custom clipper for elegant curved bottom edge on branded header.
///
/// Creates a concave curve that dips down slightly in the center for a modern,
/// polished transition from the header to content below.
class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.lineTo(0, 0);

    // Line across the top
    path.lineTo(size.width, 0);

    // Line down the right side
    path.lineTo(size.width, size.height - 20);

    // Create elegant concave curve along bottom
    // Curve dips down slightly in center for modern feel
    path.quadraticBezierTo(
      size.width * 0.5, // Control point X (center)
      size.height + 15,  // Control point Y (dips down)
      0,                 // End point X (left edge)
      size.height - 20,  // End point Y (back up)
    );

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Refined topographic contour painter - atmospheric and subtle.
///
/// Creates organic, flowing contour lines that mimic real golf course elevation
/// maps. Multiple elevation bands (upper, middle, lower) flow naturally across
/// the header with smooth bezier curves.
class SubtleTopographicPainter extends CustomPainter {
  final Color color;
  final double opacity;

  SubtleTopographicPainter({
    required this.color,
    this.opacity = 0.12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8; // Very thin lines for subtlety

    // Create organic, flowing contour lines
    // These mimic real golf course elevation maps

    // Upper elevation band
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.2,
      controlPoints: [
        [size.width * 0.25, size.height * 0.18],
        [size.width * 0.5, size.height * 0.22],
        [size.width * 0.75, size.height * 0.19],
        [size.width + 50, size.height * 0.21],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.25,
      controlPoints: [
        [size.width * 0.25, size.height * 0.23],
        [size.width * 0.5, size.height * 0.27],
        [size.width * 0.75, size.height * 0.24],
        [size.width + 50, size.height * 0.26],
      ],
    );

    // Middle elevation band
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.5,
      controlPoints: [
        [size.width * 0.3, size.height * 0.48],
        [size.width * 0.6, size.height * 0.53],
        [size.width * 0.85, size.height * 0.49],
        [size.width + 50, size.height * 0.52],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.56,
      controlPoints: [
        [size.width * 0.3, size.height * 0.54],
        [size.width * 0.6, size.height * 0.59],
        [size.width * 0.85, size.height * 0.55],
        [size.width + 50, size.height * 0.58],
      ],
    );

    // Lower elevation band
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.75,
      controlPoints: [
        [size.width * 0.2, size.height * 0.73],
        [size.width * 0.5, size.height * 0.78],
        [size.width * 0.8, size.height * 0.74],
        [size.width + 50, size.height * 0.77],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.82,
      controlPoints: [
        [size.width * 0.2, size.height * 0.80],
        [size.width * 0.5, size.height * 0.85],
        [size.width * 0.8, size.height * 0.81],
        [size.width + 50, size.height * 0.84],
      ],
    );

    // Add occasional shorter accent contours
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: size.width * 0.1,
      startY: size.height * 0.35,
      controlPoints: [
        [size.width * 0.3, size.height * 0.33],
        [size.width * 0.5, size.height * 0.36],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: size.width * 0.5,
      startY: size.height * 0.65,
      controlPoints: [
        [size.width * 0.7, size.height * 0.63],
        [size.width * 0.9, size.height * 0.66],
      ],
    );
  }

  void _drawContourLine(
    Canvas canvas,
    Paint paint,
    Size size, {
    required double startX,
    required double startY,
    required List<List<double>> controlPoints,
  }) {
    final path = Path();
    path.moveTo(startX, startY);

    // Create smooth flowing curves through all control points
    for (int i = 0; i < controlPoints.length - 1; i += 2) {
      if (i + 1 < controlPoints.length) {
        path.quadraticBezierTo(
          controlPoints[i][0],
          controlPoints[i][1],
          controlPoints[i + 1][0],
          controlPoints[i + 1][1],
        );
      } else {
        // If odd number of points, just line to the last one
        path.lineTo(controlPoints[i][0], controlPoints[i][1]);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SubtleTopographicPainter oldDelegate) => false;
}

/// Premium branded header widget with refined topographic pattern.
///
/// A 150px height header with:
/// - Elegant curved bottom edge (dips down in center)
/// - Deep forest green gradient background
/// - Subtle topographic contour pattern overlay (12% opacity)
/// - Username displayed bottom-left
/// - Course name displayed bottom-right
/// - White text with layered shadows for excellent contrast
///
/// Usage:
/// ```dart
/// BrandedGolfHeader(
///   username: 'Ryan New Test',
///   courseName: 'Predator Ridge Golf Resort',
/// )
/// ```
class BrandedGolfHeader extends StatelessWidget {
  /// The username/game name to display on bottom-left
  final String username;

  /// The course name to display on bottom-right
  final String courseName;

  const BrandedGolfHeader({
    super.key,
    required this.username,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CurvedHeaderClipper(),
      child: Container(
        height: 150, // Reduced from 200px for sleeker look
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.navyDark, // Deep forest green
              AppColors.navy, // Rich medium green
              AppColors.navyDark, // Accent darker tone
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle topographic pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: SubtleTopographicPainter(
                  color: Colors.white,
                  opacity: 0.12, // Very subtle, atmospheric
                ),
              ),
            ),

            // Subtle radial gradient overlay for depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Text content - positioned for new height
            Positioned(
              bottom: 20, // Adjusted for new curved bottom
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Username - bottom left
                  Flexible(
                    flex: 2,
                    child: Text(
                      username,
                      style: AppTypography.headlineMediumSans.copyWith(
                        fontSize: 26,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  AppSpacing.horizontalSmBox,

                  // Course name - bottom right
                  Flexible(
                    flex: 3,
                    child: Text(
                      courseName,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.2,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle highlight along top edge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
