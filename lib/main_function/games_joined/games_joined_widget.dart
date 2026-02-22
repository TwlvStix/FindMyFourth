import '/backend/backend.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/games_list/components/flexible_time_display.dart';
import '/models/game.dart';
import '/providers/game_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GamesJoinedWidget extends StatefulWidget {
  const GamesJoinedWidget({super.key});

  static String routeName = 'GamesJoined';
  static String routePath = '/gamesJoined';

  @override
  State<GamesJoinedWidget> createState() => _GamesJoinedWidgetState();
}

class _GamesJoinedWidgetState extends State<GamesJoinedWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<GamesRecord>? _cachedGames;

  @override
  void initState() {
    super.initState();

    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Retrieve cached user games (safe to access context here)
    if (_cachedGames == null && currentUserUid.isNotEmpty) {
      final gameProvider = context.read<GameProvider>();
      _cachedGames = gameProvider.getCachedUserGames(currentUserUid);
    }
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'My Games',
            style: AppTypography.headlineMediumSans.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 56,
              ),
              child: AppStreamBuilder<List<GamesRecord>>(
              stream: currentUserUid.isEmpty
                  ? Stream.value(const <GamesRecord>[])
                  : context.read<GameProvider>().userGamesStream(currentUserUid),
              initialData: _cachedGames ?? const <GamesRecord>[],
              onRetry: () => setState(() {}),
              builder: (context, listViewGamesRecordList) {
                final visibleGames = listViewGamesRecordList.where((game) {
                  if (game.isCancelled) {
                    return false;
                  }
                  final status = game.snapshotData['status'];
                  return status != 'cancelled';
                }).toList();

                return RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.navyDark,
                  onRefresh: () async {
                    context.read<GameProvider>().invalidateUserGamesCache(currentUserUid);
                    await Future.delayed(Duration(milliseconds: 500));
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: AppSpacing.md,
                          // Account for bottom nav bar (56) + FAB (56) + spacing (16) + safe area
                          bottom: MediaQuery.of(context).padding.bottom + 128.0,
                        ),
                        sliver: visibleGames.isEmpty
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.xl,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: AppColors.navy.withValues(alpha:0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: AppIcon(
                                            assetPath: AppIcons.games,
                                            size: AppIconSize.hero,
                                            color: AppColors.glassTextTertiary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.lg),
                                      Text(
                                        'No games yet',
                                        style: AppTypography.titleMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Be the first to create a game.',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.glassTextSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: AppSpacing.lg),
                                      SizedBox(
                                        width: 220,
                                        child: AppButtonEnhanced(
                                          text: 'Create a game',
                                          variant: AppButtonVariant.primary,
                                          size: AppButtonSize.medium,
                                          onPressed: () {
                                            context.pushNamed(
                                              CreateGameWidget.routeName,
                                              extra: <String, dynamic>{
                                                kTransitionInfoKey:
                                                    TransitionStandards.detailTransition,
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, listViewIndex) {
                                    final game = visibleGames[listViewIndex];
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs,
                                      ),
                                      child: _buildPremiumMyGameCard(context, game),
                                    );
                                  },
                                  childCount: visibleGames.length,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
            },
          ),
        ),
      ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM MY GAME CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPremiumMyGameCard(BuildContext context, GamesRecord gameRecord) {
    final game = Game.fromRecord(gameRecord);
    final isOwner = currentUserUid.isNotEmpty && game.userRef?.id == currentUserUid;
    final isCancelled = game.isCancelled;
    final isExpired = game.date != null && game.date!.isBefore(getCurrentTimestamp) && !isCancelled;
    final spotsLeft = game.maxPlayers - (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        context.pushNamed(
          GameJoinedDetailedWidget.routeName,
          extra: <String, dynamic>{
            'gameRef': game.reference,
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
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: AppColors.gold.withValues(alpha:0.4),
            width: 2.0,
          ),
          boxShadow: [AppElevation.lg],
        ),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Game Type Badge + Status
                  Row(
                    children: [
                      // Game Type Badge with gradient
                      if (game.gameType.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: game.styleGame == 'Money Game'
                                  ? [AppColors.gold, AppColors.goldLight]
                                  : [AppColors.navyLight, AppColors.navy],
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: (game.styleGame == 'Money Game'
                                        ? AppColors.gold
                                        : AppColors.navy)
                                    .withValues(alpha:0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            game.gameType,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (game.styleGame == 'Money Game') ...[
                        SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            '\$\$\$',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      Spacer(),
                      // Status badges
                      if (isCancelled)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha:0.3),
                            ),
                          ),
                          child: Text(
                            'Cancelled',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (isExpired)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            'Completed',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (isOwner)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha:0.9),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(
                                  assetPath: AppIcons.owner,
                                  color: AppColors.pure, size: AppIconSize.xs),
                              SizedBox(width: 4),
                              Text(
                                'Owner',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.gold, AppColors.goldLight],
                            ),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(
                                  assetPath: AppIcons.joined,
                                  color: AppColors.pure, size: AppIconSize.xs),
                              SizedBox(width: 4),
                              Text(
                                'Joined',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Course Name - Hero Element with icon
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.navyLight, AppColors.navy],
                          ),
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Center(
                          child: AppIcon(
                            assetPath: AppIcons.course,
                            color: AppColors.pure,
                            size: AppIconSize.button,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valueOrDefault<String>(game.coursePlay, 'Course Name'),
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              valueOrDefault<String>(game.nameGame, 'Game Name'),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chat button
                      if (game.chatRef != null)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (currentUserUid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in to open the chat.'),
                                ),
                              );
                              return;
                            }
                            final isMember = game.joinedPlayers.any(
                              (player) => player.id == currentUserUid,
                            );
                            if (!isMember) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Join the game to access the group chat.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.pushNamed(
                              'ChatDetails',
                              pathParameters: {
                                'chatId': game.chatRef!.id,
                              },
                              extra: <String, dynamic>{
                                kTransitionInfoKey: TransitionStandards.detailTransition,
                              },
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.gold, AppColors.goldLight],
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              boxShadow: [AppElevation.md],
                            ),
                            child: AppIcon(
                              assetPath: AppIcons.chat,
                              color: AppColors.pure,
                              size: AppIconSize.button,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Date & Time with premium styling
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Center(
                            child: AppIcon(
                              assetPath: AppIcons.calendarCheck,
                              color: AppColors.goldLight,
                              size: AppIconSize.xs,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: game.isFlexible
                              ? FlexibleTimeDisplay(
                                  game: game,
                                  showWeekLabel: true,
                                  compact: false,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dateTimeFormat("EEEE", game.date)}, ${dateTimeFormat("MMM d", game.date)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      dateTimeFormat("jm", game.date),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.glassTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        ),
                        // Player count indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isFull
                                ? AppColors.error.withValues(alpha:0.2)
                                : AppColors.navyLight.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                            border: Border.all(
                              color: isFull
                                  ? AppColors.error.withValues(alpha:0.3)
                                  : AppColors.glassSurface,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(
                                assetPath: AppIcons.golfers,
                                color: isFull ? AppColors.error : AppColors.pure,
                                size: AppIconSize.xs,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isFull ? AppColors.error : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppBorderRadius.xl),
                  bottomRight: Radius.circular(AppBorderRadius.xl),
                ),
              ),
              child: Row(
                children: [
                  // Member discount badge
                  if (game.memberDiscount == 'Yes')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyLight.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            assetPath: AppIcons.memberDiscount,
                            color: AppColors.navyLight,
                            size: AppIconSize.xs,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Discount',
                            style: AppTypography.text10.copyWith(
                              color: AppColors.navyLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Spacer(),
                  // View Details button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.navyLight, AppColors.navy],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                      boxShadow: [AppElevation.md],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: AppColors.pure,
                          size: AppIconSize.xs,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View Details',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
