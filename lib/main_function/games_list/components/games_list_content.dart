import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/providers/geo_filter_provider.dart';
import '/providers/user_provider.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_stream_builder.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/games_list_empty_state.dart';
import '/main_function/games_list/components/games_sort_bar.dart';
import '/main_function/games_list/components/game_list_slivers.dart';
import '/main_function/games_list/components/mutual_card_actions.dart';
import '/main_function/games_list/components/near_me_chip.dart';
import '/main_function/games_list/components/quick_filter_chips.dart';
import '/main_function/games_list/components/restriction_banner_selector.dart';
import '/main_function/games_list/models/quick_filter.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_canonicalization.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/main_function/games_list/utils/game_filtering.dart';
import '/main_function/games_list/utils/games_list_pipeline.dart';
import '/models/game.dart';
import '/providers/block_provider.dart';

/// Content widget for the games list that handles stream composition,
/// game processing pipeline, and sliver layout.
///
/// Displays a unified list of games with filter chips and sort bar.
class GamesListContent extends StatefulWidget {
  const GamesListContent({
    super.key,
    required this.gamesStream,
    required this.initialGames,
    required this.currentUserReference,
    required this.filters,
    required this.quickFilter,
    required this.sortOption,
    required this.vibeScores,
    required this.getCancelledHandling,
    required this.onFilterMetaChanged,
    required this.onOwnerUidsReady,
    required this.onCancelledGameTap,
    required this.onFriendsOnlyTap,
    required this.onSendFriendRequest,
    required this.onQuickFilterChanged,
    required this.onSortChanged,
    required this.onCreateGame,
    required this.onRefresh,
    required this.onRetry,
    required this.onNavigateToStanding,
    // Pagination
    this.additionalGames = const [],
    this.isLoadingMore = false,
    this.hasMorePages = true,
    this.onLoadMore,
    // Vibe score request
    this.onVibeScoreRequest,
    // Mutual friend data
    this.mutualFriendHostIds = const {},
    this.firstMutualFriendName = const {},
    this.mutualFriendsMap = const {},
    this.chatActionStates = const {},
    this.friendActionStates = const {},
    this.onMutualHostsReady,
    this.onAskToChat,
    this.onAddFriendFromMutual,
  });

  final Stream<List<Game>> gamesStream;
  final List<Game> initialGames;
  final DocumentReference? currentUserReference;
  final GameListFilters filters;
  final QuickFilter quickFilter;
  final GameSortOption sortOption;
  final Map<String, double> vibeScores;
  final CancelledGameHandling? Function(Game) getCancelledHandling;
  final ValueChanged<GameFilterMeta> onFilterMetaChanged;
  final ValueChanged<Set<String>> onOwnerUidsReady;
  final Future<void> Function(Game) onCancelledGameTap;
  final Future<void> Function() onFriendsOnlyTap;
  final Future<void> Function(BuildContext, DocumentReference) onSendFriendRequest;
  final ValueChanged<QuickFilter> onQuickFilterChanged;
  final ValueChanged<GameSortOption> onSortChanged;
  final VoidCallback onCreateGame;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onNavigateToStanding;

  // Pagination
  final List<Game> additionalGames;
  final bool isLoadingMore;
  final bool hasMorePages;
  final Future<void> Function()? onLoadMore;

  // Vibe score request (lazy computation)
  final void Function(Game game)? onVibeScoreRequest;

  // Mutual friend data for amber cards
  final Set<String> mutualFriendHostIds;
  final Map<String, String> firstMutualFriendName;
  final Map<String, List<String>> mutualFriendsMap;
  final Map<String, MutualActionState> chatActionStates;
  final Map<String, MutualActionState> friendActionStates;
  final ValueChanged<Set<String>>? onMutualHostsReady;
  final Future<void> Function(DocumentReference)? onAskToChat;
  final Future<void> Function(DocumentReference)? onAddFriendFromMutual;

  @override
  State<GamesListContent> createState() => _GamesListContentState();
}

