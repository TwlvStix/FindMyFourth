import 'package:flutter/material.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/models/streak_profile.dart';

/// Compact streak chip for displaying on public profiles.
///
/// Shows the current streak tier with week count and flame icon.
/// Color scheme:
/// - Green for active streaks (Ember, Flame, Blaze)
/// - Gold for milestone achievements (Inferno, Legend)
///
/// Example:
/// ```dart
/// StreakChip(
///   profile: streakProfile,
///   size: StreakChipSize.medium,
/// )
/// ```
class StreakChip extends StatelessWidget {
  const StreakChip({
    super.key,
    required this.profile,
    this.size = StreakChipSize.medium,
  });

  /// The streak profile to display.
  final StreakProfile profile;

  /// Size variant of the chip.
  final StreakChipSize size;

  @override
  Widget build(BuildContext context) {
    // Don't render for no streak
    if (!profile.hasActiveStreak) {
      return const SizedBox.shrink();
    }

    final colors = _getColors(profile.visualTier);
    final iconSize = _getIconSize();
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
          AppIcon(
            icon: AppPhosphorIcons.flame,
            color: colors.iconColor,
            size: iconSize,
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            '${profile.currentWeeks}',
            style: textStyle.copyWith(color: colors.textColor),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case StreakChipSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        );
      case StreakChipSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        );
      case StreakChipSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case StreakChipSize.small:
        return 12;
      case StreakChipSize.medium:
        return 14;
      case StreakChipSize.large:
        return 16;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case StreakChipSize.small:
        return AppTypography.monoSmall;
      case StreakChipSize.medium:
        return AppTypography.monoMedium;
      case StreakChipSize.large:
        return AppTypography.monoLarge;
    }
  }

  ({Color background, Color iconColor, Color textColor, Color borderColor})
      _getColors(StreakTier tier) {
    // Gold for milestone tiers (Inferno, Legend)
    if (tier == StreakTier.inferno || tier == StreakTier.legend) {
      return (
        background: AppColors.navy,
        iconColor: AppColors.gold,
        textColor: AppColors.gold,
        borderColor: AppColors.gold.withValues(alpha: 0.3),
      );
    }

    // Green for active streaks (Ember, Flame, Blaze)
    return (
      background: AppColors.navy,
      iconColor: AppColors.greenLight,
      textColor: AppColors.greenLight,
      borderColor: AppColors.green.withValues(alpha: 0.3),
    );
  }
}

/// Size variants for StreakChip.
enum StreakChipSize {
  /// Small chip for compact layouts.
  small,

  /// Medium chip (default).
  medium,

  /// Large chip for emphasis.
  large,
}

/// Extended streak chip with tier label.
///
/// Shows tier name in addition to week count.
/// Use for more prominent streak displays.
class StreakChipExtended extends StatelessWidget {
  const StreakChipExtended({
    super.key,
    required this.profile,
    this.size = StreakChipSize.medium,
  });

  /// The streak profile to display.
  final StreakProfile profile;

  /// Size variant of the chip.
  final StreakChipSize size;

  @override
  Widget build(BuildContext context) {
    // Don't render for no streak
    if (!profile.hasActiveStreak) {
      return const SizedBox.shrink();
    }

    final colors = _getColors(profile.visualTier);
    final iconSize = _getIconSize();
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
          AppIcon(
            icon: AppPhosphorIcons.flame,
            color: colors.iconColor,
            size: iconSize,
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            profile.visualTier.label,
            style: _getLabelStyle().copyWith(color: colors.textColor),
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            '${profile.currentWeeks}w',
            style: _getValueStyle().copyWith(color: colors.textColor),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case StreakChipSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        );
      case StreakChipSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        );
      case StreakChipSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case StreakChipSize.small:
        return 12;
      case StreakChipSize.medium:
        return 14;
      case StreakChipSize.large:
        return 16;
    }
  }

  TextStyle _getLabelStyle() {
    switch (size) {
      case StreakChipSize.small:
        return AppTypography.labelSmall;
      case StreakChipSize.medium:
        return AppTypography.labelMedium;
      case StreakChipSize.large:
        return AppTypography.labelLarge;
    }
  }

  TextStyle _getValueStyle() {
    switch (size) {
      case StreakChipSize.small:
        return AppTypography.monoSmall;
      case StreakChipSize.medium:
        return AppTypography.monoMedium;
      case StreakChipSize.large:
        return AppTypography.monoLarge;
    }
  }

  ({Color background, Color iconColor, Color textColor, Color borderColor})
      _getColors(StreakTier tier) {
    // Gold for milestone tiers (Inferno, Legend)
    if (tier == StreakTier.inferno || tier == StreakTier.legend) {
      return (
        background: AppColors.navy,
        iconColor: AppColors.gold,
        textColor: AppColors.gold,
        borderColor: AppColors.gold.withValues(alpha: 0.3),
      );
    }

    // Green for active streaks (Ember, Flame, Blaze)
    return (
      background: AppColors.navy,
      iconColor: AppColors.greenLight,
      textColor: AppColors.greenLight,
      borderColor: AppColors.green.withValues(alpha: 0.3),
    );
  }
}
