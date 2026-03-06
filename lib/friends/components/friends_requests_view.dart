import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/providers/profile_provider.dart';
import '/friends/components/premium_friend_card.dart';
import '/friends/components/empty_state.dart';
import '/friends/components/friend_card_skeleton.dart';
import '/friends/components/golfer_segmented_control.dart';
import '/friends/tab_friends/tab_friends_controller.dart';
import '/utils/app_util.dart';

/// View component for the friend requests tab.
///
/// Displays incoming friend requests with accept/deny actions.
class FriendsRequestsView extends StatelessWidget {
  const FriendsRequestsView({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final TabFriendsController controller;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('requests_view'),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.navy,
        backgroundColor: AppColors.pure,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AuthUserStreamWidget(
            builder: (context) {
              final friendRequestList =
                  (currentUserDocument?.friendRequests.toList() ?? []).toList();

              // PERFORMANCE FIX: Batch-warm profiles
              final requestUids =
                  friendRequestList.map((ref) => ref.id).toSet();
              if (requestUids.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context.read<ProfileProvider>().warmProfiles(requestUids);
                });
              }

              if (friendRequestList.isEmpty) {
                return FriendsEmptyState(
                  key: const ValueKey('empty_requests_state'),
                  type: FriendsEmptyStateType.noFriendRequests,
                  onActionPressed: () {
                    controller.setSegment(GolferSegment.discover);
                  },
                );
              }

              return ListView.separated(
                key: ValueKey('requests_list_${friendRequestList.length}'),
                padding: EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxl),
                primary: false,
                shrinkWrap: true,
                itemCount: friendRequestList.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final requestRef = friendRequestList[index];
                  return _RequestListItem(
                    key: ValueKey(requestRef.id),
                    requestRef: requestRef,
                    index: index,
                    controller: controller,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Individual request list item with profile loading.
class _RequestListItem extends StatelessWidget {
  const _RequestListItem({
    super.key,
    required this.requestRef,
    required this.index,
    required this.controller,
  });

  final DocumentReference requestRef;
  final int index;
  final TabFriendsController controller;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final user = profileProvider.getCachedProfile(requestRef.id);

        if (user == null) {
          return const FriendCardSkeleton();
        }

        // Filter by search term
        if (!controller.matchesSearch(user)) {
          return const SizedBox.shrink();
        }

        return PremiumFriendCard(
          key: ValueKey('request_${user.reference.id}'),
          user: user,
          currentUser: currentUserDocument,
          cardIndex: index,
          messageLabel: '+Add',
          messageIcon: AppPhosphorIcons.addPlayer,
          messageIsPrimary: true,
          onViewProfile: () {
            context.pushProfileUser(
              userRef: user.reference,
              transition: TransitionStandards.noTransition,
            );
          },
          onMessage: () async {
            await controller.acceptFriendRequest(context, user);
          },
          onAction: () async {
            await controller.denyFriendRequest(context, user);
          },
          actionLabel: 'Deny',
          actionIcon: AppPhosphorIcons.close,
          actionVariant: ActionButtonVariant.muted,
          showActionButton: true,
        );
      },
    );
  }
}
