import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_stream_builder.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/challenge.dart';
import '/models/challenge_progress.dart';
import '/providers/challenge_provider.dart';
import '/providers/leaderboard_provider.dart';
import '/services/challenge_analytics_service.dart';
import 'components/challenge_board_empty_state.dart';
import 'components/challenge_board_header.dart';
import 'components/challenge_board_skeleton.dart';
import 'components/challenge_category_section.dart';
import 'components/leaderboard_section.dart';

/// Full Challenge Board page showing all challenges grouped by category.
class ChallengeBoardWidget extends StatefulWidget {
  const ChallengeBoardWidget({super.key});

  static const String routeName = 'ChallengeBoard';
  static const String routePath = '/challengeBoard';

  @override
  State<ChallengeBoardWidget> createState() => _ChallengeBoardWidgetState();
}

class _ChallengeBoardWidgetState extends State<ChallengeBoardWidget> {
  bool _analyticsLogged = false;
  final ChallengeAnalyticsService _analytics = ChallengeAnalyticsService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm cache on first load
    context.read<ChallengeProvider>().getMyProgress();
    context.read<LeaderboardProvider>().loadLeaderboard();

    // One-shot analytics
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      _analytics.logChallengeViewed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        leading: const PremiumBackButton(),
        title: Text(
          'Challenge Board',
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
          child: AppStreamBuilder<Map<String, ChallengeProgress>?>(
            stream: context.read<ChallengeProvider>().watchMyProgress(),
            initialData: context.read<ChallengeProvider>().currentProgress,
            loadingBuilder: (_) => const ChallengeBoardSkeleton(),
            onRetry: () => setState(() {}),
            builder: (context, progressData) {
              final progress = progressData ?? {};

              // Empty state when no progress at all
              if (progress.isEmpty) {
                return const ChallengeBoardEmptyState();
              }

              final completed =
                  progress.values.where((p) => p.isCompleted).length;
              final total = Challenge.all.length;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: ChallengeBoardHeader(
                      completed: completed,
                      total: total,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: LeaderboardSection(),
                  ),
                  SliverToBoxAdapter(
                    child: ChallengeCategorySection(
                      category: ChallengeCategory.courseExplorer,
                      icon: AppPhosphorIcons.challengeCourseExplorer,
                      challenges: Challenge.all
                          .where((c) =>
                              c.category == ChallengeCategory.courseExplorer)
                          .toList(),
                      progress: progress,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ChallengeCategorySection(
                      category: ChallengeCategory.streaks,
                      icon: AppPhosphorIcons.challengeStreaks,
                      challenges: Challenge.all
                          .where(
                              (c) => c.category == ChallengeCategory.streaks)
                          .toList(),
                      progress: progress,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ChallengeCategorySection(
                      category: ChallengeCategory.social,
                      icon: AppPhosphorIcons.challengeSocial,
                      challenges: Challenge.all
                          .where(
                              (c) => c.category == ChallengeCategory.social)
                          .toList(),
                      progress: progress,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ChallengeCategorySection(
                      category: ChallengeCategory.formats,
                      icon: AppPhosphorIcons.challengeFormats,
                      challenges: Challenge.all
                          .where(
                              (c) => c.category == ChallengeCategory.formats)
                          .toList(),
                      progress: progress,
                    ),
                  ),
                  // Bottom padding for safe area
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl + AppSpacing.xl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
