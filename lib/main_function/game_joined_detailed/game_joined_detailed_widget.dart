import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button.dart';
import '/core/widgets/app_card.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/profile/profile_user/profile_user_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return StreamBuilder<GamesRecord>(
      stream: GamesRecord.getDocument(widget.gameRef!),
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

        final gameJoinedDetailedGamesRecord = snapshot.data!;

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
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.go('/');
                }
              },
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.of(context).primary,
                size: 32.0,
              ),
            ),
            title: Text(
              'Joined Game',
              style: AppTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          AppTheme.of(context).headlineSmall.fontStyle,
                    ),
                    color: AppTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        AppTheme.of(context).headlineSmall.fontStyle,
                  ),
            ),
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: FairwayBackgroundLight(
            showOrganic: true,
            showTexture: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with golf course image and gradient overlay
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: StreamBuilder<CourseRecord>(
                      stream: CourseRecord.getDocument(
                          gameJoinedDetailedGamesRecord.courseRef!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: SizedBox(
                              width: 50.0,
                              height: 50.0,
                              child: SpinKitWanderingCubes(
                                color: AppTheme.of(context).secondary,
                                size: 50.0,
                              ),
                            ),
                          );
                        }

                        final coursePicCourseRecord = snapshot.data!;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Stack(
                            children: [
                              // Golf course image
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  coursePicCourseRecord.picture,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Gradient overlay for better text contrast
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                      stops: [0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Username (bottom-left) and Course name (bottom-right)
                              Positioned(
                                bottom: AppSpacing.md,
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Username
                                    Flexible(
                                      child: Text(
                                        gameJoinedDetailedGamesRecord.nameGame,
                                        style: AppTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w600,
                                                fontStyle: AppTheme.of(context)
                                                    .headlineMedium
                                                    .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: AppTheme.of(context)
                                                  .headlineMedium
                                                  .fontStyle,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.5),
                                                  offset: Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    // Course name
                                    Flexible(
                                      child: Text(
                                        gameJoinedDetailedGamesRecord.coursePlay,
                                        textAlign: TextAlign.right,
                                        style: AppTheme.of(context)
                                            .bodyLarge
                                            .override(
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
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.5),
                                                  offset: Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Date/Time Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: AppCard(
                      variant: AppCardVariant.standard,
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Text(
                            '📅',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _formatDateTime(gameJoinedDetailedGamesRecord.date),
                              style: AppTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: AppTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                                    color: AppColors.slate,
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
                                color: AppColors.fairwayDark,
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
                              value: gameJoinedDetailedGamesRecord.memberDiscount,
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
                                color: AppColors.fairwayDark,
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
                                  stream: UsersRecord.getDocument(
                                      groupPlayersItem),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 40.0,
                                          height: 40.0,
                                          child: SpinKitWanderingCubes(
                                            color: AppTheme.of(context).secondary,
                                            size: 40.0,
                                          ),
                                        ),
                                      );
                                    }

                                    final friend1UsersRecord = snapshot.data!;

                                    return AppCard(
                                      variant: AppCardVariant.outlined,
                                      padding: EdgeInsets.all(AppSpacing.sm),
                                      onTap: () async {
                                        context.pushNamed(
                                          ProfileUserWidget.routeName,
                                          queryParameters: {
                                            'userRef': serializeParam(
                                              friend1UsersRecord,
                                              ParamType.Document,
                                            ),
                                          }.withoutNulls,
                                          extra: <String, dynamic>{
                                            'userRef': friend1UsersRecord,
                                            kTransitionInfoKey: TransitionInfo(
                                              hasTransition: true,
                                              transitionType:
                                                  PageTransitionType.bottomToTop,
                                              duration:
                                                  Duration(milliseconds: 220),
                                            ),
                                          },
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 48.0,
                                            height: 48.0,
                                            decoration: BoxDecoration(
                                              color: AppColors.fairway,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.fairwayLight,
                                                width: 2.0,
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Image.network(
                                              friend1UsersRecord.photoUrl != ''
                                                  ? friend1UsersRecord.photoUrl
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
                                                  friend1UsersRecord.displayName,
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
                                                        color: AppColors.slate,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            AppTheme.of(context)
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
                                                        font: GoogleFonts.outfit(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                        color: AppColors.success,
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
                                          // Checkmark icon
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                            size: 24.0,
                                          ),
                                        ],
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
                                child: AppCard(
                                  variant: AppCardVariant.outlined,
                                  padding: EdgeInsets.all(AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      // Avatar placeholder
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.sand,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.cloud,
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
                                                  color: AppColors.stone,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: AppTheme.of(context)
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
                                                    color: AppColors.slate,
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
                                                    color: AppColors.stone,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ],
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
                  // Leave game button (for non-owner)
                  if (gameJoinedDetailedGamesRecord.userRef !=
                      currentUserReference)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButton(
                        onPressed: () async {
                          await widget.gameRef!.update({
                            ...mapToFirestore(
                              {
                                'joined_players': FieldValue.arrayRemove(
                                    [currentUserReference]),
                              },
                            ),
                          });
                          await showDialog(
                            context: context,
                            builder: (alertDialogContext) {
                              return AlertDialog(
                                title: Text('Success'),
                                content: Text('Leave the game successfully'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(alertDialogContext),
                                    child: Text('Ok'),
                                  ),
                                ],
                              );
                            },
                          );

                          context.pushNamed(GamesListWidget.routeName);
                        },
                        text: 'Leave game',
                        options: AppButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsets.zero,
                          iconPadding: EdgeInsets.zero,
                          color: Colors.transparent,
                          textStyle: AppTheme.of(context)
                              .bodyLarge
                              .override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                                color: AppColors.error,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  // Cancel game button (for owner)
                  if (gameJoinedDetailedGamesRecord.userRef ==
                      currentUserReference)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButton(
                        onPressed: () async {
                          var confirmDialogResponse = await showDialog<bool>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: Text('Are  you sure?'),
                                    content: Text(
                                        'Do you really cancel the game?'),
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
                            await widget.gameRef!
                                .update(createGamesRecordData(
                              isCancelled: true,
                            ));
                            if (gameJoinedDetailedGamesRecord.chatRef !=
                                    null &&
                                currentUserReference != null) {
                              final gameName =
                                  gameJoinedDetailedGamesRecord.nameGame;
                              final cancelMessage = (gameName != null &&
                                      gameName.trim().isNotEmpty)
                                  ? 'Game "$gameName" has been cancelled.'
                                  : 'This game has been cancelled.';
                              await ChatMessagesRecord.collection.add(
                                createChatMessagesRecordData(
                                  user: currentUserReference,
                                  chat: gameJoinedDetailedGamesRecord.chatRef,
                                  text: cancelMessage,
                                  timestamp: getCurrentTimestamp,
                                ),
                              );
                            }
                            await showDialog(
                              context: context,
                              builder: (alertDialogContext) {
                                return AlertDialog(
                                  title: Text('Success'),
                                  content:
                                      Text('Game cancelled successfully'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(alertDialogContext),
                                      child: Text('Ok'),
                                    ),
                                  ],
                                );
                              },
                            );

                            context.pushNamed(GamesListWidget.routeName);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        text: 'Cancel game',
                        options: AppButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsets.zero,
                          iconPadding: EdgeInsets.zero,
                          color: Colors.transparent,
                          textStyle: AppTheme.of(context)
                              .bodyLarge
                              .override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                                color: AppColors.error,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
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
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: EdgeInsets.all(AppSpacing.sm),
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
                          fontStyle:
                              AppTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: AppColors.stone,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            AppTheme.of(context).labelSmall.fontStyle,
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
                  color: AppColors.fairwayDark,
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
  int _getPlayerCount(GamesRecord gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount = gameRecord.guestPlayers
        .where((name) => name.trim().isNotEmpty)
        .length;
    return joinedCount + guestCount;
  }
}
