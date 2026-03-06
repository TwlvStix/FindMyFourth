import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/fairway_background.dart';
import '/friends/components/empty_state.dart';
import '/friends/components/friends_discover_list_item.dart';
import '/friends/components/friends_requests_view.dart';
import '/friends/components/golfer_search_bar.dart';
import '/friends/components/golfer_search_section.dart';
import '/friends/components/golfer_segmented_control.dart';
import '/friends/components/grouped_friends_list.dart';
import '/friends/components/section_label_row.dart';
import '/friends/tab_friends/tab_friends_controller.dart';
import '/utils/app_util.dart';

class TabFriendsWidget extends StatefulWidget {
  const TabFriendsWidget({super.key, this.initialSegment});

  final String? initialSegment;

  static String routeName = 'Tab_Friends';
  static String routePath = '/tabFriends';

  @override
  State<TabFriendsWidget> createState() => _TabFriendsWidgetState();
}

class _TabFriendsWidgetState extends State<TabFriendsWidget> {
  late final TabFriendsController _controller;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = TabFriendsController(initialSegment: widget.initialSegment);
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
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
        key: _scaffoldKey,
        backgroundColor: AppColors.transparent,
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: AppSpacing.md),
                _buildSearchBar(),
                SizedBox(height: AppSpacing.md),
                _buildSegmentedControl(),
                SizedBox(height: AppSpacing.md),
                if (_controller.currentSegment != GolferSegment.discover) ...[
                  _buildSectionLabel(),
                  SizedBox(height: AppSpacing.sm),
                ],
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Text(
        'Golfers',
        style: AppTypography.headlineMediumSans.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GolferSearchBar(
        controller: _controller.searchController,
        focusNode: _controller.searchFocusNode,
        onFilterPressed: () => _controller.showFilterSheet(context),
        hasActiveFilters: _controller.friendFilters.hasActiveFilters,
        activeFilterCount: _controller.friendFilters.activeFilterCount,
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AuthUserStreamWidget(
        builder: (context) {
          final requestCount = currentUserDocument?.friendRequests.length ?? 0;
          return GolferSegmentedControl(
            selectedSegment: _controller.currentSegment,
            onSegmentChanged: (segment) {
              FocusScope.of(context).unfocus();
              _controller.setSegment(segment);
            },
            requestsBadgeCount: requestCount,
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AuthUserStreamWidget(
        builder: (context) {
          return SectionLabelRow(
            label: _controller.getSectionLabel(),
            count: _getCountForCurrentSegment(),
            countLabel: _controller.currentSegment == GolferSegment.requests
                ? 'requests'
                : 'golfers',
          );
        },
      ),
    );
  }

  int _getCountForCurrentSegment() {
    switch (_controller.currentSegment) {
      case GolferSegment.discover:
        return 0;
      case GolferSegment.requests:
        return currentUserDocument?.friendRequests.length ?? 0;
      case GolferSegment.friends:
        final friendsList = _controller.optimisticFriendsList ??
            (currentUserDocument?.friends.toList() ?? []);
        return friendsList.length;
    }
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
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
    );
  }

  Widget _buildCurrentView() {
    switch (_controller.currentSegment) {
      case GolferSegment.discover:
        return _buildDiscoverView();
      case GolferSegment.requests:
        return FriendsRequestsView(
          controller: _controller,
          onRefresh: _controller.refresh,
        );
      case GolferSegment.friends:
        return _buildFriendsView();
    }
  }

  Widget _buildDiscoverView() {
    return KeyedSubtree(
      key: const ValueKey('discover_view'),
      child: RefreshIndicator(
        onRefresh: _controller.refresh,
        color: AppColors.navy,
        backgroundColor: AppColors.pure,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: GolferSearchSection(
            currentUserId: currentUserUid,
            friendFilters: _controller.friendFilters,
            showDefaultsWhenBelowThreshold: true,
            searchDebounce: const Duration(milliseconds: 300),
            externalSearchTerm: _controller.searchTerm,
            hideInternalSearchBar: true,
            onClearSearch: _controller.clearSearch,
            itemBuilder: (context, user, cardIndex) {
              return FriendsDiscoverListItem(
                user: user,
                cardIndex: cardIndex,
                controller: _controller,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsView() {
    return KeyedSubtree(
      key: const ValueKey('friends_view'),
      child: RefreshIndicator(
        onRefresh: _controller.refresh,
        color: AppColors.navy,
        backgroundColor: AppColors.pure,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AuthUserStreamWidget(
            builder: (context) {
              final serverFriendsList =
                  (currentUserDocument?.friends.toList() ?? []).toList();

              // Sync optimistic state with server
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _controller.syncOptimisticState(serverFriendsList);
                }
              });

              final friendsList =
                  _controller.optimisticFriendsList ?? serverFriendsList;

              if (friendsList.isEmpty) {
                return FriendsEmptyState(
                  type: FriendsEmptyStateType.noFriends,
                  onActionPressed: () {
                    _controller.setSegment(GolferSegment.discover);
                  },
                );
              }

              return GroupedFriendsList(
                friendRefs: friendsList,
                favoriteFriends: _controller.favoriteFriends,
                currentUserHomeCourse: currentUserDocument?.homeCourse,
                currentUser: currentUserDocument,
                searchFilter: _controller.searchTerm.isNotEmpty
                    ? _controller.searchTerm
                    : null,
                onToggleFavorite: _controller.toggleFavorite,
                onViewProfile: (user) {
                  context.pushProfileUser(
                    userRef: user.reference,
                    transition: TransitionStandards.noTransition,
                  );
                },
                onMessage: (user) => _controller.openDirectChat(context, user),
                onRemove: (user) async {
                  await _controller.removeFriend(context, user, friendsList);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
