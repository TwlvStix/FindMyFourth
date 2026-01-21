import '/backend/backend.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/core/navigation/app_router.dart';
import '/utils/app_util.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/models/game.dart';
import '/providers/provider_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesJoinedWidget extends StatefulWidget {
  const GamesJoinedWidget({super.key});

  static String routeName = 'GamesJoined';
  static String routePath = '/gamesJoined';

  @override
  State<GamesJoinedWidget> createState() => _GamesJoinedWidgetState();
}

class _GamesJoinedWidgetState extends State<GamesJoinedWidget> {
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
          leading: GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/');
              }
            },
            child: Container(
              margin: EdgeInsets.only(left: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.fairway.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 28.0,
              ),
            ),
          ),
          title: Text(
            'My Games',
            style: AppTypography.headlineMedium.copyWith(
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
              child: StreamBuilder<List<Game>>(
              stream: context.userProvider.getMyGames(),
              builder: (context, snapshot) {
                // Show loading indicator
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitWanderingCubes(
                          color: AppColors.sunsetGold,
                          size: 50.0,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading your games...',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final listViewGamesRecordList = snapshot.data!;

                // Empty state
                if (listViewGamesRecordList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.fairway.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.golf_course_rounded,
                            size: 50,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'No games yet',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Join a game to see it here',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.sunsetGold,
                  backgroundColor: AppColors.fairwayDark,
                  onRefresh: () async {
                    context.userProvider.refreshMyGames();
                    await Future.delayed(Duration(milliseconds: 500));
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xxxl,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, listViewIndex) {
                              final game = listViewGamesRecordList[listViewIndex];
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                child: _buildPremiumMyGameCard(context, game),
                              );
                            },
                            childCount: listViewGamesRecordList.length,
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
  Widget _buildPremiumMyGameCard(BuildContext context, Game game) {
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
              transitionType: PageTransitionType.bottomToTop,
              duration: Duration(milliseconds: 220),
            ),
          },
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.fairway.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: AppColors.sunsetGold.withOpacity(0.4),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunsetGold.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
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
                                  ? [AppColors.sunsetGold, AppColors.sunsetPeach]
                                  : [AppColors.fairwayLight, AppColors.fairway],
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: (game.styleGame == 'Money Game'
                                        ? AppColors.sunsetGold
                                        : AppColors.fairway)
                                    .withOpacity(0.3),
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
                            color: AppColors.sunsetGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$\$\$',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.sunsetGold,
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
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
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
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            'Completed',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
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
                              colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 14),
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
                            colors: [AppColors.fairwayLight, AppColors.fairway],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.golf_course_rounded,
                          color: Colors.white,
                          size: 18,
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
                                color: AppColors.sunsetGold,
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
                                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sunsetGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 20,
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.sunsetPeach.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.sunsetPeach,
                            size: 16,
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                dateTimeFormat("jm", game.date),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
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
                                ? AppColors.sunsetRose.withOpacity(0.2)
                                : AppColors.fairwayLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFull
                                  ? AppColors.sunsetRose.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: isFull ? AppColors.sunsetRose : Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${game.joinedPlayers.length + game.guestPlayers.length}/${game.maxPlayers}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isFull ? AppColors.sunsetRose : Colors.white,
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
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
                        color: AppColors.fairwayLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_rounded,
                            color: AppColors.fairwayLight,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Discount',
                            style: AppTypography.text10.copyWith(
                              color: AppColors.fairwayLight,
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
                        colors: [AppColors.fairwayLight, AppColors.fairway],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.fairway.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 16,
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
