import '/utils/app_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import 'dart:ui';
import '/models/game.dart';
import '/providers/chat_provider.dart';
import '/providers/provider_extensions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class JoinGameWidget extends StatefulWidget {
  const JoinGameWidget({
    super.key,
    required this.gameRef,
  });

  final Game gameRef;

  @override
  State<JoinGameWidget> createState() => _JoinGameWidgetState();
}

class _JoinGameWidgetState extends State<JoinGameWidget> {
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
                    color: AppColors.navy,
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
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.xs),
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
                                    widget.gameRef.nameGame,
                                    'game name',
                                  ),
                                  style: TextStyle(),
                                )
                              ],
                              style: AppTypography.headlineMediumSans.copyWith(
                                letterSpacing: 0.0,
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
                              final currentUserRef = currentUserReference;
                              if (currentUserRef == null) {
                                showSnackbar(
                                  context,
                                  'Please sign in to join this game.',
                                );
                                return;
                              }
                              final currentUserId = currentUserRef.id;
                              final isFriendsOnly =
                                  widget.gameRef.friendGame == Game.visibilityFriends;

                              try {
                                await context.gameProvider.joinGame(
                                  widget.gameRef.reference.id,
                                  currentUserId,
                                  userGender:
                                      context.userProvider.currentUser?.gender,
                                );
                              } on FirebaseException catch (error) {
                                if (!context.mounted) return;
                                final message = error.code ==
                                        'permission-denied'
                                    ? (isFriendsOnly
                                        ? 'You must be friends with the game creator to join this game.'
                                        : 'You do not have permission to join this game.')
                                    : 'Unable to join the game right now. Please try again.';
                                showSnackbar(context, message);
                                return;
                              } catch (_) {
                                if (!context.mounted) return;
                                showSnackbar(
                                  context,
                                  'Unable to join the game right now. Please try again.',
                                );
                                return;
                              }

                              // Eagerly sync chat membership to prevent
                              // permission-denied race with Cloud Function.
                              if (!context.mounted) return;
                              if (widget.gameRef.chatRef != null) {
                                await context.read<ChatProvider>()
                                    .ensureGameChatMembership(
                                  chatId: widget.gameRef.chatRef!.id,
                                  uid: currentUserId,
                                );
                              }

                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              context.goGameJoinedDetailed(
                                gameRef: widget.gameRef.reference,
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
