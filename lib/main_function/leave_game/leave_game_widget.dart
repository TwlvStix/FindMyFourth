import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import 'dart:ui';
import '/main_function/success_page/success_page_widget.dart';
import '/models/game.dart';
import '/screens/trust/cancellation_warning_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/providers/provider_extensions.dart';
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
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
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
              color: AppColors.greenLight,
            ),
            alignment: AlignmentDirectional(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.navyBackground,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 7.0,
                        color: AppColors.overlayDark,
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
                                color: AppColors.cloud,
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
                              style: AppTypography.headlineMedium
                                  .override(
                                    font: TextStyle(fontFamily: 'Manrope',
                                      fontWeight: AppTypography.headlineMedium
                                          .fontWeight,
                                      fontStyle: AppTypography.headlineMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: AppTypography.headlineMedium
                                        .fontWeight,
                                    fontStyle: AppTypography.headlineMedium
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
                              // Show tier-aware cancellation warning before proceeding
                              final confirmed =
                                  await CancellationWarningModal.show(
                                context,
                                game: widget.gameRef,
                              );
                              if (confirmed != true) return;

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
                              final removeValues = <Object>[
                                currentUserRef,
                                currentUser.uid,
                              ];
                              await widget.gameRef.reference.update({
                                'joined_players':
                                    FieldValue.arrayRemove(removeValues),
                              });

                              if (widget.gameRef.chatRef != null) {
                                await context
                                    .read<ChatProvider>()
                                    .removeMember(
                                      chatId: widget.gameRef.chatRef!.id,
                                      uid: currentUser.uid,
                                    );
                              }
                              context.gameProvider.invalidateUserGamesCache(context.userProvider.userId);

                              context.pushNamed(
                                SuccessPageWidget.routeName,
                                extra: <String, dynamic>{
                                  kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
                                },
                              );
                            },
                            text: 'Cancel My Spot',
                            variant: AppButtonVariant.secondary,
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
