import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/friends/components/premium_friend_card.dart';
import '/friends/components/friend_section_header.dart';
import '/friends/components/swipeable_friend_card.dart';
import '/providers/user_provider.dart';

/// Grouped friends list that organizes friends into sections
class GroupedFriendsList extends StatefulWidget {
  final List<DocumentReference> friendRefs;
  final Set<String> favoriteFriends;
  final String? currentUserHomeCourse;
  final UsersRecord? currentUser; // For vibe matching
  final Function(String) onToggleFavorite;
  final Function(UsersRecord) onViewProfile;
  final Function(UsersRecord) onMessage;
  final Function(UsersRecord) onRemove;

  const GroupedFriendsList({
    super.key,
    required this.friendRefs,
    required this.favoriteFriends,
    this.currentUserHomeCourse,
    this.currentUser,
    required this.onToggleFavorite,
    required this.onViewProfile,
    required this.onMessage,
    required this.onRemove,
  });

  @override
  State<GroupedFriendsList> createState() => _GroupedFriendsListState();
}

class _GroupedFriendsListState extends State<GroupedFriendsList> {
  bool clubMembersCollapsed = false;
  bool allFriendsCollapsed = false;
  bool favoritesCollapsed = false;

  @override
  Widget build(BuildContext context) {
    // Get cached friends for initialData
    final userProvider = context.read<UserProvider>();
    final cachedFriends = widget.friendRefs
        .map((ref) => userProvider.getCachedUser(ref.id))
        .where((user) => user != null)
        .cast<UsersRecord>()
        .toList();

    return StreamBuilder<List<UsersRecord>>(
      stream: _getFriendsStream(context),
      initialData: cachedFriends.isEmpty ? null : cachedFriends,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SpinKitWanderingCubes(
              color: AppColors.fairway,
              size: 50.0,
            ),
          );
        }

        final allFriends = snapshot.data!;

        // Group friends
        final favorites = allFriends
            .where((u) => widget.favoriteFriends.contains(u.reference.id))
            .toList();

        final clubMembers = allFriends
            .where((u) =>
                !widget.favoriteFriends.contains(u.reference.id) &&
                widget.currentUserHomeCourse != null &&
                widget.currentUserHomeCourse!.isNotEmpty &&
                u.homeCourse.isNotEmpty &&
                u.homeCourse == widget.currentUserHomeCourse)
            .toList();

        final otherFriends = allFriends
            .where((u) =>
                !widget.favoriteFriends.contains(u.reference.id) &&
                (widget.currentUserHomeCourse == null ||
                    widget.currentUserHomeCourse!.isEmpty ||
                    u.homeCourse.isEmpty ||
                    u.homeCourse != widget.currentUserHomeCourse))
            .toList();

        return Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xxl,
          ),
          child: Column(
            children: [
              // Favorites Section
              if (favorites.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: FriendSectionHeader(
                    icon: Icons.star_rounded,
                    title: 'Favorites',
                    count: favorites.length,
                    color: AppColors.sunsetGold,
                    isCollapsed: favoritesCollapsed,
                    onTap: () {
                      setState(() => favoritesCollapsed = !favoritesCollapsed);
                    },
                  ),
                ),
                if (!favoritesCollapsed)
                  ...favorites.map((friend) => _buildFriendCard(friend, true)),
              ],

              // Club Members Section
              if (clubMembers.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: FriendSectionHeader(
                    icon: Icons.golf_course_rounded,
                    title: 'Club Members',
                    count: clubMembers.length,
                    color: AppColors.fairway,
                    isCollapsed: clubMembersCollapsed,
                    onTap: () {
                      setState(
                          () => clubMembersCollapsed = !clubMembersCollapsed);
                    },
                  ),
                ),
                if (!clubMembersCollapsed)
                  ...clubMembers.map((friend) => _buildFriendCard(friend, false)),
              ],

              // Other friends (no section header since it's redundant on Friends tab)
              if (otherFriends.isNotEmpty) ...[
                ...otherFriends.map((friend) => _buildFriendCard(friend, false)),
              ],

              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(UsersRecord friend, bool isFavorite) {
    return SwipeableFriendCard(
      key: ValueKey(friend.reference.id),
      friendId: friend.reference.id,
      onSwipeRight: () => widget.onMessage(friend),
      onSwipeLeft: () => widget.onRemove(friend),
      swipeRightLabel: 'Message',
      swipeLeftLabel: 'Remove',
      swipeRightIcon: Icons.message_rounded,
      swipeLeftIcon: Icons.person_remove_rounded,
      swipeRightColor: AppColors.fairway,
      swipeLeftColor: AppColors.stone,
      child: PremiumFriendCard(
        user: friend,
        currentUser: widget.currentUser,
        onViewProfile: () => widget.onViewProfile(friend),
        onMessage: () => widget.onMessage(friend),
        onAction: () => widget.onRemove(friend),
        actionLabel: 'Remove',
        actionIcon: Icons.person_remove_rounded,
        actionColor: AppColors.stone,
        showActionButton: true,
      ),
    );
  }

  Stream<List<UsersRecord>> _getFriendsStream(BuildContext context) {
    if (widget.friendRefs.isEmpty) {
      return Stream.value([]);
    }

    final userProvider = context.read<UserProvider>();

    // Create streams for each friend reference using cached watchUser
    final streams =
        widget.friendRefs.map((ref) => userProvider.watchUser(ref).where((user) => user != null).cast<UsersRecord>()).toList();

    // Combine all streams
    return _combineStreams(streams);
  }

  Stream<List<UsersRecord>> _combineStreams(
      List<Stream<UsersRecord>> streams) {
    if (streams.isEmpty) {
      return Stream.value(const <UsersRecord>[]);
    }

    // Debug log to confirm reactive stream usage (no polling)
    if (kDebugMode) {
      debugPrint('[GroupedFriendsList] Using reactive stream combiner (no polling) for ${streams.length} friend streams');
    }

    // Use RxDart's combineLatestList for reactive, non-polling stream combination
    // This emits whenever any friend's user record updates
    return Rx.combineLatestList<UsersRecord>(streams);
  }
}
