import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/design_tokens/spacing.dart';
import '/chat_group/chat_2_details/chat2_details_widget.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/providers/provider_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesJoinedWidget extends StatefulWidget {
  const GamesJoinedWidget({super.key});

  static String routeName = 'GamesJoined';
  static String routePath = '/gamesJoined';

  @override
  State<GamesJoinedWidget> createState() => _GamesJoinedWidgetState();
}

class _GamesJoinedWidgetState extends State<GamesJoinedWidget> {
  ChatsRecord? chat;

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: AppIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 55.0,
            icon: Icon(
              Icons.arrow_back_ios,
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
            'My  Games',
            style: AppTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        AppTheme.of(context).headlineLarge.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle:
                      AppTheme.of(context).headlineLarge.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.md - 1),
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
              padding: EdgeInsets.only(right: AppSpacing.xs + 2),
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
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: StreamBuilder<List<GamesRecord>>(
              stream: context.userProvider.getMyGames(),
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

                final listViewGamesRecordList = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.userProvider.refreshMyGames();
                    await Future.delayed(Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: AppSpacing.sm, bottom: AppSpacing.xxxl),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: listViewGamesRecordList.length,
                            itemBuilder: (context, listViewIndex) {
                              final listViewGamesRecord =
                                  listViewGamesRecordList[listViewIndex];
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.xs / 2),
                                child: InkWell(
                                onTap: () async {
                                  context.pushNamed(
                                    GameJoinedDetailedWidget.routeName,
                                    queryParameters: {
                                      'gameRef': serializeParam(
                                        listViewGamesRecord.reference,
                                        ParamType.DocumentReference,
                                      ),
                                    }.withoutNulls,
                                    extra: <String, dynamic>{
                                      kTransitionInfoKey: TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.bottomToTop,
                                        duration: Duration(milliseconds: 220),
                                      ),
                                    },
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14.0),
                                    border: Border(
                                      left: BorderSide(
                                        color: Color(0xFF1A4D2E),
                                        width: 5.0,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8.0,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  listViewGamesRecord.coursePlay,
                                                  'Course Name',
                                                ),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1A4D2E),
                                                  letterSpacing: -0.2,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                            // Message icon button
                                            AppIconButton(
                                              borderColor: AppTheme.of(context).primary,
                                              borderRadius: 20.0,
                                              borderWidth: 1.0,
                                              buttonSize: 40.0,
                                              fillColor: AppTheme.of(context).primary,
                                              icon: FaIcon(
                                                FontAwesomeIcons.facebookMessenger,
                                                color: Colors.white,
                                                size: 16.0,
                                              ),
                                              onPressed: () async {
                                                chat = await ChatsRecord.getDocumentOnce(
                                                    listViewGamesRecord.chatRef!);

                                                context.pushNamed(
                                                  Chat2DetailsWidget.routeName,
                                                  queryParameters: {
                                                    'chatRef': serializeParam(
                                                      chat,
                                                      ParamType.Document,
                                                    ),
                                                  }.withoutNulls,
                                                  extra: <String, dynamic>{
                                                    'chatRef': chat,
                                                  },
                                                );

                                                if (mounted) setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 14.0),

                                        // GAME NAME
                                        Text(
                                          valueOrDefault<String>(
                                            listViewGamesRecord.nameGame,
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
                                                '${dateTimeFormat("EEEE", listViewGamesRecord.date)}, ${dateTimeFormat("MMMM", listViewGamesRecord.date)} ${dateTimeFormat("d", listViewGamesRecord.date)} • ${dateTimeFormat("jm", listViewGamesRecord.date)}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.normal,
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
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Game Type Badge
                                            if (listViewGamesRecord.gameType.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.0,
                                                  vertical: 6.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFE8F5E9),
                                                  borderRadius: BorderRadius.circular(20.0),
                                                  border: Border.all(
                                                    color: Color(0xFF1A4D2E).withValues(alpha: 0.2),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  valueOrDefault<String>(
                                                    listViewGamesRecord.gameType,
                                                    'Game Type',
                                                  ),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1A4D2E),
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ),
                                            if (listViewGamesRecord.gameType.isNotEmpty)
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
                                                  '${listViewGamesRecord.joinedPlayers.length + listViewGamesRecord.guestPlayers.length}/${listViewGamesRecord.maxPlayers} players',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF4A5568),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Status Badge if cancelled
                                            if (listViewGamesRecord.isCancelled)
                                              Container(
                                                margin: EdgeInsets.only(left: 12.0),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.0,
                                                  vertical: 4.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFFFEBEE),
                                                  borderRadius: BorderRadius.circular(12.0),
                                                ),
                                                child: Text(
                                                  'Cancelled',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFD32F2F),
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
