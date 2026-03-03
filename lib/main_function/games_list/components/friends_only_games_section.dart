import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/components/friends_only_card_selector.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart';
import '/models/game.dart';

/// Builds the Friends-Only Games section slivers (header + list).
///
/// Returns a list of slivers to spread into a CustomScrollView.
class FriendsOnlyGamesSectionBuilder {
  const FriendsOnlyGamesSectionBuilder({
    required this.lockedGames,
    required this.currentUserReference,
    required this.getCancelledHandling,
    required this.onCancelledGameTap,
    required this.onFriendsOnlyTap,
    required this.onSendFriendRequest,
    required this.onToggleVisibility,
    required this.hideFriendsOnlyGames,
  });

  final List<Game> lockedGames;
  final DocumentReference? currentUserReference;
  final CancelledGameHandling? Function(Game game) getCancelledHandling;
  final Future<void> Function(Game game) onCancelledGameTap;
  final Future<void> Function() onFriendsOnlyTap;
  final Future<void> Function(BuildContext context, DocumentReference hostRef)
      onSendFriendRequest;
  final VoidCallback onToggleVisibility;
  final bool hideFriendsOnlyGames;

  /// Builds and returns the slivers for the Friends-Only Games section.
  List<Widget> build(BuildContext context) {
    if (lockedGames.isEmpty) return const [];

    return [
      // Section header
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    'Friends-Only Games',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xxs),
                  AppIcon(
                    icon: AppPhosphorIcons.lock,
                    size: AppIconSize.xs,
                    color: AppColors.textMuted,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggleVisibility,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text(
                        hideFriendsOnlyGames ? 'Show' : 'Hide',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                'Become friends with the host to join.',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      // Game list (only if not hidden)
      // Uses FriendsOnlyCardSelector for fine-grained rebuilds per card
      if (!hideFriendsOnlyGames)
        SliverPadding(
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: MediaQuery.of(context).padding.bottom + 128.0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final game = lockedGames[index];
                final isLast = index == lockedGames.length - 1;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0.0 : AppSpacing.sm,
                  ),
                  child: FriendsOnlyCardSelector(
                    game: game,
                    currentUserReference: currentUserReference,
                    getCancelledHandling: getCancelledHandling,
                    onCancelledGameTap: onCancelledGameTap,
                    onFriendsOnlyTap: onFriendsOnlyTap,
                    onSendFriendRequest: onSendFriendRequest,
                    animationIndex: index,
                    staggerDelay: Duration(milliseconds: 24 * index),
                    isLast: isLast,
                  ),
                );
              },
              childCount: lockedGames.length,
            ),
          ),
        ),
    ];
  }
}
