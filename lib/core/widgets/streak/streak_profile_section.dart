import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/models/streak_profile.dart';

/// Visual variant for the streak profile section.
enum StreakSectionVariant {
  /// Light background (sand/cloud) for use on dark screens.
  light,

  /// Dark background (navy) for use on dark screens.
  dark,
}

/// Full streak section for displaying on the user's own profile.
///
/// Shows:
/// - Current streak with tier icon and label
/// - Longest streak (personal best)
/// - Season context
/// - Freeze availability indicator
///
/// Example:
/// ```dart
/// StreakProfileSection(
///   profile: streakProfile,
///   seasonLabel: '2026 Season',
/// )
/// ```
class StreakProfileSection extends StatelessWidget {
  const StreakProfileSection({
    super.key,
    required this.profile,
    this.seasonLabel,
    this.showFreezeStatus = true,
    this.onFreezeTap,
    this.variant = StreakSectionVariant.light,
  });

  /// The streak profile to display.
  final StreakProfile profile;

  /// Optional season label (e.g., "2026 Season").
  /// If null, uses profile.seasonId.
  final String? seasonLabel;

  /// Whether to show freeze availability status.
  final bool showFreezeStatus;

  /// Callback when freeze indicator is tapped.
  final VoidCallback? onFreezeTap;

  /// Visual variant (light or dark theme).
  final StreakSectionVariant variant;

  // Color getters based on variant
  bool get _isDark => variant == StreakSectionVariant.dark;
  Color get _containerBg => _isDark ? AppColors.navy : AppColors.sand;
  Color get _containerBorder => _isDark ? AppColors.navyLight : AppColors.mist;
  Color get _titleText => _isDark ? AppColors.textPrimary : AppColors.onyx;
  Color get _subtitleText => _isDark ? AppColors.textSecondary : AppColors.stone;
  Color get _bodyText => _isDark ? AppColors.textSecondary : AppColors.slate;
  Color get _statsBg => _isDark ? AppColors.navyLight : AppColors.cloud;

