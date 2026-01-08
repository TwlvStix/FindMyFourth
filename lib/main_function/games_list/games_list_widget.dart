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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

enum CancelledGameHandling {
  removeNow,
  removeEndOfDay,
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
  static const Map<CancelledGameHandling, String>
      _cancelledHandlingStorageMap = {
    CancelledGameHandling.removeNow: 'removeNow',
    CancelledGameHandling.removeEndOfDay: 'removeEndOfDay',
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
    if (!game.isCancelled) {
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
    return false;
  }

  List<Game> _filterGames(List<Game> gamesList, String? choiceChipValue) {
    if (choiceChipValue == '\$\$\$\$') {
      return gamesList
          .where((game) => game.styleGame == 'Money Game')
          .toList();
    }
    if (choiceChipValue == 'Vegas') {
      return gamesList.where((game) => game.gameType == 'Vegas').toList();
    }
    if (choiceChipValue == 'For Fun') {
      return gamesList.where((game) => game.styleGame == 'All Fun').toList();
    }
    if (choiceChipValue == 'Discount') {
      return gamesList
          .where((game) => game.memberDiscount == 'Yes')
          .toList();
    }
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
                CancelledGameHandling.removeEndOfDay,
              ),
              child: Text('Remove after today'),
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
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/');
              }
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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('games')
                    .where('isCancelled', isEqualTo: false)
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  // Show loading indicator
                  if (!snapshot.hasData) {
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

                  final allGames = snapshot.data!.docs
                      .map((doc) => Game.fromDoc(doc))
                      .toList();
                  final filteredList =
                      _filterGames(allGames, choiceChipsValue);
                  final visibleGames = filteredList
                      .where((game) => !_shouldHideCancelledGame(game))
                      .toList();

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
                                      if (containerVarItem.isCancelled == true) {
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
                                                if (containerVarItem.isCancelled)
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
                                                if (((containerVarItem.date != null) &&
                                                        (containerVarItem.date! <
                                                            getCurrentTimestamp)) &&
                                                    (containerVarItem.isCancelled ==
                                                        false))
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
