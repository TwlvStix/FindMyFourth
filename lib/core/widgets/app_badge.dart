import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/app_icons.dart';
import 'app_icon.dart';

enum AppBadgeVariant {
  /// Success state (green) - completed, confirmed, active
  success,

  /// Warning state (gold) - pending, in-progress, attention
  warning,

  /// Error state (red) - failed, rejected, cancelled
  error,

  /// Info state (blue) - informational, neutral status
  info,

  /// Primary state (fairway green) - brand-colored badges
  primary,

  /// Subtle state (grey) - low-emphasis status
  subtle,
}

enum AppBadgeSize {
  /// Small badge for compact UI
  small,

  /// Medium badge (default)
  medium,

  /// Large badge for emphasis
  large,
}

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final IconData? icon;
  final String? svgPath;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.primary,
    this.size = AppBadgeSize.medium,
    this.icon,
    this.svgPath,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final textStyle = _getTextStyle();
    final padding = _getPadding();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgPath != null) ...[
            AppIcon(
              assetPath: svgPath!,
              color: colors.textColor,
              size: _getIconSize(),
            ),
            SizedBox(width: AppSpacing.xxs),
          ] else if (icon != null) ...[
            Icon(
              icon,
              color: colors.textColor,
              size: _getIconSize(),
            ),
            SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: textStyle.copyWith(color: colors.textColor),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppBadgeSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        );
      case AppBadgeSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        );
      case AppBadgeSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppBadgeSize.small:
        return AppTypography.labelSmall;
      case AppBadgeSize.medium:
        return AppTypography.labelMedium;
      case AppBadgeSize.large:
        return AppTypography.labelLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 12;
      case AppBadgeSize.medium:
        return 14;
      case AppBadgeSize.large:
        return 16;
    }
  }

  ({Color background, Color textColor, Color borderColor}) _getColors() {
    switch (variant) {
      case AppBadgeVariant.success:
        return (
          background: AppColors.success.withValues(alpha: 0.1),
          textColor: AppColors.success,
          borderColor: AppColors.success.withValues(alpha: 0.2),
        );
      case AppBadgeVariant.warning:
        return (
          background: AppColors.warning.withValues(alpha: 0.1),
          textColor: Color(0xFFB8860B), // Darker gold for contrast
          borderColor: AppColors.warning.withValues(alpha: 0.2),
        );
      case AppBadgeVariant.error:
        return (
          background: AppColors.error.withValues(alpha: 0.1),
          textColor: AppColors.error,
          borderColor: AppColors.error.withValues(alpha: 0.2),
        );
      case AppBadgeVariant.info:
        return (
          background: AppColors.info.withValues(alpha: 0.1),
          textColor: AppColors.info,
          borderColor: AppColors.info.withValues(alpha: 0.2),
        );
      case AppBadgeVariant.primary:
        return (
          background: AppColors.fairway.withValues(alpha: 0.1),
          textColor: AppColors.fairway,
          borderColor: AppColors.fairway.withValues(alpha: 0.2),
        );
      case AppBadgeVariant.subtle:
        return (
          background: AppColors.sand,
          textColor: AppColors.slate,
          borderColor: AppColors.cloud,
        );
    }
  }
}
