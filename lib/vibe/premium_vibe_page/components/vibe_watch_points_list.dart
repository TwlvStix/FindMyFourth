import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/app_phosphor_icons.dart';
import 'package:find_my_fourth/core/design_tokens/colors.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';
import 'package:find_my_fourth/core/widgets/app_icon.dart';
import 'package:find_my_fourth/services/vibe_match_explanation.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/styles/premium_vibe_page_styles.dart';

/// Vertical stack of watch point cards showing tension areas.
///
/// Each card displays a category name and an insight sentence explaining
/// the potential friction. Position communicates rank (most significant first).
class VibeWatchPointsList extends StatelessWidget {
  const VibeWatchPointsList({
    super.key,
    required this.watchPoints,
    required this.explanation,
  });

  /// List of categories with "watchPoint" or "dealbreakerRisk" status badges,
  /// sorted by weight (high to low)
  final List<CategoryBreakdown> watchPoints;

  /// Match explanation containing insight details
  final MatchExplanation explanation;

  @override
  Widget build(BuildContext context) {
    // If no watch points, don't show this section
    if (watchPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: PremiumVibePageStyles.sectionPaddingMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watch points',
            style: AppTypography.titleSmall.copyWith(
              color: PremiumVibePageStyles.sectionTitleColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Vertical stack of watch point cards
          ...watchPoints.map((breakdown) {
            // Find matching insight from topDifferencesThatMatter
            final insight = explanation.topDifferencesThatMatter.cast<InsightItem?>().firstWhere(
                  (item) => item?.categoryKey == breakdown.category,
                  orElse: () => null,
                );

            final isLastItem = breakdown == watchPoints.last;

            return Padding(
              padding: EdgeInsets.only(
                bottom: isLastItem ? 0 : PremiumVibePageStyles.watchPointCardSpacing,
              ),
              child: _buildWatchPointCard(
                breakdown: breakdown,
                insight: insight,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWatchPointCard({
    required CategoryBreakdown breakdown,
    required InsightItem? insight,
  }) {
    final isDealbreaker = breakdown.statusBadge == VibeStatusBadge.dealbreakerRisk;

    // Choose decoration and icon based on severity
    final decoration = isDealbreaker
        ? PremiumVibePageStyles.dealbreakerCardDecoration
        : PremiumVibePageStyles.watchPointCardDecoration;

    final iconData = isDealbreaker ? AppPhosphorIcons.warning : AppPhosphorIcons.priorityHigh;

    final iconColor = isDealbreaker
        ? PremiumVibePageStyles.dealbreakerIconColor
        : PremiumVibePageStyles.watchPointIconColor;

    return Container(
      padding: PremiumVibePageStyles.watchPointCardPadding,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category name with icon
          Row(
            children: [
              AppIcon(
                icon: iconData,
                size: PremiumVibePageStyles.watchPointIconSize,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  breakdown.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: PremiumVibePageStyles.watchPointNameFontWeight,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          // Insight description (if available)
          if (insight != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              insight.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
