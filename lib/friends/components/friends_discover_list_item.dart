import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/friends/components/premium_friend_card.dart';
import '/friends/tab_friends/tab_friends_controller.dart';
import '/providers/user_provider.dart';
import '/utils/app_util.dart';

/// Individual discover list item with friend status logic.
///
/// Displays a user card with appropriate action buttons based on
/// friendship status (add, cancel, pending, friends).
class FriendsDiscoverListItem extends StatelessWidget {
  const FriendsDiscoverListItem({
    super.key,
    required this.user,
    required this.cardIndex,
    required this.controller,
  });

  final UsersRecord user;
  final int cardIndex;
  final TabFriendsController controller;

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        final hasPendingOutgoingFromProvider =
            context.select<UserProvider, bool>(
          (p) => p.hasPendingOutgoingRequest(user.uid),
        );

        final isFriend = (currentUserDocument?.friends.toList() ?? [])
            .contains(user.reference);
        final isOutgoingPending =
            user.friendRequests.contains(currentUserReference) ||
                hasPendingOutgoingFromProvider;
        final isIncomingPending =
            (currentUserDocument?.friendRequests.toList() ?? [])
                .contains(user.reference);
        final hasPending = isOutgoingPending || isIncomingPending;

        String actionLabel;
        PhosphorIconData actionIcon;

        if (isFriend) {
          actionLabel = 'Friends';
          actionIcon = AppPhosphorIcons.golfers;
        } else if (hasPending) {
          actionLabel = isOutgoingPending ? 'Cancel' : 'Pending';
          actionIcon = isOutgoingPending
              ? AppPhosphorIcons.close
              : AppPhosphorIcons.pending;
        } else {
          actionLabel = 'Add';
          actionIcon = AppPhosphorIcons.addPlayer;
        }

        return PremiumFriendCard(
          user: user,
          currentUser: currentUserDocument,
          cardIndex: cardIndex,
          onViewProfile: () {
            context.pushProfileUser(
              userRef: user.reference,
              transition: TransitionStandards.noTransition,
            );
          },
          onMessage: () async {
            await controller.openDirectChat(context, user);
          },
          onAction: isFriend
              ? null
              : hasPending
                  ? (isOutgoingPending
                      ? () async {
                          await controller.cancelFriendRequest(context, user);
                        }
                      : () async {})
                  : () async {
                      await controller.sendFriendRequest(context, user);
                    },
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          actionColor: isOutgoingPending ? AppColors.stone : AppColors.navy,
          showActionButton: true,
        );
      },
    );
  }
}
