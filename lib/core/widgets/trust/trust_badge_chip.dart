import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mode
// ─────────────────────────────────────────────────────────────────────────────

enum TrustBadgeChipMode {
  /// Icon + label only — game lobbies, other players' profiles.
  compact,

  /// Icon + label + one-line descriptor — player's own profile.
  expanded,
}

// ─────────────────────────────────────────────────────────────────────────────
// BadgeTierStyle — pendant color + label map
// ─────────────────────────────────────────────────────────────────────────────

class BadgeTierStyle {
  final String label;
  final Color accent;
  final Color borderColor;

  const BadgeTierStyle({
    required this.label,
    required this.accent,
    required this.borderColor,
  });

  static BadgeTierStyle fromTier(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.newPlayer:
        // NEW is informational, not earned — use subtle neutral tones
        return BadgeTierStyle(
          label: 'NEW',
          accent: AppColors.textSecondary,
          borderColor: AppColors.glassBorder,
        );
      case BadgeTier.confirmed:
        return BadgeTierStyle(
          label: 'CONFIRMED',
          accent: AppColors.trustSilverFg,
          borderColor: AppColors.trustSilverBg,
        );
      case BadgeTier.regular:
        return BadgeTierStyle(
          label: 'REGULAR',
          accent: AppColors.trustPlatinumFg,
          borderColor: AppColors.trustPlatinumBg,
        );
      case BadgeTier.starter:
        return BadgeTierStyle(
          label: 'STARTER',
          accent: AppColors.trustBronzeFg,
          borderColor: AppColors.trustBronzeBg,
        );
      case BadgeTier.anchor:
        return BadgeTierStyle(
          label: 'ANCHOR',
          accent: AppColors.trustCopperFg,
          borderColor: AppColors.trustCopperBg,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrustBadgeChip
// ─────────────────────────────────────────────────────────────────────────────

/// Reusable trust badge chip for displaying a player's badge tier.
///
/// Uses AppBadge-style pill shape for all tiers except Anchor, which
/// gets a custom premium treatment with AppElevation.glowGreen.
///
/// Compact mode: icon + label (use in lobbies and other profiles)
/// Expanded mode: icon + label + descriptor (use on own profile)
class TrustBadgeChip extends StatelessWidget {
  const TrustBadgeChip({
    super.key,
    required this.tier,
    this.mode = TrustBadgeChipMode.compact,
  });

  final BadgeTier tier;
  final TrustBadgeChipMode mode;

  @override
  Widget build(BuildContext context) {
    final config = _configForTier(tier);

    if (tier == BadgeTier.anchor) {
      return _AnchorBadgeChip(config: config, mode: mode);
    }

    return _StandardBadgeChip(config: config, mode: mode);
  }

  static _BadgeConfig _configForTier(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.newPlayer:
        return _BadgeConfig(
          label: 'New',
          descriptor: 'Welcome! Play your first rounds to build your reputation.',
          icon: AppPhosphorIcons.golfCourse,
          backgroundColor: AppColors.greenLight.withValues(alpha:0.12),
          borderColor: AppColors.greenLight.withValues(alpha:0.4),
          textColor: AppColors.greenLight,
          boxShadow: AppElevation.glowGreen,
        );
      case BadgeTier.confirmed:
        return _BadgeConfig(
          label: 'Confirmed',
          descriptor: "You've been verified by the community.",
          icon: AppPhosphorIcons.success,
          backgroundColor: AppColors.info.withValues(alpha:0.12),
          borderColor: AppColors.info.withValues(alpha:0.4),
          textColor: AppColors.info,
        );
      case BadgeTier.regular:
        return _BadgeConfig(
          label: 'Regular',
          descriptor: 'A reliable player on the platform.',
          icon: AppPhosphorIcons.golfCourse,
          backgroundColor: AppColors.success.withValues(alpha:0.12),
          borderColor: AppColors.success.withValues(alpha:0.4),
          textColor: AppColors.success,
        );
      case BadgeTier.starter:
        return _BadgeConfig(
          label: 'Starter',
          descriptor: 'An active host and trusted player.',
          icon: AppPhosphorIcons.games,
          backgroundColor: AppColors.navy.withValues(alpha:0.12),
          borderColor: AppColors.navy.withValues(alpha:0.4),
          textColor: AppColors.navy,
        );
      case BadgeTier.anchor:
        return _BadgeConfig(
          label: 'Anchor',
          descriptor: 'A cornerstone of the community.',
          icon: AppPhosphorIcons.verified,
          backgroundColor: AppColors.green.withValues(alpha:0.12),
          borderColor: AppColors.green.withValues(alpha:0.4),
          textColor: AppColors.green,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: Standard badge (non-Anchor)
// ─────────────────────────────────────────────────────────────────────────────

class _StandardBadgeChip extends StatelessWidget {
  const _StandardBadgeChip({required this.config, required this.mode});

  final _BadgeConfig config;
  final TrustBadgeChipMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: config.boxShadow != null ? [config.boxShadow!] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon: config.icon, color: config.textColor, size: AppIconSize.xs),
              AppSpacing.horizontalXxs,
              Text(
                config.label,
                style: AppTypography.labelSmall.copyWith(
                  fontFamily: AppTypography.displayFamily,
                  color: config.textColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (mode == TrustBadgeChipMode.expanded) ...[
          SizedBox(height: AppSpacing.xxs),
          Text(
            config.descriptor,
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: Anchor premium badge
// ─────────────────────────────────────────────────────────────────────────────

class _AnchorBadgeChip extends StatelessWidget {
  const _AnchorBadgeChip({required this.config, required this.mode});

  final _BadgeConfig config;
  final TrustBadgeChipMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: const [AppElevation.glowGreen],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon: config.icon, color: config.textColor, size: AppIconSize.xs),
              AppSpacing.horizontalXxs,
              Text(
                config.label,
                style: AppTypography.labelSmall.copyWith(
                  fontFamily: AppTypography.displayFamily,
                  color: config.textColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (mode == TrustBadgeChipMode.expanded) ...[
          SizedBox(height: AppSpacing.xxs),
          Text(
            config.descriptor,
            style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeConfig {
  const _BadgeConfig({
    required this.label,
    required this.descriptor,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.boxShadow,
  });

  final String label;
  final String descriptor;
  final PhosphorIconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final BoxShadow? boxShadow;
}
