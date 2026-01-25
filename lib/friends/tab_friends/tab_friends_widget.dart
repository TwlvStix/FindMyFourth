import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/autocomplete_options_list.dart';
import '/core/button_tabbar.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';
import '/friends/components/premium_friend_card.dart';
import '/friends/components/empty_state.dart';
import '/friends/components/friend_section_header.dart';
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
  bool clubMembersCollapsed = false;
  bool allFriendsCollapsed = false;

  // Refresh tracking
  bool isRefreshing = false;

  // Filter tracking
  FriendFilters friendFilters = FriendFilters();

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

  final textFieldKey = GlobalKey();
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? textFieldSelectedOption;
  String? Function(BuildContext, String?)? textControllerValidator;

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
    } catch (_) {
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
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    textController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    textController?.dispose();

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
          leading: GestureDetector(
            onTap: () async {
              context.pop();
            },
            child: Container(
              margin: EdgeInsets.only(left: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.fairway.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 28.0,
              ),
            ),
          ),
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
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Expanded(
                child: Column(
                  children: [
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: AppSpacing.md,
                                            top: AppSpacing.md,
                                            right: AppSpacing.md,
                                            bottom: AppSpacing.md),
                                        child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.xs),
                                              child: Autocomplete<String>(
                                                initialValue:
                                                    TextEditingValue(),
                                                optionsBuilder:
                                                    (textEditingValue) {
                                                  if (textEditingValue.text ==
                                                      '') {
                                                    return const Iterable<
                                                        String>.empty();
                                                  }
                                                  return ['Option 1']
                                                      .where((option) {
                                                    final lowercaseOption =
                                                        option.toLowerCase();
                                                    return lowercaseOption
                                                        .contains(
                                                            textEditingValue
                                                                .text
                                                                .toLowerCase());
                                                  });
                                                },
                                                optionsViewBuilder: (context,
                                                    onSelected, options) {
                                                  return AutocompleteOptionsList(
                                                    textFieldKey: textFieldKey,
                                                    textController:
                                                        textController!,
                                                    options: options.toList(),
                                                    onSelected: onSelected,
                                                    textStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .outfit(
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                    textHighlightStyle:
                                                        TextStyle(),
                                                    elevation: 4.0,
                                                    optionBackgroundColor:
                                                        AppTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    optionHighlightColor:
                                                        AppTheme.of(
                                                                context)
                                                            .secondaryBackground,
                                                    maxHeight: 200.0,
                                                  );
                                                },
                                                onSelected: (String selection) {
                                                  if (mounted) {
                                                    setState(() =>
                                                        textFieldSelectedOption =
                                                            selection);
                                                  }
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                },
                                                fieldViewBuilder: (
                                                  context,
                                                  textEditingController,
                                                  focusNode,
                                                  onEditingComplete,
                                                ) {
                                                  textFieldFocusNode =
                                                      focusNode;

                                                  textController =
                                                      textEditingController;
                                                  return TextFormField(
                                                    key: textFieldKey,
                                                    controller:
                                                        textEditingController,
                                                    focusNode: focusNode,
                                                    onChanged: (_) {
                                                      if (mounted) {
                                                        setState(() {});
                                                      }
                                                    },
                                                    onEditingComplete:
                                                        onEditingComplete,
                                                    autofocus: true,
                                                    obscureText: false,
                                                    decoration: InputDecoration(
                                                      labelStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                      hintStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .primaryBtnText,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .primaryBtnText,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      errorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .error,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .error,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      prefixIcon: Icon(
                                                        Icons.search_rounded,
                                                        color:
                                                            AppTheme.of(
                                                                    context)
                                                                .primaryBtnText,
                                                      ),
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                    validator: textControllerValidator
                                                        .asValidator(context),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(
                                                    left: AppSpacing.sm),
                                            child: AppIconButton(
                                              borderColor: friendFilters.hasActiveFilters
                                                  ? AppColors.fairway.withOpacity(0.2)
                                                  : Colors.transparent,
                                              borderRadius: 30.0,
                                              borderWidth: friendFilters.hasActiveFilters ? 2.0 : 1.0,
                                              buttonSize: 44.0,
                                              fillColor: friendFilters.hasActiveFilters
                                                  ? AppColors.fairway.withOpacity(0.1)
                                                  : Colors.transparent,
                                              tooltip: 'Filters',
                                              icon: Icon(
                                                Icons.tune_rounded,
                                                color: friendFilters.hasActiveFilters
                                                    ? AppColors.fairway
                                                    : AppTheme.of(context).primaryBtnText,
                                                size: 24.0,
                                              ),
                                              onPressed: _showFilterBottomSheet,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(
                                                    left: AppSpacing.sm),
                                            child: AppIconButton(
                                              borderColor: Colors.transparent,
                                              borderRadius: 30.0,
                                              borderWidth: 1.0,
                                              buttonSize: 44.0,
                                              tooltip: 'Clear search',
                                              icon: Icon(
                                                Icons.clear_sharp,
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                size: 24.0,
                                              ),
                                              onPressed: () {
                                                textController?.clear();
                                                FocusScope.of(context)
                                                    .unfocus();
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: AppSpacing.lg,
                                          bottom: AppSpacing.xs),
                                      child: Text(
                                        'Search Results',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppTheme.of(context).primaryBtnText,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    StreamBuilder<List<UsersRecord>>(
                                      stream: (() {
                                        final term = textController?.text
                                                .trim()
                                                .toLowerCase() ??
                                            '';
                                        if (term.isEmpty) {
                                          return Stream.value(<UsersRecord>[]);
                                        }
                                        return queryUsersRecord(
                                          queryBuilder: (usersRecord) =>
                                              usersRecord
                                                  .orderBy('display_name_lower')
                                                  .startAt([term])
                                                  .endAt(['${term}\uf8ff'])
                                                  .limit(25),
                                        );
                                      })(),
                                      builder: (context, snapshot) {
                                        // Skeleton loading state
                                        if (!snapshot.hasData) {
                                          return Padding(
                                            padding: EdgeInsets.only(top: AppSpacing.md),
                                            child: Column(
                                              children: [
                                                FriendCardSkeleton(),
                                                FriendCardSkeleton(),
                                                FriendCardSkeleton(),
                                              ],
                                            ),
                                          );
                                        }
                                        final searchTerm = textController?.text
                                                .trim()
                                                .toLowerCase() ??
                                            '';
                                        List<UsersRecord>
                                            listViewUsersRecordList = snapshot
                                                .data!
                                                .where((u) =>
                                                    u.uid != currentUserUid)
                                                .where((user) {
                                          if (searchTerm.isEmpty) {
                                            return true;
                                          }
                                          final displayName =
                                              user.displayName.toLowerCase();
                                          final firstName =
                                              user.firstName.toLowerCase();
                                          final lastName =
                                              user.lastName.toLowerCase();
                                          return displayName
                                                  .contains(searchTerm) ||
                                              firstName.contains(searchTerm) ||
                                              lastName.contains(searchTerm);
                                        })
                                                .where((user) =>
                                                    friendFilters.matchesUser(user))
                                                .toList();

                                        // Show empty state if no results and user has searched
                                        if (listViewUsersRecordList.isEmpty &&
                                            searchTerm.isNotEmpty) {
                                          return FriendsEmptyState(
                                            type: FriendsEmptyStateType
                                                .noSearchResults,
                                            onActionPressed: () {
                                              textController?.clear();
                                              FocusScope.of(context).unfocus();
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            },
                                          );
                                        }

                                        return ListView.separated(
                                          padding: EdgeInsets.fromLTRB(
                                            0,
                                            AppSpacing.xs,
                                            0,
                                            AppSpacing.xxl,
                                          ),
                                          primary: false,
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount:
                                              listViewUsersRecordList.length,
                                          separatorBuilder: (_, __) =>
                                              SizedBox(height: 0),
                                          itemBuilder:
                                              (context, listViewIndex) {
                                            final listViewUsersRecord =
                                                listViewUsersRecordList[
                                                    listViewIndex];
                                            return AuthUserStreamWidget(
                                              builder: (context) {
                                                final isFriend =
                                                    (currentUserDocument
                                                                ?.friends
                                                                .toList() ??
                                                            [])
                                                        .contains(
                                                  listViewUsersRecord.reference,
                                                );
                                                final isOutgoingPending =
                                                    listViewUsersRecord
                                                        .friendRequests
                                                        .contains(
                                                            currentUserReference);
                                                final isIncomingPending =
                                                    (currentUserDocument
                                                                ?.friendRequests
                                                                .toList() ??
                                                            [])
                                                        .contains(
                                                  listViewUsersRecord.reference,
                                                );
                                                final hasPending =
                                                    isOutgoingPending ||
                                                        isIncomingPending;

                                                String actionLabel;
                                                IconData actionIcon;
                                                bool showActionButton;

                                                if (isFriend) {
                                                  actionLabel = 'Friends';
                                                  actionIcon = Icons.people_rounded;
                                                  showActionButton = true;
                                                } else if (hasPending) {
                                                  actionLabel = isOutgoingPending
                                                      ? 'Cancel'
                                                      : 'Pending';
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
                                                            listViewUsersRecord
                                                                .reference,
                                                      },
                                                    );
                                                  },
                                                  onMessage: () async {
                                                    await _openDirectChat(
                                                        listViewUsersRecord);
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
                                                                      setState(
                                                                          () {});
                                                                    }
                                                                    if (!mounted) {
                                                                      return;
                                                                    }
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .clearSnackBars();
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(
                                                                          'Request cancelled.',
                                                                          style: AppTheme.of(context)
                                                                              .titleMedium
                                                                              .override(
                                                                                font: GoogleFonts
                                                                                    .outfit(
                                                                                  fontWeight: AppTheme.of(context)
                                                                                      .titleMedium
                                                                                      .fontWeight,
                                                                                  fontStyle: AppTheme.of(context)
                                                                                      .titleMedium
                                                                                      .fontStyle,
                                                                                ),
                                                                                color: AppTheme.of(context)
                                                                                    .primaryBtnText,
                                                                                letterSpacing:
                                                                                    0.0,
                                                                                fontWeight: AppTheme.of(context)
                                                                                    .titleMedium
                                                                                    .fontWeight,
                                                                                fontStyle: AppTheme.of(context)
                                                                                    .titleMedium
                                                                                    .fontStyle,
                                                                              ),
                                                                        ),
                                                                        duration: Duration(
                                                                            milliseconds:
                                                                                1500),
                                                                        backgroundColor:
                                                                            AppTheme.of(context)
                                                                                .primary,
                                                                      ),
                                                                    );
                                                                  } catch (_) {
                                                                    if (!mounted) {
                                                                      return;
                                                                    }
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .clearSnackBars();
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(
                                                                          'Unable to cancel request.',
                                                                          style: AppTheme.of(context)
                                                                              .titleMedium
                                                                              .override(
                                                                                font: GoogleFonts
                                                                                    .outfit(
                                                                                  fontWeight: AppTheme.of(context)
                                                                                      .titleMedium
                                                                                      .fontWeight,
                                                                                  fontStyle: AppTheme.of(context)
                                                                                      .titleMedium
                                                                                      .fontStyle,
                                                                                ),
                                                                                color: AppTheme.of(context)
                                                                                    .primaryBtnText,
                                                                                letterSpacing:
                                                                                    0.0,
                                                                                fontWeight: AppTheme.of(context)
                                                                                    .titleMedium
                                                                                    .fontWeight,
                                                                                fontStyle: AppTheme.of(context)
                                                                                    .titleMedium
                                                                                    .fontStyle,
                                                                              ),
                                                                        ),
                                                                        duration: Duration(
                                                                            milliseconds:
                                                                                1500),
                                                                        backgroundColor:
                                                                            AppTheme.of(context)
                                                                                .error,
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              : null)
                                                          : () async {
                                                          try {
                                                            await context
                                                                .read<
                                                                    UserProvider>()
                                                                .sendFriendRequest(
                                                              listViewUsersRecord
                                                                  .reference,
                                                            );
                                                            addToReqUserList(
                                                                valueOrDefault<
                                                                    String>(
                                                              listViewUsersRecord
                                                                  .uid,
                                                              '007',
                                                            ));
                                                            if (mounted) {
                                                              setState(() {});
                                                            }
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            ScaffoldMessenger.of(
                                                                    context)
                                                                .clearSnackBars();
                                                            ScaffoldMessenger.of(
                                                                    context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Friend request sent!',
                                                                  style: AppTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
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
                                                          } catch (_) {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            ScaffoldMessenger.of(
                                                                    context)
                                                                .clearSnackBars();
                                                            ScaffoldMessenger.of(
                                                                    context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Unable to send request.',
                                                                  style: AppTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
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
                                                                        .error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  actionLabel: actionLabel,
                                                  actionIcon: actionIcon,
                                                  showActionButton:
                                                      showActionButton,
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
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
                                          print(
                                            'Requests tab friend_requests raw: ${currentUserDocument?.snapshotData['friend_requests']}',
                                          );

                                          // Show empty state if no friend requests
                                          if (friendRequestList.isEmpty) {
                                            return FriendsEmptyState(
                                              type: FriendsEmptyStateType
                                                  .noFriendRequests,
                                              onActionPressed: () {
                                                tabBarController?.animateTo(0);
                                              },
                                            );
                                          }

                                          return ListView.separated(
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
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 0),
                                            itemBuilder: (context,
                                                friendRequestListIndex) {
                                              final friendRequestListItem =
                                                  friendRequestList[
                                                      friendRequestListIndex];
                                              return StreamBuilder<UsersRecord>(
                                                stream:
                                                    UsersRecord.getDocument(
                                                        friendRequestListItem),
                                                builder: (context, snapshot) {
                                                  if (!snapshot.hasData) {
                                                    return FriendCardSkeleton();
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
                                                      // Accept button
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
                                                        if (!mounted) {
                                                          return;
                                                        }
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Friend request accepted!',
                                                              style: AppTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .outfit(
                                                                      fontWeight: AppTheme.of(
                                                                              context)
                                                                          .titleMedium
                                                                          .fontWeight,
                                                                      fontStyle: AppTheme.of(
                                                                              context)
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
                                                                      font: GoogleFonts
                                                                          .outfit(
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
                                                        print(
                                                          'Deny request failed: $e',
                                                        );
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
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AuthUserStreamWidget(
                                      builder: (context) => Builder(
                                        builder: (context) {
                                          final friendsList =
                                              (currentUserDocument?.friends
                                                          .toList() ??
                                                      [])
                                                  .toList();

                                          // Show empty state if no friends
                                          if (friendsList.isEmpty) {
                                            return FriendsEmptyState(
                                              type:
                                                  FriendsEmptyStateType.noFriends,
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
