import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/form_field_controller.dart';
import '/core/custom_functions.dart' as functions;
import '/main_function/games_list/games_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerListWidget extends StatefulWidget {
  const PlayerListWidget({
    super.key,
    required this.gameRef,
  });

  final GamesRecord? gameRef;

  static String routeName = 'PlayerList';
  static String routePath = '/usersinCreateGame';

  @override
  State<PlayerListWidget> createState() => _PlayerListWidgetState();
}

class _PlayerListWidgetState extends State<PlayerListWidget> {
  static const String guestOptionValue = 'guest';

  List<DocumentReference> playersJoined = [];
  void addToPlayersJoined(DocumentReference item) => playersJoined.add(item);
  void removeFromPlayersJoined(DocumentReference item) =>
      playersJoined.remove(item);
  void removeAtIndexFromPlayersJoined(int index) =>
      playersJoined.removeAt(index);
  void insertAtIndexInPlayersJoined(int index, DocumentReference item) =>
      playersJoined.insert(index, item);
  void updatePlayersJoinedAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      playersJoined[index] = updateFn(playersJoined[index]);

  List<String> playersJoinedUID = [];
  void addToPlayersJoinedUID(String item) => playersJoinedUID.add(item);
  void removeFromPlayersJoinedUID(String item) =>
      playersJoinedUID.remove(item);
  void removeAtIndexFromPlayersJoinedUID(int index) =>
      playersJoinedUID.removeAt(index);
  void insertAtIndexInPlayersJoinedUID(int index, String item) =>
      playersJoinedUID.insert(index, item);
  void updatePlayersJoinedUIDAtIndex(int index, Function(String) updateFn) =>
      playersJoinedUID[index] = updateFn(playersJoinedUID[index]);

