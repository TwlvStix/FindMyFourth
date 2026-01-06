import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/app_choice_chips.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/form_field_controller.dart';
import '/core/custom_functions.dart' as functions;
import '/friends/tab_friends/tab_friends_widget.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  List<GamesRecord> filteredList = [];
  List<GamesRecord>? snapshotGames;
  FormFieldController<List<String>>? choiceChipsValueController;
  final Map<DocumentReference, CancelledGameHandling>
      _cancelledGameHandlingByGame = {};
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      snapshotGames = await queryGamesRecordOnce(
        queryBuilder: (gamesRecord) => gamesRecord.where(Filter.or(
          Filter(
            'isCancelled',
            isEqualTo: false,
          ),
          Filter(
            'userRef',
            isEqualTo: currentUserReference,
          ),
        )),
      );
      filteredList = snapshotGames!.toList().cast<GamesRecord>();
      if (mounted) setState(() {});
    });

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

  bool _shouldHideCancelledGame(GamesRecord game) {
    if (!game.isCancelled) {
      return false;
    }
    final handling = _cancelledGameHandlingByGame[game.reference];
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

  Future<void> _showCancelledGameOptions(GamesRecord game) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
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
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 15.0, 0.0),
              child: AppIconButton(
                borderRadius: 20.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: AppTheme.of(context).primaryBackground,
                icon: Icon(
                  Icons.person_outline_outlined,
                  color: AppTheme.of(context).primary,
                  size: 30.0,
                ),
                onPressed: () async {
                  context.pushNamed(
                    MainProfileWidget.routeName,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                        duration: Duration(milliseconds: 200),
                      ),
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
              child: AppIconButton(
                borderRadius: 20.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: AppTheme.of(context).primaryBackground,
                icon: Icon(
                  Icons.search_sharp,
                  color: AppTheme.of(context).primary,
                  size: 26.0,
                ),
                onPressed: () async {
                  context.pushNamed(
                    TabFriendsWidget.routeName,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                        duration: Duration(milliseconds: 200),
                      ),
                    },
                  );
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 10.0,
        ),
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.of(context).secondaryBackground,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 20.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
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
                                  setState(() =>
                                      choiceChipsValue = val?.firstOrNull);
                                }
                                filteredList = functions
                                    .filterFunction(
                                        snapshotGames?.toList(),
                                        choiceChipsValue)!
                                    .toList()
                                    .cast<GamesRecord>();
                                if (mounted) setState(() {});
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
                                borderRadius: BorderRadius.circular(16.0),
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
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              chipSpacing: 12.0,
                              rowSpacing: 12.0,
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
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final containerVar = filteredList
                            .where((game) => !_shouldHideCancelledGame(game))
                            .toList();

                        return ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            12.0,
                            0,
                            44.0,
                          ),
                          scrollDirection: Axis.vertical,
                          itemCount: containerVar.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.0),
                          itemBuilder: (context, containerVarIndex) {
                            final containerVarItem =
                                containerVar[containerVarIndex];
                            final playersNeeded = containerVarItem.maxPlayers -
                                (containerVarItem.joinedPlayers.length +
                                    containerVarItem.guestPlayers.length);
                            return Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 15.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 0.85,
                                height: MediaQuery.sizeOf(context).height * 0.2,
                                decoration: BoxDecoration(
                                  color: AppTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(15.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Stack(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  children: [
                                    StreamBuilder<CourseRecord>(
                                      stream: CourseRecord.getDocument(
                                          containerVarItem.courseRef!),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: SpinKitWanderingCubes(
                                                color: Color(0xFF25504F),
                                                size: 50.0,
                                              ),
                                            ),
                                          );
                                        }

                                        final imageCourseRecord =
                                            snapshot.data!;

                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.network(
                                            imageCourseRecord.picture,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                              'assets/images/error_image.png',
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Color(0x4014181B),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 0.0, 12.0, 0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          5.0, 0.0, 0.0, 0.0),
                                                  child: AutoSizeText(
                                                    valueOrDefault<String>(
                                                      containerVarItem.nameGame,
                                                      'Game Name',
                                                    ).maybeHandleOverflow(
                                                      maxChars: 20,
                                                      replacement: '…',
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .headlineMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                AppTheme.of(
                                                                        context)
                                                                    .headlineMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .headlineMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .info,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              AppTheme.of(
                                                                      context)
                                                                  .headlineMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .headlineMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              AppIconButton(
                                                borderRadius: 20.0,
                                                borderWidth: 1.0,
                                                buttonSize: 40.0,
                                                hoverColor:
                                                    AppTheme.of(context)
                                                        .primaryText,
                                                hoverIconColor:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                icon: Icon(
                                                  Icons.navigate_next,
                                                  color: AppTheme.of(
                                                          context)
                                                      .primaryBackground,
                                                  size: 36.0,
                                                ),
                                                onPressed: () async {
                                                  if (containerVarItem
                                                          .isCancelled ==
                                                      true) {
                                                    await _showCancelledGameOptions(
                                                        containerVarItem);
                                                  } else {
                                                    if ((containerVarItem
                                                                .userRef ==
                                                            currentUserReference) ||
                                                        containerVarItem
                                                            .joinedPlayers
                                                            .contains(
                                                                currentUserReference)) {
                                                      context.pushNamed(
                                                        GameJoinedDetailedWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'gameRef':
                                                              serializeParam(
                                                            containerVarItem
                                                                .reference,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    } else {
                                                      context.pushNamed(
                                                        JoinGameDetailedWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'gameRef':
                                                              serializeParam(
                                                            containerVarItem
                                                                .reference,
                                                            ParamType
                                                                .DocumentReference,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 5.0, 0.0, 0.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          5.0, 0.0, 0.0, 0.0),
                                                  child: FaIcon(
                                                    FontAwesomeIcons.calendar,
                                                    color: AppTheme.of(
                                                            context)
                                                        .info,
                                                    size: 24.0,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          5.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      dateTimeFormat(
                                                          "EEEE",
                                                          containerVarItem
                                                              .date),
                                                      'Friday',
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .info,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  ',',
                                                  style: AppTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.outfit(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            AppTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          2.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      dateTimeFormat(
                                                          "MMMM",
                                                          containerVarItem
                                                              .date),
                                                      'July',
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .info,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          3.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      dateTimeFormat(
                                                          "d",
                                                          containerVarItem
                                                              .date),
                                                      '16',
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .info,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          5.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      dateTimeFormat(
                                                          "jm",
                                                          containerVarItem
                                                              .date),
                                                      '9:00',
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .info,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 10.0, 0.0, 0.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  5.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Icon(
                                                        Icons.golf_course,
                                                        color:
                                                            AppTheme.of(
                                                                    context)
                                                                .info,
                                                        size: 24.0,
                                                      ),
                                                    ),
                                                    Text(
                                                      valueOrDefault<String>(
                                                        containerVarItem
                                                            .coursePlay,
                                                        'Tower Ranch',
                                                      ),
                                                      style:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .info,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 10.0, 0.0, 0.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  5.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Icon(
                                                        Icons.person,
                                                        color:
                                                            AppTheme.of(
                                                                    context)
                                                                .info,
                                                        size: 24.0,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Players Needed:  ',
                                                      style:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .info,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                    ),
                                                    Text(
                                                      (playersNeeded < 0
                                                              ? 0
                                                              : playersNeeded)
                                                          .toString(),
                                                      style: AppTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .outfit(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            color: AppTheme
                                                                    .of(context)
                                                                .info,
                                                            fontSize: 20.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    if (containerVarItem
                                                        .isCancelled)
                                                      Text(
                                                        'Cancelled',
                                                        textAlign:
                                                            TextAlign.end,
                                                        style:
                                                            AppTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: AppTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: AppTheme.of(
                                                                          context)
                                                                      .error,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    if (((containerVarItem
                                                                    .date !=
                                                                null) &&
                                                            (containerVarItem
                                                                    .date! <
                                                                getCurrentTimestamp)) &&
                                                        (containerVarItem
                                                                .isCancelled ==
                                                            false))
                                                      Text(
                                                        'Expired',
                                                        textAlign:
                                                            TextAlign.end,
                                                        style:
                                                            AppTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: AppTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: AppTheme.of(
                                                                          context)
                                                                      .error,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                  ],
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
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
