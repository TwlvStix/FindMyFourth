import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/styles/premium_vibe_page_styles.dart';

/// Hero section displaying the overall fit score and plain-language verdict.
///
/// This is the most important section - if the user reads nothing else,
/// this should be enough to understand the match quality.
class VibeHeroSection extends StatelessWidget {
  const VibeHeroSection({
    super.key,
    required this.fitScore,
    required this.verdict,
  });

  /// The overall fit score (0-100)
  final int fitScore;

  /// Plain-language verdict sentence (e.g., "Solid match. A couple watch points but nothing major.")
  final String verdict;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: PremiumVibePageStyles.sectionPadding,
      child: Column(
        children: [
          // Large fit score
          Text(
            '$fitScore%',
            style: textTheme.displayLarge?.copyWith(
              color: PremiumVibePageStyles.heroScoreColor,
              fontWeight: PremiumVibePageStyles.heroScoreFontWeight,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // "Your Fit" subtitle
          Text(
            'Your Fit',
            style: textTheme.labelMedium?.copyWith(
              color: PremiumVibePageStyles.watchPointIconColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Verdict sentence
          Text(
            verdict,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: PremiumVibePageStyles.verdictTextColor,
              height: PremiumVibePageStyles.verdictLineHeight,
            ),
          ),
        ],
      ),
    );
  }
}
