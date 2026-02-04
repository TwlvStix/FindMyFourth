import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';

/// Background variant styles for different contexts
enum FairwayBackgroundVariant {
  /// Light background with sand/green tones - default for most screens
  light,

  /// Dark background with deep greens - for immersive experiences
  dark,

  /// Warm sunset gradient - for special moments, hero screens
  sunset,

  /// Minimal subtle background - when content should dominate
  minimal,
}

/// Atmospheric background component with organic overlays and depth
///
/// Creates sophisticated backgrounds that evoke rolling golf fairways with:
/// - Layered gradient meshes for atmospheric depth
/// - Organic curved overlays reminiscent of landscape contours
/// - Optional subtle noise texture for tactile quality
/// - Multiple variants for different contexts
///
/// Performance optimized with RepaintBoundary and const constructors.
///
/// Example:
/// ```dart
/// Scaffold(
///   body: FairwayBackground(
///     variant: FairwayBackgroundVariant.light,
///     showOrganic: true,
///     showTexture: true,
///     child: YourContent(),
///   ),
/// )
/// ```
class FairwayBackground extends StatelessWidget {
  const FairwayBackground({
    super.key,
    required this.child,
    this.variant = FairwayBackgroundVariant.light,
    this.showOrganic = true,
    this.showTexture = false,
    this.intensity = 1.0,
  });

  /// Content to display over the background
  final Widget child;

  /// Visual style variant
  final FairwayBackgroundVariant variant;

  /// Show organic curved overlays (rolling fairway effect)
  final bool showOrganic;

  /// Show subtle noise/grain texture
  final bool showTexture;

  /// Effect intensity (0.0 to 1.0), useful for subtle variations
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient layer
        Positioned.fill(
          child: _BaseGradient(variant: variant),
        ),

        // Organic curved overlays
        if (showOrganic)
          Positioned.fill(
            child: RepaintBoundary(
              child: _OrganicOverlays(
                variant: variant,
                intensity: intensity,
              ),
            ),
          ),

        // Subtle texture overlay
        if (showTexture)
          Positioned.fill(
            child: RepaintBoundary(
              child: _TextureOverlay(intensity: intensity),
            ),
          ),

        // Content
        child,
      ],
    );
  }
}

// ============================================================================
// BASE GRADIENT
// ============================================================================

class _BaseGradient extends StatelessWidget {
  const _BaseGradient({required this.variant});

  final FairwayBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getBaseGradient(),
      ),
    );
  }

  LinearGradient _getBaseGradient() {
    switch (variant) {
      case FairwayBackgroundVariant.light:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sand,
            AppColors.pure,
            AppColors.cloud.withOpacity(0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

      case FairwayBackgroundVariant.dark:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.fairwayDark,
            AppColors.fairway,
            AppColors.fairwayLight.withOpacity(0.3),
          ],
          stops: const [0.0, 0.6, 1.0],
        );

      case FairwayBackgroundVariant.sunset:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sunsetRose.withOpacity(0.2),
            AppColors.sunsetPeach.withOpacity(0.15),
            AppColors.sunsetGold.withOpacity(0.1),
            AppColors.sand,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        );

      case FairwayBackgroundVariant.minimal:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.pure,
            AppColors.sand.withOpacity(0.5),
          ],
        );
    }
  }
}

// ============================================================================
// ORGANIC OVERLAYS (Rolling Fairway Effect)
// ============================================================================

class _OrganicOverlays extends StatelessWidget {
  const _OrganicOverlays({
    required this.variant,
    required this.intensity,
  });

  final FairwayBackgroundVariant variant;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final overlays = _getOverlayConfigurations();

