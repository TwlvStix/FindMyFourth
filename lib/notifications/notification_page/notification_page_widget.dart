import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_page_model.dart';
export 'notification_page_model.dart';

class NotificationPageWidget extends StatefulWidget {
  const NotificationPageWidget({super.key});

  static String routeName = 'NotificationPage';
  static String routePath = '/notificationPage';

  @override
  State<NotificationPageWidget> createState() => _NotificationPageWidgetState();
}

class _NotificationPageWidgetState extends State<NotificationPageWidget> {
  late NotificationPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.notifyAll =
          valueOrDefault<bool>(currentUserDocument?.notifyAll, false);
      _model.notifyMoneyGame =
          valueOrDefault<bool>(currentUserDocument?.notifyMoneyGame, false);
      _model.notifyVegasGame =
          valueOrDefault<bool>(currentUserDocument?.notifyVegasGame, false);
      _model.notifyCompetitiveGame = valueOrDefault<bool>(
          currentUserDocument?.notifyCompetitiveGame, false);
      _model.notifyForFun =
          valueOrDefault<bool>(currentUserDocument?.notifyForFun, false);
      _model.notifyOnlyFromFriends = valueOrDefault<bool>(
          currentUserDocument?.notifyOnlyFromFriends, false);
      _model.notifyMemberDiscount = valueOrDefault<bool>(
          currentUserDocument?.notifyMemberDiscount, false);
      _model.notifyOff =
          valueOrDefault<bool>(currentUserDocument?.notifyOff, false);
      safeSetState(() {});
    });

    _model.switchValue = _model.switchListTileValue1!;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

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
                  value: _model.switchListTileValue1 ??= _model.notifyAll!,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchListTileValue1 = newValue);
                    if (newValue) {
                      _model.notifyAll = true;
                      _model.notifyMoneyGame = true;
                      _model.notifyVegasGame = true;
                      _model.notifyCompetitiveGame = true;
                      _model.notifyForFun = true;
                      _model.notifyOnlyFromFriends = true;
                      _model.notifyMemberDiscount = true;
                      _model.notifyOff = false;
                      safeSetState(() {});
                    } else {
                      _model.notifyAll = false;
                      safeSetState(() {});
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
              value: _model.switchValue!,
              onChanged: (newValue) async {
                safeSetState(() => _model.switchValue = newValue);
              },
              activeColor: AppTheme.of(context).primary,
              activeTrackColor: AppTheme.of(context).accent1,
              inactiveTrackColor: AppTheme.of(context).alternate,
              inactiveThumbColor: AppTheme.of(context).secondaryText,
            ),
            ToggleIcon(
              onPressed: () async {
                safeSetState(
                    () => _model.notifyMoneyGame = !_model.notifyMoneyGame!);
              },
              value: _model.notifyMoneyGame!,
              onIcon: Icon(
                Icons.check_box,
                color: AppTheme.of(context).primary,
                size: 25.0,
              ),
              offIcon: Icon(
                Icons.check_box_outline_blank,
                color: AppTheme.of(context).secondaryText,
                size: 25.0,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: _model.switchListTileValue2 ??=
                      _model.notifyMoneyGame!,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchListTileValue2 = newValue);
                    if (newValue) {
                      _model.notifyMoneyGame = true;
                      safeSetState(() {});
                    } else {
                      _model.notifyAll = false;
                      _model.notifyMoneyGame = false;
                      safeSetState(() {});
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
                  value: _model.switchListTileValue3 ??=
                      _model.notifyVegasGame!,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchListTileValue3 = newValue);
                    if (newValue) {
                      _model.notifyVegasGame = true;
                      safeSetState(() {});
                    } else {
                      _model.notifyAll = false;
                      _model.notifyVegasGame = false;
                      safeSetState(() {});
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
                  value: _model.switchListTileValue4 ??=
                      _model.notifyCompetitiveGame!,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchListTileValue4 = newValue);
                    if (newValue) {
                      _model.notifyCompetitiveGame = true;
                      safeSetState(() {});
                    } else {
                      _model.notifyAll = false;
                      _model.notifyCompetitiveGame = false;
                      safeSetState(() {});
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
                  value: _model.switchListTileValue5 ??= _model.notifyForFun!,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchListTileValue5 = newValue);
                    if (newValue) {
                      _model.notifyForFun = true;
                      safeSetState(() {});
                    } else {
                      _model.notifyAll = false;
                      _model.notifyForFun = false;
                      safeSetState(() {});
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
                  value: _model.switchListTileValue6 ??=
                      _model.notifyOnlyFromFriends!,
                  onChanged: (newValue) async {
                    safeSetState(() => _model.switchListTileValue6 = newValue);
                    if (newValue) {
                      _model.notifyOnlyFromFriends = true;
                      safeSetState(() {});
                    } else {
                      _model.notifyAll = false;
                      _model.notifyOnlyFromFriends = false;
                      safeSetState(() {});
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
                value: _model.switchListTileValue7 ??=
                    _model.notifyMemberDiscount!,
                onChanged: (newValue) async {
                  safeSetState(() => _model.switchListTileValue7 = newValue);
                  if (newValue) {
                    _model.notifyMemberDiscount = true;
                    safeSetState(() {});
                  } else {
                    _model.notifyAll = false;
                    _model.notifyMemberDiscount = false;
                    safeSetState(() {});
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
                value: _model.switchListTileValue8 ??= _model.notifyOff!,
                onChanged: (newValue) async {
                  safeSetState(() => _model.switchListTileValue8 = newValue);
                  if (newValue) {
                    _model.notifyAll = false;
                    _model.notifyMoneyGame = false;
                    _model.notifyVegasGame = false;
                    _model.notifyCompetitiveGame = false;
                    _model.notifyForFun = false;
                    _model.notifyOnlyFromFriends = false;
                    _model.notifyMemberDiscount = false;
                    _model.notifyOff = true;
                    safeSetState(() {});
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
                    notifyAll: _model.notifyAll,
                    notifyMoneyGame: _model.notifyMoneyGame,
                    notifyVegasGame: _model.notifyVegasGame,
                    notifyCompetitiveGame: _model.notifyCompetitiveGame,
                    notifyForFun: _model.notifyForFun,
                    notifyOnlyFromFriends: _model.notifyOnlyFromFriends,
                    notifyMemberDiscount: _model.notifyMemberDiscount,
                    notifyOff: _model.notifyOff,
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
