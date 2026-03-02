import 'dart:async';
import '/core/utils/state_update.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/utils/app_util.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';
import '/providers/profile_provider.dart';
import '/friends/components/premium_friend_card.dart';
import '/friends/components/empty_state.dart';
import '/friends/components/golfer_search_section.dart';
import '/friends/components/grouped_friends_list.dart';
import '/friends/components/friend_filter_bottom_sheet.dart';
import '/friends/components/friend_card_skeleton.dart';
import '/friends/components/golfer_search_bar.dart';
import '/friends/components/golfer_segmented_control.dart';
import '/friends/components/section_label_row.dart';

class TabFriendsWidget extends StatefulWidget {
  const TabFriendsWidget({super.key, this.initialSegment});

  /// Optional initial segment to show when the screen opens.
  /// Used for deep linking from notifications (e.g., 'requests' or 'friends').
  final String? initialSegment;

  static String routeName = 'Tab_Friends';
  static String routePath = '/tabFriends';

  @override
  State<TabFriendsWidget> createState() => _TabFriendsWidgetState();
}

class _TabFriendsWidgetState extends State<TabFriendsWidget> {
  // ═══════════════════════════════════════════════════════════════════════════
  // SEGMENT CONTROL STATE
  // ═══════════════════════════════════════════════════════════════════════════
  GolferSegment _currentSegment = GolferSegment.discover;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH STATE (persistent across all segments)
  // ═══════════════════════════════════════════════════════════════════════════
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchTerm = '';
  Timer? _debounceTimer;

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        updateState(this, () => _searchTerm = value.trim().toLowerCase());
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY STATE (preserved for compatibility)
  // ═══════════════════════════════════════════════════════════════════════════
  List<DocumentReference> friendList = [];
  void addToFriendList(DocumentReference item) => friendList.add(item);
  void removeFromFriendList(DocumentReference item) => friendList.remove(item);
  void removeAtIndexFromFriendList(int index) => friendList.removeAt(index);
  void insertAtIndexInFriendList(int index, DocumentReference item) =>
      friendList.insert(index, item);
  void updateFriendListAtIndex(
          int index, DocumentReference Function(DocumentReference) updateFn) =>
      friendList[index] = updateFn(friendList[index]);

  // Favorite friends tracking
  Set<String> favoriteFriends = {};
  void toggleFavorite(String friendId) {
    if (mounted) {
      updateState(this, () {
        if (favoriteFriends.contains(friendId)) {
          favoriteFriends.remove(friendId);
        } else {
          favoriteFriends.add(friendId);
        }
      });
    }
  }

  // Section collapse tracking
  bool allFriendsCollapsed = false;

  // Refresh tracking
  bool isRefreshing = false;

  // Filter tracking
  FriendFilters friendFilters = FriendFilters();

  // Optimistic friends list for immediate UI updates
  List<DocumentReference>? _optimisticFriendsList;

  Future<void> _showFilterBottomSheet() async {
    final topPadding = MediaQuery.of(context).padding.top;
    final result = await showModalBottomSheet<FriendFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FriendFilterBottomSheet(
        currentFilters: friendFilters,
        topPadding: topPadding,
      ),
    );

