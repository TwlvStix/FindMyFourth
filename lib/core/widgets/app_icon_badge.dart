import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/icon_size.dart';

/// Visual variants for AppIconBadge
enum AppIconBadgeVariant {
  /// Filled with primary accent color (Clubhouse green)
  primary,

  /// Filled with secondary accent color (prestige gold)
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

/// Standardized icon badge for status indicators, feature icons, and decorative elements.
///
/// Supports Material [icon], SVG [svgPath], or Phosphor [phosphorIcon].
///
/// ⚠️ DESIGN NOTE: Use sparingly — only for trust badges, achievements,
/// and premium indicators. For general info display, prefer plain [AppIcon]
/// without a colored background.
///
/// Example (Phosphor):
/// ```dart
/// AppIconBadge(
///   phosphorIcon: AppPhosphorIcons.trust,
///   variant: AppIconBadgeVariant.accent,
///   size: AppIconBadgeSize.medium,
/// )
/// ```
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    this.icon,
    this.svgPath,
    this.phosphorIcon,
    this.variant = AppIconBadgeVariant.primary,
    this.size = AppIconBadgeSize.medium,
    this.onTap,
  }) : assert(
          icon != null || svgPath != null || phosphorIcon != null,
          'Provide icon, svgPath, or phosphorIcon',
        );

  /// Material icon to display (IconData)
  final IconData? icon;

  /// SVG asset path to display (use AppIcons constants)
  final String? svgPath;

  /// Phosphor icon to display (use AppPhosphorIcons constants)
  final PhosphorIconData? phosphorIcon;

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
    final iconSize = _getIconSize();

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
      child: Center(
        child: _buildIcon(colors.iconColor, iconSize),
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }

  /// Build the icon widget based on which source was provided.
  /// Priority: phosphorIcon > svgPath > icon
  Widget _buildIcon(Color color, double iconSize) {
    if (phosphorIcon != null) {
      return PhosphorIcon(
        phosphorIcon!,
        size: iconSize,
        color: color,
      );
    }
    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath!,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(
      icon,
      color: color,
      size: iconSize,
    );
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
          background: AppColors.navy,
          iconColor: AppColors.pure,
          borderColor: null
        );
      case AppIconBadgeVariant.accent:
        return (
          background: AppColors.gold,
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
