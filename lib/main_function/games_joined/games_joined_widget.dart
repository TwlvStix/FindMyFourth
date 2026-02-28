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
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_empty_state_premium.dart';
import '/core/widgets/app_expandable_text.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/create_game/create_game_widget.dart';
import '/main_function/games_list/components/flexible_availability_summary.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
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
                                    vertical: AppSpacing.xl,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppEmptyStatePremium(
                                        assetPath: AppIcons.games,
                                        title: 'No Games Yet',
                                        message: 'Join or create a game to get started.',
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
                  transitionType: AppTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
          },
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: AppColors.navyLight,
            width: 1.0,
          ),
          boxShadow: [AppElevation.card],
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
                      // Just for Fun pill
                      if (game.isFunGame)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                            border: Border.all(
                              color: AppColors.navyLight,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'Just for Fun',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      // Game Type Badge
                      else if (game.gameType.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                            border: Border.all(
                              color: AppColors.navyLight,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            game.gameType,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
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
                            color: AppColors.gold.withValues(alpha: 0.2),
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
                      // Player eligibility badge
                      if (game.playerEligibility == PlayerEligibility.womenOnly) ...[
                        SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            'Women Only',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (game.playerEligibility == PlayerEligibility.menOnly) ...[
                        SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            'Men Only',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      // Member discount badge (icon only)
                      if (game.memberDiscount == 'Yes') ...[
                        SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: AppIcon(
                            icon: AppPhosphorIcons.memberDiscount,
                            color: AppColors.green,
                            size: AppIconSize.xs,
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
                                  icon: AppPhosphorIcons.owner,
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
                            color: AppColors.stone.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(
                                  icon: AppPhosphorIcons.joined,
                                  color: AppColors.pure, size: AppIconSize.xs),
                              SizedBox(width: 4),
                              Text(
                                'Joined',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
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
                          color: AppColors.navyLight,
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Center(
                          child: AppIcon(
                            icon: AppPhosphorIcons.course,
                            color: AppColors.textSecondary,
                            size: AppIconSize.button,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppExpandableText(
                              text: valueOrDefault<String>(game.coursePlay, 'Course Name'),
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                            ),
                            Text(
                              valueOrDefault<String>(game.nameGame, 'Game Name'),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Date & Time section
                  if (game.isFlexible)
                    FlexibleAvailabilitySummary(game: game)
                  else
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
                              color: AppColors.navyLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            ),
                            child: Center(
                              child: AppIcon(
                                icon: AppPhosphorIcons.calendarCheck,
                                color: AppColors.textSecondary,
                                size: AppIconSize.xs,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dateTimeFormat("EEEE", game.date)}, ${dateTimeFormat("MMM d", game.date)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
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
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? AppColors.error.withValues(alpha: 0.2)
                                  : AppColors.navy,
                              borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                              border: Border.all(
                                color: isFull
                                    ? AppColors.error.withValues(alpha: 0.4)
                                    : AppColors.navyLight,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  icon: AppPhosphorIcons.golfers,
                                  color: isFull ? AppColors.error : AppColors.textSecondary,
                                  size: AppIconSize.xs,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
                                  style: AppTypography.labelMicro.copyWith(
                                    color: isFull ? AppColors.error : AppColors.textSecondary,
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
          ],
        ),
      ),
    );
  }
}
