import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/friends/components/friend_card_skeleton.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section A: Recommended for you (VIBE-based)
        _buildRecommendedSection(),

        SizedBox(height: AppSpacing.lg),

        // Section B: Recently joined
        _buildRecentlyJoinedSection(),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            'RECOMMENDED FOR YOU',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.sunsetGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        FutureBuilder<VibeProfile>(
          future: _myVibesFuture,
          builder: (context, vibeSnapshot) {
            if (vibeSnapshot.hasError || !vibeSnapshot.hasData) {
              return _buildSectionEmpty(
                'Complete your VIBE profile to see personalized matches.',
              );
            }

            return StreamBuilder<List<UsersRecord>>(
              stream: queryUsersRecord(
                queryBuilder: (users) => users.limit(widget.candidateLimit),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildSectionLoading();
                }

                final recommendations = _buildRecommendations(
                  vibeSnapshot.data!,
                  snapshot.data!,
                );

                if (recommendations.isEmpty) {
                  return _buildSectionEmpty(
                    'No VIBE matches available yet.',
                  );
                }

                return ListView.separated(
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
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyJoinedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            'RECENTLY JOINED',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.fairway,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        FutureBuilder<VibeProfile>(
          future: _myVibesFuture,
          builder: (context, vibeSnapshot) {
            // Get recommended user IDs for deduplication
            final recommendedIds = <String>{};
            if (vibeSnapshot.hasData) {
              return StreamBuilder<List<UsersRecord>>(
                stream: queryUsersRecord(
                  queryBuilder: (users) => users.limit(widget.candidateLimit),
                ),
                builder: (context, candidatesSnapshot) {
                  if (candidatesSnapshot.hasData) {
                    final recs = _buildRecommendations(
                      vibeSnapshot.data!,
                      candidatesSnapshot.data!,
                    );
                    recommendedIds.addAll(recs.map((u) => u.reference.id));
                  }

                  return _buildRecentlyJoinedList(recommendedIds);
                },
              );
            }

            return _buildRecentlyJoinedList(recommendedIds);
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyJoinedList(Set<String> excludeIds) {
    return StreamBuilder<List<UsersRecord>>(
      stream: queryUsersRecord(
        queryBuilder: (users) => users
            .orderBy('created_time', descending: true)
            .limit(widget.recentlyJoinedLimit + excludeIds.length),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSectionLoading();
        }

        final recentlyJoined = snapshot.data!
            .where((user) =>
                user.reference.id != widget.currentUserId &&
                !excludeIds.contains(user.reference.id))
            .take(widget.recentlyJoinedLimit)
            .toList();

        if (recentlyJoined.isEmpty) {
          return _buildSectionEmpty(
            'No new golfers to show.',
          );
        }

        return ListView.separated(
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
        if (!result.isRecommended) {
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
      final rankA = _recommendationRank(a.recommendation);
      final rankB = _recommendationRank(b.recommendation);
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
          color: AppColors.stone.withOpacity(0.7),
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
  final dynamic recommendation;
}

int _recommendationRank(dynamic recommendation) {
  final recStr = recommendation.toString();
  if (recStr.contains('recommended')) return 0;
  if (recStr.contains('caution')) return 1;
  return 2;
}
