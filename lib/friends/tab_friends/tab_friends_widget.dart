import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/button_tabbar.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class TabFriendsWidget extends StatefulWidget {
  const TabFriendsWidget({super.key});

  static String routeName = 'Tab_Friends';
  static String routePath = '/tabFriends';

  @override
  State<TabFriendsWidget> createState() => _TabFriendsWidgetState();
}

class _TabFriendsWidgetState extends State<TabFriendsWidget>
    with TickerProviderStateMixin {
  List<String> reqUserList = [];
  void addToReqUserList(String item) => reqUserList.add(item);
  void removeFromReqUserList(String item) => reqUserList.remove(item);
  void removeAtIndexFromReqUserList(int index) => reqUserList.removeAt(index);
  void insertAtIndexInReqUserList(int index, String item) =>
      reqUserList.insert(index, item);
  void updateReqUserListAtIndex(int index, Function(String) updateFn) =>
      reqUserList[index] = updateFn(reqUserList[index]);

  List<DocumentReference> friendList = [];
  void addToFriendList(DocumentReference item) => friendList.add(item);
  void removeFromFriendList(DocumentReference item) => friendList.remove(item);
  void removeAtIndexFromFriendList(int index) => friendList.removeAt(index);
  void insertAtIndexInFriendList(int index, DocumentReference item) =>
      friendList.insert(index, item);
  void updateFriendListAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      friendList[index] = updateFn(friendList[index]);

  // Favorite friends tracking
  Set<String> favoriteFriends = {};
  void toggleFavorite(String friendId) {
    if (mounted) {
      setState(() {
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
    final result = await showModalBottomSheet<FriendFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FriendFilterBottomSheet(
        currentFilters: friendFilters,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        friendFilters = result;
      });
    }
  }

  Future<void> _refreshSearchTab() async {
    if (mounted) {
      setState(() => isRefreshing = true);
    }
    // Wait a bit to simulate refresh
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => isRefreshing = false);
    }
  }

  Future<void> _refreshRequestsTab() async {
    if (mounted) {
      setState(() => isRefreshing = true);
    }
    // Force refresh of auth user stream
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => isRefreshing = false);
    }
  }

  Future<void> _refreshFriendsTab() async {
    if (mounted) {
      setState(() => isRefreshing = true);
    }
    // Force refresh of auth user stream
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => isRefreshing = false);
    }
  }

  TabController? tabBarController;
  int get tabBarCurrentIndex => tabBarController != null
      ? tabBarController!.index
      : 0;
  int get tabBarPreviousIndex => tabBarController != null
      ? tabBarController!.previousIndex
      : 0;

  Future<void> _openDirectChat(UsersRecord user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        showSnackbar(context, 'Please sign in to chat.');
      }
      return;
    }
    final currentUserId = currentUser.uid;
    final otherUserId = user.reference.id;
    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserId,
            otherUid: otherUserId,
          );
      context.pushNamed(
        'ChatDetails',
        pathParameters: {
          'chatId': chatRef.id,
        },
      );
    } catch (error, stackTrace) {
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
      setState(() {
        final currentList = _optimisticFriendsList ??
            (currentUserDocument?.friends ?? []);
        _optimisticFriendsList = currentList
            .where((ref) => ref.id != user.reference.id)
            .toList();
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
              color: AppTheme.of(context).primaryBtnText,
            ),
          ),
          duration: Duration(milliseconds: 1500),
          backgroundColor: AppTheme.of(context).primary,
        ),
      );

      // Keep optimistic state until Firestore stream updates or user navigates away
      // The state will be cleared naturally when the widget rebuilds with updated data
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
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
    tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
      animationDuration: Duration.zero, // Instant tab switching per premium motion system
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    tabBarController?.dispose();

    super.dispose();
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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          title: Text(
            'Golfers',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [],
          centerTitle: false,
        ),
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 56,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.md),
                      // Enhanced tab bar with shadow
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.fairway.withOpacity(0.08),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment(-1.0, 0),
                          child: AppButtonTabBar(
                            useToggleButtonStyle: false,
                            labelStyle: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            unselectedLabelStyle: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            labelColor: AppTheme.of(context).primaryBtnText,
                            unselectedLabelColor:
                                AppTheme.of(context).secondaryText,
                            backgroundColor: AppTheme.of(context).primary,
                            unselectedBackgroundColor:
                                AppTheme.of(context).alternate,
                            borderColor: AppTheme.of(context).primary,
                            unselectedBorderColor:
                                AppTheme.of(context).alternate,
                            borderWidth: 2.0,
                            borderRadius: 10.0,
                            elevation: 0.0,
                            labelPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            buttonMargin:
                                EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            padding: EdgeInsets.all(AppSpacing.xxs),
                            tabs: [
                              Tab(
                                text: 'Search',
                              ),
                              Tab(
                                text: 'Requests',
                              ),
                              Tab(
                                text: 'Friends',
                              ),
                            ],
                            controller: tabBarController,
                            onTap: (i) async {
                              [
                                () async {},
                                () async {
                                  friendList = [];
                                  if (mounted) setState(() {});
                                },
                                () async {
                                  friendList = [];
                                  if (mounted) setState(() {});
                                }
                              ][i]();
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabBarController,
                          children: [
                          KeepAliveWidgetWrapper(
                            builder: (context) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              child: RefreshIndicator(
                                onRefresh: _refreshSearchTab,
                                color: AppColors.fairway,
                                backgroundColor: Colors.white,
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: GolferSearchSection(
                                    currentUserId: currentUserUid,
                                    friendFilters: friendFilters,
                                    onFilterPressed: _showFilterBottomSheet,
                                    showDefaultsWhenBelowThreshold: true,
                                    searchDebounce:
                                        Duration(milliseconds: 300),
                                    showFocusHelperText: true,
                                    itemBuilder: (context, listViewUsersRecord) {
                                      return AuthUserStreamWidget(
                                        builder: (context) {
                                          final isFriend =
                                              (currentUserDocument?.friends.toList() ?? [])
                                                  .contains(
                                            listViewUsersRecord.reference,
                                          );
                                          final isOutgoingPending =
                                              listViewUsersRecord.friendRequests
                                                  .contains(currentUserReference);
                                          final isIncomingPending =
                                              (currentUserDocument
                                                          ?.friendRequests
                                                          .toList() ??
                                                      [])
                                                  .contains(
                                            listViewUsersRecord.reference,
                                          );
                                          final hasPending =
                                              isOutgoingPending || isIncomingPending;

                                          String actionLabel;
                                          IconData actionIcon;
                                          bool showActionButton;

                                          if (isFriend) {
                                            actionLabel = 'Friends';
                                            actionIcon = Icons.people_rounded;
                                            showActionButton = true;
                                          } else if (hasPending) {
                                            actionLabel =
                                                isOutgoingPending ? 'Cancel' : 'Pending';
                                            actionIcon = isOutgoingPending
                                                ? Icons.close_rounded
                                                : Icons.pending_rounded;
                                            showActionButton = true;
                                          } else {
                                            actionLabel = 'Add';
                                            actionIcon = Icons.person_add_rounded;
                                            showActionButton = true;
                                          }

                                          return PremiumFriendCard(
                                            user: listViewUsersRecord,
                                            currentUser: currentUserDocument,
                                            onViewProfile: () {
                                              context.pushNamed(
                                                'ProfileUser',
                                                extra: <String, dynamic>{
                                                  'userRef':
                                                      listViewUsersRecord.reference,
                                                },
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
                                                            try {
                                                              await context
                                                                  .read<UserProvider>()
                                                                  .cancelFriendRequest(
                                                                listViewUsersRecord
                                                                    .reference,
                                                              );
                                                              if (mounted) {
                                                                setState(() {});
                                                              }
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              ScaffoldMessenger.of(context)
                                                                  .clearSnackBars();
                                                              ScaffoldMessenger.of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Request cancelled.',
                                                                    style: AppTheme.of(context)
                                                                        .titleMedium
                                                                        .override(
                                                                          font: TextStyle(fontFamily: 'Manrope',
                                                                            fontWeight: AppTheme.of(context)
                                                                                .titleMedium
                                                                                .fontWeight,
                                                                            fontStyle: AppTheme.of(context)
                                                                                .titleMedium
                                                                                .fontStyle,
                                                                          ),
                                                                          color: AppTheme.of(context)
                                                                              .primaryBtnText,
                                                                          letterSpacing: 0.0,
                                                                          fontWeight: AppTheme.of(context)
                                                                              .titleMedium
                                                                              .fontWeight,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .titleMedium
                                                                              .fontStyle,
                                                                        ),
                                                                  ),
                                                                  duration:
                                                                      Duration(milliseconds: 1500),
                                                                  backgroundColor:
                                                                      AppTheme.of(context)
                                                                          .primary,
                                                                ),
                                                              );
                                                            } catch (_) {
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              showSnackbar(
                                                                context,
                                                                'Unable to cancel request. Please try again.',
                                                              );
                                                            }
                                                          }
                                                        : () async {})
                                                    : () async {
                                                        try {
                                                          await context
                                                              .read<UserProvider>()
                                                              .sendFriendRequest(
                                                            listViewUsersRecord.reference,
                                                          );
                                                          addToReqUserList(
                                                              valueOrDefault<String>(
                                                            listViewUsersRecord.uid,
                                                            '007',
                                                          ));
                                                          if (mounted) {
                                                            setState(() {});
                                                          }
                                                          if (!mounted) {
                                                            return;
                                                          }
                                                          ScaffoldMessenger.of(context)
                                                              .clearSnackBars();
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Friend request sent!',
                                                                style: AppTheme.of(context)
                                                                    .titleMedium
                                                                    .override(
                                                                      font: TextStyle(fontFamily: 'Manrope',
                                                                        fontWeight: AppTheme.of(context)
                                                                            .titleMedium
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .titleMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: AppTheme.of(context)
                                                                          .primaryBtnText,
                                                                      letterSpacing: 0.0,
                                                                      fontWeight: AppTheme.of(context)
                                                                          .titleMedium
                                                                          .fontWeight,
                                                                      fontStyle: AppTheme.of(context)
                                                                          .titleMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                              duration:
                                                                  Duration(milliseconds: 1500),
                                                              backgroundColor:
                                                                  AppTheme.of(context)
                                                                      .primary,
                                                            ),
                                                          );
                                                        } catch (_) {
                                                          if (!mounted) {
                                                            return;
                                                          }
                                                          showSnackbar(
                                                            context,
                                                            'Unable to send request. Please try again.',
                                                          );
                                                        }
                                                      },
                                            actionLabel: actionLabel,
                                            actionIcon: actionIcon,
                                            actionColor: isOutgoingPending
                                                ? AppColors.stone
                                                : AppColors.fairway,
                                            showActionButton: showActionButton,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          KeepAliveWidgetWrapper(
                            builder: (context) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              constraints: BoxConstraints(
                                minWidth: double.infinity,
                                minHeight: double.infinity,
                              ),
                              child: RefreshIndicator(
                                onRefresh: _refreshRequestsTab,
                                color: AppColors.fairway,
                                backgroundColor: Colors.white,
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isiOS) const SizedBox.shrink(),
                                    AuthUserStreamWidget(
                                      builder: (context) => Builder(
                                        builder: (context) {
                                          final friendRequestList =
                                              (currentUserDocument
                                                          ?.friendRequests
                                                          .toList() ??
                                                      [])
                                                  .toList();

                                          // ═══════════════════════════════════════════════════════
                                          // PERFORMANCE FIX #7: Batch-warm profiles for friend requests
                                          // ═══════════════════════════════════════════════════════
                                          final requestUids = friendRequestList
                                              .map((ref) => ref.id)
                                              .toSet();
                                          if (requestUids.isNotEmpty) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (!context.mounted) return;
                                              context.read<ProfileProvider>().warmProfiles(requestUids);
                                            });
                                          }

                                          // AnimatedSwitcher ensures clean transition between empty state and list
                                          return AnimatedSwitcher(
                                            duration: Duration(milliseconds: 200),
                                            child: friendRequestList.isEmpty
                                                ? FriendsEmptyState(
                                                    key: ValueKey('empty_requests_state'),
                                                    type: FriendsEmptyStateType
                                                        .noFriendRequests,
                                                    onActionPressed: () {
                                                      tabBarController?.animateTo(0);
                                                    },
                                                  )
                                                : ListView.separated(
                                            key: ValueKey('requests_list_${friendRequestList.length}'),
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              AppSpacing.md,
                                              0,
                                              AppSpacing.xxl,
                                            ),
                                            primary: false,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: friendRequestList.length,
                                            addAutomaticKeepAlives: false,
                                            addRepaintBoundaries: false,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 0),
                                            itemBuilder: (context,
                                                friendRequestListIndex) {
                                              final friendRequestListItem =
                                                  friendRequestList[
                                                      friendRequestListIndex];

                                              // PERFORMANCE FIX #7: Read from cached profile (no StreamBuilder, no N+1)
                                              // Profile was batch-warmed above via ProfileProvider.warmProfiles()
                                              return Consumer<ProfileProvider>(
                                                key: ValueKey(friendRequestListItem.id),
                                                builder: (context, profileProvider, _) {
                                                  final userList5UsersRecord =
                                                      profileProvider.getCachedProfile(friendRequestListItem.id);

                                                  if (userList5UsersRecord == null) {
                                                    return FriendCardSkeleton();
                                                  }

                                                  return PremiumFriendCard(
                                                    key: ValueKey('request_${userList5UsersRecord.reference.id}'),
                                                    user: userList5UsersRecord,
                                                    currentUser: currentUserDocument,
                                                    messageLabel: '+Add',
                                                    messageIcon:
                                                        Icons.person_add_rounded,
                                                    onViewProfile: () {
                                                      context.pushNamed(
                                                        'ProfileUser',
                                                        extra: <String,
                                                            dynamic>{
                                                          'userRef':
                                                              userList5UsersRecord
                                                                  .reference,
                                                        },
                                                      );
                                                    },
                                                    onMessage: () async {
                                                      // Accept button
                                                      // Capture context values before async operation
                                                      final scaffoldMessenger =
                                                          ScaffoldMessenger.of(
                                                              context);
                                                      final theme = AppTheme.of(context);
                                                      final titleMediumStyle = theme.titleMedium;
                                                      final primaryBtnTextColor = theme.primaryBtnText;
                                                      final primaryColor = theme.primary;
                                                      try {
                                                        await context
                                                            .read<UserProvider>()
                                                            .acceptFriendRequest(
                                                              userList5UsersRecord
                                                                  .reference,
                                                            );
                                                        if (mounted) {
                                                          setState(() {});
                                                        }
                                                        // Show success message using captured values
                                                        scaffoldMessenger
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Friend request accepted!',
                                                              style: titleMediumStyle
                                                                  .override(
                                                                    font: TextStyle(fontFamily: 'Manrope',
                                                                      fontWeight: titleMediumStyle
                                                                          .fontWeight,
                                                                      fontStyle: titleMediumStyle
                                                                          .fontStyle,
                                                                    ),
                                                                    color: primaryBtnTextColor,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight: titleMediumStyle
                                                                        .fontWeight,
                                                                    fontStyle: titleMediumStyle
                                                                        .fontStyle,
                                                                  ),
                                                            ),
                                                            duration: Duration(
                                                                milliseconds:
                                                                    1500),
                                                            backgroundColor:
                                                                primaryColor,
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        if (!mounted) {
                                                          return;
                                                        }
                                                        showSnackbar(
                                                          context,
                                                          'Unable to accept request. Please try again.',
                                                        );
                                                      }
                                                    },
                                                    onAction: () async {
                                                      // Deny button
                                                      try {
                                                        await context
                                                            .read<UserProvider>()
                                                            .rejectFriendRequest(
                                                              userList5UsersRecord
                                                                  .reference,
                                                            );
                                                        if (mounted) {
                                                          setState(() {});
                                                        }
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Request denied.',
                                                                style: AppTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .override(
                                                                      font: TextStyle(fontFamily: 'Manrope',
                                                                        fontWeight: AppTheme.of(context)
                                                                            .titleMedium
                                                                            .fontWeight,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .titleMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: AppTheme.of(
                                                                              context)
                                                                          .primaryBtnText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: AppTheme.of(
                                                                              context)
                                                                          .titleMedium
                                                                          .fontWeight,
                                                                      fontStyle: AppTheme.of(
                                                                              context)
                                                                          .titleMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      1500),
                                                              backgroundColor:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .primary,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        debugPrint('Deny request failed: $e');
                                                        if (mounted) {
                                                          showSnackbar(
                                                            context,
                                                            'Unable to deny request. Please try again.',
                                                          );
                                                        }
                                                      }
                                                    },
                                                    actionLabel: 'Deny',
                                                    actionIcon:
                                                        Icons.close_rounded,
                                                    actionColor: AppColors.stone,
                                                    showActionButton: true,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ),
                            ),
                          ),
                          KeepAliveWidgetWrapper(
                            builder: (context) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              constraints: BoxConstraints(
                                minWidth: double.infinity,
                                minHeight: double.infinity,
                              ),
                              child: RefreshIndicator(
                                onRefresh: _refreshFriendsTab,
                                color: AppColors.fairway,
                                backgroundColor: Colors.white,
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: AuthUserStreamWidget(
                                    builder: (context) => Builder(
                                      builder: (context) {
                                        final serverFriendsList =
                                            (currentUserDocument?.friends.toList() ?? []).toList();

                                        // Check if optimistic state matches server state
                                        if (_optimisticFriendsList != null) {
                                          final optimisticIds =
                                              _optimisticFriendsList!.map((ref) => ref.id).toSet();
                                          final serverIds =
                                              serverFriendsList.map((ref) => ref.id).toSet();

                                          // If server state matches optimistic state, clear optimistic state
                                          if (optimisticIds.length == serverIds.length &&
                                              optimisticIds.difference(serverIds).isEmpty) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(() {
                                                  _optimisticFriendsList = null;
                                                });
                                              }
                                            });
                                          }
                                        }

                                        // Use optimistic state if available, otherwise use server state
                                        final friendsList =
                                            _optimisticFriendsList ?? serverFriendsList;

                                        // Show empty state if no friends
                                        if (friendsList.isEmpty) {
                                          return FriendsEmptyState(
                                            type: FriendsEmptyStateType.noFriends,
                                            onActionPressed: () {
                                              tabBarController?.animateTo(0);
                                            },
                                          );
                                        }

                                        return GroupedFriendsList(
                                          friendRefs: friendsList,
                                          favoriteFriends: favoriteFriends,
                                          currentUserHomeCourse:
                                              currentUserDocument?.homeCourse,
                                          currentUser: currentUserDocument,
                                          onToggleFavorite: toggleFavorite,
                                          onViewProfile: (user) {
                                            context.pushNamed(
                                              'ProfileUser',
                                              extra: <String, dynamic>{
                                                'userRef': user.reference,
                                              },
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    ));
  }
}

/*

OLD CODE BELOW - KEEPING FOR REFERENCE

                                          return ListView.separated(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              12.0,
                                              0,
                                              44.0,
                                            ),
                                            primary: false,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: friendsList.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: AppSpacing.xxs),
                                            itemBuilder:
                                                (context, friendsListIndex) {
                                              final friendsListItem =
                                                  friendsList[friendsListIndex];
                                              return StreamBuilder<UsersRecord>(
                                                stream:
                                                    UsersRecord.getDocument(
                                                        friendsListItem),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return Center(
                                                      child: SizedBox(
                                                        width: 50.0,
                                                        height: 50.0,
                                                        child:
                                                            SpinKitWanderingCubes(
                                                          color: Color(
                                                              0xFF25504F),
                                                          size: 50.0,
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  final userList5UsersRecord =
                                                      snapshot.data!;

                                                  return PremiumFriendCard(
                                                    user: userList5UsersRecord,
                                                    currentUser: currentUserDocument,
                                                    onViewProfile: () {
                                                      context.pushNamed(
                                                        'ProfileUser',
                                                        extra: <String,
                                                            dynamic>{
                                                          'userRef':
                                                              userList5UsersRecord
                                                                  .reference,
                                                        },
                                                      );
                                                    },
                                                    onMessage: () async {
                                                      await _openDirectChat(
                                                          userList5UsersRecord);
                                                    },
                                                    onAction: () async {
                                                      await _removeFriend(
                                                        userList5UsersRecord,
                                                      );
                                                    },
                                                    actionLabel: 'Remove',
                                                    actionIcon:
                                                        Icons.person_remove_rounded,
                                                    actionColor: AppColors.stone,
                                                    showActionButton: true,
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
