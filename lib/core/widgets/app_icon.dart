import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';

/// Unified SVG icon widget for the golf app.
///
/// Uses custom SVG icons with consistent 1.75px stroke weight,
/// round caps/joins, and 24x24 grid. All icons use `currentColor`
/// for dynamic theming via [colorFilter].
///
/// Example:
/// ```dart
/// AppIcon(
///   assetPath: AppIcons.games,
///   size: AppIconSize.md,
///   color: AppColors.fairway,
/// )
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.assetPath,
    this.size,
    this.color,
    this.semanticLabel,
  });

  /// Path to SVG asset (use [AppIcons] constants).
  final String assetPath;

  /// Icon size in logical pixels.
  /// Defaults to [AppIconSize.md] (24px).
  final double? size;

  /// Icon color. When null, uses the SVG's default color.
  /// Use [ColorFilter.mode] with [BlendMode.srcIn] for theming.
  final Color? color;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppIconSize.md;

    return SvgPicture.asset(
      assetPath,
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
/// Designed for bottom navigation bars where icons need to
/// visually indicate selection state.
///
/// Example:
/// ```dart
/// AppNavIcon(
///   assetPath: AppIcons.games,
///   isActive: _currentIndex == 0,
/// )
/// ```
class AppNavIcon extends StatelessWidget {
  const AppNavIcon({
    super.key,
    required this.assetPath,
    this.size,
    this.isActive = false,
    this.activeColor,
    this.inactiveColor,
    this.semanticLabel,
  });

  /// Path to SVG asset (use [AppIcons] constants).
  final String assetPath;

  /// Icon size in logical pixels.
  /// Defaults to [AppIconSize.nav] (24px).
  final double? size;

  /// Whether this nav item is currently selected.
  final bool isActive;

  /// Color when [isActive] is true.
  /// Defaults to [AppColors.fairway].
  final Color? activeColor;

  /// Color when [isActive] is false.
  /// Defaults to [AppColors.stone].
  final Color? inactiveColor;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? AppIconSize.nav;
    final effectiveColor = isActive
        ? (activeColor ?? AppColors.fairway)
        : (inactiveColor ?? AppColors.stone);

    return SvgPicture.asset(
      assetPath,
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
/// Example:
/// ```dart
/// AppIconBox(
///   assetPath: AppIcons.betting,
///   backgroundColor: AppColors.sunsetGold,
///   iconColor: Colors.white,
///   size: 44,
///   iconSize: 22,
/// )
/// ```
class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.assetPath,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 12,
    this.semanticLabel,
  });

  /// Path to SVG asset (use [AppIcons] constants).
  final String assetPath;

  /// Background color of the container box.
  /// Defaults to [AppColors.fairway].
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.fairway,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            iconColor ?? Colors.white,
            BlendMode.srcIn,
          ),
          semanticsLabel: semanticLabel,
        ),
      ),
    );
  }
}
