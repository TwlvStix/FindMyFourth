import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPageWidget extends StatefulWidget {
  const NotificationPageWidget({super.key});

  static String routeName = 'NotificationPage';
  static String routePath = '/notificationPage';

  @override
  State<NotificationPageWidget> createState() => _NotificationPageWidgetState();
}

class _NotificationPageWidgetState extends State<NotificationPageWidget> {
  bool notifyAll = false;
  bool notifyMoneyGame = false;
  bool notifyVegasGame = false;
  bool notifyCompetitiveGame = false;
  bool notifyForFun = false;
  bool notifyOnlyFromFriends = false;
  bool notifyMemberDiscount = false;
  bool notifyOff = false;
  bool switchListTileValue1 = false;
  bool switchValue = false;
  bool switchListTileValue2 = false;
  bool switchListTileValue3 = false;
  bool switchListTileValue4 = false;
  bool switchListTileValue5 = false;
  bool switchListTileValue6 = false;
  bool switchListTileValue7 = false;
  bool switchListTileValue8 = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      notifyAll =
          valueOrDefault<bool>(currentUserDocument?.notifyAll, false);
      notifyMoneyGame =
          valueOrDefault<bool>(currentUserDocument?.notifyMoneyGame, false);
      notifyVegasGame =
          valueOrDefault<bool>(currentUserDocument?.notifyVegasGame, false);
      notifyCompetitiveGame = valueOrDefault<bool>(
          currentUserDocument?.notifyCompetitiveGame, false);
      notifyForFun =
          valueOrDefault<bool>(currentUserDocument?.notifyForFun, false);
      notifyOnlyFromFriends = valueOrDefault<bool>(
          currentUserDocument?.notifyOnlyFromFriends, false);
      notifyMemberDiscount = valueOrDefault<bool>(
          currentUserDocument?.notifyMemberDiscount, false);
      notifyOff = valueOrDefault<bool>(currentUserDocument?.notifyOff, false);
      switchListTileValue1 = notifyAll;
      switchListTileValue2 = notifyMoneyGame;
      switchListTileValue3 = notifyVegasGame;
      switchListTileValue4 = notifyCompetitiveGame;
      switchListTileValue5 = notifyForFun;
      switchListTileValue6 = notifyOnlyFromFriends;
      switchListTileValue7 = notifyMemberDiscount;
      switchListTileValue8 = notifyOff;
      switchValue = switchListTileValue1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: false,
        leading: AppIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 46.0,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.of(context).primaryText,
            size: 25.0,
          ),
          onPressed: () async {
            context.pop();
          },
        ),
        title: Text(
          'Settings Page',
          style: AppTheme.of(context).headlineSmall.override(
                font: GoogleFonts.outfit(
                  fontWeight:
                      AppTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      AppTheme.of(context).headlineSmall.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight:
                    AppTheme.of(context).headlineSmall.fontWeight,
                fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Choose what notifcations you want to recieve below and we will update the settings.',
                      style: AppTheme.of(context).labelMedium.override(
                            font: GoogleFonts.outfit(
                              fontWeight: AppTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: AppTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: AppTheme.of(context)
                                .labelMedium
                                .fontWeight,
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
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: switchListTileValue1,
                  onChanged: (newValue) async {
                    if (mounted) {
                      setState(() => switchListTileValue1 = newValue);
                    }
                    if (newValue) {
                      notifyAll = true;
                      notifyMoneyGame = true;
                      notifyVegasGame = true;
                      notifyCompetitiveGame = true;
                      notifyForFun = true;
                      notifyOnlyFromFriends = true;
                      notifyMemberDiscount = true;
                      notifyOff = false;
                      if (mounted) setState(() {});
                    } else {
                      notifyAll = false;
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    'All Push Notifications',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                          lineHeight: 2.0,
                        ),
                  ),
                  subtitle: Text(
                    'Receive Push notifications for any time of game created.',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
                ),
              ),
            ),
            Switch.adaptive(
              value: switchValue,
              onChanged: (newValue) async {
                if (mounted) setState(() => switchValue = newValue);
              },
              activeColor: AppTheme.of(context).primary,
              activeTrackColor: AppTheme.of(context).accent1,
              inactiveTrackColor: AppTheme.of(context).alternate,
              inactiveThumbColor: AppTheme.of(context).secondaryText,
            ),
            IconButton(
              onPressed: () async {
                if (mounted) {
                  setState(() => notifyMoneyGame = !notifyMoneyGame);
                }
              },
              icon: notifyMoneyGame
                  ? Icon(
                      Icons.check_box,
                      color: AppTheme.of(context).primary,
                      size: 25.0,
                    )
                  : Icon(
                      Icons.check_box_outline_blank,
                      color: AppTheme.of(context).secondaryText,
                      size: 25.0,
                    ),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
                  (states) => const RoundedRectangleBorder(
                    side: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: switchListTileValue2,
                  onChanged: (newValue) async {
                    if (mounted) {
                      setState(() => switchListTileValue2 = newValue);
                    }
                    if (newValue) {
                      notifyMoneyGame = true;
                      if (mounted) setState(() {});
                    } else {
                      notifyAll = false;
                      notifyMoneyGame = false;
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    'Money Game Notifications',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                          lineHeight: 2.0,
                        ),
                  ),
                  subtitle: Text(
                    'Receive Push notifications for games that have money on the line. ',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: switchListTileValue3,
                  onChanged: (newValue) async {
                    if (mounted) {
                      setState(() => switchListTileValue3 = newValue);
                    }
                    if (newValue) {
                      notifyVegasGame = true;
                      if (mounted) setState(() {});
                    } else {
                      notifyAll = false;
                      notifyVegasGame = false;
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    'Vegas Game Notifications',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                          lineHeight: 2.0,
                        ),
                  ),
                  subtitle: Text(
                    'Receive Push notifications for when a Vegas game is created.',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: switchListTileValue4,
                  onChanged: (newValue) async {
                    if (mounted) {
                      setState(() => switchListTileValue4 = newValue);
                    }
                    if (newValue) {
                      notifyCompetitiveGame = true;
                      if (mounted) setState(() {});
                    } else {
                      notifyAll = false;
                      notifyCompetitiveGame = false;
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    'Competitive Game Notifications',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                          lineHeight: 2.0,
                        ),
                  ),
                  subtitle: Text(
                    'Receive Push notifications for games that are all about the pressure and you play by the rule book.',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: switchListTileValue5,
                  onChanged: (newValue) async {
                    if (mounted) {
                      setState(() => switchListTileValue5 = newValue);
                    }
                    if (newValue) {
                      notifyForFun = true;
                      if (mounted) setState(() {});
                    } else {
                      notifyAll = false;
                      notifyForFun = false;
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    'For Fun',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                          lineHeight: 2.0,
                        ),
                  ),
                  subtitle: Text(
                    'Receive Push notifications for games that are only for fun. You don\'t want anything too serious',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: switchListTileValue6,
                  onChanged: (newValue) async {
                    if (mounted) {
                      setState(() => switchListTileValue6 = newValue);
                    }
                    if (newValue) {
                      notifyOnlyFromFriends = true;
                      if (mounted) setState(() {});
                    } else {
                      notifyAll = false;
                      notifyOnlyFromFriends = false;
                      if (mounted) setState(() {});
                    }
                  },
                  title: Text(
                    'Only From Your Friends',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                          lineHeight: 2.0,
                        ),
                  ),
                  subtitle: Text(
                    'Receive Push notifications only when your friends make a friends only game',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
              value: switchListTileValue7,
              onChanged: (newValue) async {
                if (mounted) {
                  setState(() => switchListTileValue7 = newValue);
                }
                if (newValue) {
                  notifyMemberDiscount = true;
                  if (mounted) setState(() {});
                } else {
                  notifyAll = false;
                  notifyMemberDiscount = false;
                  if (mounted) setState(() {});
                }
              },
                title: Text(
                  'Member Discount',
                  style: AppTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).bodyLarge.fontWeight,
                        fontStyle:
                            AppTheme.of(context).bodyLarge.fontStyle,
                        lineHeight: 2.0,
                      ),
                ),
                subtitle: Text(
                  'Don\'t miss out on the games that may save you some money on green fees.',
                  style: AppTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: Color(0xFF8B97A2),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            AppTheme.of(context).bodyMedium.fontStyle,
                      ),
                ),
                tileColor: AppTheme.of(context).secondaryBackground,
                activeColor: AppTheme.of(context).primary,
                activeTrackColor: AppTheme.of(context).accent1,
                dense: false,
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding:
                    EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile.adaptive(
                value: switchListTileValue8,
                onChanged: (newValue) async {
                  if (mounted) {
                    setState(() => switchListTileValue8 = newValue);
                  }
                  if (newValue) {
                    notifyAll = false;
                    notifyMoneyGame = false;
                    notifyVegasGame = false;
                    notifyCompetitiveGame = false;
                    notifyForFun = false;
                    notifyOnlyFromFriends = false;
                    notifyMemberDiscount = false;
                    notifyOff = true;
                    if (mounted) setState(() {});
                  }
                },
                title: Text(
                  'Turn all Notifications off',
                  style: AppTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).bodyLarge.fontWeight,
                        fontStyle:
                            AppTheme.of(context).bodyLarge.fontStyle,
                        lineHeight: 2.0,
                      ),
                ),
                subtitle: Text(
                  'You don\'t want to receive any heads up on games as they are created.  You will open the app to see yourself. ',
                  style: AppTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: Color(0xFF8B97A2),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            AppTheme.of(context).bodyMedium.fontStyle,
                      ),
                ),
                tileColor: AppTheme.of(context).secondaryBackground,
                activeColor: AppTheme.of(context).primary,
                activeTrackColor: AppTheme.of(context).accent1,
                dense: false,
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding:
                    EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 24.0),
              child: AppButton(
                onPressed: () async {
                  await currentUserReference!.update(createUsersRecordData(
                    notifyAll: notifyAll,
                    notifyMoneyGame: notifyMoneyGame,
                    notifyVegasGame: notifyVegasGame,
                    notifyCompetitiveGame: notifyCompetitiveGame,
                    notifyForFun: notifyForFun,
                    notifyOnlyFromFriends: notifyOnlyFromFriends,
                    notifyMemberDiscount: notifyMemberDiscount,
                    notifyOff: notifyOff,
                  ));
                  context.pop();
                },
                text: 'Save Settings',
                options: AppButtonOptions(
                  width: 190.0,
                  height: 50.0,
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: AppTheme.of(context).primary,
                  textStyle: AppTheme.of(context).titleSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight: AppTheme.of(context)
                              .titleSmall
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).titleSmall.fontWeight,
                        fontStyle:
                            AppTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 3.0,
                  borderSide: BorderSide(
                    color: Colors.transparent,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
