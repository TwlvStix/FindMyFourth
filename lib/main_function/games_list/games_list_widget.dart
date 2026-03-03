import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/fairway_background.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/games_list_app_bar.dart';
import '/main_function/games_list/components/games_list_content.dart';
import '/main_function/games_list/components/games_list_dialogs.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/models/game.dart';
import '/providers/game_provider.dart';
import '/providers/profile_provider.dart';
import '/providers/user_provider.dart';
import '/utils/app_util.dart';

class GamesListWidget extends StatefulWidget {
  const GamesListWidget({super.key});

  static String routeName = 'GamesList';
  static String routePath = '/gamesList';

  @override
  State<GamesListWidget> createState() => _GamesListWidgetState();
}

class _GamesListWidgetState extends State<GamesListWidget> {
  final Map<DocumentReference, CancelledGameHandling>
      _cancelledGameHandlingByGame = {};
  late Stream<List<Game>> _gamesStream;
  bool _didInitDependencies = false;
  List<Game>? _cachedGames;
  GameListFilters _filters = GameListFilters();

  // Cache for the last computed filter metadata (not state - updated during build)
  GameFilterMeta _lastFilterMeta = const GameFilterMeta.empty();

  // Track last warmed profile UIDs to avoid redundant warming calls
  Set<String> _lastWarmedProfileUids = {};

  // Pending warm UIDs for deferred processing (avoids side effects during build)
  Set<String>? _pendingWarmUids;

  // Gate to prevent scheduling multiple callbacks before prior one runs
  bool _warmScheduled = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  /// Schedules profile warming to run after the current build completes.
  void _scheduleProfileWarm(Set<String> ownerUids) {
    if (ownerUids.isEmpty) return;
    if (setEquals(ownerUids, _lastWarmedProfileUids)) return;

    // Prevent scheduling if already scheduled for same UIDs
    if (_warmScheduled && setEquals(ownerUids, _pendingWarmUids)) return;

    _pendingWarmUids = ownerUids;

    if (!_warmScheduled) {
      _warmScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processPendingProfileWarm();
      });
    }
  }

  void _processPendingProfileWarm() {
    _warmScheduled = false;
    if (!mounted) return;

    final uids = _pendingWarmUids;
    if (uids == null || uids.isEmpty) return;

    _pendingWarmUids = null;
    _lastWarmedProfileUids = uids;
    context.read<ProfileProvider>().warmProfiles(uids);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didInitDependencies) {
      final gameProvider = context.read<GameProvider>();

      // Retrieve cached data
      final cachedRecords = gameProvider.getCachedAvailableGames();
      if (cachedRecords != null) {
        _cachedGames =
            cachedRecords.map((record) => Game.fromRecord(record)).toList();
      }

      _gamesStream = gameProvider.availableGamesStream().map((records) =>
          records.map((record) => Game.fromRecord(record)).toList());
      _didInitDependencies = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _retryGamesStream() {
    final gameProvider = context.read<GameProvider>();
    updateState(this, () {
      _gamesStream = gameProvider.availableGamesStream().map((records) =>
          records.map((record) => Game.fromRecord(record)).toList());
    });
  }

  CancelledGameHandling? _getCancelledHandling(Game game) {
    return getCancelledHandling(game, _cancelledGameHandlingByGame);
  }

  bool _shouldHideCancelledGame(Game game) {
    return shouldHideCancelledGame(game, _cancelledGameHandlingByGame);
  }

  Future<void> _handleFilterButtonTap() async {
    final result = await showGameListFilterSheet(
      context: context,
      currentFilters: _filters,
      filterMeta: _lastFilterMeta,
    );
    if (result != null && mounted) {
      updateState(this, () {
        _filters = result;
      });
    }
  }

  Future<void> _handleCancelledGameTap(Game game) async {
    final selection = await showCancelledGameOptionsDialog(context: context);
    if (selection == null || !mounted) return;

    updateState(this, () {
      _cancelledGameHandlingByGame[game.reference] = selection;
    });

    context.read<AppState>().setCancelledGameHandling(
      game.reference.path,
      cancelledHandlingStorageMap[selection]!,
    );

    if (selection == CancelledGameHandling.removeAfter7Days) {
      context.read<AppState>().setCancelledGameHideAt(
        game.reference.path,
        getCurrentTimestamp.add(Duration(days: 7)),
      );
    }
  }

  Future<void> _handleFriendsOnlyTap() async {
    await showFriendsOnlyInfoDialog(context: context);
  }

  Future<void> _sendFriendRequest(
    BuildContext context,
    DocumentReference hostRef,
  ) async {
    try {
      await context.read<UserProvider>().sendFriendRequest(hostRef);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLog.d('❌ GamesListWidget._sendFriendRequest error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend request. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleSeeAllFlexible(
    List<Game> games,
    DocumentReference? currentUserReference,
  ) {
    showFlexibleGamesSheet(
      context: context,
      games: games,
      currentUserReference: currentUserReference,
    );
  }

  Future<void> _handleRefresh() async {
    context.read<GameProvider>().invalidateAllGameCache();
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      updateState(this, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserReference = context.select<UserProvider, DocumentReference?>(
      (p) => p.currentUser?.reference,
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: GamesListAppBar(
          hasActiveFilters: _filters.hasActiveFilters,
          onFilterTap: _handleFilterButtonTap,
          onNotificationTap: () => context.pushNotifications(),
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: MediaQuery.of(context).padding.top + 56,
              ),
              child: GamesListContent(
                gamesStream: _gamesStream,
                initialGames: _cachedGames ?? const <Game>[],
                currentUserReference: currentUserReference,
                filters: _filters,
                shouldHideCancelledGame: _shouldHideCancelledGame,
                getCancelledHandling: _getCancelledHandling,
                onFilterMetaChanged: (meta) => _lastFilterMeta = meta,
                onOwnerUidsReady: _scheduleProfileWarm,
                onCancelledGameTap: _handleCancelledGameTap,
                onFriendsOnlyTap: _handleFriendsOnlyTap,
                onSendFriendRequest: _sendFriendRequest,
                onToggleVisibility: () {
                  final appState = context.read<AppState>();
                  appState.hideFriendsOnlyGames = !appState.hideFriendsOnlyGames;
                },
                onSeeAllFlexible: _handleSeeAllFlexible,
                onCreateGame: () => context.pushCreateGame(
                  transition: TransitionStandards.detailTransition,
                ),
                onRefresh: _handleRefresh,
                onRetry: _retryGamesStream,
                onNavigateToStanding: () => context.pushYourStanding(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
