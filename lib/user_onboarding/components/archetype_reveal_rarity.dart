import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Displays the rarity label and distribution percentage for an archetype.
///
/// Shows a pill badge with the rarity label (e.g., "LEGENDARY", "RARE")
/// and the percentage of golfers who share this archetype.
class ArchetypeRevealRarity extends StatelessWidget {
  const ArchetypeRevealRarity({
    super.key,
    required this.rarityLabel,
    required this.percentage,
    required this.accentColor,
    required this.animationValue,
  });

  /// The rarity label (e.g., "LEGENDARY", "RARE", "UNCOMMON", "FAN FAVORITE").
  final String rarityLabel;

  /// The distribution percentage of this archetype.
  final int percentage;

  /// The accent color for the rarity pill.
  final Color accentColor;

  /// Animation value (0.0-1.0) for fade and slide.
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final offset = Offset(0, 8 * (1 - animationValue));

    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: animationValue,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rarity pill
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                rarityLabel,
                style: AppTypography.labelMicro.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: AppTypography.letterSpacingWide,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            // Percentage text
            Text(
              '$percentage% of golfers',
              style: AppTypography.labelSmall.copyWith(
                color: AppColorsDark.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
