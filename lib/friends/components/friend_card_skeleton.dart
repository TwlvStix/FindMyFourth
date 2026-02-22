import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/border_radius.dart';

/// Compact skeleton loading card matching redesigned PremiumFriendCard
/// Clean white background with horizontal action layout
class FriendCardSkeleton extends StatefulWidget {
  const FriendCardSkeleton({super.key});

  @override
  State<FriendCardSkeleton> createState() => _FriendCardSkeletonState();
}

class _FriendCardSkeletonState extends State<FriendCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        // Dark green tinted background - matches card style
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [

          // Main content
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Row(
                  children: [
                    // Avatar skeleton
                    _buildShimmerCircle(
                      size: 68,
                      shimmerPosition: _shimmerAnimation.value,
                    ),

                    SizedBox(width: AppSpacing.md),

                    // Info skeleton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name skeleton (larger - hero element)
                          _buildShimmerBox(
                            width: 140,
                            height: 22,
                            borderRadius: 4,
                            shimmerPosition: _shimmerAnimation.value,
                          ),

                          SizedBox(height: AppSpacing.xs - 2),

                          // Badges row skeleton (vibe + handicap only, no location)
                          Row(
                            children: [
                              _buildShimmerBox(
                                width: 60,
                                height: 22,
                                borderRadius: 999,
                                shimmerPosition: _shimmerAnimation.value,
                              ),
                              SizedBox(width: AppSpacing.xs - 2),
                              _buildShimmerBox(
                                width: 50,
                                height: 22,
                                borderRadius: 6,
                                shimmerPosition: _shimmerAnimation.value,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: AppSpacing.sm),

                    // Action buttons skeleton (icon-only variant for compact layout)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildShimmerBox(
                          width: 44,
                          height: 44,
                          borderRadius: 12,
                          shimmerPosition: _shimmerAnimation.value,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        _buildShimmerBox(
                          width: 44,
                          height: 44,
                          borderRadius: 12,
                          shimmerPosition: _shimmerAnimation.value,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
    required double shimmerPosition,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
          stops: [
            (shimmerPosition - 0.3).clamp(0.0, 1.0),
            shimmerPosition.clamp(0.0, 1.0),
            (shimmerPosition + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCircle({
    required double size,
    required double shimmerPosition,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 3,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
            stops: [
              (shimmerPosition - 0.3).clamp(0.0, 1.0),
              shimmerPosition.clamp(0.0, 1.0),
              (shimmerPosition + 0.3).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}
