import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_empty_state_premium.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/fairway_background.dart';
import '/models/game.dart';
import '/providers/game_provider.dart';
import '/utils/app_util.dart';
import 'components/games_joined_section.dart';

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

    // ✅ PERFORMANCE: Removed empty post-frame updateState(this, no-op rebuild)
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
          backgroundColor: AppColors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'My Games',
            style: AppTypography.headlineMediumSans.copyWith(
              color: AppColors.pure,
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
                    : context
                        .read<GameProvider>()
                        .userGamesStream(currentUserUid),
                initialData: _cachedGames ?? const <GamesRecord>[],
                onRetry: () => updateState(this, () {}),
                builder: (context, listViewGamesRecordList) {
                  final visibleGames = listViewGamesRecordList.where((game) {
                    if (game.isCancelled) {
                      return false;
                    }
                    final status = game.snapshotData['status'];
                    return status != 'cancelled';
                  }).toList();

                  // Split into upcoming vs recent rounds
                  final upcomingGames = <Game>[];
                  final recentRounds = <Game>[];

                  for (final record in visibleGames) {
                    final game = Game.fromRecord(record);
                    if (game.isActive) {
                      upcomingGames.add(game);
                    } else if (game.isPlayed ||
                        game.isCompleted ||
                        game.isExpired) {
                      recentRounds.add(game);
                    }
                  }

                  // Sort upcoming by date ASC (soonest first)
                  upcomingGames.sort((a, b) =>
                      (a.date ?? DateTime(2099))
                          .compareTo(b.date ?? DateTime(2099)));
                  // Sort recent by date DESC, limit 5
                  recentRounds.sort((a, b) =>
                      (b.date ?? DateTime(2000))
                          .compareTo(a.date ?? DateTime(2000)));
                  final displayRecent = recentRounds.take(5).toList();

                  final hasNoGames =
                      upcomingGames.isEmpty && displayRecent.isEmpty;

                  return RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.navyDark,
                    onRefresh: () async {
                      context
                          .read<GameProvider>()
                          .invalidateUserGamesCache(currentUserUid);
                      await Future.delayed(Duration(milliseconds: 500));
                      if (mounted) {
                        updateState(this, () {});
                      }
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          sliver: const SliverToBoxAdapter(
                              child: SizedBox.shrink()),
                        ),
                        if (hasNoGames)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.xl,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppEmptyStatePremium(
                                    icon: AppPhosphorIcons.games,
                                    title: 'No Games Yet',
                                    message:
                                        'Join or create a game to get started.',
                                  ),
                                  SizedBox(height: AppSpacing.lg),
                                  SizedBox(
                                    width: 220,
                                    child: AppButtonEnhanced(
                                      text: 'Create a game',
                                      variant: AppButtonVariant.primary,
                                      size: AppButtonSize.medium,
                                      onPressed: () {
                                        context.pushCreateGame(
                                          transition: TransitionStandards
                                              .detailTransition,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (upcomingGames.isNotEmpty)
                          GamesJoinedSection(
                            title: 'Upcoming',
                            games: upcomingGames,
                            currentUserReference:
                                currentUserDocument?.reference,
                          ),
                        if (upcomingGames.isNotEmpty &&
                            displayRecent.isNotEmpty)
                          SliverToBoxAdapter(
                            child: SizedBox(height: AppSpacing.lg),
                          ),
                        if (displayRecent.isNotEmpty)
                          GamesJoinedSection(
                            title: 'Recent Rounds',
                            games: displayRecent,
                            currentUserReference:
                                currentUserDocument?.reference,
                            showRematchActions: true,
                            animationIndexOffset: upcomingGames.length,
                          ),
                        // Bottom padding for nav bar
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 128.0,
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
}
