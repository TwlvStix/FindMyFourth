import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/motion/motion_helpers.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/utils/app_util.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/notifications/notification_page/notification_page_widget.dart';
import '/notifications/notifications_list/notifications_list_widget.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import '/profile/edit_vibes/edit_vibes_widget.dart';
import '/models/vibe_profile.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/widgets/app_icon.dart';
import '/screens/trust/trust_profile_section.dart';
import '/screens/trust/your_standing_screen.dart';

class MainProfileWidget extends StatefulWidget {
  const MainProfileWidget({super.key});

  static String routeName = 'MainProfile';
  static String routePath = '/mainProfile';

  @override
  State<MainProfileWidget> createState() => _MainProfileWidgetState();
}

class _MainProfileWidgetState extends State<MainProfileWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _ringController;

  Future<void> _openChangePhotoSheet() async {
    await showAppBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: ChangePhotoWidget(),
          ),
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _pushNamed(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic>? extra,
  }) {
    final rootContext = appNavigatorKey.currentContext;
    final targetContext = rootContext ?? context;
    GoRouter.of(targetContext).pushNamed(
      routeName,
      pathParameters: pathParameters,
      extra: extra,
    );
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
          elevation: 0.0,
          actions: [
            if (currentUserReference != null)
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: StreamBuilder<QuerySnapshot>(
                  stream: currentUserReference!
                      .collection('notifications')
                      .where('read', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data?.docs.length ?? 0;
                    final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.fairway.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: AppIconButton(
                            borderColor: Colors.transparent,
                            borderRadius: 12.0,
                            borderWidth: 0,
                            buttonSize: 44.0,
                            tooltip: 'Notifications',
                            icon: AppIcon(
                              assetPath: AppIcons.notifications,
                              color: Colors.white,
                              size: 24.0,
                            ),
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              _pushNamed(
                                NotificationsListWidget.routeName,
                                extra: <String, dynamic>{
                                  kTransitionInfoKey:
                                      TransitionStandards.detailTransition,
                                },
                              );
                            },
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0.0,
                            bottom: 0.0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.sunsetRose,
                                    AppColors.sunsetPeach,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.sunsetRose.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                badgeText,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 60),

                  // ═══════════════════════════════════════════════════════════
                  // HERO SECTION - Animated Avatar with Gradient Ring
                  // ═══════════════════════════════════════════════════════════
                  _buildHeroSection(context),

                  SizedBox(height: AppSpacing.xl),

                  // ═══════════════════════════════════════════════════════════
                  // STATS CARDS - Handicap, Games Played, Friends
                  // ═══════════════════════════════════════════════════════════
                  _buildStatsSection(context),

                  SizedBox(height: AppSpacing.xl),

                  // ═══════════════════════════════════════════════════════════
                  // MAIN CONTENT CARD
                  // ═══════════════════════════════════════════════════════════
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.pure,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32.0),
                        topRight: Radius.circular(32.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle indicator
                        Container(
                          margin: EdgeInsets.only(top: AppSpacing.sm),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.cloud,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // Vibe completion banner (if needed)
                        _buildVibeCompletionBanner(context),

                        // Quick Actions Grid
                        _buildQuickActionsGrid(context),

                        // Trust Profile Section
                        AuthUserStreamWidget(
                          builder: (context) {
                            final userDoc = currentUserDocument;
                            if (userDoc == null) return const SizedBox.shrink();
                            return TrustProfileSection(
                                user: userDoc, isOwnProfile: true);
                          },
                        ),

                        // Golf Info Section
                        _buildGolfInfoSection(context),

                        // Settings Section
                        _buildSettingsSection(context),

                        SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        // Animated Avatar with Rotating Gradient Ring
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final avatarSize = (screenWidth * 0.45).clamp(120.0, 160.0);
            final ringSize = avatarSize * 0.925;
            final borderSize = avatarSize * 0.875;
            final photoSize = avatarSize * 0.825;
            final buttonSize = avatarSize * 0.25;
            final iconSize = avatarSize * 0.375;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sunsetGold.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

                // Rotating gradient ring
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _ringController.value * 2 * 3.14159,
                      child: Container(
                        width: ringSize,
                        height: ringSize,
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
                    );
                  },
                ),

                // White border
                Container(
                  width: borderSize,
                  height: borderSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pure,
                  ),
                ),

                // Profile photo
                AuthUserStreamWidget(
                  builder: (context) => GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _openChangePhotoSheet();
                    },
                    child: Container(
                      width: photoSize,
                      height: photoSize,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        valueOrDefault<String>(
                          currentUserPhoto,
                          'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.sand,
                          child: Icon(
                            Icons.person_rounded,
                            size: iconSize,
                            color: AppColors.stone,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Edit photo button
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _openChangePhotoSheet();
                    },
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sunsetGold.withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AppIcon(
                        assetPath: AppIcons.camera,
                        color: Colors.white,
                        size: buttonSize * 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        SizedBox(height: AppSpacing.lg),

        // Name
        AuthUserStreamWidget(
          builder: (context) => Text(
            '${valueOrDefault(currentUserDocument?.firstName, '')} ${valueOrDefault(currentUserDocument?.lastName, '')}',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.xxs),

        // Username
        AuthUserStreamWidget(
          builder: (context) => Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.fairway.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              '@${currentUserDisplayName}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.sunsetGold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Handicap
          Expanded(
            child: AuthUserStreamWidget(
              builder: (context) => _buildStatCard(
                context,
                icon: FontAwesomeIcons.golfBall,
                value: formatHandicap(
                  valueOrDefault(currentUserDocument?.handicap, 0),
                ),
                label: 'Handicap',
                gradient: [AppColors.sunsetGold, AppColors.sunsetPeach],
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Home Course (shortened)
          Expanded(
            child: AuthUserStreamWidget(
              builder: (context) {
                final course =
                    valueOrDefault(currentUserDocument?.homeCourse, 'Not Set');
                final shortCourse = course.length > 12
                    ? '${course.substring(0, 10)}...'
                    : course;
                return _buildStatCard(
                  context,
                  icon: FontAwesomeIcons.mapMarkerAlt,
                  value: shortCourse,
                  label: 'Home Course',
                  gradient: [AppColors.fairwayLight, AppColors.fairway],
                  isText: true,
                );
              },
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Friends count
          Expanded(
            child: AuthUserStreamWidget(
              builder: (context) {
                final friendsCount = currentUserDocument?.friends.length ?? 0;
                return _buildStatCard(
                  context,
                  icon: FontAwesomeIcons.userFriends,
                  value: friendsCount.toString(),
                  label: 'Friends',
                  gradient: [AppColors.sunsetPeach, AppColors.sunsetRose],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pushNamed(TabFriendsWidget.routeName);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
    bool isText = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.fairway.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: isText
                  ? AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )
                  : AppTypography.monoLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VIBE COMPLETION BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVibeCompletionBanner(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        final profile = VibeProfile.fromFirestore(
          Map<String, dynamic>.from(
            currentUserDocument?.vibeProfile ?? const <String, dynamic>{},
          ),
        );
        if (profile.isComplete) {
          return SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _pushNamed(
                EditVibesWidget.routeName,
                extra: <String, dynamic>{
                  kTransitionInfoKey: TransitionInfo(
                    hasTransition: true,
                    transitionType: PageTransitionType.fade,
                    enterDuration: Duration(milliseconds: 200),
                    exitDuration: Duration(milliseconds: 170),
                    scaleOnPush: false,
                  ),
                },
              );
            },
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.sunsetGold.withOpacity(0.15),
                    AppColors.sunsetPeach.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sunsetGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Your Vibe Profile',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.onyx,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Help us match you with the right golfers',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.sunsetGold,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS GRID
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          // Use 2 columns for small screens, 3 for larger screens
          final useCompactLayout = screenWidth < 400;

          if (useCompactLayout) {
            // 2-column layout for small screens
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        gradient: [AppColors.fairwayLight, AppColors.fairway],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pushNamed(
                            EditProfileWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.fade,
                                enterDuration: Duration(milliseconds: 200),
                                exitDuration: Duration(milliseconds: 170),
                                scaleOnPush: false,
                              ),
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.tune_rounded,
                        label: 'Golf Vibes',
                        gradient: [AppColors.sunsetGold, AppColors.sunsetPeach],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pushNamed(
                            EditVibesWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.fade,
                                enterDuration: Duration(milliseconds: 200),
                                exitDuration: Duration(milliseconds: 170),
                                scaleOnPush: false,
                              ),
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // 3-column layout for larger screens
            return Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    gradient: [AppColors.fairwayLight, AppColors.fairway],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pushNamed(
                        EditProfileWidget.routeName,
                        extra: <String, dynamic>{
                          kTransitionInfoKey: TransitionInfo(
                            hasTransition: true,
                            transitionType: PageTransitionType.fade,
                            enterDuration: Duration(milliseconds: 200),
                            exitDuration: Duration(milliseconds: 170),
                            scaleOnPush: false,
                          ),
                        },
                      );
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.tune_rounded,
                    label: 'Golf Vibes',
                    gradient: [AppColors.sunsetGold, AppColors.sunsetPeach],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pushNamed(
                        EditVibesWidget.routeName,
                        extra: <String, dynamic>{
                          kTransitionInfoKey: TransitionInfo(
                            hasTransition: true,
                            transitionType: PageTransitionType.fade,
                            enterDuration: Duration(milliseconds: 200),
                            exitDuration: Duration(milliseconds: 170),
                            scaleOnPush: false,
                          ),
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cloud,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.slate,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLF INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGolfInfoSection(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Golf Info',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onyx,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Golf Canada Number
          AuthUserStreamWidget(
            builder: (context) => _buildInfoRow(
              context,
              icon: Icons.verified_rounded,
              iconColor: AppColors.fairway,
              label: 'Golf Canada #',
              value: valueOrDefault(
                  currentUserDocument?.golfCanadaNumber, 'Not set'),
            ),
          ),

          SizedBox(height: AppSpacing.sm),

          // Email
          _buildInfoRow(
            context,
            svgPath: AppIcons.email,
            iconColor: AppColors.sunsetPeach,
            label: 'Email',
            value: currentUserEmail,
          ),

          SizedBox(height: AppSpacing.sm),

          // Phone
          AuthUserStreamWidget(
            builder: (context) => _buildInfoRow(
              context,
              svgPath: AppIcons.phone,
              iconColor: AppColors.sunsetGold,
              label: 'Phone',
              value: currentPhoneNumber.isNotEmpty
                  ? currentPhoneNumber
                  : 'Not set',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    IconData? icon,
    String? svgPath,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: svgPath != null
                ? AppIcon(assetPath: svgPath, color: iconColor, size: 20)
                : Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onyx,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onyx,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cloud),
            ),
            child: Column(
              children: [
                currentUserReference == null
                    ? _buildSettingsRow(
                        context,
                        svgPath: AppIcons.notifications,
                        label: 'Notifications',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pushNamed(
                            NotificationPageWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.fade,
                                enterDuration: Duration(milliseconds: 200),
                                exitDuration: Duration(milliseconds: 170),
                                scaleOnPush: true,
                              ),
                            },
                          );
                        },
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: currentUserReference!
                            .collection('notifications')
                            .where('read', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data?.docs.length ?? 0;
                          return _buildSettingsRow(
                            context,
                            svgPath: AppIcons.notifications,
                            label: 'Notifications',
                            trailing: unreadCount > 0
                                ? NotificationBadge(count: unreadCount)
                                : null,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pushNamed(
                                NotificationPageWidget.routeName,
                                extra: <String, dynamic>{
                                  kTransitionInfoKey: TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    enterDuration: Duration(milliseconds: 200),
                                    exitDuration: Duration(milliseconds: 170),
                                    scaleOnPush: true,
                                  ),
                                },
                              );
                            },
                          );
                        },
                      ),
                Divider(height: 1, color: AppColors.cloud, indent: 56),
                _buildSettingsRow(
                  context,
                  svgPath: AppIcons.standing,
                  label: 'Your Standing',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pushNamed(
                      YourStandingScreen.routeName,
                      extra: <String, dynamic>{
                        kTransitionInfoKey: TransitionInfo(
                          hasTransition: true,
                          transitionType: PageTransitionType.fade,
                          enterDuration: const Duration(milliseconds: 200),
                          exitDuration: const Duration(milliseconds: 170),
                          scaleOnPush: false,
                        ),
                      },
                    );
                  },
                ),
                Divider(height: 1, color: AppColors.cloud, indent: 56),
                _buildSettingsRow(
                  context,
                  svgPath: AppIcons.logOut,
                  label: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    HapticFeedback.mediumImpact();

                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Log Out?',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.onyx,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to log out of your account?',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.stone,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Log Out',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      GoRouter.of(context).prepareAuthEvent();
                      await authManager.signOut();
                      GoRouter.of(context).clearRedirectLocation();

                      if (!context.mounted) return;
                      final router = GoRouter.of(context);
                      if (router.shouldRedirect(false)) return;
                      router.goNamed(SignInWidget.routeName);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    IconData? icon,
    String? svgPath,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.slate;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            svgPath != null
                ? AppIcon(assetPath: svgPath, color: color, size: 22)
                : Icon(icon, color: color, size: 22),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight:
                      isDestructive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              SizedBox(width: AppSpacing.xs),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.stone,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
