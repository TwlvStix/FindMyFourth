import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/motion/reduced_motion.dart';

/// Reusable shimmer placeholder shape for skeleton loading screens.
///
/// Renders an animated linear gradient sweep when motion is enabled,
/// or a static solid fill when reduced motion is active.
///
/// All skeleton widgets should compose this rather than implementing
/// their own shimmer animation.
class AppShimmerBox extends StatefulWidget {
  const AppShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppBorderRadius.xs,
    this.isCircular = false,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool isCircular;

  @override
  State<AppShimmerBox> createState() => _AppShimmerBoxState();
}

class _AppShimmerBoxState extends State<AppShimmerBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    if (!ReducedMotionService.isEnabled) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();

      _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: _animation != null
          ? AnimatedBuilder(
              animation: _animation!,
              builder: (context, _) => _buildShape(_animation!.value),
            )
          : _buildStatic(),
    );
  }

  Widget _buildStatic() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircular
            ? null
            : BorderRadius.circular(widget.borderRadius),
      ),
    );
  }

  Widget _buildShape(double shimmerPosition) {
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.navyLight,
        AppColors.glassBorder,
        AppColors.navyLight,
      ],
      stops: [
        (shimmerPosition - 0.3).clamp(0.0, 1.0),
        shimmerPosition.clamp(0.0, 1.0),
        (shimmerPosition + 0.3).clamp(0.0, 1.0),
      ],
    );

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircular
            ? null
            : BorderRadius.circular(widget.borderRadius),
      ),
    );
  }
}