  final formKey = GlobalKey<FormState>();
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).primaryBtnText,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Align(
            alignment: AlignmentDirectional(-1.0, 0.0),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
              child: Text(
                'Player List',
                style: AppTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontStyle: AppTheme.of(context)
                            .headlineSmall
                            .fontStyle,
                      ),
                      fontSize: 24.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          AppTheme.of(context).headlineSmall.fontStyle,
                    ),
              ),
            ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 10.0,
        ),
        body: SafeArea(
          top: true,
          child: FairwayBackgroundDark(
            child: Padding(
              padding: AppSpacing.allLg,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FutureBuilder<List<UsersRecord>>(
                      future: queryUsersRecordOnce(),
                      builder: (context, snapshot) {
                        // Customize what your widget looks like when it's loading.
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
                        List<UsersRecord> gameFormUsersRecordList = snapshot
                            .data!
                            .where((u) => u.uid != currentUserUid)
                            .toList();
                        final playerOptions = gameFormUsersRecordList
                            .map(
                              (e) => valueOrDefault<String>(
                                e.uid,
                                '',
                              ),
                            )
                            .where((uid) => uid.isNotEmpty)
                            .toList();
                        final playerLabels = gameFormUsersRecordList
                            .map(
                              (e) => valueOrDefault<String>(
                                e.displayName,
                                'Name',
                              ),
                            )
                            .toList();
                        playerOptions.add(guestOptionValue);
                        playerLabels.add('Guest');

                        return Container(
                          width: double.infinity,
                          child: Form(
                            key: formKey,
                            autovalidateMode: AutovalidateMode.disabled,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(-1.0, 0.0),
                                  child: Padding(
                                    padding: AppSpacing.only(
                                        left: AppSpacing.xs,
                                        top: AppSpacing.sm,
                                        bottom: AppSpacing.sm),
                                    child: Text(
                                      'Add Current Players',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                            color: AppTheme.of(context)
                                                .primaryText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(-1.0, 0.0),
                                  child: Padding(
                                    padding: AppSpacing.only(
                                        left: AppSpacing.xs,
                                        bottom: AppSpacing.md),
                                    child: AuthUserStreamWidget(
                                      builder: (context) => Text(
                                        valueOrDefault<String>(
                                          currentUserDisplayName,
                                          'Maker of Game',
                                        ),
                                        style: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  AppTheme.of(context)
                                                      .primaryText,
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.gameRef!.numPlayers >= 1)
                                  Align(
                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                    child: Padding(
                                      padding: AppSpacing.only(
                                          bottom: AppSpacing.lg),
                                      child: AppDropDown<String>(
                                        controller:
                                            dropDownValueController1 ??=
                                                FormFieldController<String>(
                                          dropDownValue1 ??= '',
                                        ),
                                        options:
                                            List<String>.from(playerOptions),
                                        optionLabels: playerLabels,
                                        onChanged: (val) {
                                          if (mounted) {
                                            setState(() =>
                                                dropDownValue1 = val);
                                          }
                                        },
                                        width: 300.0,
                                        height: 50.0,
                                        searchHintTextStyle: AppTheme
                                                .of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    AppTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                        searchTextStyle: AppTheme.of(
                                                context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        textStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                        hintText: 'Find Player 2....',
                                        searchHintText: 'Search Players....',
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppTheme.of(context)
                                              .secondaryText,
                                          size: 24.0,
                                        ),
                                        fillColor: AppTheme.of(context)
                                            .secondaryBackground,
                                        elevation: 2.0,
                                        borderColor:
                                            AppTheme.of(context)
                                                .alternate,
                                        borderWidth: 2.0,
                                        borderRadius: 8.0,
                                        margin: AppSpacing.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.xxs),
                                        hidesUnderline: true,
                                        isOverButton: true,
                                        isSearchable: true,
                                        isMultiSelect: false,
                                      ),
                                    ),
                                  ),
                                if (widget.gameRef!.numPlayers >= 2)
                                  Align(
                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                    child: AppDropDown<String>(
                                      controller:
                                          dropDownValueController2 ??=
                                              FormFieldController<String>(
                                        dropDownValue2 ??= '',
                                      ),
                                      options:
                                          List<String>.from(playerOptions),
                                      optionLabels: playerLabels,
                                      onChanged: (val) {
                                        if (mounted) {
                                          setState(() =>
                                              dropDownValue2 = val);
                                        }
                                      },
                                      width: 300.0,
                                      height: 50.0,
                                      textStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Find Player 3....',
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.of(context)
                                            .secondaryText,
                                        size: 24.0,
                                      ),
                                      fillColor: AppTheme.of(context)
                                          .secondaryBackground,
                                      elevation: 2.0,
                                      borderColor: AppTheme.of(context)
                                          .alternate,
                                      borderWidth: 2.0,
                                      borderRadius: 8.0,
                                      margin: AppSpacing.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.xxs),
                                      hidesUnderline: true,
                                      isOverButton: true,
                                      isSearchable: false,
                                      isMultiSelect: false,
                                    ),
                                  ),
                                Padding(
                                  padding: AppSpacing.only(
                                      top: AppSpacing.xxxl),
                                  child: AppButtonEnhanced(
                                    onPressed: () async {
                                      final selections = <String?>[
                                        dropDownValue1,
                                        if (widget.gameRef!.numPlayers >= 2)
                                          dropDownValue2,
                                      ];
                                      final joinedPlayersToAdd =
                                          <DocumentReference>[];
                                      final guestPlayersToAdd = <String>[];

                                      for (final selection in selections) {
                                        if (selection == null ||
                                            selection.isEmpty) {
                                          continue;
                                        }
                                        if (selection == guestOptionValue) {
                                          guestPlayersToAdd.add(
                                            'Guest ${guestPlayersToAdd.length + 1}',
                                          );
                                        } else {
                                          final playerRef =
                                              functions.returnDocRefFromUID(
                                                  selection);
                                          if (playerRef != null) {
                                            joinedPlayersToAdd.add(playerRef);
                                          }
                                        }
                                      }

                                      if (joinedPlayersToAdd.isNotEmpty ||
                                          guestPlayersToAdd.isNotEmpty) {
                                        await widget.gameRef!.reference.update({
                                          ...mapToFirestore({
                                            if (joinedPlayersToAdd.isNotEmpty)
                                              'joined_players':
                                                  FieldValue.arrayUnion(
                                                      joinedPlayersToAdd),
                                            if (guestPlayersToAdd.isNotEmpty)
                                              'guest_players':
                                                  FieldValue.arrayUnion(
                                                      guestPlayersToAdd),
                                          }),
                                        });
                                      }

                                      context.pushNamed(
                                        GamesListWidget.routeName,
                                        extra: <String, dynamic>{
                                          kTransitionInfoKey: TransitionInfo(
                                            hasTransition: true,
                                            transitionType:
                                                PageTransitionType.bottomToTop,
                                            duration:
                                                Duration(milliseconds: 220),
                                          ),
                                        },
                                      );
                                    },
                                    text: 'Submit Players',
                                    variant: AppButtonVariant.primary,
                                    size: AppButtonSize.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
