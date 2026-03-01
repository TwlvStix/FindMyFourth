import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/profile/profile_user/components/mutual_friends_action_card.dart';
import '/profile/profile_user/components/quick_action_card.dart';

class ProfileQuickActionsGrid extends StatelessWidget {
  const ProfileQuickActionsGrid({
    super.key,
    required this.isSelf,
    required this.mutualFriends,
    required this.mutualFriendsLoaded,
    required this.onMessageTap,
    required this.onMutualFriendsTap,
  });

  final bool isSelf;
  final List<UsersRecord> mutualFriends;
  final bool mutualFriendsLoaded;
  final VoidCallback onMessageTap;
  final VoidCallback onMutualFriendsTap;

  @override
  Widget build(BuildContext context) {
    if (isSelf) {
      return SizedBox.shrink();
    }

    final cards = <Widget>[
      Expanded(
        child: QuickActionCard(
          icon: AppPhosphorIcons.chat,
          label: 'Message',
          gradient: [AppColors.navyLight, AppColors.navy],
          onTap: onMessageTap,
        ),
      ),
      Expanded(
        child: MutualFriendsActionCard(
          friends: mutualFriends,
          loaded: mutualFriendsLoaded,
          onTap: onMutualFriendsTap,
        ),
      ),
    ];

    final spacedCards = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      if (i > 0) {
        spacedCards.add(SizedBox(width: AppSpacing.sm));
      }
      spacedCards.add(cards[i]);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(children: spacedCards),
    );
  }
}
