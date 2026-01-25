import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cloud.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.fairwayDark.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.sunsetGold.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top accent stripe
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.sunsetGold.withValues(alpha: 0.3),
                  AppColors.sunsetPeach.withValues(alpha: 0.3),
                  AppColors.sunsetGold.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

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
                          // Name skeleton
                          _buildShimmerBox(
                            width: 120,
                            height: 17,
                            borderRadius: 4,
                            shimmerPosition: _shimmerAnimation.value,
                          ),

                          SizedBox(height: 6),

                          // Badges row skeleton
                          Row(
                            children: [
                              _buildShimmerBox(
                                width: 50,
                                height: 20,
                                borderRadius: 6,
                                shimmerPosition: _shimmerAnimation.value,
                              ),
                              SizedBox(width: 8),
                              _buildShimmerBox(
                                width: 80,
                                height: 18,
                                borderRadius: 999,
                                shimmerPosition: _shimmerAnimation.value,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: AppSpacing.sm),

                    // Horizontal action buttons skeleton
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildShimmerBox(
                          width: 70,
                          height: 40,
                          borderRadius: 10,
                          shimmerPosition: _shimmerAnimation.value,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        _buildShimmerBox(
                          width: 60,
                          height: 40,
                          borderRadius: 10,
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
            AppColors.cloud.withValues(alpha: 0.25),
            AppColors.cloud.withValues(alpha: 0.4),
            AppColors.cloud.withValues(alpha: 0.25),
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
          color: AppColors.cloud.withValues(alpha: 0.3),
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
              AppColors.cloud.withValues(alpha: 0.2),
              AppColors.cloud.withValues(alpha: 0.35),
              AppColors.cloud.withValues(alpha: 0.2),
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
