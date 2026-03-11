import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/navigation/transition_standards.dart';
import '/core/utils/app_log.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/fairway_background.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/games_list_app_bar.dart';
import '/main_function/games_list/components/games_list_content.dart';
import '/main_function/games_list/managers/filter_handler.dart';
import '/main_function/games_list/managers/mutual_action_handler.dart';
import '/main_function/games_list/managers/mutual_friends_manager.dart';
import '/main_function/games_list/managers/profile_warmer.dart';
import '/main_function/games_list/models/quick_filter.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/models/game.dart';
import '/providers/game_provider.dart';
import '/providers/geo_filter_provider.dart';
import '/providers/user_provider.dart';

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

  // Quick filter and sort state
  QuickFilter _quickFilter = QuickFilter.all;
  GameSortOption _sortOption = GameSortOption.soonest;

  // Vibe scores cache (game reference ID -> score 0-100)
  final Map<String, double> _vibeScores = {};

  // Cache for the last computed filter metadata (not state - updated during build)
  GameFilterMeta _lastFilterMeta = const GameFilterMeta.empty();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Managers for extracted logic
  late final GamesListProfileWarmer _profileWarmer;
  late final GamesListMutualFriendsManager _mutualFriendsManager;
  late final GamesListMutualActionHandler _mutualActionHandler;
  late final GamesListFilterHandler _filterHandler;

  @override
  void initState() {
    super.initState();
    _initManagers();
  }

  void _initManagers() {
    _mutualFriendsManager = GamesListMutualFriendsManager(state: this);
    _mutualActionHandler = GamesListMutualActionHandler(state: this);
    _profileWarmer = GamesListProfileWarmer(
      state: this,
      onProfilesWarmed: () {
        // After profiles are warmed, recompute mutual friends if pending
        if (_mutualFriendsManager.hasPendingHosts) {
          _mutualFriendsManager.processPendingMutualFetch();
        }
      },
    );
    _filterHandler = GamesListFilterHandler(
      state: this,
      getFilters: () => _filters,
      setFilters: (f) => _filters = f,
      getFilterMeta: () => _lastFilterMeta,
      cancelledGameHandlingByGame: _cancelledGameHandlingByGame,
    );
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

      // Initialize GeoFilterProvider with user's location settings
      _initGeoFilterFromUser();

      _didInitDependencies = true;
    }
  }

  /// Initialize the GeoFilterProvider with user's stored location settings.
  void _initGeoFilterFromUser() {
    final userProvider = context.read<UserProvider>();
    final geoFilter = context.read<GeoFilterProvider>();

    // Only initialize if user has loaded
    if (!userProvider.isAuthReady) return;

    final user = userProvider.currentUser;
    if (user == null) return;

    geoFilter.initFromUserProfile(
      nearMeEnabled: user.nearMeEnabled,
      locationSource: user.locationSource,
      homeCourseLat: userProvider.homeCourseLat,
      homeCourseLng: userProvider.homeCourseLng,
      hometownLat: userProvider.hometownLat,
      hometownLng: userProvider.hometownLng,
      searchRadiusKm: userProvider.searchRadiusKm,
    );
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

  void _handleQuickFilterChanged(QuickFilter filter) {
    updateState(this, () {
      _quickFilter = filter;
    });
  }

  void _handleSortChanged(GameSortOption option) {
    updateState(this, () {
      _sortOption = option;
    });
  }

  Future<void> _handleRefresh() async {
    context.read<GameProvider>().invalidateAllGameCache();
    // Clear mutual friend caches on refresh
    _mutualFriendsManager.clearCache();
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      updateState(this, () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserReference =
        context.select<UserProvider, DocumentReference?>(
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
          activeFilterCount: _filters.activeFilterCount,
          onFilterTap: _filterHandler.handleFilterButtonTap,
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
                quickFilter: _quickFilter,
                sortOption: _sortOption,
                vibeScores: _vibeScores,
                getCancelledHandling: _getCancelledHandling,
                onFilterMetaChanged: (meta) => _lastFilterMeta = meta,
                onOwnerUidsReady: _profileWarmer.scheduleProfileWarm,
                onCancelledGameTap: _filterHandler.handleCancelledGameTap,
                onFriendsOnlyTap: _filterHandler.handleFriendsOnlyTap,
                onSendFriendRequest: _sendFriendRequest,
                onQuickFilterChanged: _handleQuickFilterChanged,
                onSortChanged: _handleSortChanged,
                onCreateGame: () => context.pushCreateGame(
                  transition: TransitionStandards.detailTransition,
                ),
                onRefresh: _handleRefresh,
                onRetry: _retryGamesStream,
                onNavigateToStanding: () => context.pushYourStanding(),
                // Mutual friend data
                mutualFriendHostIds: _mutualFriendsManager.mutualFriendHostIds,
                firstMutualFriendName: _mutualFriendsManager.firstMutualFriendName,
                mutualFriendsMap: _mutualFriendsManager.mutualFriendsMap,
                chatActionStates: _mutualActionHandler.chatActionStates,
                friendActionStates: _mutualActionHandler.friendActionStates,
                onMutualHostsReady: _mutualFriendsManager.scheduleMutualFriendFetch,
                onAskToChat: _mutualActionHandler.handleAskToChat,
                onAddFriendFromMutual: _mutualActionHandler.handleAddFriendFromMutual,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
