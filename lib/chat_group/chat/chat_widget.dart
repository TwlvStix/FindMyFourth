import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/chat_group/empty_state_simple/empty_state_simple_widget.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/chat_group/chat_2_details/chat2_details_widget.dart';
import '/chat_group/chat_2_invite_users/chat2_invite_users_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  static String routeName = 'Chat';
  static String routePath = '/chat';

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
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
        backgroundColor: AppTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'My Chats',
            style: AppTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        AppTheme.of(context).headlineSmall.fontWeight,
                    fontStyle:
                        AppTheme.of(context).headlineSmall.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  letterSpacing: 0.0,
                  fontWeight:
                      AppTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      AppTheme.of(context).headlineSmall.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 16.0, 8.0),
              child: AppIconButton(
                borderColor: AppTheme.of(context).primary,
                borderRadius: 12.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: AppTheme.of(context).primary,
                icon: Icon(
                  Icons.add_comment,
                  color: AppTheme.of(context).primaryBtnText,
                  size: 24.0,
                ),
                onPressed: () async {
                  context.pushNamed(
                    Chat2InviteUsersWidget.routeName,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.bottomToTop,
                        duration: Duration(milliseconds: 270),
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
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                child: Text(
                  'Below are your chats and group chats',
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
                        fontWeight:
                            AppTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            AppTheme.of(context).labelMedium.fontStyle,
                      ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ChatsRecord>>(
                  stream: queryChatsRecord(
                    queryBuilder: (chatsRecord) => chatsRecord
                        .where(
                          'users',
                          arrayContains: currentUserReference,
                        )
                        .orderBy('last_message_time', descending: true),
                  ),
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
                    List<ChatsRecord> listViewChatsRecordList = snapshot.data!;
                    if (listViewChatsRecordList.isEmpty) {
                      return Center(
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 0.9,
                          child: EmptyStateSimpleWidget(
                            icon: Icon(
                              Icons.mark_chat_unread_outlined,
                              color: AppTheme.of(context).primary,
                              size: 90.0,
                            ),
                            title: 'No Chats',
                            body:
                                'You don\'t have any chats created, start a chat by tapping the button in the top right. ',
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      itemCount: listViewChatsRecordList.length,
                      itemBuilder: (context, listViewIndex) {
                        final listViewChatsRecord =
                            listViewChatsRecordList[listViewIndex];
                        return Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 1.0, 0.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(
                                Chat2DetailsWidget.routeName,
                                queryParameters: {
                                  'chatRef': serializeParam(
                                    listViewChatsRecord,
                                    ParamType.Document,
                                  ),
                                }.withoutNulls,
                                extra: <String, dynamic>{
                                  'chatRef': listViewChatsRecord,
                                },
                              );
                            },
                            child: Material(
                              color: Colors.transparent,
                              elevation: 0.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0.0),
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.of(context)
                                      .secondaryBackground,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 0.0,
                                      color: AppTheme.of(context)
                                          .alternate,
                                      offset: Offset(
                                        0.0,
                                        1.0,
                                      ),
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(0.0),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    if (listViewChatsRecord.users.length == 1) {
                                      return Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 12.0, 12.0, 12.0),
                                        child: FutureBuilder<UsersRecord>(
                                          future: AppState().userDocQuery(
                                            uniqueQueryKey: listViewChatsRecord
                                                .reference.id,
                                            requestFn: () =>
                                                UsersRecord.getDocumentOnce(
                                                    listViewChatsRecord.users
                                                        .where((e) =>
                                                            e ==
                                                            currentUserReference)
                                                        .toList()
                                                        .firstOrNull!),
                                          ),
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

                                            final rowUsersRecord =
                                                snapshot.data!;
                                            final rowUserPhotoUrl =
                                                rowUsersRecord.photoUrl;
                                            final rowUserPhotoUrl =
                                                rowUsersRecord.photoUrl;

                                            return Row(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          1.0, 1.0),
                                                  child: Container(
                                                    width: 44.0,
                                                    height: 44.0,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.of(
                                                                  context)
                                                              .accent1,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        bottomRight:
                                                            Radius.circular(
                                                                10.0),
                                                        topLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        topRight:
                                                            Radius.circular(
                                                                10.0),
                                                      ),
                                                      shape: BoxShape.rectangle,
                                                      border: Border.all(
                                                        color:
                                                            AppTheme.of(
                                                                    context)
                                                                .primary,
                                                        width: 2.0,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child: rowUserPhotoUrl
                                                                .isNotEmpty
                                                            ? Image.network(
                                                                rowUserPhotoUrl,
                                                                width: 44.0,
                                                                height: 44.0,
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder: (context,
                                                                        error,
                                                                        stackTrace) =>
                                                                    Image.asset(
                                                                  'assets/images/error_image.png',
                                                                  width: 44.0,
                                                                  height: 44.0,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              )
                                                            : Image.asset(
                                                                'assets/images/error_image.png',
                                                                width: 44.0,
                                                                height: 44.0,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(8.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            12.0,
                                                                            0.0),
                                                                child: Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    rowUsersRecord
                                                                        .displayName,
                                                                    'Ghost User',
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style: AppTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight: AppTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontWeight,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (!listViewChatsRecord
                                                                .lastMessageSeenBy
                                                                .contains(
                                                                    currentUserReference))
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            8.0,
                                                                            0.0),
                                                                child:
                                                                    Container(
                                                                  width: 12.0,
                                                                  height: 12.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: AppTheme.of(
                                                                            context)
                                                                        .accent1,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: AppTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      width:
                                                                          2.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      4.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Text(
                                                            listViewChatsRecord
                                                                .lastMessage,
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: AppTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: AppTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          4.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Text(
                                                                dateTimeFormat(
                                                                    "relative",
                                                                    listViewChatsRecord
                                                                        .lastMessageTime!),
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: AppTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .outfit(
                                                                        fontWeight: AppTheme.of(context)
                                                                            .labelSmall
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .labelSmall
                                                                            .fontStyle,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: AppTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontWeight,
                                                                      fontStyle: AppTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color: AppTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    } else if (listViewChatsRecord
                                            .users.length ==
                                        2) {
                                      return Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 12.0, 12.0, 12.0),
                                        child: FutureBuilder<UsersRecord>(
                                          future: AppState().userDocQuery(
                                            uniqueQueryKey: listViewChatsRecord
                                                .reference.id,
                                            requestFn: () =>
                                                UsersRecord.getDocumentOnce(
                                                    listViewChatsRecord.users
                                                        .where((e) =>
                                                            e !=
                                                            currentUserReference)
                                                        .toList()
                                                        .firstOrNull!),
                                          ),
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

                                            final rowUsersRecord =
                                                snapshot.data!;

                                            return Row(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          1.0, 1.0),
                                                  child: Container(
                                                    width: 44.0,
                                                    height: 44.0,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.of(
                                                                  context)
                                                              .accent1,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        bottomRight:
                                                            Radius.circular(
                                                                10.0),
                                                        topLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        topRight:
                                                            Radius.circular(
                                                                10.0),
                                                      ),
                                                      shape: BoxShape.rectangle,
                                                      border: Border.all(
                                                        color:
                                                            AppTheme.of(
                                                                    context)
                                                                .primary,
                                                        width: 2.0,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(2.0),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child: rowUserPhotoUrl
                                                                .isNotEmpty
                                                            ? Image.network(
                                                                rowUserPhotoUrl,
                                                                width: 44.0,
                                                                height: 44.0,
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder: (context,
                                                                        error,
                                                                        stackTrace) =>
                                                                    Image.asset(
                                                                  'assets/images/error_image.png',
                                                                  width: 44.0,
                                                                  height: 44.0,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              )
                                                            : Image.asset(
                                                                'assets/images/error_image.png',
                                                                width: 44.0,
                                                                height: 44.0,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(8.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            12.0,
                                                                            0.0),
                                                                child: Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    rowUsersRecord
                                                                        .displayName,
                                                                    'Ghost User',
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style: AppTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight: AppTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontWeight,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (!listViewChatsRecord
                                                                .lastMessageSeenBy
                                                                .contains(
                                                                    currentUserReference))
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            8.0,
                                                                            0.0),
                                                                child:
                                                                    Container(
                                                                  width: 12.0,
                                                                  height: 12.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: AppTheme.of(
                                                                            context)
                                                                        .accent1,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: AppTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      width:
                                                                          2.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      4.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Text(
                                                            listViewChatsRecord
                                                                .lastMessage,
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: AppTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: AppTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          4.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Text(
                                                                dateTimeFormat(
                                                                    "relative",
                                                                    listViewChatsRecord
                                                                        .lastMessageTime!),
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: AppTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .outfit(
                                                                        fontWeight: AppTheme.of(context)
                                                                            .labelSmall
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .labelSmall
                                                                            .fontStyle,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: AppTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontWeight,
                                                                      fontStyle: AppTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color: AppTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 12.0, 12.0, 12.0),
                                        child: FutureBuilder<UsersRecord>(
                                          future: AppState().userDocQuery(
                                            uniqueQueryKey: listViewChatsRecord
                                                .reference.id,
                                            requestFn: () =>
                                                UsersRecord.getDocumentOnce(
                                                    listViewChatsRecord.users
                                                        .where((e) =>
                                                            e !=
                                                            currentUserReference)
                                                        .toList()
                                                        .firstOrNull!),
                                          ),
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

                                            final rowUsersRecord =
                                                snapshot.data!;

                                            return Row(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 0.0, 8.0),
                                                  child: Container(
                                                    width: 44.0,
                                                    height: 54.0,
                                                    child: Stack(
                                                      children: [
                                                        Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  1.0, 1.0),
                                                          child: FutureBuilder<
                                                              UsersRecord>(
                                                            future: UsersRecord.getDocumentOnce(
                                                                listViewChatsRecord
                                                                    .users
                                                                    .where((e) =>
                                                                        e !=
                                                                        currentUserReference)
                                                                    .toList()
                                                                    .lastOrNull!),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return Center(
                                                                  child:
                                                                      SizedBox(
                                                                    width: 50.0,
                                                                    height:
                                                                        50.0,
                                                                    child:
                                                                        SpinKitWanderingCubes(
                                                                      color: Color(
                                                                          0xFF25504F),
                                                                      size:
                                                                          50.0,
                                                                    ),
                                                                  ),
                                                                );
                                                              }

                                                              final containerUsersRecord =
                                                                  snapshot
                                                                      .data!;

                                                              return Container(
                                                                width: 32.0,
                                                                height: 32.0,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: AppTheme.of(
                                                                          context)
                                                                      .accent1,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12.0),
                                                                  shape: BoxShape
                                                                      .rectangle,
                                                                  border: Border
                                                                      .all(
                                                                    color: AppTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    width: 2.0,
                                                                  ),
                                                                ),
                                                                child: Builder(
                                                                  builder:
                                                                      (context) {
                                                                    if (containerUsersRecord.photoUrl !=
                                                                            '') {
                                                                      return Padding(
                                                                        padding:
                                                                            EdgeInsets.all(2.0),
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(8.0),
                                                                          child:
                                                                              CachedNetworkImage(
                                                                            fadeInDuration:
                                                                                Duration(milliseconds: 200),
                                                                            fadeOutDuration:
                                                                                Duration(milliseconds: 200),
                                                                            imageUrl:
                                                                                containerUsersRecord.photoUrl,
                                                                            width:
                                                                                44.0,
                                                                            height:
                                                                                44.0,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            errorWidget: (context, error, stackTrace) =>
                                                                                Image.asset(
                                                                              'assets/images/error_image.png',
                                                                              width: 44.0,
                                                                              height: 44.0,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      return Padding(
                                                                        padding:
                                                                            EdgeInsets.all(2.0),
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              100.0,
                                                                          height:
                                                                              100.0,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                AppTheme.of(context).secondaryBackground,
                                                                            borderRadius:
                                                                                BorderRadius.circular(8.0),
                                                                          ),
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                          child:
                                                                              Text(
                                                                            valueOrDefault<String>(
                                                                              containerUsersRecord.displayName,
                                                                              'A',
                                                                            ).maybeHandleOverflow(
                                                                              maxChars: 1,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style: AppTheme.of(context).bodyLarge.override(
                                                                                  font: GoogleFonts.outfit(
                                                                                    fontWeight: FontWeight.bold,
                                                                                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                                                                                  ),
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
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
                                                              AlignmentDirectional(
                                                                  -1.0, -1.0),
                                                          child: Container(
                                                            width: 32.0,
                                                            height: 32.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: AppTheme
                                                                      .of(context)
                                                                  .accent3,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12.0),
                                                              shape: BoxShape
                                                                  .rectangle,
                                                              border:
                                                                  Border.all(
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primary,
                                                                width: 2.0,
                                                              ),
                                                            ),
                                                            child: Builder(
                                                              builder:
                                                                  (context) {
                                                                if (rowUsersRecord
                                                                            .photoUrl !=
                                                                        '') {
                                                                  return Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            2.0),
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      child:
                                                                          CachedNetworkImage(
                                                                        fadeInDuration:
                                                                            Duration(milliseconds: 200),
                                                                        fadeOutDuration:
                                                                            Duration(milliseconds: 200),
                                                                        imageUrl:
                                                                            rowUsersRecord
                                                                                .photoUrl,
                                                                        width:
                                                                            44.0,
                                                                        height:
                                                                            44.0,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorWidget: (context,
                                                                                error,
                                                                                stackTrace) =>
                                                                            Image.asset(
                                                                          'assets/images/error_image.png',
                                                                          width:
                                                                              44.0,
                                                                          height:
                                                                              44.0,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                } else {
                                                                  return Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            2.0),
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          100.0,
                                                                      height:
                                                                          100.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: AppTheme.of(context)
                                                                            .secondaryBackground,
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      alignment:
                                                                          AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                      child:
                                                                          Text(
                                                                        valueOrDefault<
                                                                            String>(
                                                                          rowUsersRecord
                                                                              .displayName,
                                                                          'A',
                                                                        ).maybeHandleOverflow(
                                                                          maxChars:
                                                                              1,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .override(
                                                                              font: GoogleFonts.outfit(
                                                                                fontWeight: FontWeight.bold,
                                                                                fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                                                                              ),
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
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
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(8.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            12.0,
                                                                            0.0),
                                                                child: Text(
                                                                  'Group Chat',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style: AppTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight: AppTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontWeight,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyLarge
                                                                              .fontStyle,
                                                                        ),
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (!listViewChatsRecord
                                                                .lastMessageSeenBy
                                                                .contains(
                                                                    currentUserReference))
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            8.0,
                                                                            0.0),
                                                                child:
                                                                    Container(
                                                                  width: 12.0,
                                                                  height: 12.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: AppTheme.of(
                                                                            context)
                                                                        .accent3,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: AppTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      width:
                                                                          2.0,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      0.0,
                                                                      4.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              listViewChatsRecord
                                                                  .lastMessage,
                                                              'No messages yet.',
                                                            ),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: AppTheme
                                                                    .of(context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight: AppTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontWeight,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .labelMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          4.0,
                                                                          0.0,
                                                                          0.0),
                                                              child: Text(
                                                                valueOrDefault<
                                                                    String>(
                                                                  dateTimeFormat(
                                                                      "relative",
                                                                      listViewChatsRecord
                                                                          .lastMessageTime),
                                                                  '--',
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: AppTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .outfit(
                                                                        fontWeight: AppTheme.of(context)
                                                                            .labelSmall
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .labelSmall
                                                                            .fontStyle,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: AppTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontWeight,
                                                                      fontStyle: AppTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .chevron_right_rounded,
                                                              color: AppTheme
                                                                      .of(context)
                                                                  .secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
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
    );
  }
}
