import '/backend/backend.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/branded_golf_header.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/providers/provider_extensions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/navigation/app_router.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/models/game.dart';
import '/profile/profile_user/profile_user_firebase_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
class GameJoinedDetailedWidget extends StatefulWidget {
  const GameJoinedDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'GameJoinedDetailed';
  static String routePath = '/gameJoinedDetailed';

  @override
  State<GameJoinedDetailedWidget> createState() =>
      _GameJoinedDetailedWidgetState();
}

class _GameJoinedDetailedWidgetState extends State<GameJoinedDetailedWidget> {
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
    if (widget.gameRef == null) {
      return Scaffold(
        backgroundColor: AppTheme.of(context).secondaryBackground,
        body: Center(
          child: Text(
            'Game details are unavailable.',
            style: AppTheme.of(context).bodyMedium,
          ),
        ),
      );
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserRef = currentUser == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.gameRef!.snapshots(),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: AppTheme.of(context).secondary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final gameJoinedDetailedGamesRecord = Game.fromDoc(snapshot.data!);

        return Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                debugPrint('🔙 GAME DETAIL: Back button pressed, navigating to Game List');
                // Always navigate to Game List, not pop() which could go to "Add Your Group"
                // This ensures clean navigation flow
                final router = GoRouter.of(context);
                router.go('/gamesList');
              },
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.of(context).primary,
                size: 32.0,
              ),
            ),
            title: Text(
              'Game Dashboard',
              style: AppTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                    ),
                    color: AppTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                  ),
            ),
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: FairwayBackgroundDark(
            showOrganic: true,
            showTexture: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branded header with abstract golf pattern
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: BrandedGolfHeader(
                      username: gameJoinedDetailedGamesRecord.nameGame,
                      courseName: gameJoinedDetailedGamesRecord.coursePlay,
                    ),
                  ),

                  // Message Group Button
                  if (gameJoinedDetailedGamesRecord.chatRef != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButtonEnhanced(
                        text: 'Message Group',
                        leadingIcon: Icons.chat_bubble_outline,
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.medium,
                        fullWidth: true,
                        onPressed: () {
                          final chatRef =
                              gameJoinedDetailedGamesRecord.chatRef;
                          if (chatRef == null) {
                            return;
                          }
                          context.pushNamed(
                            'ChatDetails',
                            pathParameters: {
                              'chatId': chatRef.id,
                            },
                          );
                        },
                      ),
                    ),

                  SizedBox(height: AppSpacing.md),

                  // Date/Time Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.fairway.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.fairwayLight.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '📅',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _formatDateTime(
                                  gameJoinedDetailedGamesRecord.date),
                              style: AppTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: AppTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: AppTheme.of(context)
                                        .bodyLarge
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.md),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Game Details Section Header
                        Text(
                          'Game Details',
                          style: AppTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .headlineSmall
                                    .fontStyle,
                              ),
                        ),
                        SizedBox(height: AppSpacing.sm),

                        // 2x3 Grid of Info Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 2.5,
                          children: [
                            _buildInfoCard(
                              context,
                              icon: '💰',
                              label: 'Betting',
                              value: gameJoinedDetailedGamesRecord.styleGame,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '📋',
                              label: 'Rule Style',
                              value: gameJoinedDetailedGamesRecord.rulesSetting,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '⛳',
                              label: 'Game Type',
                              value: gameJoinedDetailedGamesRecord.gameType,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '📊',
                              label: 'Scoring',
                              value: gameJoinedDetailedGamesRecord.scoring,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '💬',
                              label: 'Member Discount',
                              value:
                                  gameJoinedDetailedGamesRecord.memberDiscount,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '👥',
                              label: 'Friends Only',
                              value: gameJoinedDetailedGamesRecord.friendGame,
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.lg),

                        // Players Section Header
                        Text(
                          'Players (${_getPlayerCount(gameJoinedDetailedGamesRecord)}/4)',
                          style: AppTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .headlineSmall
                                    .fontStyle,
                              ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                  // Players horizontal cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Builder(
                      builder: (context) {
                        final groupPlayers = gameJoinedDetailedGamesRecord
                            .joinedPlayers
                            .toList();
                        final guestPlayers = gameJoinedDetailedGamesRecord
                            .guestPlayers
                            .where((name) => name.trim().isNotEmpty)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Registered players
                            ...List.generate(groupPlayers.length,
                                (groupPlayersIndex) {
                              final groupPlayersItem =
                                  groupPlayers[groupPlayersIndex];
                              return Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: StreamBuilder<UsersRecord>(
                                  stream:
                                      UsersRecord.getDocument(groupPlayersItem),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 40.0,
                                          height: 40.0,
                                          child: SpinKitWanderingCubes(
                                            color:
                                                AppTheme.of(context).secondary,
                                            size: 40.0,
                                          ),
                                        ),
                                      );
                                    }

                                    final friend1UsersRecord = snapshot.data!;

                                    return InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfileUserFirebaseWidget(
                                              userRef:
                                                  friend1UsersRecord.reference,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: AppColors.fairway
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.fairwayLight
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 48.0,
                                              height: 48.0,
                                              decoration: BoxDecoration(
                                                color: AppColors.fairwayLight,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.sunsetGold,
                                                  width: 2.0,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Image.network(
                                                friend1UsersRecord.photoUrl !=
                                                        ''
                                                    ? friend1UsersRecord
                                                        .photoUrl
                                                    : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Image.asset(
                                                  'assets/images/error_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: AppSpacing.sm),
                                            // Name and ready status
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    friend1UsersRecord
                                                        .displayName,
                                                    style: AppTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Ready',
                                                    style: AppTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: AppColors
                                                              .sunsetGold,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Show remove button for owner, checkmark for others
                                            if (gameJoinedDetailedGamesRecord.userRef == currentUserRef)
                                              AppIconButton(
                                                icon: Icon(
                                                  Icons.remove_circle_outline,
                                                  color: AppTheme.of(context).error,
                                                  size: 24.0,
                                                ),
                                                borderRadius: 20.0,
                                                buttonSize: 40.0,
                                                fillColor: Colors.transparent,
                                                onPressed: () => _showRemovePlayerDialog(
                                                  context: context,
                                                  playerName: friend1UsersRecord.displayName,
                                                  playerRef: groupPlayersItem,
                                                  isGuest: false,
                                                  gameRecord: gameJoinedDetailedGamesRecord,
                                                ),
                                              )
                                            else
                                              Icon(
                                                Icons.check_circle,
                                                color: AppColors.sunsetGold,
                                                size: 24.0,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                            // Guest players
                            ...guestPlayers.map(
                              (guestName) => Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.fairway
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.fairwayLight
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar placeholder
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.fairwayLight
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.3),
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'G',
                                            style: AppTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  font: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Colors.white,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      AppTheme.of(context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      // Name and guest label
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              guestName,
                                              style: AppTheme.of(context)
                                                  .bodyLarge
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodyLarge
                                                            .fontStyle,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Guest',
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Remove button for owner
                                      if (gameJoinedDetailedGamesRecord.userRef == currentUserRef)
                                        AppIconButton(
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            color: AppTheme.of(context).error,
                                            size: 24.0,
                                          ),
                                          borderRadius: 20.0,
                                          buttonSize: 40.0,
                                          fillColor: Colors.transparent,
                                          onPressed: () => _showRemovePlayerDialog(
                                            context: context,
                                            playerName: guestName,
                                            playerRef: null,
                                            isGuest: true,
                                            guestName: guestName,
                                            gameRecord: gameJoinedDetailedGamesRecord,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  // Add Players button (for owner, when not full)
                  if (gameJoinedDetailedGamesRecord.userRef == currentUserRef &&
                      _getPlayerCount(gameJoinedDetailedGamesRecord) < 4)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButtonEnhanced(
                        text: 'Add Players',
                        leadingIcon: Icons.person_add,
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.medium,
                        fullWidth: true,
                        onPressed: () => _navigateToAddPlayers(context),
                      ),
                    ),
                  if (gameJoinedDetailedGamesRecord.userRef == currentUserRef &&
                      _getPlayerCount(gameJoinedDetailedGamesRecord) < 4)
                    SizedBox(height: AppSpacing.md),
                  // Leave game button (for non-owner)
                  if (gameJoinedDetailedGamesRecord.userRef != currentUserRef)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _buildDestructiveButton(
                        context: context,
                        text: 'Leave game',
                        onPressed: () async {
                          if (currentUserRef == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please sign in to leave the game.'),
                                backgroundColor: AppTheme.of(context).error,
                              ),
                            );
                            return;
                          }
                          final currentUser =
                              FirebaseAuth.instance.currentUser;
                          final currentUserId =
                              currentUser?.uid ?? currentUserRef.id;
                          final removeValues = <Object>[
                            currentUserRef,
                            currentUserId,
                          ];
                          await widget.gameRef!.update({
                            'joined_players':
                                FieldValue.arrayRemove(removeValues),
                          });
                          context.userProvider.refreshMyGames();

                          // Show success toast
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You left the game'),
                              backgroundColor: AppTheme.of(context).success,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to Schedule tab (My Games)
                          context.goNamed(GamesJoinedWidget.routeName);
                        },
                      ),
                    ),
                  // Cancel game button (for owner)
                  if (gameJoinedDetailedGamesRecord.userRef == currentUserRef)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: _buildDestructiveButton(
                        context: context,
                        text: 'Cancel game',
                        onPressed: () async {
                          if (currentUserRef == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please sign in to cancel the game.'),
                                backgroundColor: AppTheme.of(context).error,
                              ),
                            );
                            return;
                          }
                          var confirmDialogResponse = await showDialog<bool>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: Text('Are  you sure?'),
                                    content:
                                        Text('Do you really cancel the game?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            alertDialogContext, false),
                                        child: Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            alertDialogContext, true),
                                        child: Text('Yes'),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                          if (confirmDialogResponse) {
                            try {
                              debugPrint(
                                'CancelGame: updating ${widget.gameRef?.path}',
                              );
                              await widget.gameRef!.update({
                                'isCancelled': true,
                                'status': 'cancelled',
                              });
                              final updatedSnapshot =
                                  await widget.gameRef!.get();
                              final updatedData = updatedSnapshot.data()
                                  as Map<String, dynamic>?;
                              debugPrint(
                                'CancelGame: isCancelled=${updatedData?['isCancelled']}',
                              );

                              final currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (gameJoinedDetailedGamesRecord.chatRef !=
                                      null &&
                                  currentUserId != null) {
                                final gameName =
                                    gameJoinedDetailedGamesRecord.nameGame;
                                final cancelMessage = (gameName != null &&
                                        gameName.trim().isNotEmpty)
                                    ? 'Game "$gameName" has been cancelled.'
                                    : 'This game has been cancelled.';
                                final chatRef =
                                    gameJoinedDetailedGamesRecord.chatRef!;
                                await context.read<ChatProvider>().sendMessage(
                                      chatId: chatRef.id,
                                      senderId: currentUserId,
                                      text: cancelMessage,
                                    );
                              }
                            } catch (error, stackTrace) {
                              debugPrint('CancelGame: failed $error');
                              debugPrintStack(stackTrace: stackTrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Unable to cancel the game. Please try again.',
                                  ),
                                  backgroundColor: AppTheme.of(context).error,
                                ),
                              );
                              return;
                            }

                            // Show success toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Game cancelled successfully'),
                                backgroundColor: AppTheme.of(context).success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            context.userProvider.refreshMyGames();

                            // Navigate to Schedule tab (My Games)
                            context.goNamed(GamesJoinedWidget.routeName);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to format date/time
  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Date not set';
    final formatter = DateFormat('EEEE, MMMM d • HH:mm');
    return formatter.format(date);
  }

  // Helper method to build info card
  Widget _buildInfoCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fairwayLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.of(context).labelSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontStyle: AppTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle: AppTheme.of(context).labelSmall.fontStyle,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to get player count
  int _getPlayerCount(Game gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount =
        gameRecord.guestPlayers.where((name) => name.trim().isNotEmpty).length;
    return joinedCount + guestCount;
  }

  // Player management helper methods

  Future<void> _showRemovePlayerDialog({
    required BuildContext context,
    required String playerName,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required Game gameRecord,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserRef = currentUser == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    // Prevent owner from removing themselves
    if (!isGuest && playerRef == currentUserRef) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot remove yourself. Use "Cancel game" instead.'),
          backgroundColor: AppTheme.of(context).error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text('Remove Player?'),
          content: Text('Remove $playerName from this game?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext, true),
              child: Text(
                'Remove',
                style: TextStyle(color: AppTheme.of(context).error),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      await _removePlayer(
        context: context,
        playerRef: playerRef,
        isGuest: isGuest,
        guestName: guestName,
        playerName: playerName,
        gameRecord: gameRecord,
      );
    }
  }

  Future<void> _removePlayer({
    required BuildContext context,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required String playerName,
    required Game gameRecord,
  }) async {
    try {

      if (isGuest && guestName != null) {
        // Remove guest player
        await widget.gameRef!.update({
          'guest_players': FieldValue.arrayRemove([guestName]),
        });

        debugPrint('Player Management: Removed guest player: $guestName');
      } else if (!isGuest && playerRef != null) {
        // Remove registered player from game
        await widget.gameRef!.update({
          'joined_players': FieldValue.arrayRemove([playerRef]),
        });

        // Remove from chat group if chat exists
        if (gameRecord.chatRef != null) {
          try {
            await context.read<ChatProvider>().removeMember(
              chatId: gameRecord.chatRef!.id,
              uid: playerRef.id,
            );
            debugPrint('Player Management: Removed from chat: ${playerRef.id}');
          } catch (chatError) {
            debugPrint('Player Management: Chat removal failed: $chatError');
            // Continue even if chat removal fails - game removal succeeded
          }
        }

        debugPrint('Player Management: Removed registered player: ${playerRef.id}');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$playerName removed from game'),
          backgroundColor: AppTheme.of(context).success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Player Management: Remove failed - $error');
      debugPrintStack(stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove player. Please try again.'),
          backgroundColor: AppTheme.of(context).error,
        ),
      );
    }
  }

  void _navigateToAddPlayers(BuildContext context) {
    // Navigate to PlayerListWidget with game reference
    // This reuses the exact same flow as game creation
    context.pushNamed(
      PlayerListWidget.routeName,
      extra: <String, dynamic>{
        'gameRef': widget.gameRef,
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.bottomToTop,
          duration: Duration(milliseconds: 220),
        ),
      },
    );
  }

  // Helper method to build destructive action buttons (Leave/Cancel)
  Widget _buildDestructiveButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 2.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.0),
          child: Center(
            child: Text(
              text,
              style: AppTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                    ),
                    color: AppColors.error,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
