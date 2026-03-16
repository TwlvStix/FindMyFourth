import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/models/leaderboard_entry.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/providers/leaderboard_provider.dart';
import '/services/challenge_analytics_service.dart';
import 'leaderboard_list_tile.dart';
import 'leaderboard_top_card.dart';

/// Main leaderboard section for the Challenge Board.
///
/// Reads from LeaderboardProvider. Hidden if fewer than 50 active users.
/// Shows top 5 as prominent cards, ranks 6+ as compact tiles,
/// and a "Your position" bar if the current user isn't in the top N.
class LeaderboardSection extends StatefulWidget {
  const LeaderboardSection({super.key});

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {
  bool _analyticsLogged = false;
  final ChallengeAnalyticsService _analytics = ChallengeAnalyticsService();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();

    if (!provider.isVisible) return const SizedBox.shrink();

    // Log analytics once when section becomes visible
    if (!_analyticsLogged && provider.topPlayers.isNotEmpty) {
      _analyticsLogged = true;
      _analytics.logLeaderboardViewed();
    }

    if (provider.isLoading && provider.topPlayers.isEmpty) {
      return _buildShimmer();
    }

    final players = provider.topPlayers;
    if (players.isEmpty) return const SizedBox.shrink();

    final top5 = players.length > 5 ? players.sublist(0, 5) : players;
    final rest = players.length > 5 ? players.sublist(5) : <LeaderboardEntry>[];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.lg),

          // Header row
          Row(
            children: [
              AppIcon(
                icon: AppPhosphorIcons.trophy,
                size: AppIconSize.section,
                color: AppColors.gold,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Season Leaderboard',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                DateTime.now().year.toString(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md),

          // Top 5 cards
          ...top5.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: LeaderboardTopCard(entry: entry),
              )),

          // Ranks 6+
          if (rest.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs),
            ...rest.map((entry) => LeaderboardListTile(entry: entry)),
          ],

          // "Your position" bar if user not in top N
          if (!provider.isCurrentUserInTop && provider.userRank > 0)
            _buildUserRankBar(provider.userRank),

          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildUserRankBar(int rank) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(color: AppColors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your position: ',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '#$rank',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.lg),
          // Header placeholder
          Container(
            height: 24,
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.xs),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Card placeholders
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
              ),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