    if (result != null && mounted) {
      updateState(this, () {
        friendFilters = result;
      });
    }
  }

  Future<void> _refreshSearchTab() async {
    if (mounted) {
      updateState(this, () => isRefreshing = true);
    }
    // Wait a bit to simulate refresh
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      updateState(this, () => isRefreshing = false);
    }
  }

  Future<void> _refreshRequestsTab() async {
    if (mounted) {
      updateState(this, () => isRefreshing = true);
    }
    // Force refresh of auth user stream
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      updateState(this, () => isRefreshing = false);
    }
  }

  Future<void> _refreshFriendsTab() async {
    if (mounted) {
      updateState(this, () => isRefreshing = true);
    }
    // Force refresh of auth user stream
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      updateState(this, () => isRefreshing = false);
    }
  }

  Future<void> _openDirectChat(UsersRecord user) async {
    final currentUserId = currentUserUid;
    if (currentUserId.isEmpty) {
      if (mounted) {
        showSnackbar(context, 'Please sign in to chat.');
      }
      return;
    }
    final otherUserId = user.reference.id;
    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserId,
            otherUid: otherUserId,
          );
      if (!mounted) return;
      context.pushChatDetails(
        chatId: chatRef.id,
        transition: TransitionStandards.noTransition,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      if (mounted) {
        showSnackbar(context, 'Unable to start chat. Please try again.');
      }
    }
  }

  Future<void> _removeFriend(UsersRecord user) async {
    try {
      // Optimistically update local state for immediate UI feedback
      // Use existing optimistic state if available, otherwise use server state
      updateState(this, () {
        final currentList =
            _optimisticFriendsList ?? (currentUserDocument?.friends ?? []);
        _optimisticFriendsList =
            currentList.where((ref) => ref.id != user.reference.id).toList();
      });

      await context.read<UserProvider>().removeFriend(user.reference);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend removed',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
          duration: Duration(milliseconds: 1500),
          backgroundColor: AppColors.navyDark,
        ),
      );

      // Keep optimistic state until Firestore stream updates or user navigates away
      // The state will be cleared naturally when the widget rebuilds with updated data
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        updateState(this, () {
          _optimisticFriendsList = null;
        });
      }

      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to remove friend. Please try again.');
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Apply initial segment from deep link if provided
    if (widget.initialSegment != null) {
      switch (widget.initialSegment) {
        case 'requests':
          _currentSegment = GolferSegment.requests;
          break;
        case 'friends':
          _currentSegment = GolferSegment.friends;
          break;
        case 'discover':
        default:
          _currentSegment = GolferSegment.discover;
          break;
      }
    }

    // Search controller listener
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS FOR SECTION LABELS
  // ═══════════════════════════════════════════════════════════════════════════
  String _getSectionLabel() {
    switch (_currentSegment) {
      case GolferSegment.discover:
        if (_searchTerm.isNotEmpty) {
          return "Results for '$_searchTerm'";
        }
        return 'Recommended for you';
      case GolferSegment.requests:
        return 'Pending requests';
      case GolferSegment.friends:
        return 'Your circle';
    }
  }

  bool _matchesSearch(UsersRecord user) {
    if (_searchTerm.isEmpty) return true;
    return user.displayName.toLowerCase().contains(_searchTerm) ||
        user.firstName.toLowerCase().contains(_searchTerm) ||
        user.lastName.toLowerCase().contains(_searchTerm);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════════════
                // HEADER ROW: Title + Settings Icon
                // ═══════════════════════════════════════════════════════════════
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    'Golfers',
                    style: AppTypography.headlineMediumSans.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.md),

                // ═══════════════════════════════════════════════════════════════
                // PERSISTENT SEARCH BAR
                // ═══════════════════════════════════════════════════════════════
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: GolferSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onFilterPressed: _showFilterBottomSheet,
                    hasActiveFilters: friendFilters.hasActiveFilters,
                  ),
                ),

                SizedBox(height: AppSpacing.md),

                // ═══════════════════════════════════════════════════════════════
                // SEGMENTED CONTROL
                // ═══════════════════════════════════════════════════════════════
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AuthUserStreamWidget(
                    builder: (context) {
                      final requestCount =
                          currentUserDocument?.friendRequests.length ?? 0;
                      return GolferSegmentedControl(
                        selectedSegment: _currentSegment,
                        onSegmentChanged: (segment) {
                          HapticFeedback.lightImpact();
                          FocusScope.of(context).unfocus();
                          updateState(this, () => _currentSegment = segment);
                        },
                        requestsBadgeCount: requestCount,
                      );
                    },
                  ),
                ),

                SizedBox(height: AppSpacing.md),

                // ═══════════════════════════════════════════════════════════════
                // SECTION LABEL ROW (hidden for Discover - DefaultExploreContent has its own)
                // ═══════════════════════════════════════════════════════════════
                if (_currentSegment != GolferSegment.discover) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AuthUserStreamWidget(
                      builder: (context) {
                        return SectionLabelRow(
                          label: _getSectionLabel(),
                          count: _getCountForCurrentSegment(),
                          countLabel: _currentSegment == GolferSegment.requests
                              ? 'requests'
                              : 'golfers',
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],

                // ═══════════════════════════════════════════════════════════════
                // SCROLLABLE CONTENT AREA
                // ═══════════════════════════════════════════════════════════════
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: _buildCurrentView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getCountForCurrentSegment() {
    switch (_currentSegment) {
      case GolferSegment.discover:
        return 0; // Will be updated by the view
      case GolferSegment.requests:
        return currentUserDocument?.friendRequests.length ?? 0;
      case GolferSegment.friends:
        final friendsList = _optimisticFriendsList ??
            (currentUserDocument?.friends.toList() ?? []);
        return friendsList.length;
    }
  }

  Widget _buildCurrentView() {
    switch (_currentSegment) {
      case GolferSegment.discover:
        return _buildDiscoverView();
      case GolferSegment.requests:
        return _buildRequestsView();
      case GolferSegment.friends:
        return _buildFriendsView();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVER VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDiscoverView() {
    return KeyedSubtree(
      key: const ValueKey('discover_view'),
      child: RefreshIndicator(
        onRefresh: _refreshSearchTab,
        color: AppColors.navy,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: GolferSearchSection(
            currentUserId: currentUserUid,
            friendFilters: friendFilters,
            showDefaultsWhenBelowThreshold: true,
            searchDebounce: const Duration(milliseconds: 300),
            externalSearchTerm: _searchTerm,
            hideInternalSearchBar: true,
            itemBuilder: (context, listViewUsersRecord) {
              return AuthUserStreamWidget(
                builder: (context) {
                  // Use context.select to minimize rebuilds - only rebuilds when
                  // this specific user's pending status changes
                  final hasPendingOutgoingFromProvider =
                      context.select<UserProvider, bool>(
                    (p) => p.hasPendingOutgoingRequest(listViewUsersRecord.uid),
                  );

                  final isFriend = (currentUserDocument?.friends.toList() ?? [])
                      .contains(listViewUsersRecord.reference);
                  final isOutgoingPending = listViewUsersRecord.friendRequests
                          .contains(currentUserReference) ||
                      hasPendingOutgoingFromProvider;
                  final isIncomingPending =
                      (currentUserDocument?.friendRequests.toList() ?? [])
                          .contains(listViewUsersRecord.reference);
                  final hasPending = isOutgoingPending || isIncomingPending;

                  String actionLabel;
                  PhosphorIconData actionIcon;
                  bool showActionButton;

                  if (isFriend) {
                    actionLabel = 'Friends';
                    actionIcon = AppPhosphorIcons.golfers;
                    showActionButton = true;
                  } else if (hasPending) {
                    actionLabel = isOutgoingPending ? 'Cancel' : 'Pending';
                    actionIcon = isOutgoingPending
                        ? AppPhosphorIcons.close
                        : AppPhosphorIcons.pending;
                    showActionButton = true;
                  } else {
                    actionLabel = 'Add';
                    actionIcon = AppPhosphorIcons.addPlayer;
                    showActionButton = true;
                  }

                  return PremiumFriendCard(
                    user: listViewUsersRecord,
                    currentUser: currentUserDocument,
                    onViewProfile: () {
                      context.pushProfileUser(
                        userRef: listViewUsersRecord.reference,
                        transition: TransitionStandards.noTransition,
                      );
                    },
                    onMessage: () async {
                      await _openDirectChat(listViewUsersRecord);
                    },
                    onAction: isFriend
                        ? null
                        : hasPending
                            ? (isOutgoingPending
                                ? () async {
                                    await _cancelFriendRequest(
                                        listViewUsersRecord);
                                  }
                                : () async {})
                            : () async {
                                await _sendFriendRequest(listViewUsersRecord);
                              },
                    actionLabel: actionLabel,
                    actionIcon: actionIcon,
                    actionColor:
                        isOutgoingPending ? AppColors.stone : AppColors.navy,
                    showActionButton: showActionButton,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _cancelFriendRequest(UsersRecord user) async {
    try {
      await context.read<UserProvider>().cancelFriendRequest(user.reference);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request cancelled.',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: AppColors.navyDark,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to cancel request. Please try again.');
    }
  }

  Future<void> _sendFriendRequest(UsersRecord user) async {
    try {
      await context.read<UserProvider>().sendFriendRequest(user.reference);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request sent!',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: AppColors.navyDark,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to send request. Please try again.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REQUESTS VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRequestsView() {
    return KeyedSubtree(
      key: const ValueKey('requests_view'),
      child: RefreshIndicator(
        onRefresh: _refreshRequestsTab,
        color: AppColors.navy,
        backgroundColor: Colors.white,
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

              // Filter by search term
              if (friendRequestList.isEmpty) {
                return FriendsEmptyState(
                  key: const ValueKey('empty_requests_state'),
                  type: FriendsEmptyStateType.noFriendRequests,
                  onActionPressed: () {
                    updateState(
                        this, () => _currentSegment = GolferSegment.discover);
                  },
                );
              }

              return ListView.separated(
                key: ValueKey('requests_list_${friendRequestList.length}'),
                padding: EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxl),
                primary: false,
                shrinkWrap: true,
                itemCount: friendRequestList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final requestRef = friendRequestList[index];

                  return Consumer<ProfileProvider>(
                    key: ValueKey(requestRef.id),
                    builder: (context, profileProvider, _) {
                      final user =
                          profileProvider.getCachedProfile(requestRef.id);

                      if (user == null) {
                        return const FriendCardSkeleton();
                      }

                      // Filter by search term
                      if (!_matchesSearch(user)) {
                        return const SizedBox.shrink();
                      }

                      return PremiumFriendCard(
                        key: ValueKey('request_${user.reference.id}'),
                        user: user,
                        currentUser: currentUserDocument,
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
                          await _acceptFriendRequest(user);
                        },
                        onAction: () async {
                          await _denyFriendRequest(user);
                        },
                        actionLabel: 'Deny',
                        actionIcon: AppPhosphorIcons.close,
                        actionVariant: ActionButtonVariant.muted,
                        showActionButton: true,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _acceptFriendRequest(UsersRecord user) async {
    try {
      await context.read<UserProvider>().acceptFriendRequest(user.reference);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request accepted!',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: AppColors.navyDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to accept request. Please try again.');
    }
  }

  Future<void> _denyFriendRequest(UsersRecord user) async {
    try {
      await context.read<UserProvider>().rejectFriendRequest(user.reference);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request denied.',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.pure,
            ),
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: AppColors.navyDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to deny request. Please try again.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIENDS VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFriendsView() {
    return KeyedSubtree(
      key: const ValueKey('friends_view'),
      child: RefreshIndicator(
        onRefresh: _refreshFriendsTab,
        color: AppColors.navy,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AuthUserStreamWidget(
            builder: (context) {
              final serverFriendsList =
                  (currentUserDocument?.friends.toList() ?? []).toList();

              // Sync optimistic state with server
              if (_optimisticFriendsList != null) {
                final optimisticIds =
                    _optimisticFriendsList!.map((ref) => ref.id).toSet();
                final serverIds =
                    serverFriendsList.map((ref) => ref.id).toSet();

                if (optimisticIds.length == serverIds.length &&
                    optimisticIds.difference(serverIds).isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      updateState(this, () => _optimisticFriendsList = null);
                    }
                  });
                }
              }

              final friendsList = _optimisticFriendsList ?? serverFriendsList;

              if (friendsList.isEmpty) {
                return FriendsEmptyState(
                  type: FriendsEmptyStateType.noFriends,
                  onActionPressed: () {
                    updateState(
                        this, () => _currentSegment = GolferSegment.discover);
                  },
                );
              }

              return GroupedFriendsList(
                friendRefs: friendsList,
                favoriteFriends: favoriteFriends,
                currentUserHomeCourse: currentUserDocument?.homeCourse,
                currentUser: currentUserDocument,
                searchFilter: _searchTerm.isNotEmpty ? _searchTerm : null,
                onToggleFavorite: toggleFavorite,
                onViewProfile: (user) {
                  context.pushProfileUser(
                    userRef: user.reference,
                    transition: TransitionStandards.noTransition,
                  );
                },
                onMessage: _openDirectChat,
                onRemove: (user) async {
                  await _removeFriend(user);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