  @override
  Widget build(BuildContext context) {
    final effectiveSeasonLabel =
        seasonLabel ?? (profile.seasonId != null ? '${profile.seasonId} Season' : null);

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: _containerBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with flame icon and section title
          _buildHeader(effectiveSeasonLabel),
          SizedBox(height: AppSpacing.md),

          // Main streak display
          _buildCurrentStreak(),

          // Show previous streak if exists and current is broken
          if (profile.hasPreviousStreak && !profile.hasActiveStreak) ...[
            SizedBox(height: AppSpacing.sm),
            _buildPreviousStreak(),
          ],

          SizedBox(height: AppSpacing.md),

          // Stats row: longest streak + freeze status
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildHeader(String? seasonLabel) {
    return Row(
      children: [
        AppIcon(
          icon: AppPhosphorIcons.flame,
          color: profile.hasActiveStreak ? AppColors.green : _subtitleText,
          size: 20,
        ),
        SizedBox(width: AppSpacing.xs),
        Text(
          'Weekly Streak',
          style: AppTypography.titleMedium.copyWith(
            color: _titleText,
          ),
        ),
        const Spacer(),
        if (seasonLabel != null)
          Text(
            seasonLabel,
            style: AppTypography.labelSmall.copyWith(
              color: _subtitleText,
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStreak() {
    final tier = profile.visualTier;
    final colors = _getTierColors(tier);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Tier icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.flame,
                color: AppColors.pure,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Tier label and week count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.textColor,
                  ),
                ),
                Text(
                  profile.currentWeeksText,
                  style: AppTypography.bodySmall.copyWith(
                    color: _bodyText,
                  ),
                ),
              ],
            ),
          ),

          // Large week count
          Text(
            '${profile.currentWeeks}',
            style: AppTypography.monoDisplay.copyWith(
              color: colors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousStreak() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _statsBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: PhosphorIconsRegular.clockCounterClockwise,
            color: _subtitleText,
            size: 16,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Previous streak',
            style: AppTypography.bodySmall.copyWith(
              color: _subtitleText,
            ),
          ),
          const Spacer(),
          Text(
            profile.previousWeeksText ?? '',
            style: AppTypography.monoMedium.copyWith(
              color: _bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        // Longest streak
        Expanded(
          child: _buildStatItem(
            icon: PhosphorIconsRegular.trophy,
            label: 'Best',
            value: profile.longestWeeksText,
            color: AppColors.gold,
          ),
        ),

        if (showFreezeStatus) ...[
          SizedBox(width: AppSpacing.md),
          // Freeze status
          Expanded(
            child: GestureDetector(
              onTap: onFreezeTap,
              child: _buildFreezeStatus(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required PhosphorIconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _statsBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: icon,
            color: color,
            size: 16,
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: _subtitleText,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.monoSmall.copyWith(
                    color: _bodyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeStatus() {
    final canUse = profile.canUseFreeze;
    final earned = profile.freezeEarned;
    final used = profile.freezeUsed;

    Color iconColor;
    String statusText;
    PhosphorIconData icon;

    if (used) {
      iconColor = _subtitleText;
      statusText = 'Used';
      icon = PhosphorIconsRegular.snowflake;
    } else if (canUse) {
      iconColor = AppColors.info;
      statusText = 'Available';
      icon = PhosphorIconsRegular.snowflake;
    } else if (!earned) {
      iconColor = _subtitleText;
      statusText = 'Locked';
      icon = PhosphorIconsRegular.lock;
    } else {
      iconColor = _subtitleText;
      statusText = 'Unavailable';
      icon = PhosphorIconsRegular.snowflake;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: canUse
            ? AppColors.info.withValues(alpha: 0.1)
            : _statsBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: canUse
            ? Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          AppIcon(
            icon: icon,
            color: iconColor,
            size: 16,
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Freeze',
                  style: AppTypography.labelSmall.copyWith(
                    color: _subtitleText,
                  ),
                ),
                Text(
                  statusText,
                  style: AppTypography.labelSmall.copyWith(
                    color: canUse ? AppColors.info : _bodyText,
                    fontWeight: canUse ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canUse)
            AppIcon(
              icon: PhosphorIconsRegular.caretRight,
              color: AppColors.info,
              size: 14,
            ),
        ],
      ),
    );
  }

  ({
    Color background,
    Color textColor,
    Color borderColor,
    List<Color> gradient,
  }) _getTierColors(StreakTier tier) {
    switch (tier) {
      case StreakTier.none:
        return (
          background: _statsBg,
          textColor: _subtitleText,
          borderColor: _containerBorder,
          gradient: [AppColors.stone, AppColors.slate],
        );
      case StreakTier.ember:
        return (
          background: AppColors.green.withValues(alpha: 0.05),
          textColor: AppColors.greenDark,
          borderColor: AppColors.green.withValues(alpha: 0.15),
          gradient: [AppColors.green, AppColors.greenLight],
        );
      case StreakTier.flame:
        return (
          background: AppColors.green.withValues(alpha: 0.08),
          textColor: AppColors.greenDark,
          borderColor: AppColors.green.withValues(alpha: 0.2),
          gradient: [AppColors.greenDark, AppColors.green],
        );
      case StreakTier.blaze:
        return (
          background: AppColors.green.withValues(alpha: 0.1),
          textColor: AppColors.greenDark,
          borderColor: AppColors.green.withValues(alpha: 0.25),
          gradient: [AppColors.greenDark, AppColors.greenLight],
        );
      case StreakTier.inferno:
        return (
          background: AppColors.gold.withValues(alpha: 0.08),
          textColor: AppColors.goldDark,
          borderColor: AppColors.gold.withValues(alpha: 0.2),
          gradient: [AppColors.gold, AppColors.goldLight],
        );
      case StreakTier.legend:
        return (
          background: AppColors.gold.withValues(alpha: 0.12),
          textColor: AppColors.goldDark,
          borderColor: AppColors.gold.withValues(alpha: 0.3),
          gradient: [AppColors.goldDark, AppColors.gold],
        );
    }
  }
}

/// Compact streak display for tight spaces.
///
/// Shows just the current streak count with tier indicator.
class StreakCompactDisplay extends StatelessWidget {
  const StreakCompactDisplay({
    super.key,
    required this.profile,
  });

  final StreakProfile profile;

  @override
  Widget build(BuildContext context) {
    if (!profile.hasActiveStreak) {
      return const SizedBox.shrink();
    }

    final colors = _getColors(profile.visualTier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: AppIcon(
              icon: AppPhosphorIcons.flame,
              color: AppColors.pure,
              size: 14,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Text(
          '${profile.currentWeeks}',
          style: AppTypography.monoLarge.copyWith(
            color: colors.textColor,
          ),
        ),
      ],
    );
  }

  ({Color textColor, List<Color> gradient}) _getColors(StreakTier tier) {
    if (tier == StreakTier.inferno || tier == StreakTier.legend) {
      return (
        textColor: AppColors.goldDark,
        gradient: [AppColors.gold, AppColors.goldLight],
      );
    }
    return (
      textColor: AppColors.greenDark,
      gradient: [AppColors.green, AppColors.greenLight],
    );
  }
}
