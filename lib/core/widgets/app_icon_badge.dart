import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/icon_size.dart';

/// Visual variants for AppIconBadge
enum AppIconBadgeVariant {
  /// Filled with primary color (fairway green)
  primary,

  /// Filled with accent color (sunset gold)
  accent,

  /// Filled with success color
  success,

  /// Filled with error color
  error,

  /// Light background with subtle border
  subtle,

  /// Transparent background, icon only
  ghost,
}

/// Size variants for AppIconBadge
enum AppIconBadgeSize {
  /// Small (32x32) - compact UI
  small,

  /// Medium (40x40) - standard size
  medium,

  /// Large (56x56) - feature highlights
  large,
}

/// Standardized icon badge for status indicators, feature icons, and decorative elements
///
/// Purpose: Replaces 25+ inline icon containers with consistent sizing and semantic variants.
///
/// Features:
/// - 6 semantic color variants (primary, accent, success, error, subtle, ghost)
/// - 3 size options (small, medium, large)
/// - Design token integration
/// - Optional tap interaction
///
/// Example:
/// ```dart
/// AppIconBadge(
///   icon: Icons.golf_course,
///   variant: AppIconBadgeVariant.accent,
///   size: AppIconBadgeSize.medium,
///   onTap: () => navigateToFeature(),
/// )
/// ```
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    this.icon,
    this.svgPath,
    this.variant = AppIconBadgeVariant.primary,
    this.size = AppIconBadgeSize.medium,
    this.onTap,
  }) : assert(icon != null || svgPath != null, 'Either icon or svgPath must be provided');

  /// Icon to display in the badge (IconData)
  final IconData? icon;

  /// SVG asset path to display in the badge (use AppIcons constants)
  final String? svgPath;

  /// Visual style variant
  final AppIconBadgeVariant variant;

  /// Size of the badge
  final AppIconBadgeSize size;

  /// Callback when badge is tapped (makes badge interactive)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();
    final colors = _getColors();

    Widget badge = Container(
      width: dimensions,
      height: dimensions,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: colors.borderColor != null
            ? Border.all(color: colors.borderColor!, width: 1)
            : null,
      ),
      child: svgPath != null
          ? SvgPicture.asset(
              svgPath!,
              width: _getIconSize(),
              height: _getIconSize(),
              colorFilter: ColorFilter.mode(colors.iconColor, BlendMode.srcIn),
            )
          : Icon(
              icon,
              color: colors.iconColor,
              size: _getIconSize(),
            ),
    );

    // Add tap interaction if onTap is provided
    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }

  /// Get badge container dimensions based on size
  double _getDimensions() {
    switch (size) {
      case AppIconBadgeSize.small:
        return 32;
      case AppIconBadgeSize.medium:
        return 40;
      case AppIconBadgeSize.large:
        return 56;
    }
  }

  /// Get icon size based on badge size
  double _getIconSize() {
    switch (size) {
      case AppIconBadgeSize.small:
        return AppIconSize.sm;
      case AppIconBadgeSize.medium:
        return AppIconSize.md;
      case AppIconBadgeSize.large:
        return AppIconSize.lg;
    }
  }

  /// Get colors based on variant
  ({Color background, Color iconColor, Color? borderColor}) _getColors() {
    switch (variant) {
      case AppIconBadgeVariant.primary:
        return (
          background: AppColors.fairway,
          iconColor: AppColors.pure,
          borderColor: null
        );
      case AppIconBadgeVariant.accent:
        return (
          background: AppColors.sunsetGold,
          iconColor: AppColors.onyx,
          borderColor: null
        );
      case AppIconBadgeVariant.success:
        return (
          background: AppColors.success,
          iconColor: AppColors.pure,
          borderColor: null
        );
      case AppIconBadgeVariant.error:
        return (
          background: AppColors.error,
          iconColor: AppColors.pure,
          borderColor: null
        );
      case AppIconBadgeVariant.subtle:
        return (
          background: AppColors.sand,
          iconColor: AppColors.slate,
          borderColor: AppColors.cloud
        );
      case AppIconBadgeVariant.ghost:
        return (
          background: Colors.transparent,
          iconColor: AppColors.slate,
          borderColor: null
        );
    }
  }
}