class _GamesListContentState extends State<GamesListContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300 &&
        widget.hasMorePages &&
        !widget.isLoadingMore &&
        widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  /// Merge first-page stream games with additional paginated games,
  /// deduplicating by document ID (prefer stream version).
  List<Game> _mergeAndDeduplicate(List<Game> streamGames) {
    if (widget.additionalGames.isEmpty) return streamGames;

    final seenIds = <String>{};
    final merged = <Game>[];

    // Stream games take priority (real-time updates)
    for (final game in streamGames) {
      if (seenIds.add(game.reference.id)) {
        merged.add(game);
      }
    }

    // Add additional page games that aren't already in stream
    for (final game in widget.additionalGames) {
      if (seenIds.add(game.reference.id)) {
        merged.add(game);
      }
    }

    return merged;
  }

  @override
  Widget build(BuildContext context) {
    // Get friend IDs and gender from UserProvider (replaces inner StreamBuilder)
    final userProvider = context.watch<UserProvider>();
    final friendIds = friendIdsFromRecord(userProvider.currentUser);
    final userGender = userProvider.currentUser?.gender;

    return AppStreamBuilder<List<Game>>(
      stream: widget.gamesStream,
      initialData: widget.initialGames,
      onRetry: widget.onRetry,
      builder: (context, gamesList) {
        // Merge stream page with additional paginated pages
        final mergedGames = _mergeAndDeduplicate(gamesList);

        final activeGames = filterActiveGames(mergedGames);

        // Compute filter metadata once from the active games snapshot
        final filterMeta = GameFilterMeta.fromGames(
          activeGames,
          gameTypeForFilters,
          vibeForFilters,
          stakesForFilters,
          handicapForFilters,
        );

        // Notify parent of filter meta update (no setState, just field update)
        widget.onFilterMetaChanged(filterMeta);

        // Filter out games from blocked users
        final blockedIds = context.select<BlockProvider, Set<String>>((p) => p.blockedUserIds);
        final unblockedGames = filterBlockedUserGames(activeGames, blockedIds);

        // Apply user-selected filters from bottom sheet
        var visibleGames = applyGameListFilters(unblockedGames, widget.filters);

        // Apply geo filter if enabled and has location
        final geoFilterEnabled = context.select<GeoFilterProvider, bool>((p) => p.isEnabled);
        final geoFilterHasLocation = context.select<GeoFilterProvider, bool>((p) => p.hasLocation);
        if (geoFilterEnabled && geoFilterHasLocation) {
          final geoFilter = context.read<GeoFilterProvider>();
          visibleGames = applyGeoFilter(
            visibleGames,
            centerLat: geoFilter.lat!,
            centerLng: geoFilter.lng!,
            radiusKm: geoFilter.radiusKm,
          );
        }

        final quickFilteredGames = widget.quickFilter.apply(visibleGames);
        final userRef = widget.currentUserReference;

        // Filter out gender-restricted games
        final eligibleGames = filterEligibleGames(
          quickFilteredGames,
          currentUserReference: userRef,
          userGender: userGender,
        );

        // Partition into joinable, mutual, and locked
        final partitioned = partitionJoinableAndLockedGames(
          eligibleGames,
          currentUserReference: userRef,
          friendIds: friendIds,
          mutualFriendHostIds: widget.mutualFriendHostIds,
        );

        // Sort joinable games
        final sortedJoinableGames = widget.sortOption.sort(
          partitioned.joinable,
          vibeScores: widget.vibeScores,
        );

        // Sort mutual games by date (they always come last)
        final sortedMutualGames = widget.sortOption.sort(
          partitioned.mutual,
          vibeScores: widget.vibeScores,
        );

        // Schedule profile warming for all game owners
        final ownerUids = [...sortedJoinableGames, ...sortedMutualGames]
            .map((game) => game.userRef?.id)
            .whereType<String>()
            .toSet();
        if (ownerUids.isNotEmpty) {
          widget.onOwnerUidsReady(ownerUids);
        }

        // Schedule mutual friend fetching for hosts of locked friends-only games
        // (Deferred to avoid blocking initial render)
        final lockedHostIds = partitioned.locked
            .map((g) => g.userRef?.id ?? g.uid)
            .whereType<String>()
            .toSet();
        if (lockedHostIds.isNotEmpty && widget.onMutualHostsReady != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            widget.onMutualHostsReady!(lockedHostIds);
          });
        }

        // Combined game count for sort bar
        final totalGameCount = sortedJoinableGames.length + sortedMutualGames.length;

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // RestrictionBanner (uses selector for fine-grained rebuilds)
              SliverToBoxAdapter(
                child: RestrictionBannerSelector(
                  onNavigateToStanding: widget.onNavigateToStanding,
                ),
              ),
              // Quick Filter Chips with Near Me toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  child: QuickFilterChips(
                    selectedFilter: widget.quickFilter,
                    onFilterChanged: widget.onQuickFilterChanged,
                    trailing: const NearMeChip(),
                  ),
                ),
              ),
              // Divider
              SliverToBoxAdapter(
                child: Container(
                  height: 1,
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                ),
              ),
              // Sort Bar
              SliverToBoxAdapter(
                child: GamesSortBar(
                  gameCount: totalGameCount,
                  sortOption: widget.sortOption,
                  onSortChanged: widget.onSortChanged,
                ),
              ),
              // Global Empty State
              if (sortedJoinableGames.isEmpty && sortedMutualGames.isEmpty)
                SliverToBoxAdapter(
                  child: GamesListEmptyState(
                    onCreateGame: widget.onCreateGame,
                  ),
                ),
              // Joinable Games List
              if (sortedJoinableGames.isNotEmpty)
                JoinableGamesSliverList(
                  games: sortedJoinableGames,
                  currentUserReference: widget.currentUserReference,
                  vibeScores: widget.vibeScores,
                  hasMutualGames: sortedMutualGames.isNotEmpty,
                  onVibeScoreRequest: widget.onVibeScoreRequest,
                ),
              // Mutual Games List (amber cards, rendered inline after joinable)
              if (sortedMutualGames.isNotEmpty)
                MutualGamesSliverList(
                  games: sortedMutualGames,
                  firstMutualFriendName: widget.firstMutualFriendName,
                  mutualFriendsMap: widget.mutualFriendsMap,
                  chatActionStates: widget.chatActionStates,
                  friendActionStates: widget.friendActionStates,
                  joinableGameCount: sortedJoinableGames.length,
                  onAskToChat: widget.onAskToChat,
                  onAddFriendFromMutual: widget.onAddFriendFromMutual,
                ),
              // Loading indicator for pagination
              if (widget.isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              // Bottom padding for FAB
              SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }
}
