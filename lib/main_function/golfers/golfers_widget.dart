import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/autocomplete_options_list.dart';
import '/core/button_tabbar.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/app_router.dart';
import '/profile/profile_user/profile_user_firebase_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    textFieldFocusNode?.dispose();
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
        backgroundColor: AppTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Golfers',
            style: AppTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with dark background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A4D2E),
                    Color(0xFF2A5F3E),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'Find golfers, manage connections, and build your network',
                  style: AppTheme.of(context).labelMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).labelMedium.fontWeight,
                          fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight: AppTheme.of(context).labelMedium.fontWeight,
                        fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                      ),
                ),
              ),
            ),
            // Tabs with light background
            Container(
              color: Color(0xFFF5F5F5),
              child: Align(
                alignment: Alignment(-1.0, 0),
                child: AppButtonTabBar(
                  useToggleButtonStyle: false,
                  labelStyle: AppTheme.of(context).titleMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).titleMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).titleMedium.fontStyle,
                        ),
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).titleMedium.fontWeight,
                        fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                      ),
                  unselectedLabelStyle: TextStyle(),
                  labelColor: AppTheme.of(context).primaryBtnText,
                  unselectedLabelColor: AppTheme.of(context).secondaryText,
                  backgroundColor: AppTheme.of(context).primary,
                  unselectedBackgroundColor: AppTheme.of(context).alternate,
                  borderColor: AppTheme.of(context).primary,
                  unselectedBorderColor: AppTheme.of(context).alternate,
                  borderWidth: 2.0,
                  borderRadius: 8.0,
                  elevation: 0.0,
                  labelPadding: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.sm, 0.0, AppSpacing.sm, 0.0),
                  buttonMargin: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.xs, 0.0, AppSpacing.xs, 0.0),
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
            // Content area with light background
            Expanded(
              child: Container(
                color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.xs, 0.0, AppSpacing.xs, 0.0),
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
                            textStyle: AppTheme.of(context).bodyMedium,
                            textHighlightStyle: TextStyle(),
                            elevation: 4.0,
                            optionBackgroundColor:
                                AppTheme.of(context).primaryBackground,
                            optionHighlightColor:
                                AppTheme.of(context).secondaryBackground,
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
                              labelStyle: AppTheme.of(context).labelMedium,
                              hintStyle: AppTheme.of(context).labelMedium,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.of(context).alternate,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.of(context).primary,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.of(context).error,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.of(context).secondaryText,
                              ),
                            ),
                            style: AppTheme.of(context).bodyMedium,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.sm, 0.0, 0.0, 0.0),
                    child: AppIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 30.0,
                      borderWidth: 1.0,
                      buttonSize: 44.0,
                      icon: Icon(
                        Icons.clear_sharp,
                        color: AppTheme.of(context).primary,
                        size: 24.0,
                      ),
                      onPressed: () {
                        textController?.clear();
                        FocusScope.of(context).unfocus();
                        if (mounted) {
                          setState(() {});
                        }
                      },
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
                    child: SizedBox(
                      width: 50.0,
                      height: 50.0,
                      child: SpinKitWanderingCubes(
                        color: AppTheme.of(context).secondary,
                        size: 50.0,
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
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64.0,
                            color: Color(0xFF9E9E9E),
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'No golfers found',
                            style: AppTheme.of(context).bodyLarge.override(
                                  font: GoogleFonts.outfit(),
                                  color: Color(0xFF616161),
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
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
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
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64.0,
                              color: Color(0xFF9E9E9E),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'No pending requests',
                              style: AppTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.outfit(),
                                    color: Color(0xFF616161),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Friend requests will appear here',
                              style: AppTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.outfit(),
                                    color: Color(0xFF9E9E9E),
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
                                  color: AppTheme.of(context).secondary,
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
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
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
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64.0,
                              color: Color(0xFF9E9E9E),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'No friends yet',
                              style: AppTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.outfit(),
                                    color: Color(0xFF616161),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Search for golfers to connect with',
                              style: AppTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.outfit(),
                                    color: Color(0xFF9E9E9E),
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
                                  color: AppTheme.of(context).secondary,
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
      ),
    );
  }

  Widget _buildUserCard(UsersRecord user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border(
          left: BorderSide(
            color: Color(0xFF1A4D2E),
            width: 5.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(28.0),
              child: Image.network(
                valueOrDefault<String>(
                  user.photoUrl,
                  'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                ),
                width: 56.0,
                height: 56.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.0),
            // Name and course
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOrDefault<String>(user.displayName, 'Golfer'),
                    style: GoogleFonts.outfit(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A4D2E),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  if (user.homeCourse.isNotEmpty)
                    Text(
                      user.homeCourse,
                      style: GoogleFonts.outfit(
                        fontSize: 13.0,
                        color: Color(0xFF718096),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.0),
            // Action buttons
            AuthUserStreamWidget(
              builder: (context) {
                final isFriend =
                    (currentUserDocument?.friends.toList() ?? [])
                        .contains(user.reference);
                final hasPending = user.friendRequests
                        .contains(currentUserReference) ||
                    (currentUserDocument?.friendRequests.toList() ?? [])
                        .contains(user.reference);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary action button (state-based)
                    if (isFriend)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Color(0xFF1A4D2E),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF1A4D2E),
                              size: 16.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'Friends',
                              style: GoogleFonts.outfit(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A4D2E),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (hasPending)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Color(0xFF9E9E9E),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending,
                              color: Color(0xFF718096),
                              size: 16.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'Pending',
                              style: GoogleFonts.outfit(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context
                              .read<UserProvider>()
                              .sendFriendRequest(user.reference);
                          if (mounted) setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Friend request sent!',
                                style: GoogleFonts.outfit(color: Colors.white),
                              ),
                              duration: Duration(milliseconds: 1500),
                              backgroundColor: Color(0xFF1A4D2E),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.person_add,
                          size: 16.0,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Add Friend',
                          style: GoogleFonts.outfit(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A4D2E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                        ),
                      ),
                    SizedBox(width: 8.0),
                    // View profile icon button
                    AppIconButton(
                      borderColor: Color(0xFFE0E0E0),
                      borderRadius: 8.0,
                      borderWidth: 1.0,
                      buttonSize: 44.0,
                      fillColor: Colors.white,
                      icon: Icon(
                        Icons.visibility_outlined,
                        color: Color(0xFF1A4D2E),
                        size: 20.0,
                      ),
                      onPressed: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileUserFirebaseWidget(
                              userRef: user.reference,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8.0),
                    // Chat icon button
                    AppIconButton(
                      borderColor: Color(0xFFE0E0E0),
                      borderRadius: 8.0,
                      borderWidth: 1.0,
                      buttonSize: 44.0,
                      fillColor: Colors.white,
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF1A4D2E),
                        size: 20.0,
                      ),
                      onPressed: () async {
                        await _openDirectChat(user);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(UsersRecord user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border(
          left: BorderSide(
            color: Color(0xFFE65100),
            width: 5.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26.0),
              child: Image.network(
                valueOrDefault<String>(
                  user.photoUrl,
                  'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                ),
                width: 52.0,
                height: 52.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A4D2E),
                    ),
                  ),
                  if (user.homeCourse.isNotEmpty)
                    Text(
                      user.homeCourse,
                      style: GoogleFonts.outfit(
                        fontSize: 13.0,
                        color: Color(0xFF718096),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                AppIconButton(
                  borderColor: Color(0xFF1A4D2E),
                  borderRadius: 20.0,
                  borderWidth: 1.0,
                  buttonSize: 40.0,
                  fillColor: Color(0xFF1A4D2E),
                  icon: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18.0,
                  ),
                  onPressed: () async {
                    await context
                        .read<UserProvider>()
                        .acceptFriendRequest(user.reference);
                    if (mounted) setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Friend request accepted!',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: AppTheme.of(context).primary,
                      ),
                    );
                  },
                ),
                SizedBox(width: 8.0),
                AppIconButton(
                  borderColor: Color(0xFFD32F2F),
                  borderRadius: 20.0,
                  borderWidth: 1.0,
                  buttonSize: 40.0,
                  fillColor: Color(0xFFD32F2F),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18.0,
                  ),
                  onPressed: () async {
                    await context
                        .read<UserProvider>()
                        .rejectFriendRequest(user.reference);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(UsersRecord user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border(
          left: BorderSide(
            color: Color(0xFF1A4D2E),
            width: 5.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26.0),
              child: Image.network(
                valueOrDefault<String>(
                  user.photoUrl,
                  'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                ),
                width: 52.0,
                height: 52.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueOrDefault<String>(user.displayName, 'Friend'),
                    style: GoogleFonts.outfit(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A4D2E),
                    ),
                  ),
                  if (user.homeCourse.isNotEmpty)
                    Text(
                      user.homeCourse,
                      style: GoogleFonts.outfit(
                        fontSize: 13.0,
                        color: Color(0xFF718096),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                AppButtonEnhanced(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileUserFirebaseWidget(
                          userRef: user.reference,
                        ),
                      ),
                    );
                  },
                  text: 'View',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                ),
                SizedBox(width: 8.0),
                AppIconButton(
                  borderColor: AppTheme.of(context).primary,
                  borderRadius: 20.0,
                  borderWidth: 1.0,
                  buttonSize: 40.0,
                  fillColor: Color(0xFF1A4D2E),
                  icon: FaIcon(
                    FontAwesomeIcons.facebookMessenger,
                    color: Colors.white,
                    size: 16.0,
                  ),
                  onPressed: () async {
                    await _openDirectChat(user);
                  },
                ),
                SizedBox(width: 8.0),
                AppIconButton(
                  borderColor: AppTheme.of(context).error,
                  borderRadius: 20.0,
                  borderWidth: 1.0,
                  buttonSize: 40.0,
                  fillColor: AppTheme.of(context).error,
                  icon: Icon(
                    Icons.person_remove,
                    color: Colors.white,
                    size: 18.0,
                  ),
                  onPressed: () async {
                    try {
                      final confirm = await showDialog<bool>(
                            context: context,
                            builder: (alertDialogContext) {
                              return AlertDialog(
                                title: Text('Remove friend?'),
                                content: Text(
                                  'This will remove you from each other’s friends list.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(alertDialogContext, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(alertDialogContext, true),
                                    child: Text('Remove'),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;
                      if (!confirm) {
                        return;
                      }
                      await context
                          .read<UserProvider>()
                          .removeFriend(user.reference);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Friend removed.',
                            style: GoogleFonts.outfit(color: Colors.white),
                          ),
                          duration: Duration(milliseconds: 1500),
                          backgroundColor: AppTheme.of(context).error,
                        ),
                      );
                    } catch (_) {
                      if (!mounted) return;
                      showSnackbar(
                        context,
                        'Unable to remove friend. Please try again.',
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
