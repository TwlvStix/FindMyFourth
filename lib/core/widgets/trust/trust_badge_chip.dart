import 'package:flutter/material.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';

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
        return const BadgeTierStyle(
          label: 'NEW',
          accent: Color(0xFFD4A843),
          borderColor: Color(0x33D4A843),
        );
      case BadgeTier.confirmed:
        return const BadgeTierStyle(
          label: 'CONFIRMED',
          accent: Color(0xFFA8B4C0),
          borderColor: Color(0x33A8B4C0),
        );
      case BadgeTier.regular:
        return const BadgeTierStyle(
          label: 'REGULAR',
          accent: Color(0xFF6BAF8D),
          borderColor: Color(0x336BAF8D),
        );
      case BadgeTier.starter:
        return const BadgeTierStyle(
          label: 'STARTER',
          accent: Color(0xFFC9895A),
          borderColor: Color(0x33C9895A),
        );
      case BadgeTier.anchor:
        return const BadgeTierStyle(
          label: 'ANCHOR',
          accent: Color(0xFFB8A0D4),
          borderColor: Color(0x33B8A0D4),
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
/// gets a custom premium treatment with AppElevation.glowGold.
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
          icon: Icons.golf_course_rounded,
          backgroundColor: AppColors.goldLight.withValues(alpha:0.15),
          borderColor: AppColors.goldLight.withValues(alpha:0.55),
          textColor: AppColors.goldLight,
          boxShadow: const BoxShadow(
            color: Color(0x40E89E71), // sunsetPeach ~25% opacity
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        );
      case BadgeTier.confirmed:
        return _BadgeConfig(
          label: 'Confirmed',
          descriptor: "You've been verified by the community.",
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: AppColors.info.withValues(alpha:0.12),
          borderColor: AppColors.info.withValues(alpha:0.4),
          textColor: AppColors.info,
        );
      case BadgeTier.regular:
        return _BadgeConfig(
          label: 'Regular',
          descriptor: 'A reliable player on the platform.',
          icon: Icons.sports_golf_rounded,
          backgroundColor: AppColors.success.withValues(alpha:0.12),
          borderColor: AppColors.success.withValues(alpha:0.4),
          textColor: AppColors.success,
        );
      case BadgeTier.starter:
        return _BadgeConfig(
          label: 'Starter',
          descriptor: 'An active host and trusted player.',
          icon: Icons.flag_rounded,
          backgroundColor: AppColors.navy.withValues(alpha:0.12),
          borderColor: AppColors.navy.withValues(alpha:0.4),
          textColor: AppColors.navy,
        );
      case BadgeTier.anchor:
        return _BadgeConfig(
          label: 'Anchor',
          descriptor: 'A cornerstone of the community.',
          icon: Icons.verified_rounded,
          backgroundColor: AppColors.gold.withValues(alpha:0.12),
          borderColor: AppColors.gold.withValues(alpha:0.4),
          textColor: AppColors.gold,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: config.boxShadow != null ? [config.boxShadow!] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icon, color: config.textColor, size: 14),
              const SizedBox(width: 5),
              Text(
                config.label,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            border: Border.all(color: config.borderColor, width: 1),
            boxShadow: const [AppElevation.glowGold],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icon, color: config.textColor, size: 14),
              const SizedBox(width: 5),
              Text(
                config.label,
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final BoxShadow? boxShadow;
}
