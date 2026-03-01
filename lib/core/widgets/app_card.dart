import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/elevation.dart';
import '../design_tokens/opacity.dart';
import 'app_icon.dart';

/// Visual variants for AppCard
enum AppCardVariant {
  /// Standard elevated card with shadow
  standard,

  /// Elevated card with stronger shadow
  elevated,

  /// Outlined card with border, no shadow
  outlined,

  /// Standard card with gradient accent bar
  gradientAccent,

  /// Premium card with gradient background and green glow shadow
  /// Usage: Featured content, premium games, VIP features, special offers
  /// Golf aesthetic: Like the pristine fairway at a championship course
  premium,

  /// Glass-effect card with subtle background and blur (for overlays)
  /// Usage: Modal overlays, floating panels, translucent surfaces
  /// Golf aesthetic: Like the modern glass walls of the clubhouse
  glass,

  /// Dark surface card for use on dark backgrounds (FairwayBackgroundDark)
  /// Usage: Vibe sliders, settings on dark screens, immersive overlays
  /// Golf aesthetic: Like a premium leather scorecard holder
  darkSurface,
}

/// Enhanced card component with variants and micro-interactions
///
/// Production-grade card that integrates with the design token system.
/// Provides consistent styling, shadows, and interactive states.
///
/// Features:
/// - 4 visual variants (standard, elevated, outlined, gradientAccent)
/// - Optional tap interaction with scale animation
/// - Flexible content area
/// - Design token integration
/// - Accessibility support
///
/// Example:
/// ```dart
/// AppCard(
///   variant: AppCardVariant.gradientAccent,
///   onTap: () => navigateToDetails(),
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       Text('Pebble Beach Round', style: AppTypography.headlineMedium),
///       SizedBox(height: 8),
///       Text('Saturday, Jan 6 at 9:00 AM', style: AppTypography.bodyMedium),
///     ],
///   ),
/// )
/// ```
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.backgroundColor,
    this.elevation,
    this.borderColor,
    this.borderWidth,
  });

  /// Content to display inside the card
  final Widget child;

  /// Visual style variant
  final AppCardVariant variant;

  /// Callback when card is tapped (makes card interactive)
  final VoidCallback? onTap;

  /// Internal padding (defaults to AppSpacing.card)
  final EdgeInsetsGeometry? padding;

  /// External margin
  final EdgeInsetsGeometry? margin;

  /// Corner radius (defaults to 16)
  final double? borderRadius;

  /// Card width (defaults to match parent)
  final double? width;

  /// Card height (defaults to wrap content)
  final double? height;

  /// Background color override
  final Color? backgroundColor;

  /// Shadow elevation override
  final double? elevation;

  /// Border color override (for outlined variant)
  final Color? borderColor;

  /// Border width override (for outlined variant)
  final double? borderWidth;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: MotionTokens.curveEnter,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPadding = widget.padding ?? AppSpacing.card;
    final defaultBorderRadius = widget.borderRadius ?? AppBorderRadius.md;

    Widget cardContent;

    // Special handling for glass variant with blur effect
    if (widget.variant == AppCardVariant.glass) {
      cardContent = Container(
        width: widget.width,
        height: widget.height,
        decoration: _buildDecoration(defaultBorderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: defaultPadding,
              child: widget.child,
            ),
          ),
        ),
      );
    } else if (widget.variant == AppCardVariant.premium) {
      // Special handling for premium variant to ensure ClipRRect for gradient
      cardContent = Container(
        width: widget.width,
        height: widget.height,
        decoration: _buildDecoration(defaultBorderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          child: Padding(
            padding: defaultPadding,
            child: widget.child,
          ),
        ),
      );
    } else {
      cardContent = Container(
        width: widget.width,
        height: widget.height,
        padding: defaultPadding,
        decoration: _buildDecoration(defaultBorderRadius),
        child: widget.child,
      );
    }

    // Add margin if specified
    if (widget.margin != null) {
      cardContent = Padding(
        padding: widget.margin!,
        child: cardContent,
      );
    }

    // Add tap interaction if onTap is provided
    if (widget.onTap != null) {
      cardContent = GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  BoxDecoration _buildDecoration(double borderRadius) {
    final backgroundColor =
        widget.backgroundColor ?? AppColors.pure;

    switch (widget.variant) {
      case AppCardVariant.standard:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: [AppElevation.sm],
        );

      case AppCardVariant.elevated:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: [AppElevation.md],
        );

      case AppCardVariant.outlined:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: widget.borderColor ?? AppColors.cloud,
            width: widget.borderWidth ?? 1.5,
          ),
        );

      case AppCardVariant.gradientAccent:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border(
            left: BorderSide(
              color: AppColors.gold,
              width: widget.borderWidth ?? 4,
            ),
          ),
          boxShadow: [AppElevation.sm],
        );

      case AppCardVariant.premium:
        return BoxDecoration(
          gradient: AppColors.greenGradient,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: [AppElevation.glowGreen],
          border: Border.all(
            color: AppColors.green.withValues(alpha: AppOpacity.light),
            width: 1,
          ),
        );

      case AppCardVariant.glass:
        return BoxDecoration(
          color: AppColors.pure.withValues(alpha: AppOpacity.medium),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.cloud.withValues(alpha: AppOpacity.light),
            width: 1,
          ),
        );

      case AppCardVariant.darkSurface:
        return BoxDecoration(
          color: widget.backgroundColor ?? AppColorsDark.navyLight,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: widget.borderColor ?? AppColorsDark.glassBorder,
            width: widget.borderWidth ?? 1,
          ),
          boxShadow: [AppElevation.sm],
        );
    }
  }
}

