import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/border_radius.dart';

/// Premium card background with navy gradient, shimmer highlight, and gold glow.
///
/// Features:
/// - Diagonal gradient from navyDark to navy
/// - Top shimmer highlight line (1px)
/// - Gold radial glow in top-right corner
class FriendCardBackground extends StatelessWidget {
  const FriendCardBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDark,
            AppColors.navy,
          ],
        ),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl - 1),
        child: Stack(
          children: [
            // Gold radial glow in top-right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.08),
                      AppColors.gold.withValues(alpha: 0.02),
                      AppColors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Top shimmer highlight line
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.transparent,
                      AppColors.sand.withValues(alpha: 0.1),
                      AppColors.sand.withValues(alpha: 0.15),
                      AppColors.sand.withValues(alpha: 0.1),
                      AppColors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // Main content
            child,
          ],
        ),
      ),
    );
  }
}
