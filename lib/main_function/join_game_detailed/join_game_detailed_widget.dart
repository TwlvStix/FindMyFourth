import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/date_format_widget.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/core/widgets/app_button.dart';
import '/main_function/join_game/join_game_widget.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/profile/profile_user/profile_user_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinGameDetailedWidget extends StatefulWidget {
  const JoinGameDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'JoinGameDetailed';
  static String routePath = '/joinGameDetailed';

  @override
  State<JoinGameDetailedWidget> createState() => _JoinGameDetailedWidgetState();
}

class _JoinGameDetailedWidgetState extends State<JoinGameDetailedWidget> {
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
    return StreamBuilder<GamesRecord>(
      stream: GamesRecord.getDocument(widget.gameRef!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: Color(0xFF25504F),
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final joinGameDetailedGamesRecord = snapshot.data!;

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: AppTheme.of(context).secondaryBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.of(context).primaryBackground,
            automaticallyImplyLeading: false,
            leading: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.go('/');
                }
              },
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.of(context).primary,
                size: 32.0,
              ),
            ),
            title: Text(
              'Join Game',
              style: AppTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          AppTheme.of(context).headlineSmall.fontStyle,
                    ),
                    color: AppTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        AppTheme.of(context).headlineSmall.fontStyle,
                  ),
            ),
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: AuthUserStreamWidget(
            builder: (context) {
              final isCreatorFriend =
                  currentUserDocument?.friends.contains(
                        joinGameDetailedGamesRecord.userRef,
                      ) ??
                      false;

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.of(context).tertiary,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Stack(
                          alignment: AlignmentDirectional(0.0, 1.0),
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(),
                              child: StreamBuilder<CourseRecord>(
                                stream: CourseRecord.getDocument(
                                    joinGameDetailedGamesRecord.courseRef!),
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

                                  final coursePicCourseRecord = snapshot.data!;

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Image.network(
                                      coursePicCourseRecord.picture,
                                      width: double.infinity,
                                      fit: BoxFit.fill,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      joinGameDetailedGamesRecord.nameGame,
                                      style: AppTheme.of(context)
                                          .headlineMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .headlineMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .headlineMedium
                                                      .fontStyle,
                                            ),
                                            color: AppTheme.of(context)
                                                .primaryBtnText,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .headlineMedium
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .headlineMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: AlignmentDirectional(1.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 20.0, 0.0),
                                        child: Text(
                                          joinGameDetailedGamesRecord
                                              .coursePlay,
                                          style: AppTheme.of(context)
                                              .headlineSmall
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight:
                                                      AppTheme.of(
                                                              context)
                                                          .headlineSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      AppTheme.of(
                                                              context)
                                                          .headlineSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    AppTheme.of(context)
                                                        .headlineSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .headlineSmall
                                                        .fontStyle,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateFormatWidget(
                              date: joinGameDetailedGamesRecord.date,
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: Text(
                                'Game Details:',
                                style: AppTheme.of(context)
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
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF253551),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .styleGame,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Betting\n',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF253551),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .rulesSetting,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Rule\nStyle',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF253551),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .gameType,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Game\nType',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF253551),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .scoring,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Scoring\n',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF253551),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .memberDiscount,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Member\nDiscount',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF253551),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .friendGame,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Friends\nOnly?',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                      .divide(SizedBox(width: 10.0))
                                      .addToStart(SizedBox(width: 10.0))
                                      .addToEnd(SizedBox(width: 10.0)),
                                ),
                              ),
                            ),
                            Divider(
                              height: 32.0,
                              thickness: 1.0,
                              color: AppTheme.of(context).alternate,
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: Text(
                                'Players in this Group:',
                                style: AppTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontStyle: AppTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: AppTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 0.0, 8.0),
                        child: Container(
                          height: 120.0,
                          decoration: BoxDecoration(),
                          child: Builder(
                            builder: (context) {
                              final groupPlayers = joinGameDetailedGamesRecord
                                  .joinedPlayers
                                  .toList();

                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                primary: false,
                                scrollDirection: Axis.horizontal,
                                itemCount: groupPlayers.length,
                                itemBuilder: (context, groupPlayersIndex) {
                                  final groupPlayersItem =
                                      groupPlayers[groupPlayersIndex];
                                  return Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        12.0, 12.0, 0.0, 12.0),
                                    child: StreamBuilder<UsersRecord>(
                                      stream: UsersRecord.getDocument(
                                          groupPlayersItem),
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

                                        final friend1UsersRecord =
                                            snapshot.data!;

                                        return Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 64.0,
                                              height: 64.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.of(context)
                                                        .info,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Color(0xFFA9A9A9),
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    context.pushNamed(
                                                      ProfileUserWidget
                                                          .routeName,
                                                      queryParameters: {
                                                        'userRef':
                                                            serializeParam(
                                                          friend1UsersRecord,
                                                          ParamType.Document,
                                                        ),
                                                      }.withoutNulls,
                                                      extra: <String, dynamic>{
                                                        'userRef':
                                                            friend1UsersRecord,
                                                        kTransitionInfoKey:
                                                            TransitionInfo(
                                                          hasTransition: true,
                                                          transitionType:
                                                              PageTransitionType
                                                                  .bottomToTop,
                                                          duration: Duration(
                                                              milliseconds:
                                                                  220),
                                                        ),
                                                      },
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 70.0,
                                                    height: 70.0,
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Image.network(
                                                      valueOrDefault<String>(
                                                        friend1UsersRecord
                                                            .photoUrl,
                                                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                      ),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          Image.asset(
                                                        'assets/images/error_image.png',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 8.0, 0.0, 0.0),
                                              child: Text(
                                                friend1UsersRecord.displayName,
                                                textAlign: TextAlign.center,
                                                style:
                                                    AppTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .lexendDeca(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      if (joinGameDetailedGamesRecord.userRef !=
                          currentUserReference)
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 8.0),
                            child: AppButton(
                              onPressed: () async {
                                if ((joinGameDetailedGamesRecord.maxPlayers >
                                        joinGameDetailedGamesRecord
                                            .joinedPlayers.length) &&
                                    ((joinGameDetailedGamesRecord.friendGame ==
                                            'Public') ||
                                        ((joinGameDetailedGamesRecord
                                                    .friendGame ==
                                                'Friends') &&
                                            isCreatorFriend))) {
                                  await showModalBottomSheet(
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    enableDrag: false,
                                    context: context,
                                    builder: (context) {
                                      return Padding(
                                        padding:
                                            MediaQuery.viewInsetsOf(context),
                                        child: JoinGameWidget(
                                          gameRef: joinGameDetailedGamesRecord,
                                        ),
                                      );
                                    },
                                  ).then((value) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                } else {
                                  await showDialog(
                                    context: context,
                                    builder: (alertDialogContext) {
                                      return AlertDialog(
                                        title: Text('Sorry!'),
                                        content: Text(
                                            'You are not friends with the game creator or the group  is full.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                alertDialogContext),
                                            child: Text('Ok'),
                                          ),
                                        ],
                                        );
                                    },
                                  );
                                }
                              },
                              text: 'Reserve Spot',
                              options: AppButtonOptions(
                                width: 300.0,
                                height: 60.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: Color(0xFF253551),
                                textStyle: AppTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: AppTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                                elevation: 3.0,
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(40.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
