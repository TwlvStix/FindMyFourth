import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/schema/users_record.dart';
import '/providers/geo_filter_provider.dart';
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
  /// Cached user stream to prevent re-subscriptions on every build.
  Stream<UsersRecord?>? _userStream;
  DocumentReference? _cachedUserRef;

  @override
  void initState() {
    super.initState();
    _updateUserStream();
  }

  @override
  void didUpdateWidget(GamesListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recreate stream if user reference changed
    if (widget.currentUserReference != oldWidget.currentUserReference) {
      _updateUserStream();
    }
  }

  void _updateUserStream() {
    final userRef = widget.currentUserReference;
    if (userRef != _cachedUserRef) {
      _cachedUserRef = userRef;
      _userStream = userRef == null ? null : UsersRecord.getDocument(userRef);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStreamBuilder<List<Game>>(
      stream: widget.gamesStream,
      initialData: widget.initialGames,
      onRetry: widget.onRetry,
      builder: (context, gamesList) {
        final activeGames = filterActiveGames(gamesList);

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

        // Apply user-selected filters from bottom sheet
        var visibleGames = applyGameListFilters(activeGames, widget.filters);

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
        return StreamBuilder<UsersRecord?>(
          stream: _userStream,
          builder: (context, userSnapshot) {
            final friendIds = friendIdsFromRecord(userSnapshot.data);
            final userGender = userSnapshot.data?.gender;

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
            // (These are potential mutual games we haven't fetched data for yet)
            final lockedHostIds = partitioned.locked
                .map((g) => g.userRef?.id ?? g.uid)
                .whereType<String>()
                .toSet();
            if (lockedHostIds.isNotEmpty && widget.onMutualHostsReady != null) {
              widget.onMutualHostsReady!(lockedHostIds);
            }

            // Combined game count for sort bar
            final totalGameCount = sortedJoinableGames.length + sortedMutualGames.length;

            return RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: CustomScrollView(
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
                  // Bottom padding for FAB
                  SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
