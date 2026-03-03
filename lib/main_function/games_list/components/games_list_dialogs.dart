import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/main_function/games_list/components/flexible_games_bottom_sheet.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/models/game.dart';

/// Shows the game list filter bottom sheet and returns selected filters.
///
/// Returns null if the user dismisses without applying.
Future<GameListFilters?> showGameListFilterSheet({
  required BuildContext context,
  required GameListFilters currentFilters,
  required GameFilterMeta filterMeta,
}) async {
  final topPadding = MediaQuery.of(context).padding.top;
  return showModalBottomSheet<GameListFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => GameListFilterBottomSheet(
      currentFilters: currentFilters,
      availableGameTypes: filterMeta.availableGameTypes,
      availableVibes: filterMeta.availableVibes,
      availableStakes: filterMeta.availableStakes,
      availableHandicaps: filterMeta.availableHandicaps,
      availableCourses: filterMeta.availableCourses,
      availableEligibilities: filterMeta.availableEligibilities,
      topPadding: topPadding,
    ),
  );
}

/// Shows the flexible games bottom sheet.
void showFlexibleGamesSheet({
  required BuildContext context,
  required List<Game> games,
  required DocumentReference? currentUserReference,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => FlexibleGamesBottomSheet(
      games: games,
      currentUserReference: currentUserReference,
    ),
  );
}

/// Shows the cancelled game options dialog and returns the selected handling.
///
/// Returns null if the user dismisses without selecting.
Future<CancelledGameHandling?> showCancelledGameOptionsDialog({
  required BuildContext context,
}) {
  return showDialog<CancelledGameHandling>(
    context: context,
    builder: (alertDialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text(
          'Game cancelled',
          style:
              AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'How would you like to handle this game?',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          AppButtonEnhanced(
            text: 'Remove now',
            variant: AppButtonVariant.destructiveOutlined,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(
              alertDialogContext,
              CancelledGameHandling.removeNow,
            ),
          ),
          AppButtonEnhanced(
            text: 'Hide after 7 days',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(
              alertDialogContext,
              CancelledGameHandling.removeAfter7Days,
            ),
          ),
          AppButtonEnhanced(
            text: 'Keep in list',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(
              alertDialogContext,
              CancelledGameHandling.keepInList,
            ),
          ),
        ],
      );
    },
  );
}

/// Shows the friends-only informational dialog.
Future<void> showFriendsOnlyInfoDialog({
  required BuildContext context,
}) {
  return showPremiumDialog(
    context: context,
    variant: PremiumDialogVariant.informational,
    icon: PhosphorIconsRegular.lock,
    title: 'Friends Only Game',
    body:
        'This game is visible to friends only. Add the host as a friend to view details.',
    actionLabel: 'Got It',
  );
}
