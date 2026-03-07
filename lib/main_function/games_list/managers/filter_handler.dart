import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '/core/utils/state_update.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/games_list_dialogs.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/models/game.dart';
import '/utils/app_util.dart';

/// Handles filter and dialog interactions for the games list.
///
/// Manages filter bottom sheet, cancelled game dialogs, and friends-only info.
class GamesListFilterHandler {
  GamesListFilterHandler({
    required State state,
    required this.getFilters,
    required this.setFilters,
    required this.getFilterMeta,
    required this.cancelledGameHandlingByGame,
  }) : _state = state;

  final State _state;

  /// Getter for current filters.
  final GameListFilters Function() getFilters;

  /// Setter for updated filters.
  final void Function(GameListFilters) setFilters;

  /// Getter for current filter metadata.
  final GameFilterMeta Function() getFilterMeta;

  /// Map of cancelled game handling by game reference.
  final Map<DocumentReference, CancelledGameHandling> cancelledGameHandlingByGame;

  /// Shows the filter bottom sheet and updates filters if changed.
  Future<void> handleFilterButtonTap() async {
    final result = await showGameListFilterSheet(
      context: _state.context,
      currentFilters: getFilters(),
      filterMeta: getFilterMeta(),
    );
    if (result != null && _state.mounted) {
      updateState(_state, () {
        setFilters(result);
      });
    }
  }

  /// Shows cancelled game options dialog and updates handling preference.
  Future<void> handleCancelledGameTap(Game game) async {
    final selection = await showCancelledGameOptionsDialog(context: _state.context);
    if (selection == null || !_state.mounted) return;

    updateState(_state, () {
      cancelledGameHandlingByGame[game.reference] = selection;
    });

    _state.context.read<AppState>().setCancelledGameHandling(
          game.reference.path,
          cancelledHandlingStorageMap[selection]!,
        );

    if (selection == CancelledGameHandling.removeAfter7Days) {
      _state.context.read<AppState>().setCancelledGameHideAt(
            game.reference.path,
            getCurrentTimestamp.add(Duration(days: 7)),
          );
    }
  }

  /// Shows the friends-only info dialog.
  Future<void> handleFriendsOnlyTap() async {
    await showFriendsOnlyInfoDialog(context: _state.context);
  }
}
