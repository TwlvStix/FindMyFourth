import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/utils/vibe_archetypes.dart';

/// A shareable card displaying the user's archetype result.
///
/// Designed for screenshot sharing at 1080x1350 portrait (4:5 ratio).
/// This widget is rendered offscreen and captured as an image.
class ArchetypeShareCard extends StatelessWidget {
  const ArchetypeShareCard({
    super.key,
    required this.match,
    required this.tagline,
    required this.rarity,
    required this.percentage,
    required this.accentColor,
    required this.icon,
  });

  /// The archetype match result.
  final VibeArchetypeMatch match;

  /// The archetype's tagline.
  final String tagline;

  /// The rarity label.
  final String rarity;

  /// The distribution percentage.
  final int percentage;

  /// The accent color for styling.
  final Color accentColor;

  /// The archetype's icon.
  final PhosphorIconData icon;

  /// The card's design width (1080px for sharing).
  static const double cardWidth = 1080;

  /// The card's design height (1350px for 4:5 ratio).
  static const double cardHeight = 1350;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColorsDark.navyDark,
            AppColorsDark.navy,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: cardHeight * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.25),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 120),
            child: Column(
              children: [
                const Spacer(flex: 1),
                // Icon
                _buildIconSection(),
                const SizedBox(height: 60),
                // "Your vibe style" label
                Text(
                  'My vibe style',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColorsDark.textMuted,
                    letterSpacing: AppTypography.letterSpacingWide,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 16),
                // Archetype name
                Text(
                  match.name,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColorsDark.textPrimary,
                    fontSize: 72,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Warden base archetype
                if (match.isWarden && match.baseLabel != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    match.baseLabel!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColorsDark.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 32,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                // Tagline
                Text(
                  tagline,
                  style: AppTypography.titleMedium.copyWith(
                    color: accentColor,
                    fontStyle: FontStyle.italic,
                    fontSize: 36,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Rarity pill
                _buildRarityPill(),
                const Spacer(flex: 2),
                // Divider
                Container(
                  width: 300,
                  height: 2,
                  color: accentColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 48),
                // Description
                Text(
                  match.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColorsDark.textSecondary,
                    height: 1.6,
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                // Branding
                _buildBranding(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColorsDark.navyLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.6),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: AppIcon(
          icon: icon,
          size: AppIconSize.xxl * 2.5,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildRarityPill() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Text(
            rarity,
            style: AppTypography.labelLarge.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
              letterSpacing: AppTypography.letterSpacingWide,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          '$percentage% of golfers',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColorsDark.textMuted,
            fontSize: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Text(
          'Find My Fourth',
          style: AppTypography.titleLarge.copyWith(
            color: AppColorsDark.textSecondary,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'findmyfourth.com',
          style: AppTypography.labelMedium.copyWith(
            color: AppColorsDark.textMuted,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
