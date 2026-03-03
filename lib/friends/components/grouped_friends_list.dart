import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_empty_state.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/icon_size.dart';
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
  final String? searchFilter; // Optional search filter
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
    this.searchFilter,
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
  bool _isLoading = true;

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
      _isLoading = true;
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
    if (friendUids.isEmpty) {
      // No friends to warm - mark loading complete
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _profilesWarmed = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<ProfileProvider>().warmProfiles(friendUids);
      } finally {
        // Always mark loading complete, even if warming fails
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PERFORMANCE FIX #7: Read friends from cache instead of creating N streams
    // Profiles were batch-warmed in initState via ProfileProvider.warmProfiles()
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        // Read all friends from cache
        var allFriends = widget.friendRefs
            .map((ref) => profileProvider.getCachedProfile(ref.id))
            .whereType<UsersRecord>()
            .toList();

        // Show loading spinner while warming profiles
        if (_isLoading && allFriends.isEmpty && widget.friendRefs.isNotEmpty) {
          return Center(
            child: SpinKitWanderingCubes(
              color: AppColors.navy,
              size: 50.0,
            ),
          );
        }

        // Show empty state if loading finished but no profiles could be loaded
        // (e.g., friend references point to deleted/non-existent user documents)
        if (!_isLoading && allFriends.isEmpty && widget.friendRefs.isNotEmpty) {
          return AppEmptyState(
            icon: AppPhosphorIcons.users,
            title: 'Unable to load friends',
            message: 'Pull down to refresh',
          );
        }

        // Apply search filter if provided
        if (widget.searchFilter != null && widget.searchFilter!.isNotEmpty) {
          final searchTerm = widget.searchFilter!.toLowerCase();
          allFriends = allFriends.where((user) {
            return user.displayName.toLowerCase().contains(searchTerm) ||
                user.firstName.toLowerCase().contains(searchTerm) ||
                user.lastName.toLowerCase().contains(searchTerm);
          }).toList();
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
                    icon: AppPhosphorIcons.star,
                    title: 'Favorites',
                    count: favorites.length,
                    color: AppColors.gold,
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
      swipeRightIcon: AppPhosphorIcons.message,
      swipeLeftIcon: AppPhosphorIcons.removePlayer,
      swipeRightColor: AppColors.navy,
      swipeLeftColor: AppColors.stone,
      child: PremiumFriendCard(
        user: friend,
        currentUser: widget.currentUser,
        onViewProfile: () => widget.onViewProfile(friend),
        messageIsPrimary: true,
        onMessage: () => widget.onMessage(friend),
        showActionButton: false,
        showOverflowMenu: true,
        onOverflowAction: () => _showRemoveSheet(context, friend),
      ),
    );
  }

  void _showRemoveSheet(BuildContext context, UsersRecord friend) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RemoveFriendSheet(
        friend: friend,
        onRemove: () {
          Navigator.of(ctx).pop();
          widget.onRemove(friend);
        },
      ),
    );
  }
}

/// Bottom sheet for removing a friend with inline confirmation
class _RemoveFriendSheet extends StatefulWidget {
  final UsersRecord friend;
  final VoidCallback onRemove;

  const _RemoveFriendSheet({
    required this.friend,
    required this.onRemove,
  });

  @override
  State<_RemoveFriendSheet> createState() => _RemoveFriendSheetState();
}

class _RemoveFriendSheetState extends State<_RemoveFriendSheet> {
  bool _showConfirm = false;

  // Confirmation styling colors - using AppColors semantic tokens
  static Color get _confirmBg => AppColors.error.withValues(alpha: 0.06);
  static Color get _confirmBorder => AppColors.error.withValues(alpha: 0.12);
  static Color get _cancelBg => AppColors.whiteSubtle; // 5% white
  static Color get _cancelBorder => AppColors.glassSurface; // 10% white
  static Color get _removeBg => AppColors.error.withValues(alpha: 0.2);
  static Color get _removeBorder => AppColors.error.withValues(alpha: 0.3);
  static Color get _removeText => AppColors.errorHovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Animated content switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showConfirm
                ? _buildConfirmation()
                : _buildRemoveButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton() {
    return Material(
      key: const ValueKey('remove_button'),
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _showConfirm = true);
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: _removeBg,
            border: Border.all(color: _removeBorder, width: 1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: AppPhosphorIcons.removePlayer,
                size: AppIconSize.button,
                color: _removeText,
              ),
              AppSpacing.horizontalXsBox,
              Text(
                'Remove Friend',
                style: AppTypography.labelLarge.copyWith(
                  color: _removeText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final friendName = widget.friend.displayName.isNotEmpty
        ? widget.friend.displayName
        : 'this friend';

    return Container(
      key: const ValueKey('confirmation'),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: _confirmBg,
        border: Border.all(color: _confirmBorder, width: 1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirmation text
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              children: [
                const TextSpan(text: 'Remove '),
                TextSpan(
                  text: friendName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' from your circle?'),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xxs),

          // Subtitle
          Text(
            "You'll need to send a new request to reconnect.",
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
          AppSpacing.verticalMdBox,

          // Buttons row
          Row(
            children: [
              // Cancel button
              Expanded(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showConfirm = false);
                    },
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    child: Container(
                      padding: AppSpacing.verticalSm,
                      decoration: BoxDecoration(
                        color: _cancelBg,
                        border: Border.all(color: _cancelBorder, width: 1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.card),
                      ),
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.horizontalXsBox,

              // Remove button
              Expanded(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onRemove();
                    },
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    child: Container(
                      padding: AppSpacing.verticalSm,
                      decoration: BoxDecoration(
                        color: _removeBg,
                        border: Border.all(color: _removeBorder, width: 1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.card),
                      ),
                      child: Text(
                        'Remove',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                          color: _removeText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
