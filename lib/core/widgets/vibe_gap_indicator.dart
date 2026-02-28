import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/vibe/premium_vibe_page/components/vibe_spectrum_bar.dart';

/// Who is viewing the vibe gap indicator.
///
/// This determines which profile is labeled "You" vs "Them" in the spectrum bars:
/// - [player]: The requesting player is viewing (Stage 2 bottom sheet).
///   "You" = player, "Them" = owner.
/// - [owner]: The game owner is viewing (Stage 3 request cards).
///   "You" = owner, "Them" = player/requester.
enum VibeGapPerspective {
  /// Player requesting to join (default) - "You" = player
  player,

  /// Owner reviewing request - "You" = owner
  owner,
}

/// Displays the top 2-3 vibe dimensions with the largest gaps.
///
/// Reuses the existing [VibeSpectrumBar] component from the full vibe
/// breakdown. This widget filters and sorts dimensions by gap size,
/// showing only the most significant mismatches.
///
/// Used in the vibe floor bottom sheet to explain why a player is below
/// the owner's vibe floor threshold.
class VibeGapIndicator extends StatelessWidget {
  const VibeGapIndicator({
    super.key,
    required this.matchResult,
    required this.ownerProfile,
    required this.playerProfile,
    this.maxDimensions = 2,
    this.perspective = VibeGapPerspective.player,
  });

  /// The full match result containing topDifferences and perCategory data
  final VibeMatchResult matchResult;

  /// The game owner's vibe profile
  final VibeProfile ownerProfile;

  /// The requesting player's vibe profile
  final VibeProfile playerProfile;

  /// Maximum number of dimensions to show (default 2, max 3)
  final int maxDimensions;

  /// Who is viewing the indicator - determines "You" vs "Them" labels.
  /// Default is [VibeGapPerspective.player] for backwards compatibility.
  final VibeGapPerspective perspective;

  @override
  Widget build(BuildContext context) {
    // Use topDifferences from matchResult - already sorted by impact
    final topCategories = matchResult.topDifferences
        .take(maxDimensions.clamp(1, 3))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < topCategories.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.md),
          _buildCategoryRow(topCategories[i].category),
        ],
      ],
    );
  }

  Widget _buildCategoryRow(VibeCategory category) {
    final playerPref = playerProfile.preferenceFor(category);
    final ownerPref = ownerProfile.preferenceFor(category);

    // Swap "You" and "Them" based on who is viewing
    final myPref =
        perspective == VibeGapPerspective.owner ? ownerPref : playerPref;
    final theirPref =
        perspective == VibeGapPerspective.owner ? playerPref : ownerPref;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category label
        Text(
          VibeLabels.titleFor(category),
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Spectrum bar showing "You" vs "Them" positions
        VibeSpectrumBar(
          myValue: myPref.value,
          theirValue: theirPref.value,
          category: category,
          myIsDealbreaker: myPref.dealbreaker,
          theirIsDealbreaker: theirPref.dealbreaker,
        ),
      ],
    );
  }
}