    return Stack(
      children: overlays.map((config) {
        return Positioned(
          top: config.top,
          left: config.left,
          right: config.right,
          bottom: config.bottom,
          child: Opacity(
            opacity: config.opacity * intensity,
            child: Container(
              width: config.size,
              height: config.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.color,
                    config.color.withOpacity(0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_OverlayConfig> _getOverlayConfigurations() {
    switch (variant) {
      case FairwayBackgroundVariant.light:
        return [
          // Top-left organic blob
          _OverlayConfig(
            top: -150,
            left: -100,
            size: 400,
            color: AppColors.fairwayLight.withOpacity(0.08),
            opacity: 1.0,
          ),
          // Mid-right warm accent
          _OverlayConfig(
            top: 200,
            right: -150,
            size: 500,
            color: AppColors.sunsetGold.withOpacity(0.05),
            opacity: 0.8,
          ),
          // Bottom-left subtle green
          _OverlayConfig(
            bottom: -100,
            left: 50,
            size: 350,
            color: AppColors.fairway.withOpacity(0.06),
            opacity: 0.6,
          ),
        ];

      case FairwayBackgroundVariant.dark:
        return [
          // Top-right lighter green
          _OverlayConfig(
            top: -120,
            right: -80,
            size: 450,
            color: AppColors.fairwayLight.withOpacity(0.15),
            opacity: 1.0,
          ),
          // Mid-left deep accent
          _OverlayConfig(
            top: 250,
            left: -120,
            size: 400,
            color: AppColors.fairway.withOpacity(0.2),
            opacity: 0.7,
          ),
          // Bottom-center glow
          _OverlayConfig(
            bottom: -150,
            left: null,
            right: null,
            size: 500,
            color: AppColors.sunsetGold.withOpacity(0.08),
            opacity: 0.5,
          ),
        ];

      case FairwayBackgroundVariant.sunset:
        return [
          // Top warm glow
          _OverlayConfig(
            top: -180,
            left: null,
            right: null,
            size: 600,
            color: AppColors.sunsetPeach.withOpacity(0.2),
            opacity: 1.0,
          ),
          // Right side golden
          _OverlayConfig(
            top: 150,
            right: -200,
            size: 550,
            color: AppColors.sunsetGold.withOpacity(0.15),
            opacity: 0.8,
          ),
          // Bottom rose accent
          _OverlayConfig(
            bottom: -100,
            left: -150,
            size: 450,
            color: AppColors.sunsetRose.withOpacity(0.12),
            opacity: 0.6,
          ),
        ];

      case FairwayBackgroundVariant.minimal:
        return [
          // Single subtle overlay
          _OverlayConfig(
            top: -100,
            right: -50,
            size: 300,
            color: AppColors.cloud.withOpacity(0.05),
            opacity: 0.5,
          ),
        ];
    }
  }
}

class _OverlayConfig {
  const _OverlayConfig({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;
}

// ============================================================================
// TEXTURE OVERLAY (Subtle Grain)
// ============================================================================

class _TextureOverlay extends StatelessWidget {
  const _TextureOverlay({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.03 * intensity, // Very subtle
      child: CustomPaint(
        painter: _NoisePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onyx
      ..style = PaintingStyle.fill;

    // Create procedural noise pattern
    // Using a simple dot pattern for performance
    final random = _SeededRandom(42); // Fixed seed for consistency

    for (var i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = AppColors.onyx.withOpacity(random.nextDouble() * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple seeded random for consistent noise pattern
class _SeededRandom {
  _SeededRandom(this.seed);

  int seed;

  double nextDouble() {
    seed = ((seed * 1103515245) + 12345) & 0x7fffffff;
    return (seed % 10000) / 10000;
  }
}

// ============================================================================
// SPECIALIZED BACKGROUND VARIANTS
// ============================================================================

/// Pre-configured light background (most common use case)
class FairwayBackgroundLight extends StatelessWidget {
  const FairwayBackgroundLight({
    super.key,
    required this.child,
    this.showOrganic = true,
    this.showTexture = false,
  });

  final Widget child;
  final bool showOrganic;
  final bool showTexture;

  @override
  Widget build(BuildContext context) {
    return FairwayBackground(
      variant: FairwayBackgroundVariant.light,
      showOrganic: showOrganic,
      showTexture: showTexture,
      child: child,
    );
  }
}

/// Pre-configured dark background for immersive screens
class FairwayBackgroundDark extends StatelessWidget {
  const FairwayBackgroundDark({
    super.key,
    required this.child,
    this.showOrganic = true,
    this.showTexture = false,
  });

  final Widget child;
  final bool showOrganic;
  final bool showTexture;

  @override
  Widget build(BuildContext context) {
    return FairwayBackground(
      variant: FairwayBackgroundVariant.dark,
      showOrganic: showOrganic,
      showTexture: showTexture,
      child: child,
    );
  }
}

/// Pre-configured sunset background for hero moments
class FairwayBackgroundSunset extends StatelessWidget {
  const FairwayBackgroundSunset({
    super.key,
    required this.child,
    this.showOrganic = true,
    this.showTexture = false,
  });

  final Widget child;
  final bool showOrganic;
  final bool showTexture;

  @override
  Widget build(BuildContext context) {
    return FairwayBackground(
      variant: FairwayBackgroundVariant.sunset,
      showOrganic: showOrganic,
      showTexture: showTexture,
      child: child,
    );
  }
}

/// Pre-configured minimal background when content should dominate
class FairwayBackgroundMinimal extends StatelessWidget {
  const FairwayBackgroundMinimal({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FairwayBackground(
      variant: FairwayBackgroundVariant.minimal,
      showOrganic: false,
      showTexture: false,
      child: child,
    );
  }
}
