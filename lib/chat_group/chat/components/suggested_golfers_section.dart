import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';
import '/vibe/vibe_match_types.dart';
import '/vibe/vibe_recommendation_rank.dart';

class SuggestedGolfersSection extends StatefulWidget {
  const SuggestedGolfersSection({
    super.key,
    required this.currentUserId,
    required this.onGolferTap,
    this.maxSuggestions = 8,
    this.candidateLimit = 60,
  });

  final String currentUserId;
  final ValueChanged<UsersRecord> onGolferTap;
  final int maxSuggestions;
  final int candidateLimit;

  @override
  State<SuggestedGolfersSection> createState() =>
      _SuggestedGolfersSectionState();
}

class _SuggestedGolfersSectionState extends State<SuggestedGolfersSection> {
  final VibeRepository _vibeRepository = VibeRepository();
  late final Future<VibeProfile> _myVibesFuture;

  @override
  void initState() {
    super.initState();
    _myVibesFuture = _vibeRepository.getMyVibesCached();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Text(
              'Suggested Golfers',
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          FutureBuilder<VibeProfile>(
            future: _myVibesFuture,
            builder: (context, vibeSnapshot) {
              if (vibeSnapshot.hasError) {
                return _buildEmptyState(
                  'Complete your VIBE profile to see matches.',
                );
              }
              if (!vibeSnapshot.hasData) {
                return _buildLoading();
              }

              return StreamBuilder<List<UsersRecord>>(
                stream: queryUsersRecord(
                  queryBuilder: (users) => users.limit(widget.candidateLimit),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildLoading();
                  }

                  final suggestions = _buildSuggestions(
                    vibeSnapshot.data!,
                    snapshot.data!,
                  );

                  if (suggestions.isEmpty) {
                    return _buildEmptyState(
                      'No VIBE matches yet.',
                    );
                  }

                  return SizedBox(
                    height: 96,
                    child: ListView.separated(
                      padding: EdgeInsets.only(right: AppSpacing.md),
                      scrollDirection: Axis.horizontal,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return _SuggestedGolferCard(
                          user: suggestion.user,
                          score: suggestion.score,
                          recommendation: suggestion.recommendation,
                          onTap: () => widget.onGolferTap(suggestion.user),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<_SuggestedGolfer> _buildSuggestions(
    VibeProfile myVibes,
    List<UsersRecord> candidates,
  ) {
    final suggestions = <_SuggestedGolfer>[];

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
        suggestions.add(
          _SuggestedGolfer(
            user: user,
            score: score,
            recommendation: result.recommendation,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    suggestions.sort((a, b) {
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

    if (suggestions.length > widget.maxSuggestions) {
      return suggestions.sublist(0, widget.maxSuggestions);
    }
    return suggestions;
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 96,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: AppColors.gold,
            strokeWidth: 2.2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.glassTextSecondary,
        ),
      ),
    );
  }
}

class _SuggestedGolfer {
  const _SuggestedGolfer({
    required this.user,
    required this.score,
    required this.recommendation,
  });

  final UsersRecord user;
  final int score;
  final VibeRecommendation recommendation;
}

class _SuggestedGolferCard extends StatelessWidget {
  const _SuggestedGolferCard({
    required this.user,
    required this.score,
    required this.recommendation,
    required this.onTap,
  });

  final UsersRecord user;
  final int score;
  final VibeRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(user);
    final photoUrl = user.photoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha:0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.glassSurface,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(photoUrl: photoUrl),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: recommendation == VibeRecommendation.recommended
                          ? LinearGradient(
                              colors: [AppColors.gold, AppColors.goldLight],
                            )
                          : null,
                      color: recommendation == VibeRecommendation.caution
                          ? AppColors.stone.withValues(alpha:0.3)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VIBE $score%',
                      style: AppTypography.text11.copyWith(
                        color: recommendation == VibeRecommendation.recommended
                            ? Colors.white
                            : AppColors.glassTextSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.glassTextTertiary,
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(UsersRecord user) {
    final displayName = user.displayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final combined = '${user.firstName} ${user.lastName}'.trim();
    return combined.isNotEmpty ? combined : 'Golfer';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyLight, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                cacheWidth: 88,
                cacheHeight: 88,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }
}
