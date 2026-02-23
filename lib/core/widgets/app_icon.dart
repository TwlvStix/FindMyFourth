import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';

/// Unified icon widget for the golf app.
///
/// Supports both custom SVG icons (via [assetPath]) and Phosphor font icons
/// (via [icon]). Exactly one must be provided.
///
/// SVG icons use 1.75px stroke weight, round caps/joins, 24x24 grid.
/// Phosphor icons use Regular weight by default; use Fill for active states.
///
/// Example (Phosphor — preferred for new code):
/// ```dart
/// AppIcon(
///   icon: AppPhosphorIcons.games,
///   size: AppIconSize.md,
///   color: AppColors.textSecondary,
/// )
/// ```
///
/// Example (SVG — legacy, still supported):
/// ```dart
/// AppIcon(
///   assetPath: AppIcons.games,
///   size: AppIconSize.md,
///   color: AppColors.textSecondary,
/// )
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    this.assetPath,
    this.icon,
    this.size,
    this.color,
    this.semanticLabel,
  }) : assert(
          (assetPath != null) != (icon != null),
          'Provide exactly one: assetPath (SVG) or icon (Phosphor)',
        );

  /// Path to SVG asset (use [AppIcons] constants).
  /// Mutually exclusive with [icon].
  final String? assetPath;

  /// Phosphor icon data (use [AppPhosphorIcons] constants).
  /// Mutually exclusive with [assetPath].
  final PhosphorIconData? icon;

  /// Icon size in logical pixels.
  /// Defaults to [AppIconSize.md] (24px).
  final double? size;

  /// Icon color. When null, defaults to [AppColors.textSecondary]
  /// for Phosphor icons, or the SVG's default color for SVG icons.
  final Color? color;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppIconSize.md;

    if (icon != null) {
      return PhosphorIcon(
        icon!,
        size: effectiveSize,
        color: color ?? AppColors.textSecondary,
        semanticLabel: semanticLabel,
      );
    }

    return SvgPicture.asset(
      assetPath!,
      width: effectiveSize,
      height: effectiveSize,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticLabel,
    );
  }
}

/// Navigation icon variant with active/inactive states.
///
/// Designed for bottom navigation bars. Supports both SVG and Phosphor icons.
/// For Phosphor, provide [iconFill] for the active (filled) variant.
///
/// Example (Phosphor):
/// ```dart
/// AppNavIcon(
///   icon: AppPhosphorIcons.games,
///   iconFill: AppPhosphorIcons.gamesFill,
///   isActive: _currentIndex == 0,
/// )
/// ```
///
/// Example (SVG — legacy):
/// ```dart
/// AppNavIcon(
///   assetPath: AppIcons.games,
///   isActive: _currentIndex == 0,
/// )
/// ```
class AppNavIcon extends StatelessWidget {
  const AppNavIcon({
    super.key,
    this.assetPath,
    this.icon,
    this.iconFill,
    this.size,
    this.isActive = false,
    this.activeColor,
    this.inactiveColor,
    this.semanticLabel,
  }) : assert(
          (assetPath != null) || (icon != null),
          'Provide either assetPath (SVG) or icon (Phosphor)',
        );

  /// Path to SVG asset (use [AppIcons] constants).
  final String? assetPath;

  /// Phosphor icon data for inactive (regular) state.
  final PhosphorIconData? icon;

  /// Phosphor icon data for active (filled) state.
  /// Falls back to [icon] if not provided.
  final PhosphorIconData? iconFill;

  /// Icon size in logical pixels.
  /// Defaults to [AppIconSize.nav] (24px).
  final double? size;

  /// Whether this nav item is currently selected.
  final bool isActive;

  /// Color when [isActive] is true.
  /// Defaults to [AppColors.green].
  final Color? activeColor;

  /// Color when [isActive] is false.
  /// Defaults to [AppColors.textMuted].
  final Color? inactiveColor;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppIconSize.nav;
    final effectiveColor = isActive
        ? (activeColor ?? AppColors.green)
        : (inactiveColor ?? AppColors.textMuted);

    // Phosphor icon path
    if (icon != null) {
      final effectiveIcon = isActive ? (iconFill ?? icon!) : icon!;
      return PhosphorIcon(
        effectiveIcon,
        size: effectiveSize,
        color: effectiveColor,
        semanticLabel: semanticLabel,
      );
    }

    // SVG path (legacy)
    return SvgPicture.asset(
      assetPath!,
      width: effectiveSize,
      height: effectiveSize,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// Icon wrapped in a colored container box.
///
/// Used for game detail cards, feature highlights, and
/// other UI elements where icons need a colored background.
///
/// ⚠️ DESIGN NOTE: Prefer plain [AppIcon] without a colored box
/// for most contexts. Reserve AppIconBox for trust badges,
/// achievements, and premium indicators only.
///
/// Example (Phosphor):
/// ```dart
/// AppIconBox(
///   icon: AppPhosphorIcons.trust,
///   backgroundColor: AppColors.gold,
///   iconColor: Colors.white,
/// )
/// ```
class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    this.assetPath,
    this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 12,
    this.semanticLabel,
  }) : assert(
          (assetPath != null) || (icon != null),
          'Provide either assetPath (SVG) or icon (Phosphor)',
        );

  /// Path to SVG asset (use [AppIcons] constants).
  final String? assetPath;

  /// Phosphor icon data (use [AppPhosphorIcons] constants).
  final PhosphorIconData? icon;

  /// Background color of the container box.
  /// Defaults to [AppColors.navy].
  final Color? backgroundColor;

  /// Color of the icon inside the box.
  /// Defaults to white.
  final Color? iconColor;

  /// Size of the outer container box.
  final double size;

  /// Size of the icon inside the box.
  final double iconSize;

  /// Border radius of the container box.
  final double borderRadius;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.navy,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: icon != null
            ? PhosphorIcon(
                icon!,
                size: iconSize,
                color: effectiveIconColor,
                semanticLabel: semanticLabel,
              )
            : SvgPicture.asset(
                assetPath!,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  effectiveIconColor,
                  BlendMode.srcIn,
                ),
                semanticsLabel: semanticLabel,
              ),
      ),
    );
  }
}
