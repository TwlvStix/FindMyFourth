import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/app_phosphor_icons.dart';
import 'package:find_my_fourth/core/design_tokens/colors.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';
import 'package:find_my_fourth/core/widgets/app_icon.dart';
import 'package:find_my_fourth/services/vibe_match_explanation.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/styles/premium_vibe_page_styles.dart';

/// Compressed display of aligned vibe categories.
///
/// Shows categories where users' preferences align as compact pill chips.
/// Effortless to scan, confirms compatibility at a glance.
class VibeStrengthsList extends StatelessWidget {
  const VibeStrengthsList({
    super.key,
    required this.alignedCategories,
  });

  /// List of categories with "aligned" status badge
  final List<CategoryBreakdown> alignedCategories;

  @override
  Widget build(BuildContext context) {
    // If no aligned categories, don't show this section
    if (alignedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: PremiumVibePageStyles.sectionPaddingMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What aligns',
            style: AppTypography.titleSmall.copyWith(
              color: PremiumVibePageStyles.sectionTitleColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Horizontal wrap of chips
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: alignedCategories.map((breakdown) {
              return _buildStrengthChip(breakdown.label);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthChip(String label) {
    return Container(
      padding: PremiumVibePageStyles.chipPadding,
      decoration: PremiumVibePageStyles.strengthChipDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.successFill,
            size: PremiumVibePageStyles.chipIconSize,
            color: PremiumVibePageStyles.alignedIconColor,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
