import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_choice_chips.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/form_field_controller.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/models/game.dart';
import '/services/firestore_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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
    _gamesStream = const FirestoreRepository()
        .queryCollectionPage<Game>(
          FirebaseFirestore.instance.collection('games').orderBy('date'),
          (doc) => Game.fromDoc(doc),
          pageSize: 100,
          isStream: true,
        )
        .asStream()
        .asyncExpand((page) => page.dataStream ?? Stream.value(page.data));
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: AppIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 55.0,
            icon: Icon(
              Icons.arrow_back_sharp,
              color: AppTheme.of(context).primary,
              size: 25.0,
            ),
            onPressed: () async {
              debugPrint('🔙 GAME LIST: Back button pressed');
              final router = GoRouter.of(context);

              // Always navigate to home screen instead of popping
              // This prevents navigation stack issues and ensures consistent behavior
              debugPrint('🔙 GAME LIST: Navigating to home screen');
              router.go('/home');
            },
          ),
          title: Text(
            'Game List',
            style: AppTheme.of(context).headlineLarge.override(
                  fontFamily: 'Gotham',
                  color: AppTheme.of(context).primary,
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          child: SafeArea(
            top: true,
            child: Padding(
              padding: AppSpacing.screen,
              child: StreamBuilder<List<Game>>(
                stream: _gamesStream,
                builder: (context, snapshot) {
                  debugPrint('📋 GAME LIST: StreamBuilder triggered');

                  // Handle errors
                  if (snapshot.hasError) {
                    debugPrint('❌ GAME LIST: Error fetching games: ${snapshot.error}');
                    debugPrint('❌ GAME LIST: Error type: ${snapshot.error.runtimeType}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading games',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Show loading indicator
                  if (!snapshot.hasData) {
                    debugPrint('⏳ GAME LIST: Waiting for data...');
                    return Center(
                      child: SizedBox(
                        width: 50.0,
                        height: 50.0,
                        child: SpinKitWanderingCubes(
                          color: AppTheme.of(context).secondary,
                          size: 50.0,
                        ),
                      ),
                    );
                  }

                  debugPrint('✅ GAME LIST: Received ${snapshot.data!.length} documents from Firestore');

                  final allGames = snapshot.data!
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
                      await Future.delayed(Duration(milliseconds: 500));
                      setState(() {});
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
                                        backgroundColor: Color(0xFFA2A2A2),
                                        textStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                              color: AppTheme.of(context)
                                                  .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                        iconColor: Colors.white,
                                        iconSize: 18.0,
                                        elevation: 4.0,
                                        borderColor: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                      ),
                                      unselectedChipStyle: ChipStyle(
                                        backgroundColor:
                                            AppTheme.of(context).primaryBtnText,
                                        textStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                              color: AppTheme.of(context)
                                                  .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                        iconColor: Colors.white,
                                        iconSize: 18.0,
                                        elevation: 5.0,
                                        borderColor:
                                            AppTheme.of(context).primaryBtnText,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      chipSpacing: AppSpacing.sm,
                                      rowSpacing: AppSpacing.sm,
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
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final containerVarItem = visibleGames[index];
                                final isLast = index == visibleGames.length - 1;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0.0 : AppSpacing.sm,
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      if (containerVarItem.status == 'cancelled') {
                                        if (_getCancelledHandling(
                                                containerVarItem) ==
                                            null) {
                                          await _showCancelledGameOptions(
                                              containerVarItem);
                                        }
                                      } else if (currentUserReference != null &&
                                          ((containerVarItem.userRef ==
                                                  currentUserReference) ||
                                              containerVarItem.joinedPlayers
                                                  .contains(
                                                      currentUserReference))) {
                                          context.pushNamed(
                                            GameJoinedDetailedWidget.routeName,
                                            extra: <String, dynamic>{
                                              'gameRef':
                                                  containerVarItem.reference,
                                            },
                                          );
                                      } else {
                                        context.pushNamed(
                                          JoinGameDetailedWidget.routeName,
                                          extra: <String, dynamic>{
                                            'gameRef':
                                                containerVarItem.reference,
                                          },
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14.0),
                                        border: Border(
                                          left: BorderSide(
                                            color: Color(0xFF1A4D2E),
                                            width: 5.0,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.06),
                                            blurRadius: 8.0,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // COURSE NAME - HERO ELEMENT
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  color: Color(0xFF1A4D2E),
                                                  size: 22.0,
                                                ),
                                                SizedBox(width: 6.0),
                                                Expanded(
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      containerVarItem
                                                          .coursePlay,
                                                      'Course Name',
                                                    ),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 20.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1A4D2E),
                                                      letterSpacing: -0.2,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 14.0),

                                            // GAME NAME
                                            Text(
                                              valueOrDefault<String>(
                                                containerVarItem.nameGame,
                                                'Game Name',
                                              ),
                                              style: GoogleFonts.outfit(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF4A5568),
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                            SizedBox(height: 10.0),

                                            // DATE & TIME
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  color: Color(0xFF718096),
                                                  size: 16.0,
                                                ),
                                                SizedBox(width: 6.0),
                                                Expanded(
                                                  child: Text(
                                                    '${dateTimeFormat("EEEE", containerVarItem.date)}, ${dateTimeFormat("MMMM", containerVarItem.date)} ${dateTimeFormat("d", containerVarItem.date)} • ${dateTimeFormat("jm", containerVarItem.date)}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Color(0xFF718096),
                                                      letterSpacing: 0.0,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12.0),

                                            // GAME TYPE & PLAYERS
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Game Type Badge
                                                if (containerVarItem
                                                    .gameType.isNotEmpty)
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                      vertical: 6.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFE8F5E9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                      border: Border.all(
                                                        color: Color(0xFF1A4D2E)
                                                            .withValues(
                                                                alpha: 0.2),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      valueOrDefault<String>(
                                                        containerVarItem
                                                            .gameType,
                                                        'Game Type',
                                                      ),
                                                      style:
                                                          GoogleFonts.outfit(
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color(0xFF1A4D2E),
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ),
                                                if (containerVarItem
                                                    .gameType.isNotEmpty)
                                                  Spacer(),

                                                // Players Info
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.people,
                                                      color: Color(0xFF718096),
                                                      size: 18.0,
                                                    ),
                                                    SizedBox(width: 6.0),
                                                    Text(
                                                      '${containerVarItem.joinedPlayers.length + containerVarItem.guestPlayers.length}/${containerVarItem.maxPlayers} players',
                                                      style:
                                                          GoogleFonts.outfit(
                                                        fontSize: 14.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color(0xFF4A5568),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // Status Badges
                                                if (containerVarItem.status == 'cancelled')
                                                  Container(
                                                    margin:
                                                        EdgeInsets.only(left: 12.0),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 4.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFFFEBEE),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                    child: Text(
                                                      'Cancelled',
                                                      style:
                                                          GoogleFonts.outfit(
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(0xFFD32F2F),
                                                      ),
                                                    ),
                                                  ),
                                                if (containerVarItem.status == 'expired')
                                                  Container(
                                                    margin:
                                                        EdgeInsets.only(left: 12.0),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 4.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFFFF3E0),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                    ),
                                                    child: Text(
                                                      'Expired',
                                                      style:
                                                          GoogleFonts.outfit(
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(0xFFE65100),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
}
