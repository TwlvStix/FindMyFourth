import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/animated_entrance.dart';
import '/utils/app_util.dart';
import '/main_function/games_list/components/premium_card_badge_row.dart';
import '/main_function/games_list/components/premium_card_course_section.dart';
import '/main_function/games_list/components/premium_card_datetime_section.dart';
import '/main_function/games_list/utils/cancelled_game_handler.dart'
    show CancelledGameHandling;
import '/models/game.dart';

/// Premium-styled game card for the games list with entrance animation.
class PremiumGameCard extends StatelessWidget {
  const PremiumGameCard({
    super.key,
    required this.game,
    required this.currentUserReference,
    this.isLocked = false,
    this.hasPendingFriendRequest = false,
    this.getCancelledHandling,
    this.onCancelledGameTap,
    this.onFriendsOnlyTap,
    this.onAddFriend,
    this.animationIndex = 0,
  });

  final Game game;
  final DocumentReference? currentUserReference;
  final bool isLocked;
  final bool hasPendingFriendRequest;
  final CancelledGameHandling? Function(Game game)? getCancelledHandling;
  final Future<void> Function(Game game)? onCancelledGameTap;
  final Future<void> Function()? onFriendsOnlyTap;
  final Future<void> Function()? onAddFriend;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntrance(
      animationIndex: animationIndex,
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isOwner =
        currentUserReference != null && game.userRef == currentUserReference;
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
    final isCancelled = game.status == 'cancelled';
    final isExpired = game.status == 'expired';
    final spotsLeft = game.maxPlayers -
        (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;

    return GestureDetector(
      onTap: () async {
        if (isLocked && !isCancelled) {
          await onFriendsOnlyTap?.call();
        } else if (isUserGame) {
          context.pushGameJoinedDetailed(gameRef: game.reference);
        } else {
          context.pushJoinGameDetailed(gameRef: game.reference);
        }
      },
      child: Opacity(
        opacity: isCancelled ? 0.65 : 1.0,
        child: Container(
          clipBehavior: Clip.antiAlias,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(
              color: AppColors.navyLight,
              width: 1.0,
            ),
            boxShadow: [AppElevation.card],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumCardBadgeRow(
                  game: game,
                  isLocked: isLocked,
                  isUserGame: isUserGame,
                  isCancelled: isCancelled,
                  isExpired: isExpired,
                  isOwner: isOwner,
                  hasPendingFriendRequest: hasPendingFriendRequest,
                  onAddFriend: onAddFriend,
                ),
                SizedBox(height: AppSpacing.md),
                PremiumCardCourseSection(
                  game: game,
                  isUserGame: isUserGame,
                  isLocked: isLocked,
                  ownerRef: game.userRef,
                ),
                SizedBox(height: AppSpacing.md),
                PremiumCardDateTimeSection(
                  game: game,
                  isUserGame: isUserGame,
                  isFull: isFull,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
