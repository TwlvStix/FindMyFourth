import '/backend/backend.dart';
import '/chat_group/delete_dialog/delete_dialog_widget.dart';
import '/chat_group/user_list_small/user_list_small_widget.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/core/widgets/app_button.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_details_overlay_model.dart';
export 'chat_details_overlay_model.dart';

class ChatDetailsOverlayWidget extends StatefulWidget {
  const ChatDetailsOverlayWidget({
    super.key,
    required this.chatRef,
  });

  final ChatsRecord? chatRef;

  @override
  State<ChatDetailsOverlayWidget> createState() =>
      _ChatDetailsOverlayWidgetState();
}

class _ChatDetailsOverlayWidgetState extends State<ChatDetailsOverlayWidget> {
  late ChatDetailsOverlayModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatDetailsOverlayModel());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 4.0,
          sigmaY: 4.0,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(),
          child: Align(
            alignment: AlignmentDirectional(0.0, -1.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 700.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0.0),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 70.0, 0.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 0.0, 0.0),
                          child: Text(
                            'Chat Details',
                            style: AppTheme.of(context)
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
                                  letterSpacing: 0.0,
                                  fontWeight: AppTheme.of(context)
                                      .headlineSmall
                                      .fontWeight,
                                  fontStyle: AppTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 16.0, 0.0),
                          child: AppIconButton(
                            borderColor: AppTheme.of(context).alternate,
                            borderRadius: 12.0,
                            borderWidth: 1.0,
                            buttonSize: 40.0,
                            fillColor: AppTheme.of(context).accent4,
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppTheme.of(context).primaryText,
                              size: 24.0,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 0.0, 4.0),
                      child: RichText(
                        textScaler: MediaQuery.of(context).textScaler,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Group Chat ID: ',
                              style: TextStyle(),
                            ),
                            TextSpan(
                              text: valueOrDefault<String>(
                                widget.chatRef?.groupChatId.toString(),
                                '--',
                              ),
                              style: TextStyle(
                                color: AppTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                          style:
                              AppTheme.of(context).labelMedium.override(
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
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 0.0, 0.0),
                      child: Text(
                        'In this chat',
                        style:
                            AppTheme.of(context).labelMedium.override(
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
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 16.0, 0.0),
                        child: Builder(
                          builder: (context) {
                            final chatUsers =
                                widget.chatRef?.users.toList() ?? [];

                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.vertical,
                              itemCount: chatUsers.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 8.0),
                              itemBuilder: (context, chatUsersIndex) {
                                final chatUsersItem = chatUsers[chatUsersIndex];
                                return FutureBuilder<UsersRecord>(
                                  future: UsersRecord.getDocumentOnce(
                                      chatUsersItem),
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

                                    final userListSmallUsersRecord =
                                        snapshot.data!;

                                    return UserListSmallWidget(
                                      key: Key(
                                        'Key258_${chatUsersItem.id}',
                                      ),
                                      userRef: userListSmallUsersRecord,
                                      action: () async {},
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(0.0, -1.0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: AppTheme.of(context).alternate,
                              ),
                            ),
                            child: DeleteDialogWidget(
                              chatList: widget.chatRef,
                              inviteAction: () async {
                                Navigator.pop(context);

                                  context.pushNamed(
                                    Chat2InviteUsersWidget.routeName,
                                    queryParameters: {
                                      'chatRef': serializeParam(
                                        widget.chatRef,
                                        ParamType.Document,
                                      ),
                                    }.withoutNulls,
                                    extra: <String, dynamic>{
                                      'chatRef': widget.chatRef,
                                      kTransitionInfoKey: TransitionInfo(
                                        hasTransition: true,
                                        transitionType:
                                            PageTransitionType.bottomToTop,
                                        duration: Duration(milliseconds: 250),
                                      ),
                                    },
                                  );
                              },
                              deleteAction: () async {
                                await widget.chatRef!.reference.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'You have successfully deleted a chat!',
                                      style: AppTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: AppTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                            ),
                                            color: AppTheme.of(context).info,
                                            letterSpacing: 0.0,
                                            fontWeight: AppTheme.of(context)
                                                .titleSmall
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .titleSmall
                                                .fontStyle,
                                          ),
                                    ),
                                    duration: Duration(milliseconds: 3000),
                                    backgroundColor: AppTheme.of(context).error,
                                  ),
                                );

                                context.pushNamed(
                                  ChatWidget.routeName,
                                  extra: <String, dynamic>{
                                    kTransitionInfoKey: TransitionInfo(
                                      hasTransition: true,
                                      transitionType:
                                          PageTransitionType.leftToRight,
                                      duration: Duration(milliseconds: 220),
                                    ),
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          16.0, 16.0, 16.0, 44.0),
                      child: AppButton(
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                        text: 'Close',
                        options: AppButtonOptions(
                          width: double.infinity,
                          height: 52.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              44.0, 0.0, 44.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color:
                              AppTheme.of(context).secondaryBackground,
                          textStyle:
                              AppTheme.of(context).titleLarge.override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: AppTheme.of(context)
                                          .titleLarge
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: AppTheme.of(context)
                                        .titleLarge
                                        .fontWeight,
                                    fontStyle: AppTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: AppTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          hoverColor: AppTheme.of(context).alternate,
                          hoverBorderSide: BorderSide(
                            color: AppTheme.of(context).alternate,
                            width: 2.0,
                          ),
                          hoverTextColor:
                              AppTheme.of(context).primaryText,
                          hoverElevation: 3.0,
                        ),
                      ),
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
