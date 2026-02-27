import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../design_tokens/border_radius.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/typography.dart';

/// A detail row widget for displaying key-value pairs with an icon.
///
/// Used in game details sections and other info displays.
/// Supports optional tags (pills) shown to the LEFT of the value.
///
/// Example:
/// ```dart
/// AppDetailRow(
///   icon: AppPhosphorIcons.betting,
///   label: 'Betting',
///   value: 'Nassau \$5',
///   valueColor: AppColors.gold,
///   tag: 'Stakes',
///   tagColor: AppColors.gold,
///   tagBgColor: AppColors.gold.withValues(alpha: 0.12),
/// )
/// ```
class AppDetailRow extends StatelessWidget {
  const AppDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.tag,
    this.tagColor,
    this.tagBgColor,
    this.showDivider = true,
  });

  /// The Phosphor icon to display in the leading container.
  final PhosphorIconData icon;

  /// The label text (left side, muted).
  final String label;

  /// The value text (right side, emphasized).
  final String value;

  /// Optional color override for the value text.
  final Color? valueColor;

  /// Optional tag/pill text shown to the LEFT of the value.
  final String? tag;

  /// Color for the tag text. Required if [tag] is provided.
  final Color? tagColor;

  /// Background color for the tag pill. Required if [tag] is provided.
  final Color? tagBgColor;

  /// Whether to show a bottom divider. Defaults to true.
  /// Set to false for the last row in a list.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Center(
                  child: PhosphorIcon(
                    icon,
                    size: AppIconSize.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              // Tag (optional) + Value
              if (tag != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tagBgColor ?? AppColors.navyLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                  ),
                  child: Text(
                    tag!.toUpperCase(),
                    style: AppTypography.labelMicro.copyWith(
                      color: tagColor ?? AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
              ],
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            height: 1,
            color: AppColors.navyLight.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
