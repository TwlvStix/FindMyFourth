import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_empty_state_premium.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/providers/geo_filter_provider.dart';

/// Empty state shown when there are no games in any section.
class GamesListEmptyState extends StatelessWidget {
  const GamesListEmptyState({
    super.key,
    required this.onCreateGame,
  });

  /// Callback when user taps the "Create a game" button.
  final VoidCallback onCreateGame;

  @override
  Widget build(BuildContext context) {
    final geoFilter = context.watch<GeoFilterProvider>();

    // Show geo-specific empty state when filter is active
    final isGeoFiltered = geoFilter.isEnabled && geoFilter.hasLocation;
    final radiusKm = geoFilter.radiusKm.toInt();

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).padding.bottom + 128.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppEmptyStatePremium(
            icon: isGeoFiltered
                ? AppPhosphorIcons.homeCourse
                : AppPhosphorIcons.games,
            title: isGeoFiltered
                ? 'No games within $radiusKm km'
                : 'No Games Yet',
            message: isGeoFiltered
                ? 'Try expanding your search radius in Settings.'
                : 'Join or create a game to get started.',
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 220,
            child: AppButtonEnhanced(
              text: 'Create a game',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.medium,
              onPressed: onCreateGame,
            ),
          ),
        ],
      ),
    );
  }
}
