import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_patterns/premium_ui_patterns.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/typography.dart';

/// Info card pattern for displaying labeled icon + value pairs.
///
/// Extracted from the premium info card pattern used in game detail screens.
/// Renders a compact card with an icon, label, value, and optional trailing widget.
///
/// **Icon rendering modes:**
/// - `useBadge: false` (default): Plain icon with [AppColors.textSecondary]
/// - `useBadge: true`: Icon inside a [GradientIconBox] using [badgeColors]
///
/// **Example (plain icon):**
/// ```dart
/// AppInfoCard(
///   icon: AppPhosphorIcons.betting,
///   label: 'Betting',
///   value: '\$20 Nassau',
/// )
/// ```
///
/// **Example (badge icon with gradient):**
/// ```dart
/// AppInfoCard(
///   icon: AppPhosphorIcons.trophy,
///   label: 'Achievement',
///   value: 'Gold Member',
///   useBadge: true,
///   badgeColors: [AppColors.gold, AppColors.goldLight],
/// )
/// ```
///
/// **Example (tappable with trailing widget):**
/// ```dart
/// AppInfoCard(
///   icon: AppPhosphorIcons.mapPin,
///   label: 'Course',
///   value: 'Pebble Beach',
///   sublabel: '18 holes',
///   onTap: () => _openCourseDetails(),
///   trailing: Icon(PhosphorIconsRegular.caretRight),
/// )
/// ```
///
/// **Example (highlighted "fun badge" style):**
/// ```dart
/// AppInfoCard(
///   icon: AppPhosphorIcons.gameVibe,
///   label: 'Vibe',
///   value: 'Just for Fun',
///   useBadge: true,
///   badgeColors: [AppColors.gold, AppColors.goldLight],
///   isHighlighted: true, // Adds gold border and value text accent
/// )
/// ```
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sublabel,
    this.useBadge = false,
    this.badgeColors,
    this.onTap,
    this.trailing,
    this.isHighlighted = false,
  }) : assert(
          !useBadge || (useBadge && badgeColors != null),
          'badgeColors required when useBadge is true',
        );

  /// The Phosphor icon to display.
  final PhosphorIconData icon;

  /// The label text displayed above the value.
  final String label;

  /// The main value text displayed below the label.
  final String value;

  /// Optional sublabel displayed below the value.
  final String? sublabel;

  /// Whether to render the icon inside a gradient badge.
  /// When false (default), renders a plain icon with [AppColors.textSecondary].
  final bool useBadge;

  /// Gradient colors for the badge when [useBadge] is true.
  /// Must be provided if [useBadge] is true.
  final List<Color>? badgeColors;

  /// Optional tap callback. When provided, adds a hover/press effect.
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., chevron for navigation).
  final Widget? trailing;

  /// Whether to apply highlighted styling (gold border and value text).
  /// Useful for "fun badge" or special emphasis states.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.navy.withValues(alpha: 0.4)
            : AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isHighlighted
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          _buildIcon(),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '--',
                  style: AppTypography.bodySmall.copyWith(
                    color: isHighlighted ? AppColors.gold : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel != null && sublabel!.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    sublabel!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildIcon() {
    if (useBadge && badgeColors != null) {
      return GradientIconBox(
        icon: icon,
        gradientColors: badgeColors!,
        size: 36,
        iconSize: AppIconSize.button,
        borderRadius: AppBorderRadius.sm,
        withShadow: true,
      );
    }

    // Plain icon mode
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: PhosphorIcon(
          icon,
          size: AppIconSize.listItem,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
