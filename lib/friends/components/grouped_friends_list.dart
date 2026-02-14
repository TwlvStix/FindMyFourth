import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/friends/components/premium_friend_card.dart';
import '/friends/components/friend_section_header.dart';
import '/friends/components/swipeable_friend_card.dart';
import '/providers/profile_provider.dart';

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
  bool allFriendsCollapsed = false;
  bool favoritesCollapsed = false;
  bool _profilesWarmed = false;

  @override
  void initState() {
    super.initState();
    // Warm profiles on init (fire-and-forget batch prefetch)
    _warmFriendProfiles();
  }

  @override
  void didUpdateWidget(GroupedFriendsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-warm if friend list changed
    if (!setEquals(
        oldWidget.friendRefs.map((r) => r.id).toSet(),
        widget.friendRefs.map((r) => r.id).toSet())) {
      _profilesWarmed = false;
      _warmFriendProfiles();
    }
  }

  /// PERFORMANCE FIX #7: Batch-warm friend profiles to avoid N+1 pattern
  ///
  /// This replaces the previous approach of creating N streams (one per friend)
  /// with a single batch prefetch that fetches profiles in chunks of 10.
  void _warmFriendProfiles() {
    if (_profilesWarmed) return;

    final friendUids = widget.friendRefs.map((ref) => ref.id).toSet();
    if (friendUids.isEmpty) return;

    _profilesWarmed = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().warmProfiles(friendUids);
    });
  }

  @override
  Widget build(BuildContext context) {
    // PERFORMANCE FIX #7: Read friends from cache instead of creating N streams
    // Profiles were batch-warmed in initState via ProfileProvider.warmProfiles()
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        // Read all friends from cache
        final allFriends = widget.friendRefs
            .map((ref) => profileProvider.getCachedProfile(ref.id))
            .whereType<UsersRecord>()
            .toList();

        // Show loading if profiles aren't cached yet
        if (allFriends.isEmpty && widget.friendRefs.isNotEmpty) {
          return Center(
            child: SpinKitWanderingCubes(
              color: AppColors.fairway,
              size: 50.0,
            ),
          );
        }

        // Group friends
        final favorites = allFriends
            .where((u) => widget.favoriteFriends.contains(u.reference.id))
            .toList();

        final otherFriends = allFriends
            .where((u) => !widget.favoriteFriends.contains(u.reference.id))
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
}
