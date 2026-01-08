import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import 'dart:ui';
import '/main_function/success_page/success_page_widget.dart';
import '/models/game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
class LeaveGameWidget extends StatefulWidget {
  const LeaveGameWidget({
    super.key,
    required this.gameRef,
  });

  final Game gameRef;

  @override
  State<LeaveGameWidget> createState() => _LeaveGameWidgetState();
}

class _LeaveGameWidgetState extends State<LeaveGameWidget> {
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
    return FairwayBackgroundDark(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6.0,
            sigmaY: 8.0,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.of(context).accent4,
            ),
            alignment: AlignmentDirectional(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.of(context).secondaryBackground,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 7.0,
                        color: Color(0x33000000),
                        offset: Offset(
                          0.0,
                          -2.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0.0),
                      bottomRight: Radius.circular(0.0),
                      topLeft: Radius.circular(AppSpacing.md),
                      topRight: Radius.circular(AppSpacing.md),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60.0,
                              height: 3.0,
                              decoration: BoxDecoration(
                                color: AppTheme.of(context).alternate,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: AppSpacing.md,
                            top: AppSpacing.md,
                          ),
                          child: RichText(
                            textScaler: MediaQuery.of(context).textScaler,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Are you sure you want to leave ',
                                  style: TextStyle(),
                                ),
                                TextSpan(
                                  text: valueOrDefault<String>(
                                    widget.gameRef.nameGame,
                                    'game name',
                                  ),
                                  style: TextStyle(),
                                )
                              ],
                              style: AppTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: AppTheme.of(context)
                                          .headlineMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: AppTheme.of(context)
                                        .headlineMedium
                                        .fontWeight,
                                    fontStyle: AppTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            44.0,
                          ),
                          child: AppButtonEnhanced(
                            onPressed: () async {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser == null) {
                                showSnackbar(
                                  context,
                                  'Please sign in to leave this game.',
                                );
                                return;
                              }
                              final currentUserRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid);
                              await widget.gameRef.reference.update({
                                'joined_players':
                                    FieldValue.arrayRemove([currentUserRef]),
                              });

                              if (widget.gameRef.chatRef != null) {
                                await context
                                    .read<ChatProvider>()
                                    .removeMember(
                                      chatId: widget.gameRef.chatRef!.id,
                                      uid: currentUser.uid,
                                    );
                              }

                              context.pushNamed(
                                SuccessPageWidget.routeName,
                                extra: <String, dynamic>{
                                  kTransitionInfoKey: TransitionInfo(
                                    hasTransition: true,
                                    transitionType:
                                        PageTransitionType.bottomToTop,
                                    duration: Duration(milliseconds: 220),
                                  ),
                                },
                              );
                            },
                            text: 'Leave Game',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.large,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
