import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/friends/components/friend_card_skeleton.dart';
import '/models/vibe_profile.dart';
import '/providers/user_provider.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';
import '/vibe/vibe_match_types.dart';
import '/vibe/vibe_recommendation_rank.dart';

typedef DefaultExploreItemBuilder = Widget Function(
  BuildContext context,
  UsersRecord user,
);

class DefaultExploreContent extends StatefulWidget {
  const DefaultExploreContent({
    super.key,
    required this.currentUserId,
    required this.itemBuilder,
    this.recommendedLimit = 8,
    this.recentlyJoinedLimit = 20,
    this.candidateLimit = 60,
  });

  final String currentUserId;
  final DefaultExploreItemBuilder itemBuilder;
  final int recommendedLimit;
  final int recentlyJoinedLimit;
  final int candidateLimit;

  @override
  State<DefaultExploreContent> createState() => _DefaultExploreContentState();
}

class _DefaultExploreContentState extends State<DefaultExploreContent> {
  final VibeRepository _vibeRepository = VibeRepository();
  late final Future<VibeProfile> _myVibesFuture;

  @override
  void initState() {
    super.initState();
    _myVibesFuture = _vibeRepository.getMyVibesCached();
  }

  @override
  Widget build(BuildContext context) {
    final cachedVibeProfile = _vibeRepository.getCachedVibeProfileSync();

    return FutureBuilder<VibeProfile>(
      future: _myVibesFuture,
      initialData: cachedVibeProfile,
      builder: (context, vibeSnapshot) {
        if (!vibeSnapshot.hasData || vibeSnapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('RECOMMENDED FOR YOU', 0, AppColors.gold),
              _buildSectionEmpty(
                'Complete your VIBE profile to see personalized matches.',
              ),
              SizedBox(height: AppSpacing.lg),
              _buildRecentlyJoinedSection(const <String>{}, 0),
            ],
          );
        }

        final userProvider = context.read<UserProvider>();
        final cachedCandidates = userProvider.getCachedCandidateUsers(limit: widget.candidateLimit);

        return StreamBuilder<List<UsersRecord>>(
          stream: userProvider.queryCandidateUsers(limit: widget.candidateLimit),
          initialData: cachedCandidates,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('RECOMMENDED FOR YOU', 0, AppColors.gold),
                  _buildSectionLoading(),
                  SizedBox(height: AppSpacing.lg),
                  _buildRecentlyJoinedSection(const <String>{}, 0),
                ],
              );
            }

            final recommendations = _buildRecommendations(
              vibeSnapshot.data!,
              snapshot.data!,
            );
            final recommendedIds =
                recommendations.map((user) => user.reference.id).toSet();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecommendedSection(recommendations),
                SizedBox(height: AppSpacing.lg),
                _buildRecentlyJoinedSection(recommendedIds),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedSection(List<UsersRecord> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'RECOMMENDED FOR YOU',
          recommendations.length,
          AppColors.gold,
        ),
        if (recommendations.isEmpty)
          _buildSectionEmpty(
            'No VIBE matches available yet.',
          )
        else
          ListView.separated(
            padding: EdgeInsets.fromLTRB(
              0,
              AppSpacing.xs,
              0,
              0,
            ),
            primary: false,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: recommendations.length,
            separatorBuilder: (_, __) => SizedBox(height: 0),
            itemBuilder: (context, index) {
              final user = recommendations[index];
              return widget.itemBuilder(context, user);
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.labelMicro.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '$count ${count == 1 ? 'golfer' : 'golfers'}',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyJoinedSection(Set<String> excludeIds, [int? overrideCount]) {
    final userProvider = context.read<UserProvider>();
    final cachedRecent = userProvider.getCachedRecentlyJoinedUsers(
      limit: widget.recentlyJoinedLimit + excludeIds.length,
    );

    return StreamBuilder<List<UsersRecord>>(
      stream: userProvider.queryRecentlyJoinedUsers(
        limit: widget.recentlyJoinedLimit + excludeIds.length,
      ),
      initialData: cachedRecent,
      builder: (context, snapshot) {
        final recentlyJoined = snapshot.hasData
            ? snapshot.data!
                .where((user) =>
                    user.reference.id != widget.currentUserId &&
                    !excludeIds.contains(user.reference.id))
                .take(widget.recentlyJoinedLimit)
                .toList()
            : <UsersRecord>[];

        final count = overrideCount ?? recentlyJoined.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('RECENTLY JOINED', count, AppColors.gold),
            if (!snapshot.hasData)
              _buildSectionLoading()
            else if (recentlyJoined.isEmpty)
              _buildSectionEmpty('No new golfers to show.')
            else
              ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.xs,
                  0,
                  AppSpacing.xxl,
                ),
                primary: false,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: recentlyJoined.length,
                separatorBuilder: (_, __) => SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final user = recentlyJoined[index];
                  return widget.itemBuilder(context, user);
                },
              ),
          ],
        );
      },
    );
  }

  List<UsersRecord> _buildRecommendations(
    VibeProfile myVibes,
    List<UsersRecord> candidates,
  ) {
    final recommendations = <_ScoredUser>[];

    for (final user in candidates) {
      if (user.reference.id == widget.currentUserId) {
        continue;
      }
      if (user.vibeProfile.isEmpty) {
        continue;
      }
      try {
        final theirProfile = VibeProfile.fromFirestore(user.vibeProfile);
        final result = VibeMatcher.score(myVibes, theirProfile);
        if (result.recommendation == VibeRecommendation.notRecommended) {
          continue;
        }
        final score = result.finalScorePercent.round();
        recommendations.add(
          _ScoredUser(
            user: user,
            score: score,
            recommendation: result.recommendation,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    recommendations.sort((a, b) {
      final rankA = recommendationRank(a.recommendation);
      final rankB = recommendationRank(b.recommendation);
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.user.displayName.compareTo(b.user.displayName);
    });

    if (recommendations.length > widget.recommendedLimit) {
      return recommendations
          .sublist(0, widget.recommendedLimit)
          .map((s) => s.user)
          .toList();
    }
    return recommendations.map((s) => s.user).toList();
  }

  Widget _buildSectionLoading() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        children: [
          FriendCardSkeleton(),
          FriendCardSkeleton(),
          FriendCardSkeleton(),
        ],
      ),
    );
  }

  Widget _buildSectionEmpty(String message) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.stone.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _ScoredUser {
  const _ScoredUser({
    required this.user,
    required this.score,
    required this.recommendation,
  });

  final UsersRecord user;
  final int score;
  final VibeRecommendation recommendation;
}
