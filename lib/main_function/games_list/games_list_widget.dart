import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/main_function/games_list/components/game_list_filter_bottom_sheet.dart';
import '/models/game.dart';
import '/providers/game_provider.dart';
import '/backend/backend.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/notifications/notifications_list/notifications_list_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum CancelledGameHandling {
  removeNow,
  removeEndOfDay,
  removeAfter7Days,
  keepInList,
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
  late final Stream<List<Game>> _gamesStream;
  List<Game>? _cachedGames;
  GameListFilters _filters = GameListFilters();
  Set<String> _availableGameTypes = {};
  Set<String> _availableVibes = {};
  Set<String> _availableStakes = {};
  Set<String> _availableHandicaps = {};
  Set<String> _availableCourses = {};
  bool _showLockedGames = false;
  static const Map<CancelledGameHandling, String>
      _cancelledHandlingStorageMap = {
    CancelledGameHandling.removeNow: 'removeNow',
    CancelledGameHandling.removeEndOfDay: 'removeEndOfDay',
    CancelledGameHandling.removeAfter7Days: 'removeAfter7Days',
    CancelledGameHandling.keepInList: 'keepInList',
  };
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize streams and cache on first call (safe to access context here)
    if (_cachedGames == null) {
      final gameProvider = context.read<GameProvider>();

      // Retrieve cached data (no filters initially)
      final cachedRecords = gameProvider.getCachedAvailableGames();
      if (cachedRecords != null) {
        _cachedGames = cachedRecords
            .map((record) => Game.fromRecord(record))
            .toList();
      }

      _gamesStream = gameProvider
          .availableGamesStream()
          .map((records) => records.map((record) => Game.fromRecord(record)).toList());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  CancelledGameHandling? _parseCancelledHandling(String? value) {
    if (value == null) {
      return null;
    }
    for (final entry in _cancelledHandlingStorageMap.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }

  CancelledGameHandling? _getCancelledHandling(Game game) {
    final cached = _cancelledGameHandlingByGame[game.reference];
    if (cached != null) {
      return cached;
    }
    final storedValue =
        AppState().getCancelledGameHandling(game.reference.path);
    final parsed = _parseCancelledHandling(storedValue);
    if (parsed != null) {
      _cancelledGameHandlingByGame[game.reference] = parsed;
    }
    return parsed;
  }

  bool _shouldHideCancelledGame(Game game) {
    // Use status field instead of isCancelled
    if (game.status != 'cancelled') {
      return false;
    }
    final handling = _getCancelledHandling(game);
    if (handling == CancelledGameHandling.removeNow) {
      return true;
    }
    if (handling == CancelledGameHandling.removeEndOfDay) {
      final gameDate = game.date;
      if (gameDate == null) {
        return false;
      }
      final endOfDay = DateTime(
        gameDate.year,
        gameDate.month,
        gameDate.day,
        23,
        59,
        59,
      );
      return getCurrentTimestamp.isAfter(endOfDay);
    }
    if (handling == CancelledGameHandling.removeAfter7Days) {
      final hideAt =
          AppState().getCancelledGameHideAt(game.reference.path);
      if (hideAt == null) {
        return false;
      }
      return getCurrentTimestamp.isAfter(hideAt);
    }
    return false;
  }

  String? _canonicalGameType(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    switch (value) {
      case 'stroke':
      case 'stroke play':
        return 'Stroke Play';
      case 'match play':
      case 'matchplay':
        return 'Match Play';
      case 'stableford':
        return 'Stableford';
      default:
        return null;
    }
  }

  String? _canonicalVibe(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    switch (value) {
      case 'competitive':
        return 'Competitive';
      case 'casual':
        return 'Casual';
      default:
        return null;
    }
  }

  String? _canonicalStakes(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    switch (value) {
      case 'no money':
      case 'nomoney':
        return 'No Money';
      case 'low stakes':
      case 'lowstakes':
        return 'Low Stakes';
      case 'high stakes':
      case 'highstakes':
        return 'High Stakes';
      default:
        return null;
    }
  }

  String? _canonicalHandicap(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    switch (value) {
      case 'gross':
        return 'Gross';
      case 'net':
        return 'Net';
      case 'both':
      case 'gross + net':
      case 'gross+net':
        return 'Both';
      default:
        return null;
    }
  }

  String? _gameTypeForFilters(Game game) {
    return _canonicalGameType(game.gameType);
  }

  String? _vibeForFilters(Game game) {
    return _canonicalVibe(game.rulesSetting);
  }

  String? _stakesForFilters(Game game) {
    return _canonicalStakes(game.styleGame);
  }

  String? _handicapForFilters(Game game) {
    return _canonicalHandicap(game.scoring);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesDateRange(DateTime? gameDate, GameDateRange range) {
    if (range == GameDateRange.any) {
      return true;
    }
    if (gameDate == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gameDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
    switch (range) {
      case GameDateRange.today:
        return _isSameDay(gameDay, today);
      case GameDateRange.tomorrow:
        return _isSameDay(gameDay, today.add(Duration(days: 1)));
      case GameDateRange.next7Days:
        final end = today.add(Duration(days: 7));
        return !gameDay.isBefore(today) && !gameDay.isAfter(end);
      case GameDateRange.any:
        return true;
    }
  }

  bool _isPublicGame(Game game) {
    final value = game.friendGame.trim().toLowerCase();
    return value.isEmpty || value == 'public';
  }

  bool _isFriendsOnlyGame(Game game) {
    return game.friendGame.trim().toLowerCase() == 'friends';
  }

  Set<String> _friendIdsFromRecord(UsersRecord? record) {
    final friends = record?.friends ?? const <DocumentReference>[];
    final ids = <String>{};
    for (final entry in friends) {
      ids.add(entry.id);
    }
    return ids;
  }

  bool _isUserGame(Game game, DocumentReference? currentUserReference) {
    return currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
  }

  bool _isJoinableGame(
    Game game,
    DocumentReference? currentUserReference,
    Set<String> friendIds,
  ) {
    if (_isUserGame(game, currentUserReference)) {
      return true;
    }
    if (_isPublicGame(game)) {
      return true;
    }
    if (_isFriendsOnlyGame(game)) {
      final ownerRef = game.userRef;
      if (ownerRef == null) {
        return false;
      }
      return friendIds.contains(ownerRef.id) || friendIds.contains(game.uid);
    }
    return true;
  }

  List<Game> _applyFilters(List<Game> gamesList, GameListFilters filters) {
    return gamesList.where((game) {
      if (filters.selectedGameTypes.isNotEmpty) {
        final gameType = _gameTypeForFilters(game);
        if (gameType == null ||
            !filters.selectedGameTypes.contains(gameType)) {
          return false;
        }
      }
      if (filters.selectedVibes.isNotEmpty) {
        final vibe = _vibeForFilters(game);
        if (vibe == null || !filters.selectedVibes.contains(vibe)) {
          return false;
        }
      }
      if (filters.selectedStakes.isNotEmpty) {
        final stakes = _stakesForFilters(game);
        if (stakes == null || !filters.selectedStakes.contains(stakes)) {
          return false;
        }
      }
      if (filters.selectedHandicaps.isNotEmpty) {
        final handicap = _handicapForFilters(game);
        if (handicap == null ||
            !filters.selectedHandicaps.contains(handicap)) {
          return false;
        }
      }
      if (filters.selectedCourse != null &&
          filters.selectedCourse!.trim().isNotEmpty) {
        if (game.coursePlay.trim() != filters.selectedCourse!.trim()) {
          return false;
        }
      }
      if (!_matchesDateRange(game.date, filters.selectedDateRange)) {
        return false;
      }
      return true;
    }).toList();
  }

  Set<String> _extractAvailableGameTypes(List<Game> gamesList) {
    final types = <String>{};
    for (final game in gamesList) {
      final type = _gameTypeForFilters(game);
      if (type != null) {
        types.add(type);
      }
    }
    return types;
  }

  Set<String> _extractAvailableVibes(List<Game> gamesList) {
    final vibes = <String>{};
    for (final game in gamesList) {
      final vibe = _vibeForFilters(game);
      if (vibe != null) {
        vibes.add(vibe);
      }
    }
    return vibes;
  }

  Set<String> _extractAvailableStakes(List<Game> gamesList) {
    final stakes = <String>{};
    for (final game in gamesList) {
      final stake = _stakesForFilters(game);
      if (stake != null) {
        stakes.add(stake);
      }
    }
    return stakes;
  }

  Set<String> _extractAvailableHandicaps(List<Game> gamesList) {
    final handicaps = <String>{};
    for (final game in gamesList) {
      final handicap = _handicapForFilters(game);
      if (handicap != null) {
        handicaps.add(handicap);
      }
    }
    return handicaps;
  }

  Set<String> _extractAvailableCourses(List<Game> gamesList) {
    final courses = <String>{};
    for (final game in gamesList) {
      final course = game.coursePlay.trim();
      if (course.isNotEmpty) {
        courses.add(course);
      }
    }
    return courses;
  }

  Future<void> _showFilterBottomSheet(
    Set<String> availableGameTypes,
    Set<String> availableVibes,
    Set<String> availableStakes,
    Set<String> availableHandicaps,
    Set<String> availableCourses,
  ) async {
    final result = await showModalBottomSheet<GameListFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GameListFilterBottomSheet(
        currentFilters: _filters,
        availableGameTypes: availableGameTypes,
        availableVibes: availableVibes,
        availableStakes: availableStakes,
        availableHandicaps: availableHandicaps,
        availableCourses: availableCourses,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _filters = result;
      });
    }
  }

  Future<void> _showCancelledGameOptions(Game game) async {
    final selection = await showDialog<CancelledGameHandling>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text('Game cancelled'),
          content: Text('How would you like to handle this game?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                alertDialogContext,
                CancelledGameHandling.removeNow,
              ),
              child: Text('Remove now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                alertDialogContext,
                CancelledGameHandling.removeAfter7Days,
              ),
              child: Text('Hide after 7 days'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                alertDialogContext,
                CancelledGameHandling.keepInList,
              ),
              child: Text('Keep in list'),
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
    setState(() {
      _cancelledGameHandlingByGame[game.reference] = selection;
    });
    AppState().setCancelledGameHandling(
      game.reference.path,
      _cancelledHandlingStorageMap[selection]!,
    );
    if (selection == CancelledGameHandling.removeAfter7Days) {
      AppState().setCancelledGameHideAt(
        game.reference.path,
        getCurrentTimestamp.add(Duration(days: 7)),
      );
    }
  }

  Future<void> _showFriendsOnlyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text('Friends Only Game'),
          content: Text(
            'This game is visible to friends only. Add the host as a friend to view details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserReference = currentUser == null
        ? null
        : FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid);
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
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
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
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: () {
                        context.pushNamed(
                          NotificationsListWidget.routeName,
                          extra: <String, dynamic>{
                            kTransitionInfoKey:
                                TransitionStandards.detailTransition,
                          },
                        );
                      },
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: currentUserReference!
                          .collection('notifications')
                          .where('read', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data?.docs.length ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AppIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 30.0,
                              borderWidth: 1.0,
                              buttonSize: 44.0,
                              fillColor: Colors.transparent,
                              tooltip: 'Notifications',
                              icon: Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 24.0,
                              ),
                              onPressed: () {
                                context.pushNamed(
                                  NotificationsListWidget.routeName,
                                  extra: <String, dynamic>{
                                    kTransitionInfoKey:
                                        TransitionStandards.detailTransition,
                                  },
                                );
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
                    ? AppColors.fairway.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: 30.0,
                borderWidth: _filters.hasActiveFilters ? 2.0 : 1.0,
                buttonSize: 44.0,
                fillColor: _filters.hasActiveFilters
                    ? AppColors.fairway.withOpacity(0.12)
                    : Colors.transparent,
                tooltip: 'Filter games',
                icon: Icon(
                  Icons.tune_rounded,
                  color: _filters.hasActiveFilters
                      ? AppColors.fairway
                      : Colors.white,
                  size: 24.0,
                ),
                onPressed: () {
                  _showFilterBottomSheet(
                    _availableGameTypes,
                    _availableVibes,
                    _availableStakes,
                    _availableHandicaps,
                    _availableCourses,
                  );
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
                onRetry: () => setState(() {}),
                builder: (context, gamesList) {
                  debugPrint('📋 GAME LIST: StreamBuilder triggered');
                  debugPrint('✅ GAME LIST: Received ${gamesList.length} documents from Firestore');

                  final allGames = gamesList
                      .map((game) {
                        debugPrint('  - Game: ${game.nameGame} (ID: ${game.reference.id}, isCancelled: ${game.isCancelled})');
                        return game;
                      })
                      .toList();

                  debugPrint('📊 GAME LIST: Total games parsed: ${allGames.length}');

                  // Filter games by status: only show active games, hide expired/completed
                  // For cancelled games, respect user preference
                  final activeGames = allGames.where((game) {
                    debugPrint('  - Checking game: ${game.nameGame} (status: ${game.status})');

                    // Always hide expired and completed games
                    if (game.status == 'expired' || game.status == 'completed') {
                      debugPrint('    → Hiding ${game.status} game');
                      return false;
                    }

                    // For cancelled games, check user preference
                    if (game.status == 'cancelled') {
                      final shouldHide = _shouldHideCancelledGame(game);
                      debugPrint('    → Cancelled game, shouldHide: $shouldHide');
                      return !shouldHide;
                    }

                    // Show active games
                    debugPrint('    → Showing active game');
                    return true;
                  }).toList();

                  debugPrint('📊 GAME LIST: After status filter: ${activeGames.length} games');

                  final availableTypes = _extractAvailableGameTypes(activeGames);
                  if (!setEquals(availableTypes, _availableGameTypes)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _availableGameTypes = availableTypes;
                        });
                      }
                    });
                  }
                  final availableVibes = _extractAvailableVibes(activeGames);
                  if (!setEquals(availableVibes, _availableVibes)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _availableVibes = availableVibes;
                        });
                      }
                    });
                  }
                  final availableStakes = _extractAvailableStakes(activeGames);
                  if (!setEquals(availableStakes, _availableStakes)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _availableStakes = availableStakes;
                        });
                      }
                    });
                  }
                  final availableHandicaps =
                      _extractAvailableHandicaps(activeGames);
                  if (!setEquals(availableHandicaps, _availableHandicaps)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _availableHandicaps = availableHandicaps;
                        });
                      }
                    });
                  }
                  final availableCourses =
                      _extractAvailableCourses(activeGames);
                  if (!setEquals(availableCourses, _availableCourses)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _availableCourses = availableCourses;
                        });
                      }
                    });
                  }

                  final visibleGames = _applyFilters(activeGames, _filters);

                  debugPrint('✅ GAME LIST: Final visible games: ${visibleGames.length}');
                  visibleGames.forEach((game) {
                    debugPrint('  ✓ ${game.nameGame} at ${game.coursePlay}');
                  });

                  return StreamBuilder<UsersRecord?>(
                    stream: currentUserReference == null
                        ? null
                        : UsersRecord.getDocument(currentUserReference),
                    builder: (context, userSnapshot) {
                      final friendIds =
                          _friendIdsFromRecord(userSnapshot.data);
                      final joinableGames = <Game>[];
                      final lockedGames = <Game>[];
                      for (final game in visibleGames) {
                        if (_isJoinableGame(
                            game, currentUserReference, friendIds)) {
                          joinableGames.add(game);
                        } else if (_isFriendsOnlyGame(game)) {
                          lockedGames.add(game);
                        } else {
                          joinableGames.add(game);
                        }
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<GameProvider>().invalidateAllGameCache();
                          await Future.delayed(Duration(milliseconds: 500));
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.md,
                                bottom: 44.0,
                              ),
                              sliver: joinableGames.isEmpty
                                  ? SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.xl,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: AppColors.fairway.withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.golf_course_rounded,
                                                size: 56,
                                                color: Colors.white.withOpacity(0.5),
                                              ),
                                            ),
                                            SizedBox(height: AppSpacing.lg),
                                            if (_filters.hasActiveFilters) ...[
                                              Text(
                                                'No games match these filters',
                                                style: AppTypography.titleMedium.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSpacing.xs),
                                              Text(
                                                'Try adjusting or clearing your filters.',
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSpacing.lg),
                                              SizedBox(
                                                width: 220,
                                                child: AppButtonEnhanced(
                                                  text: 'Clear filters',
                                                  variant: AppButtonVariant.secondary,
                                                  size: AppButtonSize.medium,
                                                  onPressed: () {
                                                    if (mounted) {
                                                      setState(() {
                                                        _filters = GameListFilters();
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ] else if (lockedGames.isNotEmpty) ...[
                                              Text(
                                                'No joinable games right now',
                                                style: AppTypography.titleMedium.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSpacing.xs),
                                              Text(
                                                'There are friends-only games you can view below.',
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSpacing.lg),
                                              SizedBox(
                                                width: 220,
                                                child: AppButtonEnhanced(
                                                  text: _showLockedGames
                                                      ? 'Hide locked games'
                                                      : 'Show locked games',
                                                  variant: AppButtonVariant.secondary,
                                                  size: AppButtonSize.medium,
                                                  onPressed: () {
                                                    if (mounted) {
                                                      setState(() {
                                                        _showLockedGames =
                                                            !_showLockedGames;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ] else ...[
                                              Text(
                                                'No games yet',
                                                style: AppTypography.titleMedium.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSpacing.xs),
                                              Text(
                                                'Be the first to create a game.',
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: AppSpacing.lg),
                                              SizedBox(
                                                width: 220,
                                                child: AppButtonEnhanced(
                                                  text: 'Create a game',
                                                  variant: AppButtonVariant.primary,
                                                  size: AppButtonSize.medium,
                                                  onPressed: () {
                                                    context.pushNamed(
                                                      CreateGameWidget.routeName,
                                                      extra: <String, dynamic>{
                                                        kTransitionInfoKey:
                                                            TransitionStandards.detailTransition,
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final containerVarItem = joinableGames[index];
                                          final isLast =
                                              index == joinableGames.length - 1;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: isLast ? 0.0 : AppSpacing.sm,
                                            ),
                                            child: _buildPremiumGameCard(
                                              context,
                                              containerVarItem,
                                              currentUserReference,
                                            ),
                                          );
                                        },
                                        childCount: joinableGames.length,
                                      ),
                                    ),
                            ),
                            if (lockedGames.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppSpacing.sm,
                                    AppSpacing.md,
                                    AppSpacing.sm,
                                    AppSpacing.sm,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.fairway.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.lock_rounded,
                                                color: Colors.white.withOpacity(0.8),
                                                size: 18,
                                              ),
                                            ),
                                            SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                'Friends-only games',
                                                style: AppTypography.titleSmall.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                if (mounted) {
                                                  setState(() {
                                                    _showLockedGames = !_showLockedGames;
                                                  });
                                                }
                                              },
                                              child: Text(
                                                _showLockedGames ? 'Hide' : 'Show',
                                                style: AppTypography.labelMedium.copyWith(
                                                  color: AppColors.sunsetGold,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Become friends with the host to join.',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_showLockedGames && lockedGames.isNotEmpty)
                              SliverPadding(
                                padding: EdgeInsets.only(
                                  top: AppSpacing.sm,
                                  bottom: 44.0,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final lockedGame = lockedGames[index];
                                      final isLast = index == lockedGames.length - 1;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: isLast ? 0.0 : AppSpacing.sm,
                                        ),
                                        child: _buildPremiumGameCard(
                                          context,
                                          lockedGame,
                                          currentUserReference,
                                          isLocked: true,
                                        ),
                                      );
                                    },
                                    childCount: lockedGames.length,
                                  ),
                                ),
                              ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM GAME CARD - Matching Profile Page Style
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPremiumGameCard(
    BuildContext context,
    Game game,
    DocumentReference? currentUserReference,
    {bool isLocked = false}
  ) {
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
    final isCancelled = game.status == 'cancelled';
    final isExpired = game.status == 'expired';
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;
    final ownerRef = game.userRef;

    return GestureDetector(
      onTap: () async {
        if (isCancelled) {
          if (_getCancelledHandling(game) == null) {
            await _showCancelledGameOptions(game);
          }
        } else if (isLocked) {
          await _showFriendsOnlyDialog();
        } else if (isUserGame) {
          context.pushNamed(
            GameJoinedDetailedWidget.routeName,
            extra: <String, dynamic>{
              'gameRef': game.reference,
              kTransitionInfoKey: TransitionStandards.detailTransition,
            },
          );
        } else {
          context.pushNamed(
            JoinGameDetailedWidget.routeName,
            extra: <String, dynamic>{
              'gameRef': game.reference,
              kTransitionInfoKey: TransitionStandards.detailTransition,
            },
          );
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.fairway.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isUserGame
                ? AppColors.sunsetGold.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: isUserGame ? 2.0 : 1.0,
          ),
          boxShadow: isUserGame
              ? [
                  BoxShadow(
                    color: AppColors.sunsetGold.withOpacity(0.15),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Game Type Badge + Status + Spots indicator
                  Row(
                    children: [
                      if (isLocked)
                        Tooltip(
                          message: 'Friends-only game',
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Friends Only',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isLocked) SizedBox(width: AppSpacing.xs),
                      // Game Type Badge with gradient
                      if (game.gameType.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: game.styleGame == 'Money Game'
                                  ? [AppColors.sunsetGold, AppColors.sunsetPeach]
                                  : [AppColors.fairwayLight, AppColors.fairway],
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: (game.styleGame == 'Money Game'
                                        ? AppColors.sunsetGold
                                        : AppColors.fairway)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            game.gameType,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (game.styleGame == 'Money Game') ...[
                        SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sunsetGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$\$\$',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.sunsetGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      Spacer(),
                      // Status badges
                      if (isCancelled)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Cancelled',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (isExpired)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            'Expired',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (isUserGame)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Joined',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Course Name - Hero Element with icon
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.fairwayLight, AppColors.fairway],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.golf_course_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valueOrDefault<String>(game.coursePlay, 'Course Name'),
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              valueOrDefault<String>(game.nameGame, 'Game Name'),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.sunsetGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isLocked)
                              _LockedGameHostLabel(ownerRef: ownerRef),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Date & Time with premium styling
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.sunsetPeach.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.sunsetPeach,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dateTimeFormat("EEEE", game.date)}, ${dateTimeFormat("MMM d", game.date)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                dateTimeFormat("jm", game.date),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Player count indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isFull
                                ? AppColors.sunsetRose.withOpacity(0.2)
                                : AppColors.fairwayLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFull
                                  ? AppColors.sunsetRose.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: isFull
                                    ? AppColors.sunsetRose
                                    : Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isFull
                                      ? AppColors.sunsetRose
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action bar
            if (!isCancelled && !isExpired)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Member discount badge
                    if (game.memberDiscount == 'Yes')
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fairwayLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer_rounded,
                              color: AppColors.fairwayLight,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Discount',
                              style: AppTypography.text10.copyWith(
                                color: AppTheme.of(context).primaryBtnText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Spacer(),
                    // Action button
                    isLocked
                        ? InkWell(
                            onTap: () {
                              context.pushNamed(TabFriendsWidget.routeName);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.sunsetGold.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add Friend',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              gradient: isUserGame
                                  ? LinearGradient(
                                      colors: [AppColors.fairwayLight, AppColors.fairway],
                                    )
                                  : LinearGradient(
                                      colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isUserGame
                                          ? AppColors.fairway
                                          : AppColors.sunsetGold)
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUserGame
                                      ? Icons.visibility_rounded
                                      : (isFull
                                          ? Icons.hourglass_empty_rounded
                                          : Icons.add_rounded),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  isUserGame
                                      ? 'View Details'
                                      : (isFull ? 'Full' : 'Join Game'),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedGameHostLabel extends StatelessWidget {
  const _LockedGameHostLabel({required this.ownerRef});

  final DocumentReference? ownerRef;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: Colors.white.withOpacity(0.7),
      fontWeight: FontWeight.w500,
    );

    if (ownerRef == null) {
      return Text('Host: Unknown', style: style);
    }

    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(ownerRef!),
      builder: (context, snapshot) {
        final hostName = snapshot.data?.displayName;
        final label = hostName != null && hostName.trim().isNotEmpty
            ? hostName.trim()
            : 'Unknown';
        return Text('Host: $label', style: style);
      },
    );
  }
}
