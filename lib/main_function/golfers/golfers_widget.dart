import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/autocomplete_options_list.dart';
import '/core/button_tabbar.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/profile/main_profile/main_profile_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';
class GolfersWidget extends StatefulWidget {
  const GolfersWidget({super.key});

  static String routeName = 'Golfers';
  static String routePath = '/golfers';

  @override
  State<GolfersWidget> createState() => _GolfersWidgetState();
}

class _GolfersWidgetState extends State<GolfersWidget>
    with TickerProviderStateMixin {
  List<String> reqUserList = [];
  List<DocumentReference> friendList = [];

  TabController? _tabBarController;
  int get tabBarCurrentIndex =>
      _tabBarController != null ? _tabBarController!.index : 0;

  final textFieldKey = GlobalKey();
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? textFieldSelectedOption;

  Future<void> _openDirectChat(UsersRecord user) async {
    debugPrint('🔵 Chat button clicked for user: ${user.displayName}');

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ Chat failed: User not signed in');
      if (mounted) {
        showSnackbar(context, 'Please sign in to chat.');
      }
      return;
    }

    final currentUserId = currentUser.uid;
    final otherUserId = user.reference.id;

    debugPrint('🔵 Current user ID: $currentUserId');
    debugPrint('🔵 Other user ID: $otherUserId');
    debugPrint('🔵 Attempting to create/find direct chat...');

    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserId,
            otherUid: otherUserId,
          );

      debugPrint('✅ Chat created/found successfully: ${chatRef.id}');
      debugPrint('🔵 Navigating to ChatDetails with chatId: ${chatRef.id}');

      context.pushNamed(
        'ChatDetails',
        pathParameters: {
          'chatId': chatRef.id,
        },
      );
    } catch (error, stackTrace) {
      debugPrint('❌ CHAT CREATION FAILED!');
      debugPrint('❌ Error type: ${error.runtimeType}');
      debugPrint('❌ Error message: $error');
      debugPrint('❌ Stack trace:\n$stackTrace');

      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);

      if (mounted) {
        showSnackbar(
          context,
          'Unable to start chat. Error: ${error.toString().substring(0, 100)}'
        );
      }
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(
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
    _tabBarController?.dispose();
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Golfers',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 56),
                // Header section with subtle glass effect
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.fairway.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    'Find golfers, manage connections, and build your network',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                // Tabs with glass morphism style
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.fairway.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: AppButtonTabBar(
                      useToggleButtonStyle: false,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: AppTypography.labelMedium,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      backgroundColor: AppColors.sunsetGold,
                      unselectedBackgroundColor: Colors.transparent,
                      borderColor: AppColors.sunsetGold,
                      unselectedBorderColor: Colors.transparent,
                      borderWidth: 0,
                      borderRadius: 10.0,
                      elevation: 0.0,
                      labelPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      buttonMargin: EdgeInsets.all(AppSpacing.xxs),
                      padding: AppSpacing.allXxs,
                      tabs: [
                        Tab(text: 'Search'),
                        Tab(text: 'Requests'),
                        Tab(text: 'Friends'),
                      ],
                      controller: _tabBarController,
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
                SizedBox(height: AppSpacing.md),
                // Content area
                Expanded(
                  child: TabBarView(
                    controller: _tabBarController,
                    children: [
                      // Search Tab
                      _buildSearchTab(),
                      // Requests Tab
                      _buildRequestsTab(),
                      // Friends Tab
                      _buildFriendsTab(),
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

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar with glass morphism
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(),
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return ['Option 1'].where((option) {
                        final lowercaseOption = option.toLowerCase();
                        return lowercaseOption.contains(
                            textEditingValue.text.toLowerCase());
                      });
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return AutocompleteOptionsList(
                        textFieldKey: textFieldKey,
                        textController: textController!,
                        options: options.toList(),
                        onSelected: onSelected,
                        textStyle: AppTypography.bodyMedium,
                        textHighlightStyle: TextStyle(),
                        elevation: 4.0,
                        optionBackgroundColor: AppColors.fairwayDark,
                        optionHighlightColor: AppColors.fairway,
                        maxHeight: 200.0,
                      );
                    },
                    onSelected: (String selection) {
                      if (mounted) {
                        setState(() => textFieldSelectedOption = selection);
                      }
                      FocusScope.of(context).unfocus();
                    },
                    fieldViewBuilder: (
                      context,
                      textEditingController,
                      focusNode,
                      onEditingComplete,
                    ) {
                      textFieldFocusNode = focusNode;
                      textController = textEditingController;
                      return TextFormField(
                        key: textFieldKey,
                        controller: textEditingController,
                        focusNode: focusNode,
                        onChanged: (_) {
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        onEditingComplete: onEditingComplete,
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: 'Search golfers...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.sunsetGold,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          filled: true,
                          fillColor: AppColors.fairway.withOpacity(0.3),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Clear button with glass style
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    textController?.clear();
                    FocusScope.of(context).unfocus();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.fairway.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // User List
          StreamBuilder<List<UsersRecord>>(
            stream: queryUsersRecord(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitWanderingCubes(
                          color: AppColors.sunsetGold,
                          size: 50.0,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Finding golfers...',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final searchTerm =
                  textController?.text.trim().toLowerCase() ?? '';
              List<UsersRecord> filteredUsers = snapshot.data!
                  .where((u) => u.uid != currentUserUid)
                  .where((user) {
                if (searchTerm.isEmpty) {
                  return true;
                }
                final displayName = user.displayName.toLowerCase();
                final firstName = user.firstName.toLowerCase();
                final lastName = user.lastName.toLowerCase();
                return displayName.contains(searchTerm) ||
                    firstName.contains(searchTerm) ||
                    lastName.contains(searchTerm);
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.fairway.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'No golfers found',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Try a different search term',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  44.0,
                ),
                primary: false,
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemCount: filteredUsers.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _buildUserCard(user);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthUserStreamWidget(
            builder: (context) => Builder(
              builder: (context) {
                final friendRequestList =
                    (currentUserDocument?.friendRequests.toList() ?? [])
                        .toList();

                if (friendRequestList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.fairway.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline_rounded,
                              size: 40,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'No pending requests',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Friend requests will appear here',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    44.0,
                  ),
                  primary: false,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: friendRequestList.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final friendRequestItem = friendRequestList[index];
                    return StreamBuilder<UsersRecord>(
                      stream: UsersRecord.getDocument(friendRequestItem),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: SizedBox(
                              width: 50.0,
                              height: 50.0,
                              child: SpinKitWanderingCubes(
                                color: AppColors.sunsetGold,
                                size: 50.0,
                              ),
                            ),
                          );
                        }

                        final user = snapshot.data!;
                        return _buildRequestCard(user);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthUserStreamWidget(
            builder: (context) => Builder(
              builder: (context) {
                final friendsList =
                    (currentUserDocument?.friends.toList() ?? []).toList();

                if (friendsList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.fairway.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline_rounded,
                              size: 40,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'No friends yet',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Search for golfers to connect with',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    44.0,
                  ),
                  primary: false,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: friendsList.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final friendItem = friendsList[index];
                    return StreamBuilder<UsersRecord>(
                      stream: UsersRecord.getDocument(friendItem),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: SizedBox(
                              width: 50.0,
                              height: 50.0,
                              child: SpinKitWanderingCubes(
                                color: AppColors.sunsetGold,
                                size: 50.0,
                              ),
                            ),
                          );
                        }

                        final user = snapshot.data!;
                        return _buildFriendCard(user);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UsersRecord user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.fairway.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.fairwayLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Premium Avatar with gradient ring
          _buildPremiumAvatar(user.photoUrl, 56),
          SizedBox(width: AppSpacing.md),
          // Name, course, and handicap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(user.displayName, 'Golfer'),
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                if (user.homeCourse.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.sunsetGold,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.homeCourse,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (user.handicap != null && user.handicap > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'HC ${user.handicap}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.sunsetGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Action buttons
          AuthUserStreamWidget(
            builder: (context) {
              final isFriend =
                  (currentUserDocument?.friends.toList() ?? [])
                      .contains(user.reference);
              final hasPending = user.friendRequests.contains(
                      currentUserReference) ||
                  (currentUserDocument?.friendRequests.toList() ?? [])
                      .contains(user.reference);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary action button (state-based)
                  if (isFriend)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.fairwayLight, AppColors.fairway],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Friends',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hasPending)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.7), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Pending',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await context.read<UserProvider>().sendFriendRequest(user.reference);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Friend request sent!', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                              duration: Duration(milliseconds: 1500),
                              backgroundColor: AppColors.fairwayDark,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unable to send request.', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunsetGold.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Add',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  // View profile
                  _buildGlassIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pushNamed(
                        'ProfileUser',
                        extra: <String, dynamic>{
                          'userRef': user.reference,
                        },
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  // Chat
                  _buildGlassIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _openDirectChat(user);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAvatar(String? photoUrl, double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gradient ring
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                AppColors.sunsetGold,
                AppColors.sunsetPeach,
                AppColors.sunsetRose,
                AppColors.fairwayLight,
                AppColors.sunsetGold,
              ],
            ),
          ),
        ),
        // White border
        Container(
          width: size + 4,
          height: size + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pure,
          ),
        ),
        // Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            valueOrDefault<String>(
              photoUrl,
              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
            ),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              color: AppColors.sand,
              child: Icon(Icons.person_rounded, size: size * 0.5, color: AppColors.stone),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildRequestCard(UsersRecord user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sunsetPeach.withOpacity(0.15),
            AppColors.sunsetGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.sunsetGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Premium Avatar
          _buildPremiumAvatar(user.photoUrl, 52),
          SizedBox(width: AppSpacing.md),
          // Name and course
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Friend Request',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.sunsetGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  valueOrDefault<String>(user.displayName, 'Golfer'),
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.homeCourse.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      user.homeCourse,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Accept/Reject buttons
          Row(
            children: [
              // Accept button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await context.read<UserProvider>().acceptFriendRequest(user.reference);
                  if (mounted) setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Friend request accepted!',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white),
                      ),
                      duration: Duration(milliseconds: 1500),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.fairwayLight, AppColors.fairway],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.fairway.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 22),
                ),
              ),
              SizedBox(width: 8),
              // Reject button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await context.read<UserProvider>().rejectFriendRequest(user.reference);
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.close_rounded, color: AppColors.error, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(UsersRecord user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.fairway.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.fairwayLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Premium Avatar
          _buildPremiumAvatar(user.photoUrl, 52),
          SizedBox(width: AppSpacing.md),
          // Name and course
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(user.displayName, 'Friend'),
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                if (user.homeCourse.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.sunsetGold,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.homeCourse,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (user.handicap != null && user.handicap > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'HC ${user.handicap}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.sunsetGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              // View profile
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pushNamed(
                    'ProfileUser',
                    extra: <String, dynamic>{
                      'userRef': user.reference,
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.fairwayLight, AppColors.fairway],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'View',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Chat
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _openDirectChat(user);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sunsetGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: 8),
              // Remove friend
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (alertDialogContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Remove Friend?',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onyx,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            'This will remove you from each other\'s friends list.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(alertDialogContext, false),
                              child: Text(
                                'Cancel',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.stone,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(alertDialogContext, true),
                              child: Text(
                                'Remove',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ) ?? false;
                    if (!confirm) return;
                    await context.read<UserProvider>().removeFriend(user.reference);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Friend removed.',
                          style: AppTypography.bodySmall.copyWith(color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } catch (_) {
                    if (!mounted) return;
                    showSnackbar(context, 'Unable to remove friend. Please try again.');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_remove_rounded, color: AppColors.error, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
