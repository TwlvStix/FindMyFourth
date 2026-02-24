import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/app_phosphor_icons.dart';
import 'package:find_my_fourth/core/design_tokens/colors.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';
import 'package:find_my_fourth/core/widgets/app_icon.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_match_explanation.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/components/vibe_spectrum_bar.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/styles/premium_vibe_page_styles.dart';

/// Collapsible full category breakdown with spectrum visualization.
///
/// Shows all 6 vibe categories with spectrum bars when expanded.
/// Collapsed by default to avoid overwhelming users with detail.
class VibeFullBreakdownSection extends StatelessWidget {
  const VibeFullBreakdownSection({
    super.key,
    required this.categories,
    required this.myProfile,
    required this.theirProfile,
    required this.isExpanded,
    required this.onToggle,
  });

  /// All category breakdowns from match explanation
  final List<CategoryBreakdown> categories;

  /// Current user's vibe profile
  final VibeProfile myProfile;

  /// Matched user's vibe profile
  final VibeProfile theirProfile;

  /// Whether the section is currently expanded
  final bool isExpanded;

  /// Callback when user taps to expand/collapse
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PremiumVibePageStyles.sectionPaddingMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable header row with chevron
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Full category breakdown',
                    style: AppTypography.titleSmall.copyWith(
                      color: PremiumVibePageStyles.sectionTitleColor,
                    ),
                  ),
                ),
                AppIcon(
                  icon: isExpanded ? AppPhosphorIcons.expandLess : AppPhosphorIcons.expandMore,
                  color: AppColors.slate,
                  size: PremiumVibePageStyles.chevronIconSize,
                ),
              ],
            ),
          ),

          // Expanded content (all categories with spectrum bars)
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.md),
            ...VibeCategory.values.map((category) {
              // Find the breakdown for this category
              final breakdown = categories.firstWhere(
                (c) => c.category == category,
              );

              // Get preference values from profiles
              final myPref = myProfile.preferenceFor(category);
              final theirPref = theirProfile.preferenceFor(category);

              final isLastCategory = category == VibeCategory.values.last;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: isLastCategory ? 0 : PremiumVibePageStyles.categoryBreakdownSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category name
                    Text(
                      breakdown.label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: AppTypography.semiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Spectrum bar
                    VibeSpectrumBar(
                      myValue: myPref.value,
                      theirValue: theirPref.value,
                      category: category,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
