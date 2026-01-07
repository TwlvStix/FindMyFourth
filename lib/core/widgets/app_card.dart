import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/typography.dart';

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
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
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
    final defaultBorderRadius = widget.borderRadius ?? 16.0;

    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      padding: defaultPadding,
      decoration: _buildDecoration(defaultBorderRadius),
      child: widget.child,
    );

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
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.fairwayDark.withOpacity(
                widget.elevation ?? 0.08,
              ),
              blurRadius: widget.elevation ?? 20,
              offset: Offset(0, widget.elevation ?? 8),
            ),
          ],
        );

      case AppCardVariant.elevated:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.fairwayDark.withOpacity(
                widget.elevation ?? 0.12,
              ),
              blurRadius: widget.elevation ?? 32,
              offset: Offset(0, widget.elevation ?? 12),
            ),
          ],
        );

      case AppCardVariant.outlined:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: widget.borderColor ?? AppColors.cloud,
            width: widget.borderWidth ?? 1.5,
          ),
        );

      case AppCardVariant.gradientAccent:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border(
            left: BorderSide(
              color: AppColors.sunsetGold,
              width: widget.borderWidth ?? 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.fairwayDark.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
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
                .withColor(AppColors.fairwayDark),
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
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
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
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.fairway,
                  size: 20,
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
            style: AppTypography.monoLarge.withColor(AppColors.fairwayDark),
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
                        .withColor(AppColors.fairwayDark),
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
