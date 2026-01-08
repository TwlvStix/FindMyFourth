import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import 'dart:ui';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinGameWidget extends StatefulWidget {
  const JoinGameWidget({
    super.key,
    required this.gameRef,
  });

  final GamesRecord? gameRef;

  @override
  State<JoinGameWidget> createState() => _JoinGameWidgetState();
}

class _JoinGameWidgetState extends State<JoinGameWidget> {
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
                                borderRadius: BorderRadius.circular(AppSpacing.xxs),
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
                                  text: 'Join ',
                                  style: TextStyle(),
                                ),
                                TextSpan(
                                  text: valueOrDefault<String>(
                                    widget.gameRef?.nameGame,
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
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.xxxl - AppSpacing.xxs,
                          ),
                          child: AppButtonEnhanced(
                            onPressed: () async {
                              if (widget.gameRef == null) {
                                showSnackbar(
                                  context,
                                  'Game details are unavailable. Please try again.',
                                );
                                return;
                              }
                              if (currentUserReference == null) {
                                showSnackbar(
                                  context,
                                  'Please sign in to join this game.',
                                );
                                return;
                              }
                              try {
                                await widget.gameRef!.reference.update({
                                  ...mapToFirestore(
                                    {
                                      'joined_players': FieldValue.arrayUnion(
                                          [currentUserReference]),
                                    },
                                  ),
                                });

                                await widget.gameRef!.chatRef!.update({
                                  ...mapToFirestore(
                                    {
                                      'users': FieldValue.arrayUnion(
                                          [currentUserReference]),
                                    },
                                  ),
                                });
                              } on FirebaseException catch (error) {
                                if (!mounted) {
                                  return;
                                }
                                final message = error.code == 'permission-denied'
                                    ? 'You do not have permission to join this game.'
                                    : 'Unable to join the game right now. Please try again.';
                                showSnackbar(context, message);
                                return;
                              } catch (_) {
                                if (!mounted) {
                                  return;
                                }
                                showSnackbar(
                                  context,
                                  'Unable to join the game right now. Please try again.',
                                );
                                return;
                              }

                              if (!mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                              context.goNamed(
                                GameJoinedDetailedWidget.routeName,
                                queryParameters: {
                                  'gameRef': serializeParam(
                                    widget.gameRef!.reference,
                                    ParamType.DocumentReference,
                                  ),
                                }.withoutNulls,
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
                            text: 'Join Game',
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
