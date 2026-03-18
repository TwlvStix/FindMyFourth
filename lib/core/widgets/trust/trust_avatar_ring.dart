import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrustRingStyle — visual config per trust tier
// ─────────────────────────────────────────────────────────────────────────────

class TrustRingStyle {
  const TrustRingStyle({
    required this.ringColor,
    this.badgeIcon,
    this.badgeBgColor,
    this.glow,
  });

  final Color ringColor;
  final PhosphorIconData? badgeIcon;
  final Color? badgeBgColor;
  final BoxShadow? glow;

  bool get hasBadge => badgeIcon != null;

  factory TrustRingStyle.fromTier(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.newPlayer:
        return TrustRingStyle(
          ringColor: AppColors.textMuted.withValues(alpha: 0.5),
        );
      case BadgeTier.confirmed:
        return TrustRingStyle(
          ringColor: AppColors.info,
          badgeIcon: AppPhosphorIcons.success,
          badgeBgColor: AppColors.info,
        );
      case BadgeTier.regular:
        return TrustRingStyle(
          ringColor: AppColors.green,
          badgeIcon: AppPhosphorIcons.shield,
          badgeBgColor: AppColors.green,
        );
      case BadgeTier.starter:
        return TrustRingStyle(
          ringColor: AppColors.gold,
          badgeIcon: AppPhosphorIcons.star,
          badgeBgColor: AppColors.gold,
        );
      case BadgeTier.anchor:
        return TrustRingStyle(
          ringColor: AppColors.green,
          badgeIcon: AppPhosphorIcons.anchor,
          badgeBgColor: AppColors.green,
          glow: AppElevation.glowGreen,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrustAvatarRing
// ─────────────────────────────────────────────────────────────────────────────

/// Avatar with a colored trust-tier ring and optional corner badge.
///
/// The ring color and badge icon are derived from [tier].
/// `newPlayer` gets a muted ring with no corner badge.
/// `anchor` gets a green glow effect around the ring.
class TrustAvatarRing extends StatelessWidget {
  const TrustAvatarRing({
    super.key,
    required this.imageUrl,
    required this.tier,
    this.size = 52,
    this.borderRadius = AppBorderRadius.lg,
  });

  final String imageUrl;
  final BadgeTier tier;
  final double size;
  final double borderRadius;

  static const double _ringWidth = 2.5;
  static const double _badgeSize = 18.0;
  static const double _badgeIconSize = 11.0;
  static const double _badgeBorderWidth = 1.5;
  static const double _badgeOffset = -3.0;

  @override
  Widget build(BuildContext context) {
    final style = TrustRingStyle.fromTier(tier);
    final outerSize = size + (_ringWidth * 2);

    return SizedBox(
      // Extra room for the overflowing corner badge
      width: outerSize + 4,
      height: outerSize + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Ring + avatar ──────────────────────────────────────────────
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius + _ringWidth),
                border: Border.all(
                  color: style.ringColor,
                  width: _ringWidth,
                ),
                boxShadow: style.glow != null ? [style.glow!] : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius - 1),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        errorWidget: (_, __, ___) =>
                            _AvatarPlaceholder(size: size),
                      )
                    : _AvatarPlaceholder(size: size),
              ),
            ),
          ),

          // ── Corner badge ───────────────────────────────────────────────
          if (style.hasBadge)
            Positioned(
              bottom: _badgeOffset + 2,
              right: _badgeOffset + 2,
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: style.badgeBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.navyDark,
                    width: _badgeBorderWidth,
                  ),
                ),
                child: Center(
                  child: AppIcon(
                    icon: style.badgeIcon!,
                    size: _badgeIconSize,
                    color: AppColors.textPrimary,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar placeholder (shared fallback)
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.whiteSubtle,
      child: Center(
        child: AppIcon(
          icon: AppPhosphorIcons.profile,
          color: AppColors.glassTextTertiary,
          size: AppIconSize.md,
        ),
      ),
    );
  }
}