/// Specialized card for game listings
///
/// Pre-configured card with gradient accent and proper spacing for game items.
///
/// Example:
/// ```dart
/// GameCard(
///   title: 'Pebble Beach Round',
///   subtitle: 'Saturday, Jan 6 at 9:00 AM',
///   metadata: '3/4 players',
///   onTap: () => navigateToGame(),
/// )
/// ```
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.title,
    this.subtitle,
    this.metadata,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? metadata;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.gradientAccent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headlineMedium
                .withColor(AppColors.navyDark),
          ),
          if (subtitle != null) ...[
            AppSpacing.verticalXsBox,
            Text(
              subtitle!,
              style: AppTypography.bodyMedium.withColor(AppColors.slate),
            ),
          ],
          if (metadata != null || trailing != null) ...[
            AppSpacing.verticalSmBox,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (metadata != null)
                  Text(
                    metadata!,
                    style: AppTypography.monoMedium.withColor(AppColors.stone),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Specialized card for profile/stat displays
///
/// Pre-configured card with clean styling for user profiles and statistics.
///
/// Example:
/// ```dart
/// StatCard(
///   label: 'Games Played',
///   value: '24',
/// )
/// ```
@Deprecated('Use AppStatCard with AppStatCardVariant.standard instead. '
    'See lib/core/widgets/app_stat_card.dart')
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.phosphorIcon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final PhosphorIconData? phosphorIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: onTap,
      backgroundColor: AppColors.sand,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (phosphorIcon != null) ...[
                AppIcon(
                  icon: phosphorIcon!,
                  color: AppColors.navy,
                  size: AppIconSize.button,
                ),
                AppSpacing.horizontalSmBox,
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.navy,
                  size: AppIconSize.button,
                ),
                AppSpacing.horizontalSmBox,
              ],
              Text(
                label,
                style: AppTypography.bodyMedium.withColor(AppColors.slate),
              ),
            ],
          ),
          Text(
            value,
            style: AppTypography.monoLarge.withColor(AppColors.navyDark),
          ),
        ],
      ),
    );
  }
}

/// Specialized card for content sections
///
/// Pre-configured elevated card with header and content areas.
///
/// Example:
/// ```dart
/// SectionCard(
///   title: 'Recent Activity',
///   child: ActivityList(),
/// )
/// ```
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge
                        .withColor(AppColors.navyDark),
                  ),
                  if (subtitle != null) ...[
                    AppSpacing.verticalXxs,
                    Text(
                      subtitle!,
                      style:
                          AppTypography.bodySmall.withColor(AppColors.slate),
                    ),
                  ],
                ],
              ),
              if (action != null) action!,
            ],
          ),
          AppSpacing.verticalMdBox,
          child,
        ],
      ),
    );
  }
}
