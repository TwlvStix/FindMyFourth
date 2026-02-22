/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM UI PATTERNS - Find My Fourth
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This file contains reusable premium UI patterns extracted from the Profile
/// redesign. Use these patterns throughout the app for consistency.
///
/// Design Language: "The Clubhouse"
/// - Club Navy structural backgrounds + Fairway Green accents
/// - Prestige Gold for trust tiers, achievements, premium elements
/// - Glass-morphic cards on dark backgrounds
/// - Gradient accents for emphasis
/// - Subtle animations for delight
/// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_icon.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GRADIENT PRESETS
// ═══════════════════════════════════════════════════════════════════════════

class AppGradients {
  AppGradients._();

  /// Primary gold gradient for CTAs and highlights
  static const gold = LinearGradient(
    colors: [AppColors.gold, AppColors.goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warm accent gradient for social/friends elements
  static const warmAccent = LinearGradient(
    colors: [AppColors.goldLight, AppColors.error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Green gradient for golf/nature elements
  static const green = LinearGradient(
    colors: [AppColors.greenLight, AppColors.green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Navy gradient for backgrounds
  static const navy = LinearGradient(
    colors: [AppColors.navy, AppColors.navyDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Full spectrum sweep for animated rings - green-centric with navy depth
  static const accentSweep = SweepGradient(
    colors: [
      AppColors.green,
      AppColors.greenLight,
      AppColors.gold,
      AppColors.navy,
      AppColors.green,
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS-MORPHIC CARD (Dark Background)
// ═══════════════════════════════════════════════════════════════════════════

/// A semi-transparent card that works on dark backgrounds
/// Used for stats, info cards, and overlays on FairwayBackgroundDark
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double opacity;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.opacity = 0.3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: padding ?? EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha:opacity),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.glassSurface,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADIENT ICON BOX
// ═══════════════════════════════════════════════════════════════════════════

/// A gradient-filled box containing an icon
/// Used for action buttons, stat indicators, and category icons
class GradientIconBox extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final List<Color> gradientColors;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool withShadow;

  const GradientIconBox({
    super.key,
    this.icon,
    this.svgPath,
    required this.gradientColors,
    this.size = 48,
    this.iconSize = 24,
    this.borderRadius = 14,
    this.withShadow = true,
  }) : assert(icon != null || svgPath != null, 'Either icon or svgPath must be provided');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha:0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: svgPath != null
          ? Center(
              child: SvgPicture.asset(
                svgPath!,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            )
          : Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED AVATAR RING
// ═══════════════════════════════════════════════════════════════════════════

/// An animated rotating gradient ring around an avatar
/// Creates a premium, eye-catching profile display
class AnimatedAvatarRing extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onEditTap;
  final Widget? fallbackIcon;

  const AnimatedAvatarRing({
    super.key,
    this.imageUrl,
    this.size = 132,
    this.onEditTap,
    this.fallbackIcon,
  });

  @override
  State<AnimatedAvatarRing> createState() => _AnimatedAvatarRingState();
}

class _AnimatedAvatarRingState extends State<AnimatedAvatarRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = widget.size + 16;
    final borderSize = widget.size + 8;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: ringSize + 12,
          height: ringSize + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha:0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // Rotating gradient ring
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.14159,
              child: Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.accentSweep,
                ),
              ),
            );
          },
        ),

        // White border
        Container(
          width: borderSize,
          height: borderSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pure,
          ),
        ),

        // Avatar image
        Container(
          width: widget.size,
          height: widget.size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
              ? Image.network(
                  widget.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallback(),
                )
              : _buildFallback(),
        ),

        // Edit button
        if (widget.onEditTap != null)
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onEditTap!();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.green,
                  shape: BoxShape.circle,
                  boxShadow: [AppElevation.glowGreen],
                ),
                child: AppIcon(
                  assetPath: AppIcons.camera,
                  color: Colors.white,
                  size: AppIconSize.button,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.sand,
      child: widget.fallbackIcon ??
          AppIcon(
            assetPath: AppIcons.profile,
            size: widget.size * 0.45,
            color: AppColors.stone,
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════════════════

/// A compact stat display card for metrics like handicap, friends count, etc.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradientColors;
  final bool isTextValue;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.gradientColors,
    this.isTextValue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      onTap: onTap,
      child: Column(
        children: [
          GradientIconBox(
            icon: icon,
            gradientColors: gradientColors,
            size: 36,
            iconSize: 16,
            borderRadius: 10,
            withShadow: false,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: isTextValue
                ? AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                : AppTypography.monoLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.glassTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUICK ACTION CARD
// ═══════════════════════════════════════════════════════════════════════════

/// A tappable action card with gradient icon
/// Used for quick navigation to common actions
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.cloud),
        ),
        child: Column(
          children: [
            GradientIconBox(
              icon: icon,
              gradientColors: gradientColors,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.slate,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INFO ROW
// ═══════════════════════════════════════════════════════════════════════════

/// A labeled info row with colored icon badge
/// Used for displaying user details like email, phone, etc.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.cloud),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: AppIconSize.button),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onyx,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.stone,
                size: AppIconSize.md,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION BADGE
// ═══════════════════════════════════════════════════════════════════════════

/// A gradient notification badge with glow effect
class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return SizedBox.shrink();

    final displayText = count > 99 ? '99+' : '$count';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs - 2, vertical: AppSpacing.xxs - 1),
      decoration: BoxDecoration(
        gradient: AppGradients.warmAccent,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha:0.4),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET CARD
// ═══════════════════════════════════════════════════════════════════════════

/// A card that looks like a bottom sheet sliding up
/// Has rounded top corners and a drag handle
class BottomSheetCard extends StatelessWidget {
  final Widget child;
  final double topRadius;

  const BottomSheetCard({
    super.key,
    required this.child,
    this.topRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topRadius),
          topRight: Radius.circular(topRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cloud,
              borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USERNAME PILL
// ═══════════════════════════════════════════════════════════════════════════

/// A pill-shaped badge for displaying usernames
class UsernamePill extends StatelessWidget {
  final String username;
  final bool showAtSymbol;

  const UsernamePill({
    super.key,
    required this.username,
    this.showAtSymbol = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha:0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: AppColors.glassSurface,
        ),
      ),
      child: Text(
        showAtSymbol ? '@$username' : username,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
