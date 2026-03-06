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
import '/main_function/games_list/components/mutual_card_actions.dart';
import '/main_function/games_list/models/quick_filter.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/models/game.dart';
import '/providers/chat_provider.dart';
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

  // Quick filter and sort state
  QuickFilter _quickFilter = QuickFilter.all;
  GameSortOption _sortOption = GameSortOption.soonest;

  // Vibe scores cache (game reference ID -> score 0-100)
  final Map<String, double> _vibeScores = {};

  // Cache for the last computed filter metadata (not state - updated during build)
  GameFilterMeta _lastFilterMeta = const GameFilterMeta.empty();

  // Track last warmed profile UIDs to avoid redundant warming calls
  Set<String> _lastWarmedProfileUids = {};

  // Pending warm UIDs for deferred processing (avoids side effects during build)
  Set<String>? _pendingWarmUids;

  // Gate to prevent scheduling multiple callbacks before prior one runs
  bool _warmScheduled = false;

  // Mutual friend caches: hostId -> list of mutual friend UIDs
  final Map<String, List<String>> _mutualFriendsMap = {};

  // First mutual friend display name cache: hostId -> name
  final Map<String, String> _firstMutualFriendName = {};

  // Hosts that need mutual friend computation (persists until computed)
  final Set<String> _hostsNeedingMutualComputation = {};

  // Gate to prevent scheduling multiple callbacks
  bool _mutualFetchScheduled = false;

  // Track action states for mutual cards: hostId -> state
  final Map<String, MutualActionState> _chatActionStates = {};
  final Map<String, MutualActionState> _friendActionStates = {};

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

  Future<void> _processPendingProfileWarm() async {
    _warmScheduled = false;
    if (!mounted) return;

    final uids = _pendingWarmUids;
    if (uids == null || uids.isEmpty) return;

    _pendingWarmUids = null;
    _lastWarmedProfileUids = uids;

    // Warm profiles and wait for completion
    await context.read<ProfileProvider>().warmProfiles(uids);

    // After profiles are warmed, recompute mutual friends if we have pending hosts
    if (mounted && _hostsNeedingMutualComputation.isNotEmpty) {
      _processPendingMutualFetch();
    }
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

  void _handleQuickFilterChanged(QuickFilter filter) {
    updateState(this, () {
      _quickFilter = filter;
      // If selecting Top VIBE, also change sort
      if (filter == QuickFilter.topVibe) {
        _sortOption = GameSortOption.topVibe;
      }
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
    _mutualFriendsMap.clear();
    _firstMutualFriendName.clear();
    _hostsNeedingMutualComputation.clear();
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      updateState(this, () {});
    }
  }

  /// Schedules mutual friend computation to run after the current build completes.
  void _scheduleMutualFriendFetch(Set<String> hostIds) {
    if (hostIds.isEmpty) return;

    // Add hosts that we haven't computed yet
    final newHostIds = hostIds.where((id) => !_mutualFriendsMap.containsKey(id));
    _hostsNeedingMutualComputation.addAll(newHostIds);

    if (_hostsNeedingMutualComputation.isEmpty) return;

    if (!_mutualFetchScheduled) {
      _mutualFetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processPendingMutualFetch();
      });
    }
  }

  /// Computes mutual friends from cached ProfileProvider data.
  ///
  /// Uses the already-warmed profiles to get host friends lists and compute
  /// mutual friends locally, avoiding additional Firestore reads.
  void _processPendingMutualFetch() {
    _mutualFetchScheduled = false;
    if (!mounted) return;

    if (_hostsNeedingMutualComputation.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final myFriends = userProvider.currentUser?.friends ?? [];
    if (myFriends.isEmpty) return;

    // Build set of my friend UIDs for intersection
    final myFriendIds = myFriends.map((ref) => ref.id).toSet();

    // Collect UIDs of mutual friends we find (to warm their profiles for names)
    final mutualFriendUidsToWarm = <String>{};
    final hostsToRemove = <String>[];
    var hasUpdates = false;

    for (final hostId in _hostsNeedingMutualComputation) {
      // Skip if already computed
      if (_mutualFriendsMap.containsKey(hostId)) {
        hostsToRemove.add(hostId);
        continue;
      }

      // Get host's profile from cache (already warmed by onOwnerUidsReady)
      final hostProfile = profileProvider.getCachedProfile(hostId);
      if (hostProfile == null) {
        // Profile not cached yet - will be recomputed after profile warm completes
        continue;
      }

      // Get host's friend UIDs
      final hostFriendIds = hostProfile.friends.map((ref) => ref.id).toSet();

      // Compute intersection locally (no Firestore call!)
      final mutualIds = myFriendIds.intersection(hostFriendIds);

      if (mutualIds.isNotEmpty) {
        // Get first mutual friend's name from cache (if available)
        final firstMutualId = mutualIds.first;
        final firstMutualProfile = profileProvider.getCachedProfile(firstMutualId);
        final firstName = firstMutualProfile?.displayName ?? '';

        _mutualFriendsMap[hostId] = mutualIds.toList();
        _firstMutualFriendName[hostId] = firstName.isNotEmpty ? firstName : 'a friend';
        hasUpdates = true;

        // Schedule warming of mutual friend profiles for display names
        mutualFriendUidsToWarm.addAll(mutualIds);
      }

      // Mark this host as processed (whether or not it had mutual friends)
      hostsToRemove.add(hostId);
    }

    // Remove processed hosts
    _hostsNeedingMutualComputation.removeAll(hostsToRemove);

    // Warm mutual friend profiles to get their display names
    if (mutualFriendUidsToWarm.isNotEmpty) {
      profileProvider.warmProfiles(mutualFriendUidsToWarm);
    }

    // Trigger rebuild if we found any mutual friends
    if (hasUpdates && mounted) {
      updateState(this, () {});
    }
  }

  /// Returns the set of host IDs that have mutual friends with the current user.
  Set<String> get _mutualFriendHostIds => _mutualFriendsMap.keys.toSet();

  /// Handle "Ask to Chat" action for a mutual friend game.
  Future<void> _handleAskToChat(DocumentReference hostRef) async {
    final hostId = hostRef.id;
    if (_chatActionStates[hostId] == MutualActionState.completed) return;

    updateState(this, () {
      _chatActionStates[hostId] = MutualActionState.loading;
    });

    try {
      final currentUserId = context.read<UserProvider>().currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Create or get existing DM chat
      final chatProvider = context.read<ChatProvider>();
      final chatRef = await chatProvider.createOrGetDirectChat(
        currentUid: currentUserId,
        otherUid: hostId,
      );

      if (!mounted) return;

      updateState(this, () {
        _chatActionStates[hostId] = MutualActionState.completed;
      });

      // Navigate to chat
      context.pushChatDetails(chatId: chatRef.id);
    } catch (e) {
      AppLog.d('❌ GamesListWidget._handleAskToChat error: $e');
      if (!mounted) return;

      updateState(this, () {
        _chatActionStates[hostId] = MutualActionState.idle;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Handle "Add Friend" action for a mutual friend game.
  Future<void> _handleAddFriendFromMutual(DocumentReference hostRef) async {
    final hostId = hostRef.id;
    if (_friendActionStates[hostId] == MutualActionState.completed) return;

    updateState(this, () {
      _friendActionStates[hostId] = MutualActionState.loading;
    });

    try {
      await context.read<UserProvider>().sendFriendRequest(hostRef);

      if (!mounted) return;

      updateState(this, () {
        _friendActionStates[hostId] = MutualActionState.completed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      AppLog.d('❌ GamesListWidget._handleAddFriendFromMutual error: $e');
      if (!mounted) return;

      updateState(this, () {
        _friendActionStates[hostId] = MutualActionState.idle;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
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
          activeFilterCount: _filters.activeFilterCount,
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
                quickFilter: _quickFilter,
                sortOption: _sortOption,
                vibeScores: _vibeScores,
                shouldHideCancelledGame: _shouldHideCancelledGame,
                getCancelledHandling: _getCancelledHandling,
                onFilterMetaChanged: (meta) => _lastFilterMeta = meta,
                onOwnerUidsReady: _scheduleProfileWarm,
                onCancelledGameTap: _handleCancelledGameTap,
                onFriendsOnlyTap: _handleFriendsOnlyTap,
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
                mutualFriendHostIds: _mutualFriendHostIds,
                firstMutualFriendName: _firstMutualFriendName,
                mutualFriendsMap: _mutualFriendsMap,
                chatActionStates: _chatActionStates,
                friendActionStates: _friendActionStates,
                onMutualHostsReady: _scheduleMutualFriendFetch,
                onAskToChat: _handleAskToChat,
                onAddFriendFromMutual: _handleAddFriendFromMutual,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
