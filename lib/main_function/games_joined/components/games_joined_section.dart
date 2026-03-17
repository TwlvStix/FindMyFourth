import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
import '/core/widgets/premium_section_header.dart';
import '/main_function/games_list/components/unified_game_card.dart';
import '/models/game.dart';

/// Reusable sliver section for My Games: a PremiumSectionHeader + list of game cards.
class GamesJoinedSection extends StatelessWidget {
  const GamesJoinedSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.games,
    required this.currentUserReference,
    this.showRematchActions = false,
    this.animationIndexOffset = 0,
  });

  final String title;
  final String? subtitle;
  final List<Game> games;
  final DocumentReference? currentUserReference;
  final bool showRematchActions;
  final int animationIndexOffset;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: PremiumSectionHeader(
              title: title,
              subtitle: subtitle,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: UnifiedGameCard(
                  game: games[index],
                  currentUserReference: currentUserReference,
                  showStatusBadge: true,
                  showRematchActions: showRematchActions,
                  animationIndex: animationIndexOffset + index,
                  onTap: showRematchActions ? () {} : null,
                ),
              );
            },
            childCount: games.length,
          ),
        ),
      ],
    );
  }
}
