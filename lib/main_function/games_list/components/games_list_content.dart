import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_stream_builder.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/games_list_empty_state.dart';
import '/main_function/games_list/components/games_sort_bar.dart';
import '/main_function/games_list/components/mutual_card_actions.dart';
import '/main_function/games_list/components/mutual_game_card.dart';
import '/main_function/games_list/components/quick_filter_chips.dart';
import '/main_function/games_list/components/restriction_banner_selector.dart';
import '/main_function/games_list/components/unified_game_card.dart';
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
class GamesListContent extends StatelessWidget {
  const GamesListContent({
    super.key,
    required this.gamesStream,
    required this.initialGames,
    required this.currentUserReference,
    required this.filters,
    required this.quickFilter,
    required this.sortOption,
    required this.vibeScores,
    required this.shouldHideCancelledGame,
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
  final bool Function(Game) shouldHideCancelledGame;
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
  Widget build(BuildContext context) {
    return AppStreamBuilder<List<Game>>(
      stream: gamesStream,
      initialData: initialGames,
      onRetry: onRetry,
      builder: (context, gamesList) {
        // Debug logging wrapped in assertions (only runs in debug mode)
        assert(() {
          AppLog.d(
              '📋 GAME LIST: StreamBuilder triggered with ${gamesList.length} games');
          return true;
        }());

        // Filter games by status
        final activeGames = filterActiveGames(
          gamesList,
          shouldHideCancelledGame: shouldHideCancelledGame,
        );

        assert(() {
          AppLog.d(
              '📊 GAME LIST: After status filter: ${activeGames.length} games');
          return true;
        }());

        // Compute filter metadata once from the active games snapshot
        final filterMeta = GameFilterMeta.fromGames(
          activeGames,
          gameTypeForFilters,
          vibeForFilters,
          stakesForFilters,
          handicapForFilters,
        );

        // Notify parent of filter meta update (no setState, just field update)
        onFilterMetaChanged(filterMeta);

        // Apply user-selected filters from bottom sheet
        final visibleGames = applyGameListFilters(activeGames, filters);

        // Apply quick filter
        final quickFilteredGames = quickFilter.apply(visibleGames);

        assert(() {
          AppLog.d(
              '✅ GAME LIST: After quick filter: ${quickFilteredGames.length}');
          return true;
        }());

        final userRef = currentUserReference;
        return StreamBuilder<UsersRecord?>(
          stream: userRef == null
              ? null
              : UsersRecord.getDocument(userRef),
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
              mutualFriendHostIds: mutualFriendHostIds,
            );

            // Sort joinable games
            final sortedJoinableGames = sortOption.sort(
              partitioned.joinable,
              vibeScores: vibeScores,
            );

            // Sort mutual games by date (they always come last)
            final sortedMutualGames = sortOption.sort(
              partitioned.mutual,
              vibeScores: vibeScores,
            );

            // Schedule profile warming for all game owners
            final ownerUids = [...sortedJoinableGames, ...sortedMutualGames]
                .map((game) => game.userRef?.id)
                .whereType<String>()
                .toSet();
            if (ownerUids.isNotEmpty) {
              onOwnerUidsReady(ownerUids);
            }

            // Schedule mutual friend fetching for hosts of locked friends-only games
            // (These are potential mutual games we haven't fetched data for yet)
            final lockedHostIds = partitioned.locked
                .map((g) => g.userRef?.id ?? g.uid)
                .whereType<String>()
                .toSet();
            if (lockedHostIds.isNotEmpty && onMutualHostsReady != null) {
              onMutualHostsReady!(lockedHostIds);
            }

            // Combined game count for sort bar
            final totalGameCount = sortedJoinableGames.length + sortedMutualGames.length;

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // RestrictionBanner (uses selector for fine-grained rebuilds)
                  SliverToBoxAdapter(
                    child: RestrictionBannerSelector(
                      onNavigateToStanding: onNavigateToStanding,
                    ),
                  ),
                  // Quick Filter Chips
                  SliverToBoxAdapter(
                    child: QuickFilterChips(
                      selectedFilter: quickFilter,
                      onFilterChanged: onQuickFilterChanged,
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
                      sortOption: sortOption,
                      onSortChanged: onSortChanged,
                    ),
                  ),
                  // Global Empty State
                  if (sortedJoinableGames.isEmpty && sortedMutualGames.isEmpty)
                    SliverToBoxAdapter(
                      child: GamesListEmptyState(
                        onCreateGame: onCreateGame,
                      ),
                    ),
                  // Joinable Games List
                  if (sortedJoinableGames.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final game = sortedJoinableGames[index];
                            final isLastJoinable = index == sortedJoinableGames.length - 1;
                            final hasMoreMutual = sortedMutualGames.isNotEmpty;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLastJoinable && !hasMoreMutual
                                    ? AppSpacing.md
                                    : AppSpacing.sm,
                              ),
                              child: UnifiedGameCard(
                                game: game,
                                currentUserReference: currentUserReference,
                                vibeScore: vibeScores[game.reference.id],
                                animationIndex: index,
                              ),
                            );
                          },
                          childCount: sortedJoinableGames.length,
                        ),
                      ),
                    ),
                  // Mutual Games List (amber cards, rendered inline after joinable)
                  if (sortedMutualGames.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final game = sortedMutualGames[index];
                            final hostId = game.userRef?.id ?? game.uid;
                            final mutualName = firstMutualFriendName[hostId] ?? 'a friend';
                            final mutualCount = (mutualFriendsMap[hostId]?.length ?? 1) - 1;
                            final animationIndex = sortedJoinableGames.length + index;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < sortedMutualGames.length - 1
                                    ? AppSpacing.sm
                                    : AppSpacing.md,
                              ),
                              child: MutualGameCard(
                                game: game,
                                mutualFriendName: mutualName,
                                additionalMutualCount: mutualCount,
                                chatState: chatActionStates[hostId] ?? MutualActionState.idle,
                                friendState: friendActionStates[hostId] ?? MutualActionState.idle,
                                animationIndex: animationIndex,
                                onAskToChat: () {
                                  if (onAskToChat != null && game.userRef != null) {
                                    onAskToChat!(game.userRef!);
                                  }
                                },
                                onAddFriend: () {
                                  if (onAddFriendFromMutual != null && game.userRef != null) {
                                    onAddFriendFromMutual!(game.userRef!);
                                  }
                                },
                              ),
                            );
                          },
                          childCount: sortedMutualGames.length,
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
      },
    );
  }
}
