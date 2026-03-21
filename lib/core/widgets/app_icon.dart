import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';

/// Unified icon widget for the golf app using Phosphor icons.
///
/// Phosphor icons use Regular weight by default; use Fill for active states.
///
/// Example:
/// ```dart
/// AppIcon(
///   icon: AppPhosphorIcons.games,
///   size: AppIconSize.md,
///   color: AppColors.textSecondary,
/// )
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.semanticLabel,
  });

  /// Phosphor icon data (use [AppPhosphorIcons] constants).
  final PhosphorIconData icon;

  /// Icon size in logical pixels.
  /// Defaults to [AppIconSize.md] (24px).
  final double? size;

  /// Icon color. When null, defaults to [AppColors.textSecondary].
  final Color? color;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(
      icon,
      size: size ?? AppIconSize.md,
      color: color ?? AppColors.textSecondary,
      semanticLabel: semanticLabel,
    );
  }
}

/// Navigation icon variant with active/inactive states.
///
/// Designed for bottom navigation bars. Provide [iconFill] for the
/// active (filled) variant.
///
/// Example:
/// ```dart
/// AppNavIcon(
///   icon: AppPhosphorIcons.games,
///   iconFill: AppPhosphorIcons.gamesFill,
///   isActive: _currentIndex == 0,
/// )
/// ```
class AppNavIcon extends StatelessWidget {
  const AppNavIcon({
    super.key,
    required this.icon,
    this.iconFill,
    this.size,
    this.isActive = false,
    this.activeColor,
    this.inactiveColor,
    this.semanticLabel,
  });

  /// Phosphor icon data for inactive (regular) state.
  final PhosphorIconData icon;

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
    final effectiveIcon = isActive ? (iconFill ?? icon) : icon;

    return PhosphorIcon(
      effectiveIcon,
      size: effectiveSize,
      color: effectiveColor,
      semanticLabel: semanticLabel,
    );
  }
}

/// Icon wrapped in a colored container box.
///
/// Used for game detail cards, feature highlights, and
/// other UI elements where icons need a colored background.
///
/// DESIGN NOTE: Prefer plain [AppIcon] without a colored box
/// for most contexts. Reserve AppIconBox for trust badges,
/// achievements, and premium indicators only.
///
/// Example:
/// ```dart
/// AppIconBox(
///   icon: AppPhosphorIcons.trust,
///   backgroundColor: AppColors.gold,
///   iconColor: AppColors.pure,
/// )
/// ```
class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 12,
    this.semanticLabel,
  });

  /// Phosphor icon data (use [AppPhosphorIcons] constants).
  final PhosphorIconData icon;

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.navy,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: PhosphorIcon(
          icon,
          size: iconSize,
          color: iconColor ?? AppColors.pure,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
