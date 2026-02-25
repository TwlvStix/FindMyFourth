import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/reduced_motion.dart';
import '/core/widgets/app_icon.dart';

/// Premium empty state widget matching the Friend Request empty state style.
///
/// Features:
/// - Floating vertical animation (gentle bob)
/// - Double-layered gradient circle icon container
/// - Clean typography hierarchy
/// - Designed for dark backgrounds
///
/// Supports either Phosphor icons or SVG asset paths:
/// ```dart
/// // Using Phosphor icon
/// AppEmptyStatePremium(
///   icon: AppPhosphorIcons.notifications,
///   title: "You're all caught up",
///   message: "New activity will appear here.",
/// )
///
/// // Using SVG asset
/// AppEmptyStatePremium(
///   assetPath: AppIcons.games,
///   title: "No Games Yet",
///   message: "Be the first to create a game.",
/// )
/// ```
class AppEmptyStatePremium extends StatefulWidget {
  const AppEmptyStatePremium({
    super.key,
    this.icon,
    this.assetPath,
    required this.title,
    this.message,
    this.animate = true,
  }) : assert(
         icon != null || assetPath != null,
         'Either icon or assetPath must be provided',
       );

  /// Icon to display (Phosphor icon) - provide either this or assetPath
  final PhosphorIconData? icon;

  /// SVG asset path to display - provide either this or icon
  final String? assetPath;

  /// Title text - displayed prominently
  final String title;

  /// Optional message text - displayed with lower emphasis
  final String? message;

  /// Whether to animate the icon with a gentle float
  final bool animate;

  @override
  State<AppEmptyStatePremium> createState() => _AppEmptyStatePremiumState();
}

class _AppEmptyStatePremiumState extends State<AppEmptyStatePremium>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: ReducedMotionService.adjust(const Duration(milliseconds: 2000)),
      vsync: this,
    );

    // Floating animation: gentle vertical bob ±4px
    _floatAnimation = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate && !ReducedMotionService.isEnabled) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Widget _buildIllustration() {
    final gradientColors = [AppColors.navy, AppColors.navyLight];

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withValues(alpha: 0.12),
            gradientColors[1].withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.assetPath != null
              ? AppIcon(
                  assetPath: widget.assetPath,
                  size: AppIconSize.lg,
                  color: AppColors.pure,
                )
              : Icon(
                  widget.icon,
                  size: AppIconSize.lg,
                  color: AppColors.pure,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated floating icon
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, widget.animate ? _floatAnimation.value : 0),
                  child: child,
                );
              },
              child: _buildIllustration(),
            ),

            SizedBox(height: AppSpacing.xl),

            // Title - bold and prominent
            Text(
              widget.title,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Message - lighter and smaller
            if (widget.message != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                widget.message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
