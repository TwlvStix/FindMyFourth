import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_choice_chips.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/form_field_controller.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/models/game.dart';
import '/providers/game_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
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
  FormFieldController<List<String>>? choiceChipsValueController;
  final Map<DocumentReference, CancelledGameHandling>
      _cancelledGameHandlingByGame = {};
  late final Stream<List<Game>> _gamesStream;
  static const Map<CancelledGameHandling, String>
      _cancelledHandlingStorageMap = {
    CancelledGameHandling.removeNow: 'removeNow',
    CancelledGameHandling.removeEndOfDay: 'removeEndOfDay',
    CancelledGameHandling.removeAfter7Days: 'removeAfter7Days',
    CancelledGameHandling.keepInList: 'keepInList',
  };
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final gameProvider = context.read<GameProvider>();
    _gamesStream = gameProvider
        .availableGamesStream()
        .map((records) => records.map((record) => Game.fromRecord(record)).toList());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  CancelledGameHandling? _parseCancelledHandling(String? value) {
    if (value == null) {
      return null;
    }
    return _cancelledHandlingStorageMap.entries
        .firstWhereOrNull((entry) => entry.value == value)
        ?.key;
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

  List<Game> _filterGames(List<Game> gamesList, String? choiceChipValue) {
    debugPrint('🔍 FILTER: Applying choice chip filter: "$choiceChipValue"');
    debugPrint('🔍 FILTER: Input games: ${gamesList.length}');

    if (choiceChipValue == '\$\$\$\$') {
      debugPrint('🔍 FILTER: Filtering for Money Game');
      final filtered = gamesList
          .where((game) => game.styleGame == 'Money Game')
          .toList();
      debugPrint('🔍 FILTER: Found ${filtered.length} Money Games');
      return filtered;
    }
    if (choiceChipValue == 'Vegas') {
      debugPrint('🔍 FILTER: Filtering for Vegas');
      final filtered = gamesList.where((game) => game.gameType == 'Vegas').toList();
      debugPrint('🔍 FILTER: Found ${filtered.length} Vegas games');
      return filtered;
    }
    if (choiceChipValue == 'For Fun') {
      debugPrint('🔍 FILTER: Filtering for All Fun');
      final filtered = gamesList.where((game) => game.styleGame == 'All Fun').toList();
      debugPrint('🔍 FILTER: Found ${filtered.length} All Fun games');
      return filtered;
    }
    if (choiceChipValue == 'Discount') {
      debugPrint('🔍 FILTER: Filtering for Member Discount');
      final filtered = gamesList
          .where((game) => game.memberDiscount == 'Yes')
          .toList();
      debugPrint('🔍 FILTER: Found ${filtered.length} games with discount');
      return filtered;
    }
    debugPrint('🔍 FILTER: No filter applied (showing all ${gamesList.length} games)');
    return gamesList;
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
          leading: GestureDetector(
            onTap: () async {
              debugPrint('🔙 GAME LIST: Back button pressed');
              final router = GoRouter.of(context);
              debugPrint('🔙 GAME LIST: Navigating to home screen');
              router.go('/home');
            },
            child: Container(
              margin: EdgeInsets.only(left: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.fairway.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 28.0,
              ),
            ),
          ),
          title: Text(
            'Game List',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                initialData: const <Game>[],
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

                  final filteredList =
                      _filterGames(activeGames, choiceChipsValue);

                  debugPrint('📊 GAME LIST: After choice chip filter ("$choiceChipsValue"): ${filteredList.length} games');

                  final visibleGames = filteredList;

                  debugPrint('✅ GAME LIST: Final visible games: ${visibleGames.length}');
                  visibleGames.forEach((game) {
                    debugPrint('  ✓ ${game.nameGame} at ${game.coursePlay}');
                  });

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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: AppSpacing.verticalSm,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: AppChoiceChips(
                                      options: [
                                        ChipData('\$\$\$\$'),
                                        ChipData('Vegas'),
                                        ChipData('For Fun'),
                                        ChipData('Discount'),
                                        ChipData('All')
                                      ],
                                      onChanged: (val) async {
                                        if (mounted) {
                                          setState(() => choiceChipsValue =
                                              val?.firstOrNull);
                                        }
                                      },
                                      selectedChipStyle: ChipStyle(
                                        backgroundColor: AppColors.fairwayDark,
                                        textStyle: AppTypography.labelMedium.withColor(AppColors.pure),
                                        iconColor: AppColors.pure,
                                        iconSize: 16.0,
                                        elevation: 2.0,
                                        borderColor: AppColors.fairwayDark,
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      unselectedChipStyle: ChipStyle(
                                        backgroundColor: AppColors.pure,
                                        textStyle: AppTypography.labelMedium.withColor(AppColors.slate),
                                        iconColor: AppColors.slate,
                                        iconSize: 16.0,
                                        elevation: 0.0,
                                        borderColor: AppColors.cloud,
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      chipSpacing: AppSpacing.xs,
                                      rowSpacing: AppSpacing.xs,
                                      multiselect: false,
                                      initialized: choiceChipsValue != null,
                                      alignment: WrapAlignment.start,
                                      controller: choiceChipsValueController ??=
                                          FormFieldController<List<String>>(
                                        ['All'],
                                      ),
                                      wrapped: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            top: AppSpacing.sm,
                            bottom: 44.0,
                          ),
                          sliver: visibleGames.isEmpty
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
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final containerVarItem = visibleGames[index];
                                      final isLast = index == visibleGames.length - 1;
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
                                    childCount: visibleGames.length,
                                  ),
                                ),
                        ),
                      ],
                    ),
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
  ) {
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
    final isCancelled = game.status == 'cancelled';
    final isExpired = game.status == 'expired';
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return GestureDetector(
      onTap: () async {
        if (isCancelled) {
          if (_getCancelledHandling(game) == null) {
            await _showCancelledGameOptions(game);
          }
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
                    Container(
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
