import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/spacing.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/main_function/games_list/components/fixed_games_section.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/flexible_games_shelf.dart';
import '/main_function/games_list/components/friends_only_games_section.dart';
import '/main_function/games_list/components/games_list_empty_state.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/main_function/games_list/utils/game_canonicalization.dart';
import '/main_function/games_list/utils/game_filter_meta.dart';
import '/main_function/games_list/utils/game_filtering.dart';
import '/main_function/games_list/utils/games_list_pipeline.dart';
import '/models/game.dart';
import '/providers/trust_provider.dart';
import '/utils/app_util.dart';

/// Content widget for the games list that handles stream composition,
/// game processing pipeline, and sliver layout.
class GamesListContent extends StatelessWidget {
  const GamesListContent({
    super.key,
    required this.gamesStream,
    required this.initialGames,
    required this.currentUserReference,
    required this.filters,
    required this.shouldHideCancelledGame,
    required this.getCancelledHandling,
    required this.onFilterMetaChanged,
    required this.onOwnerUidsReady,
    required this.onCancelledGameTap,
    required this.onFriendsOnlyTap,
    required this.onSendFriendRequest,
    required this.onToggleVisibility,
    required this.onSeeAllFlexible,
    required this.onCreateGame,
    required this.onRefresh,
    required this.onRetry,
    required this.onNavigateToStanding,
  });

  final Stream<List<Game>> gamesStream;
  final List<Game> initialGames;
  final DocumentReference? currentUserReference;
  final GameListFilters filters;
  final bool Function(Game) shouldHideCancelledGame;
  final CancelledGameHandling? Function(Game) getCancelledHandling;
  final ValueChanged<GameFilterMeta> onFilterMetaChanged;
  final ValueChanged<Set<String>> onOwnerUidsReady;
  final Future<void> Function(Game) onCancelledGameTap;
  final Future<void> Function() onFriendsOnlyTap;
  final Future<void> Function(BuildContext, DocumentReference) onSendFriendRequest;
  final VoidCallback onToggleVisibility;
  final void Function(List<Game>, DocumentReference?) onSeeAllFlexible;
  final VoidCallback onCreateGame;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onNavigateToStanding;

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

        // Apply user-selected filters to get visible games
        final visibleGames = applyGameListFilters(activeGames, filters);

        assert(() {
          AppLog.d(
              '✅ GAME LIST: Final visible games: ${visibleGames.length}');
          return true;
        }());

        return StreamBuilder<UsersRecord?>(
          stream: currentUserReference == null
              ? null
              : UsersRecord.getDocument(currentUserReference!),
          builder: (context, userSnapshot) {
            final friendIds = friendIdsFromRecord(userSnapshot.data);
            final userGender = userSnapshot.data?.gender;

            // Filter out gender-restricted games
            final eligibleGames = filterEligibleGames(
              visibleGames,
              currentUserReference: currentUserReference,
              userGender: userGender,
            );

            // Partition into joinable and locked
            final partitioned = partitionJoinableAndLockedGames(
              eligibleGames,
              currentUserReference: currentUserReference,
              friendIds: friendIds,
            );

            // Split and sort
            final splitGames = splitAndSortGames(partitioned.joinable);
            final flexibleGames = splitGames.flexible;
            final scheduledGames = splitGames.scheduled;
            final lockedGames = partitioned.locked;

            // Schedule profile warming for locked game owners
            final ownerUids = lockedGames
                .map((game) => game.userRef?.id)
                .whereType<String>()
                .toSet();
            if (ownerUids.isNotEmpty) {
              onOwnerUidsReady(ownerUids);
            }

            // Watch AppState for friends-only visibility toggle
            final hideFriendsOnly = context.select<AppState, bool>(
              (s) => s.hideFriendsOnlyGames,
            );

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // RestrictionBanner
                  Consumer<TrustProvider>(
                    builder: (context, trust, _) {
                      final restriction = trust.myStanding?.currentRestriction;
                      if (restriction == null) {
                        return const SliverToBoxAdapter(
                            child: SizedBox.shrink());
                      }
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            0,
                          ),
                          child: RestrictionBanner(
                            restriction: restriction,
                            onViewStanding: onNavigateToStanding,
                          ),
                        ),
                      );
                    },
                  ),
                  // Flexible Games Shelf
                  if (flexibleGames.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FlexibleGamesShelf(
                        games: flexibleGames,
                        currentUserReference: currentUserReference,
                        onSeeAll: () => onSeeAllFlexible(
                          flexibleGames,
                          currentUserReference,
                        ),
                      ),
                    ),
                  // Global Empty State
                  if (flexibleGames.isEmpty &&
                      scheduledGames.isEmpty &&
                      lockedGames.isEmpty)
                    SliverToBoxAdapter(
                      child: GamesListEmptyState(
                        onCreateGame: onCreateGame,
                      ),
                    ),
                  // Fixed Games Section
                  ...FixedGamesSectionBuilder(
                    scheduledGames: scheduledGames,
                    hasFlexibleGames: flexibleGames.isNotEmpty,
                    hasLockedGames: lockedGames.isNotEmpty,
                    currentUserReference: currentUserReference,
                    getCancelledHandling: getCancelledHandling,
                    onCancelledGameTap: onCancelledGameTap,
                    onFriendsOnlyTap: onFriendsOnlyTap,
                  ).build(context),
                  // Friends-Only Games Section
                  ...FriendsOnlyGamesSectionBuilder(
                    lockedGames: lockedGames,
                    currentUserReference: currentUserReference,
                    getCancelledHandling: getCancelledHandling,
                    onCancelledGameTap: onCancelledGameTap,
                    onFriendsOnlyTap: onFriendsOnlyTap,
                    onSendFriendRequest: onSendFriendRequest,
                    hideFriendsOnlyGames: hideFriendsOnly,
                    onToggleVisibility: onToggleVisibility,
                  ).build(context),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
