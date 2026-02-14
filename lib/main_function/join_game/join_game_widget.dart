import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import 'dart:ui';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/models/game.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/backend/backend.dart';

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
                                    widget.gameRef.nameGame,
                                    'game name',
                                  ),
                                  style: TextStyle(),
                                )
                              ],
                              style: AppTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: TextStyle(fontFamily: 'Manrope',
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
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser == null) {
                                showSnackbar(
                                  context,
                                  'Please sign in to join this game.',
                                );
                                return;
                              }
                              final friendGameValue =
                                  widget.gameRef.friendGame.trim();
                              final friendGameLower = friendGameValue.toLowerCase();
                              final isFriendsOnly = friendGameLower == 'friends';
                              bool isCreatorFriend = false;
                              if (isFriendsOnly) {
                                try {
                                  final ownerRef = widget.gameRef.userRef;
                                  if (ownerRef != null) {
                                    final ownerSnap = await ownerRef.get();
                                    final ownerData =
                                        ownerSnap.data() as Map<String, dynamic>? ?? {};
                                    final friends = ownerData['friends'];
                                    if (friends is List) {
                                      final currentUserRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUser.uid);
                                      final currentUserId = currentUserRef.id;
                                      String? normalizeFriendEntry(Object? entry) {
                                        if (entry is DocumentReference) {
                                          return entry.id;
                                        }
                                        if (entry is String) {
                                          if (entry.contains('/')) {
                                            final parts = entry.split('/');
                                            return parts.isNotEmpty ? parts.last : entry;
                                          }
                                          return entry;
                                        }
                                        return null;
                                      }
                                      isCreatorFriend = friends.any(
                                        (entry) =>
                                            normalizeFriendEntry(entry) == currentUserId,
                                      );
                                    }
                                  }
                                } catch (error) {
                                  debugPrint(
                                    'JoinGame: friend check failed $error',
                                  );
                                }
                                if (!isCreatorFriend) {
                                  showSnackbar(
                                    context,
                                    'You must be friends with the game creator to join this game.',
                                  );
                                  return;
                                }
                              }
                              final currentUserRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid);
                              try {
                                await widget.gameRef.reference.update({
                                  'joined_players':
                                      FieldValue.arrayUnion([currentUserRef]),
                                });

                                if (widget.gameRef.chatRef != null) {
                                  await context
                                      .read<ChatProvider>()
                                      .addMember(
                                        chatId: widget.gameRef.chatRef!.id,
                                        uid: currentUser.uid,
                                      );
                                }
                              } on FirebaseException catch (error) {
                                if (!mounted) {
                                  return;
                                }
                                final message = error.code == 'permission-denied'
                                    ? (isFriendsOnly && !isCreatorFriend
                                        ? 'You must be friends with the game creator to join this game.'
                                        : 'You do not have permission to join this game.')
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
                                extra: <String, dynamic>{
                                  'gameRef': widget.gameRef.reference,
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
