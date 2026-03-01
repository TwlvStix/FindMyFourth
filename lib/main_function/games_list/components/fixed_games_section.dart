import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/main_function/games_list/components/premium_game_card.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/models/game.dart';

/// Builds the Fixed Games section slivers (header + list).
///
/// Returns a list of slivers to spread into a CustomScrollView.
class FixedGamesSectionBuilder {
  const FixedGamesSectionBuilder({
    required this.scheduledGames,
    required this.hasFlexibleGames,
    required this.hasLockedGames,
    required this.currentUserReference,
    required this.getCancelledHandling,
    required this.onCancelledGameTap,
    required this.onFriendsOnlyTap,
  });

  final List<Game> scheduledGames;
  final bool hasFlexibleGames;
  final bool hasLockedGames;
  final DocumentReference? currentUserReference;
  final CancelledGameHandling? Function(Game game) getCancelledHandling;
  final Future<void> Function(Game game) onCancelledGameTap;
  final Future<void> Function() onFriendsOnlyTap;

  /// Builds and returns the slivers for the Fixed Games section.
  List<Widget> build(BuildContext context) {
    if (scheduledGames.isEmpty) return const [];

    return [
      // Section header
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: hasFlexibleGames ? 0 : AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Fixed Games',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      // Game list
      SliverPadding(
        padding: EdgeInsets.only(
          top: 0,
          bottom: hasLockedGames
              ? AppSpacing.md
              : MediaQuery.of(context).padding.bottom + 128.0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final game = scheduledGames[index];
              final isLast = index == scheduledGames.length - 1;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0.0 : AppSpacing.sm,
                ),
                child: PremiumGameCard(
                  game: game,
                  currentUserReference: currentUserReference,
                  getCancelledHandling: getCancelledHandling,
                  onCancelledGameTap: onCancelledGameTap,
                  onFriendsOnlyTap: onFriendsOnlyTap,
                  animationIndex: index,
                  staggerDelay: Duration(milliseconds: 24 * index),
                ),
              );
            },
            childCount: scheduledGames.length,
          ),
        ),
      ),
    ];
  }
}
