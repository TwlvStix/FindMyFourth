import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/chat_group/chat_details_overlay/chat_details_overlay_widget.dart';
import '/chat_group/chat_thread_component/chat_thread_component_widget.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import 'dart:async';
import '/chat_group/chat/chat_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class Chat2DetailsWidget extends StatefulWidget {
  const Chat2DetailsWidget({
    super.key,
    required this.chatRef,
  });

  final ChatsRecord? chatRef;

  static String routeName = 'chat_2_Details';
  static String routePath = '/chat2Details';

  @override
  State<Chat2DetailsWidget> createState() => _Chat2DetailsWidgetState();
}

class _Chat2DetailsWidgetState extends State<Chat2DetailsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) setState(() {});
      unawaited(
        () async {
          await widget.chatRef!.reference.update({
            ...mapToFirestore(
              {
                'last_message_seen_by':
                    FieldValue.arrayUnion([currentUserReference]),
              },
            ),
          });
        }(),
      );
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: AppIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.of(context).primaryText,
              size: 30.0,
            ),
            onPressed: () async {
              context.goNamed(
                ChatWidget.routeName,
                extra: <String, dynamic>{
                  kTransitionInfoKey: TransitionInfo(
                    hasTransition: true,
                    transitionType: PageTransitionType.leftToRight,
                    duration: Duration(milliseconds: 230),
                  ),
                },
              );
            },
          ),
          title: Builder(
            builder: (context) {
              if (widget.chatRef?.users.length == 1) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'SET YOUR TEXT IF SOLO IN GROUP',
                      style: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.outfit(
                              fontWeight: AppTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: AppTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ],
                );
              } else {
                return FutureBuilder<UsersRecord>(
                  future: UsersRecord.getDocumentOnce(widget.chatRef!.users
                      .where((e) => e != currentUserReference)
                      .toList()
                      .firstOrNull!),
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

                    final conditionalBuilderUsersRecord = snapshot.data!;

                    return Builder(
                      builder: (context) {
                        if (widget.chatRef?.users.length == 2) {
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (conditionalBuilderUsersRecord.photoUrl != '')
                                Align(
                                  alignment: AlignmentDirectional(-1.0, -1.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 12.0, 0.0),
                                    child: Container(
                                      width: 44.0,
                                      height: 44.0,
                                      decoration: BoxDecoration(
                                        color: AppTheme.of(context)
                                            .accent1,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10.0),
                                          bottomRight: Radius.circular(10.0),
                                          topLeft: Radius.circular(10.0),
                                          topRight: Radius.circular(10.0),
                                        ),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: AppTheme.of(context)
                                              .primary,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(2.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.network(
                                            conditionalBuilderUsersRecord
                                                .photoUrl,
                                            width: 44.0,
                                            height: 44.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      valueOrDefault<String>(
                                        conditionalBuilderUsersRecord
                                            .displayName,
                                        'Ghost User',
                                      ),
                                      style: AppTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 4.0, 12.0, 4.0),
                                child: Container(
                                  width: 54.0,
                                  height: 44.0,
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment:
                                            AlignmentDirectional(1.0, 1.0),
                                        child: FutureBuilder<UsersRecord>(
                                          future: UsersRecord.getDocumentOnce(
                                              widget.chatRef!.users
                                                  .where((e) =>
                                                      e != currentUserReference)
                                                  .toList()
                                                  .lastOrNull!),
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

                                            final secondUserUsersRecord =
                                                snapshot.data!;

                                            return Container(
                                              width: 32.0,
                                              height: 32.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.of(context)
                                                        .accent1,
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                shape: BoxShape.rectangle,
                                                border: Border.all(
                                                  color: AppTheme.of(
                                                          context)
                                                      .primary,
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  if (secondUserUsersRecord
                                                              .photoUrl !=
                                                          '') {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child:
                                                            CachedNetworkImage(
                                                          fadeInDuration:
                                                              Duration(
                                                                  milliseconds:
                                                                      200),
                                                          fadeOutDuration:
                                                              Duration(
                                                                  milliseconds:
                                                                      200),
                                                          imageUrl:
                                                              valueOrDefault<
                                                                  String>(
                                                            secondUserUsersRecord
                                                                .photoUrl,
                                                            '',
                                                          ),
                                                          width: 44.0,
                                                          height: 44.0,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: Container(
                                                        width: 100.0,
                                                        height: 100.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: Text(
                                                          valueOrDefault<
                                                              String>(
                                                            secondUserUsersRecord
                                                                .displayName,
                                                            'A',
                                                          ).maybeHandleOverflow(
                                                            maxChars: 1,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: AppTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Align(
                                        alignment:
                                            AlignmentDirectional(-1.0, -1.0),
                                        child: Container(
                                          width: 32.0,
                                          height: 32.0,
                                          decoration: BoxDecoration(
                                            color: AppTheme.of(context)
                                                .accent1,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            shape: BoxShape.rectangle,
                                            border: Border.all(
                                              color:
                                                  AppTheme.of(context)
                                                      .primary,
                                              width: 2.0,
                                            ),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              if (conditionalBuilderUsersRecord
                                                          .photoUrl !=
                                                      '') {
                                                return Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: CachedNetworkImage(
                                                      fadeInDuration: Duration(
                                                          milliseconds: 200),
                                                      fadeOutDuration: Duration(
                                                          milliseconds: 200),
                                                      imageUrl: valueOrDefault<
                                                          String>(
                                                        conditionalBuilderUsersRecord
                                                            .photoUrl,
                                                        '',
                                                      ),
                                                      width: 44.0,
                                                      height: 44.0,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Padding(
                                                  padding: EdgeInsets.all(2.0),
                                                  child: Container(
                                                    width: 100.0,
                                                    height: 100.0,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Text(
                                                      valueOrDefault<String>(
                                                        conditionalBuilderUsersRecord
                                                            .displayName,
                                                        'A',
                                                      ).maybeHandleOverflow(
                                                        maxChars: 1,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: AppTheme
                                                              .of(context)
                                                          .bodyLarge
                                                          .override(
                                                            font: GoogleFonts
                                                                .outfit(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                            ),
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Group Chat',
                                      style: AppTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 4.0, 0.0, 0.0),
                                      child: Text(
                                        '${valueOrDefault<String>(
                                          widget.chatRef?.users.length
                                              .toString(),
                                          '2',
                                        )} members',
                                        style: AppTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    AppTheme.of(context)
                                                        .labelSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  AppTheme.of(context)
                                                      .primary,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    );
                  },
                );
              }
            },
          ),
          actions: [
            Builder(
              builder: (context) => Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 16.0, 8.0),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onDoubleTap: () async {
                    await showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return Dialog(
                          elevation: 0,
                          insetPadding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          alignment: AlignmentDirectional(0.0, 0.0)
                              .resolve(Directionality.of(context)),
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(dialogContext).unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: ChatDetailsOverlayWidget(
                              chatRef: widget.chatRef!,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: AppIconButton(
                    borderColor: AppTheme.of(context).alternate,
                    borderRadius: 12.0,
                    borderWidth: 2.0,
                    buttonSize: 40.0,
                    fillColor: AppTheme.of(context).primaryBackground,
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.of(context).primaryText,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      await showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: AppTheme.of(context).accent4,
                        barrierColor: Colors.white,
                        enableDrag: false,
                        context: context,
                        builder: (context) {
                          return GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: Padding(
                              padding: MediaQuery.viewInsetsOf(context),
                              child: Container(
                                height: double.infinity,
                                child: ChatDetailsOverlayWidget(
                                  chatRef: widget.chatRef!,
                                ),
                              ),
                            ),
                          );
                        },
                      ).then((value) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: ChatThreadComponentWidget(
            chatRef: widget.chatRef,
          ),
        ),
      ),
    );
  }
}
