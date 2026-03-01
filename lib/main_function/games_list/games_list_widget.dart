import '/core/design_tokens/spacing.dart';
import '/core/utils/state_update.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/providers/trust_provider.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/main_function/games_list/components/flexible_games_shelf.dart';
import '/main_function/games_list/components/flexible_games_bottom_sheet.dart';
import '/main_function/games_list/components/games_list_empty_state.dart';
import '/main_function/games_list/components/fixed_games_section.dart';
import '/main_function/games_list/components/friends_only_games_section.dart';
import '/main_function/games_list/utils/game_canonicalization.dart';
import '/main_function/games_list/utils/game_filtering.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/providers/game_provider.dart';
import '/services/game_eligibility_service.dart';
import '/providers/profile_provider.dart';
import '/providers/user_provider.dart';
import '/core/utils/app_log.dart';
import '/backend/backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

/// Immutable metadata derived from the current games snapshot.
/// Computed once per build to avoid repeated state mutations.
class GameFilterMeta {
  final Set<String> availableGameTypes;
  final Set<String> availableVibes;
  final Set<String> availableStakes;
  final Set<String> availableHandicaps;
  final Set<String> availableCourses;
  final Set<String> availableEligibilities;

  const GameFilterMeta({
    required this.availableGameTypes,
    required this.availableVibes,
    required this.availableStakes,
    required this.availableHandicaps,
    required this.availableCourses,
    required this.availableEligibilities,
  });

  factory GameFilterMeta.fromGames(
    List<Game> games,
    String? Function(Game) gameTypeExtractor,
    String? Function(Game) vibeExtractor,
    String? Function(Game) stakesExtractor,
    String? Function(Game) handicapExtractor,
  ) {
    final types = <String>{};
    final vibes = <String>{};
    final stakes = <String>{};
    final handicaps = <String>{};
    final courses = <String>{};
    final eligibilities = <String>{};

    for (final game in games) {
      final type = gameTypeExtractor(game);
      if (type != null) types.add(type);

      final vibe = vibeExtractor(game);
      if (vibe != null) vibes.add(vibe);

      final stake = stakesExtractor(game);
      if (stake != null) stakes.add(stake);

      final handicap = handicapExtractor(game);
      if (handicap != null) handicaps.add(handicap);

      final course = game.coursePlay.trim();
      if (course.isNotEmpty) courses.add(course);

      // Extract eligibility value
      eligibilities.add(game.playerEligibility.toFirestoreValue());
    }

    return GameFilterMeta(
      availableGameTypes: types,
      availableVibes: vibes,
      availableStakes: stakes,
      availableHandicaps: handicaps,
      availableCourses: courses,
      availableEligibilities: eligibilities,
    );
  }
}

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
  GameFilterMeta _lastFilterMeta = const GameFilterMeta(
    availableGameTypes: {},
    availableVibes: {},
    availableStakes: {},
    availableHandicaps: {},
    availableCourses: {},
    availableEligibilities: {},
  );

  // Track last warmed profile UIDs to avoid redundant warming calls
  Set<String> _lastWarmedProfileUids = {};
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame updateState(this, no-op rebuild)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize streams and cache on first call (safe to access context here)
    if (!_didInitDependencies) {
      final gameProvider = context.read<GameProvider>();

      // Retrieve cached data (no filters initially)
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

  // TODO: needs GameProvider cache invalidation before stream recreation to force fresh fetch
  /// Retry loading games by recreating the stream.
  void _retryGamesStream() {
    final gameProvider = context.read<GameProvider>();
    updateState(this, () {
      _gamesStream = gameProvider.availableGamesStream().map((records) =>
          records.map((record) => Game.fromRecord(record)).toList());
    });
  }

  /// Wrapper that uses the widget's cache to get cancelled game handling.
  CancelledGameHandling? _getCancelledHandling(Game game) {
    return getCancelledHandling(game, _cancelledGameHandlingByGame);
  }

  /// Wrapper that uses the widget's cache to check if cancelled game should hide.
  bool _shouldHideCancelledGame(Game game) {
    return shouldHideCancelledGame(game, _cancelledGameHandlingByGame);
  }

  List<Game> _applyFilters(List<Game> gamesList, GameListFilters filters) {
    return gamesList.where((game) {
      if (filters.selectedGameTypes.isNotEmpty) {
        final gameType = gameTypeForFilters(game);
        if (gameType == null || !filters.selectedGameTypes.contains(gameType)) {
          return false;
        }
      }
      if (filters.selectedVibes.isNotEmpty) {
        final vibe = vibeForFilters(game);
        if (vibe == null || !filters.selectedVibes.contains(vibe)) {
          return false;
        }
      }
      if (filters.selectedStakes.isNotEmpty) {
        final stakes = stakesForFilters(game);
        if (stakes == null || !filters.selectedStakes.contains(stakes)) {
          return false;
        }
      }
      if (filters.selectedHandicaps.isNotEmpty) {
        final handicap = handicapForFilters(game);
        if (handicap == null || !filters.selectedHandicaps.contains(handicap)) {
          return false;
        }
      }
      if (filters.selectedCourse != null &&
          filters.selectedCourse!.trim().isNotEmpty) {
        if (game.coursePlay.trim() != filters.selectedCourse!.trim()) {
          return false;
        }
      }
      if (filters.selectedEligibility.isNotEmpty) {
        final eligibility = game.playerEligibility.toFirestoreValue();
        if (!filters.selectedEligibility.contains(eligibility)) {
          return false;
        }
      }
      if (!matchesDateRange(game.date, filters.selectedDateRange)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showFilterBottomSheet(GameFilterMeta filterMeta) async {
    final topPadding = MediaQuery.of(context).padding.top;
    final result = await showModalBottomSheet<GameListFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GameListFilterBottomSheet(
        currentFilters: _filters,
        availableGameTypes: filterMeta.availableGameTypes,
        availableVibes: filterMeta.availableVibes,
        availableStakes: filterMeta.availableStakes,
        availableHandicaps: filterMeta.availableHandicaps,
        availableCourses: filterMeta.availableCourses,
        availableEligibilities: filterMeta.availableEligibilities,
        topPadding: topPadding,
      ),
    );

    if (result != null && mounted) {
      updateState(this, () {
        _filters = result;
      });
    }
  }

  void _showFlexibleGamesSheet(
    List<Game> games,
    DocumentReference? currentUserReference,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FlexibleGamesBottomSheet(
        games: games,
        currentUserReference: currentUserReference,
      ),
    );
  }

  Future<void> _showCancelledGameOptions(Game game) async {
    final selection = await showDialog<CancelledGameHandling>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.navy,
          title: Text(
            'Game cancelled',
            style: AppTypography.titleMedium
                .copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'How would you like to handle this game?',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
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
    if (selection == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    updateState(this, () {
      _cancelledGameHandlingByGame[game.reference] = selection;
    });
    AppState().setCancelledGameHandling(
      game.reference.path,
      cancelledHandlingStorageMap[selection]!,
    );
    if (selection == CancelledGameHandling.removeAfter7Days) {
      AppState().setCancelledGameHideAt(
        game.reference.path,
        getCurrentTimestamp.add(Duration(days: 7)),
      );
    }
  }

  Future<void> _showFriendsOnlyDialog() async {
    await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.informational,
      icon: PhosphorIconsRegular.lock,
      title: 'Friends Only Game',
      body:
          'This game is visible to friends only. Add the host as a friend to view details.',
      actionLabel: 'Got It',
    );
  }

  /// Sends a friend request to the game host
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

  @override
  Widget build(BuildContext context) {
    final currentUserReference = currentUserUid.isEmpty
        ? null
        : UsersRecord.collection.doc(currentUserUid);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Game List',
            style: AppTypography.headlineMediumSans.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: currentUserReference == null
                  ? AppIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 30.0,
                      borderWidth: 1.0,
                      buttonSize: 44.0,
                      fillColor: Colors.transparent,
                      tooltip: 'Notifications',
                      icon: AppIcon(
                        icon: AppPhosphorIcons.notifications,
                        color: AppColors.pure,
                        size: AppIconSize.md,
                      ),
                      onPressed: () {
                        context.pushNotifications();
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: currentUserReference
                          .collection('notifications')
                          .where('read', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data?.docs.length ?? 0;
                        return Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AppIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 30.0,
                              borderWidth: 1.0,
                              buttonSize: 44.0,
                              fillColor: Colors.transparent,
                              tooltip: 'Notifications',
                              icon: AppIcon(
                                icon: AppPhosphorIcons.notifications,
                                color: AppColors.pure,
                                size: AppIconSize.md,
                              ),
                              onPressed: () {
                                context.pushNotifications();
                              },
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0.0,
                                bottom: 0.0,
                                child: NotificationBadge(count: unreadCount),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: AppIconButton(
                borderColor: _filters.hasActiveFilters
                    ? AppColors.navy.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: 30.0,
                borderWidth: _filters.hasActiveFilters ? 2.0 : 1.0,
                buttonSize: 44.0,
                fillColor: _filters.hasActiveFilters
                    ? AppColors.navy.withValues(alpha: 0.12)
                    : Colors.transparent,
                tooltip: 'Filter games',
                icon: AppIcon(
                  icon: AppPhosphorIcons.filter,
                  color: _filters.hasActiveFilters
                      ? AppColors.navy
                      : AppColors.pure,
                  size: AppIconSize.md,
                ),
                onPressed: () {
                  _showFilterBottomSheet(_lastFilterMeta);
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
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
              child: AppStreamBuilder<List<Game>>(
                stream: _gamesStream,
                initialData: _cachedGames ?? const <Game>[],
                onRetry: _retryGamesStream,
                builder: (context, gamesList) {
                  // Debug logging wrapped in assertions (only runs in debug mode)
                  assert(() {
                    AppLog.d(
                        '📋 GAME LIST: StreamBuilder triggered with ${gamesList.length} games');
                    return true;
                  }());

                  // Filter games by status: only show active games, hide expired/completed
                  // For cancelled games, respect user preference
                  final activeGames = gamesList.where((game) {
                    // Always hide expired and completed games
                    if (game.status == 'expired' ||
                        game.status == 'completed') {
                      return false;
                    }

                    // For cancelled games, check user preference
                    if (game.status == 'cancelled') {
                      return !_shouldHideCancelledGame(game);
                    }

                    // Show active games
                    return true;
                  }).toList();

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

                  // Cache for use by filter button (no setState - just update the field)
                  _lastFilterMeta = filterMeta;

                  // Apply user-selected filters to get visible games
                  final visibleGames = _applyFilters(activeGames, _filters);

                  assert(() {
                    AppLog.d(
                        '✅ GAME LIST: Final visible games: ${visibleGames.length}');
                    return true;
                  }());

                  return StreamBuilder<UsersRecord?>(
                    stream: currentUserReference == null
                        ? null
                        : UsersRecord.getDocument(currentUserReference),
                    builder: (context, userSnapshot) {
                      final friendIds = friendIdsFromRecord(userSnapshot.data);

                      // Filter out gender-restricted games the user isn't eligible for
                      // (unless they're the owner)
                      final userGender = userSnapshot.data?.gender;
                      final eligibleGames = visibleGames.where((game) {
                        // Owner always sees their own games
                        if (game.userRef == currentUserReference) {
                          return true;
                        }

                        // Check gender eligibility
                        final eligibilityResult = checkPlayerEligibility(
                          eligibility: game.playerEligibility,
                          userGender: userGender,
                        );
                        return eligibilityResult.allowed;
                      }).toList();

                      final joinableGames = <Game>[];
                      final lockedGames = <Game>[];
                      for (final game in eligibleGames) {
                        if (isJoinableGame(
                            game, currentUserReference, friendIds)) {
                          joinableGames.add(game);
                        } else if (isFriendsOnlyGame(game)) {
                          lockedGames.add(game);
                        } else {
                          joinableGames.add(game);
                        }
                      }

                      // ═══════════════════════════════════════════════════════
                      // Split games into flexible and scheduled
                      // ═══════════════════════════════════════════════════════
                      final flexibleGames =
                          joinableGames.where((g) => g.isFlexible).toList();
                      final scheduledGames =
                          joinableGames.where((g) => !g.isFlexible).toList();

                      // Sort scheduled by date ascending (soonest first)
                      scheduledGames.sort((a, b) {
                        final aDate = a.date;
                        final bDate = b.date;
                        if (aDate == null && bDate == null) return 0;
                        if (aDate == null) return 1;
                        if (bDate == null) return -1;
                        return aDate.compareTo(bDate);
                      });

                      // Sort flexible by readiness (most players first)
                      flexibleGames.sort((a, b) => b.joinedPlayers.length
                          .compareTo(a.joinedPlayers.length));

                      // ═══════════════════════════════════════════════════════
                      // PERFORMANCE FIX #7: Batch-warm profiles for locked games
                      // ═══════════════════════════════════════════════════════
                      // Extract all unique owner UIDs from locked games and pre-fetch
                      // them in batches (chunks of 10) to avoid N+1 listener pattern.
                      // This replaces per-row StreamBuilder with cached reads.
                      final ownerUids = lockedGames
                          .map((game) => game.userRef?.id)
                          .whereType<String>()
                          .toSet();

                      // Only warm if the UID set has changed (avoid redundant calls)
                      if (ownerUids.isNotEmpty &&
                          !setEquals(ownerUids, _lastWarmedProfileUids)) {
                        _lastWarmedProfileUids = ownerUids;
                        // Fire-and-forget batch prefetch (non-blocking)
                        context.read<ProfileProvider>().warmProfiles(ownerUids);
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<GameProvider>().invalidateAllGameCache();
                          await Future.delayed(Duration(milliseconds: 500));
                          if (mounted) {
                            updateState(this, () {});
                          }
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // RestrictionBanner — shown when player has an active restriction
                            Consumer<TrustProvider>(
                              builder: (context, trust, _) {
                                final restriction =
                                    trust.myStanding?.currentRestriction;
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
                                      onViewStanding: () =>
                                          context.pushYourStanding(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // ════════════════════════════════════════════════════
                            // Flexible Games Shelf
                            // ════════════════════════════════════════════════════
                            if (flexibleGames.isNotEmpty)
                              SliverToBoxAdapter(
                                child: FlexibleGamesShelf(
                                  games: flexibleGames,
                                  currentUserReference: currentUserReference,
                                  onSeeAll: () => _showFlexibleGamesSheet(
                                    flexibleGames,
                                    currentUserReference,
                                  ),
                                ),
                              ),
                            // ════════════════════════════════════════════════════
                            // Global Empty State (only when ALL sections empty)
                            // ════════════════════════════════════════════════════
                            if (flexibleGames.isEmpty &&
                                scheduledGames.isEmpty &&
                                lockedGames.isEmpty)
                              SliverToBoxAdapter(
                                child: GamesListEmptyState(
                                  onCreateGame: () => context.pushCreateGame(
                                    transition:
                                        TransitionStandards.detailTransition,
                                  ),
                                ),
                              ),
                            // ════════════════════════════════════════════════════
                            // Fixed Games Section (header + list)
                            // ════════════════════════════════════════════════════
                            ...FixedGamesSectionBuilder(
                              scheduledGames: scheduledGames,
                              hasFlexibleGames: flexibleGames.isNotEmpty,
                              hasLockedGames: lockedGames.isNotEmpty,
                              currentUserReference: currentUserReference,
                              getCancelledHandling: _getCancelledHandling,
                              onCancelledGameTap: _showCancelledGameOptions,
                              onFriendsOnlyTap: _showFriendsOnlyDialog,
                            ).build(context),
                            // ════════════════════════════════════════════════════
                            // Friends-Only Games Section (header + list)
                            // ════════════════════════════════════════════════════
                            ...FriendsOnlyGamesSectionBuilder(
                              lockedGames: lockedGames,
                              currentUserReference: currentUserReference,
                              getCancelledHandling: _getCancelledHandling,
                              onCancelledGameTap: _showCancelledGameOptions,
                              onFriendsOnlyTap: _showFriendsOnlyDialog,
                              onSendFriendRequest: _sendFriendRequest,
                              onToggleVisibility: () {
                                AppState().hideFriendsOnlyGames =
                                    !AppState().hideFriendsOnlyGames;
                                if (mounted) {
                                  updateState(this, () {});
                                }
                              },
                            ).build(context),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
