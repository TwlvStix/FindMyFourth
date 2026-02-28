import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/motion/motion_helpers.dart';
import '/utils/app_util.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/notification_settings/notification_settings_widget.dart';
import '/notifications/notifications_list/notifications_list_widget.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import '/profile/edit_vibes/edit_vibes_widget.dart';
import '/models/vibe_profile.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_stat_card.dart';
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
                            color: AppColors.navy.withValues(alpha:0.3),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                              color: AppColors.glassSurface,
                            ),
                          ),
                          child: AppIconButton(
                            borderColor: Colors.transparent,
                            borderRadius: 12.0,
                            borderWidth: 0,
                            buttonSize: 44.0,
                            tooltip: 'Notifications',
                            icon: AppIcon(
                              icon: AppPhosphorIcons.notifications,
                              color: AppColors.pure,
                              size: AppIconSize.md,
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
                                horizontal: AppSpacing.xs - 2,
                                vertical: AppSpacing.xxs - 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.error,
                                    AppColors.goldLight,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                boxShadow: [AppElevation.md],
                              ),
                              child: Text(
                                badgeText,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.pure,
                                  fontWeight: AppTypography.bold,
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
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.xxl),
                        topRight: Radius.circular(AppBorderRadius.xxl),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.overlayDark,
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
                            color: AppColors.navyLight,
                            borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
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
                // Outer glow - gold with ambient intensity
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                // Rotating gradient ring - gold-centric for premium feel
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
                              AppColors.gold,
                              AppColors.goldLight,
                              AppColors.error,
                              AppColors.navyLight,
                              AppColors.gold,
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
                          child: AppIcon(
                            icon: AppPhosphorIcons.profile,
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
                          colors: [AppColors.green, AppColors.greenLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [AppElevation.glowGreen],
                      ),
                      child: AppIcon(
                        icon: AppPhosphorIcons.camera,
                        color: AppColors.pure,
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
              color: AppColors.pure,
            ),
          ),
        ),

        SizedBox(height: AppSpacing.xs),

        // Metadata row: age · gender · @username
        AuthUserStreamWidget(
          builder: (context) {
            final metadataParts = <String>[];

            // Calculate age from date of birth
            final dob = currentUserDocument?.dateOfBirth;
            if (dob != null) {
              final now = DateTime.now();
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
              if (age > 0) metadataParts.add(age.toString());
            }

            // Gender
            final gender = valueOrDefault(currentUserDocument?.gender, '');
            if (gender.isNotEmpty) metadataParts.add(gender);

            // Username
            final handle = currentUserDisplayName;
            if (handle.isNotEmpty) metadataParts.add('@$handle');

            final metadataLine = metadataParts.join(' · ');

            if (metadataLine.isEmpty) return SizedBox.shrink();

            return Text(
              metadataLine,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsSection(BuildContext context) {
    return Column(
      children: [
        // Two-card row: Handicap + Friends
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handicap
                Expanded(
                  child: AuthUserStreamWidget(
                    builder: (context) => AppStatCard(
                      variant: AppStatCardVariant.glass,
                      icon: AppPhosphorIcons.handicap,
                      value: formatHandicap(
                        valueOrDefault(currentUserDocument?.handicap, 0),
                      ),
                      label: 'Handicap',
                      iconGradient: [AppColors.gold, AppColors.goldLight],
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),

                // Friends count
                Expanded(
                  child: AuthUserStreamWidget(
                    builder: (context) {
                      final friendsCount = currentUserDocument?.friends.length ?? 0;
                      return AppStatCard(
                        variant: AppStatCardVariant.glass,
                        icon: AppPhosphorIcons.friends,
                        value: friendsCount.toString(),
                        label: 'Friends',
                        iconGradient: [AppColors.gold, AppColors.goldLight],
                        onTap: () {
                          _pushNamed(
                            TabFriendsWidget.routeName,
                            extra: <String, dynamic>{'initialSegment': 'friends'},
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
        SizedBox(height: AppSpacing.md),

        // Home course text row
        AuthUserStreamWidget(
          builder: (context) {
            final course =
                valueOrDefault(currentUserDocument?.homeCourse, 'Not Set');
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppPhosphorIcons.homeCourse,
                  color: AppColors.textSecondary,
                  size: AppIconSize.sm,
                ),
                SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    course,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ],
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
                    transitionType: AppTransitionType.fade,
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
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha:0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: AppIcon(
                      icon: AppPhosphorIcons.golfVibes,
                      color: AppColors.pure,
                      size: AppIconSize.md,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Help us match you with the right golfers',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIcon(
                    icon: AppPhosphorIcons.chevronRight,
                    color: AppColors.gold,
                    size: AppIconSize.button,
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
                        icon: AppPhosphorIcons.editProfile,
                        label: 'Edit Profile',
                        gradient: [AppColors.navyLight, AppColors.navy],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pushNamed(
                            EditProfileWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: AppTransitionType.fade,
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
                        icon: AppPhosphorIcons.golfVibes,
                        label: 'Golf Vibes',
                        gradient: [AppColors.gold, AppColors.goldLight],
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _pushNamed(
                            EditVibesWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: AppTransitionType.fade,
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
                    icon: AppPhosphorIcons.editProfile,
                    label: 'Edit Profile',
                    gradient: [AppColors.navyLight, AppColors.navy],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pushNamed(
                        EditProfileWidget.routeName,
                        extra: <String, dynamic>{
                          kTransitionInfoKey: TransitionInfo(
                            hasTransition: true,
                            transitionType: AppTransitionType.fade,
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
                    icon: AppPhosphorIcons.golfVibes,
                    label: 'Golf Vibes',
                    gradient: [AppColors.green, AppColors.greenLight],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pushNamed(
                        EditVibesWidget.routeName,
                        extra: <String, dynamic>{
                          kTransitionInfoKey: TransitionInfo(
                            hasTransition: true,
                            transitionType: AppTransitionType.fade,
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
    required PhosphorIconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.navyLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: AppIcon(
                icon: icon,
                color: AppColors.pure,
                size: AppIconSize.button,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: AppTypography.medium,
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Golf Canada Number
          AuthUserStreamWidget(
            builder: (context) => _buildInfoRow(
              context,
              phosphorIcon: AppPhosphorIcons.verified,
              label: 'Golf Canada #',
              value: valueOrDefault(
                  currentUserDocument?.golfCanadaNumber, 'Not set'),
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Email
          _buildInfoRow(
            context,
            phosphorIcon: AppPhosphorIcons.email,
            label: 'Email',
            value: currentUserEmail,
          ),

          SizedBox(height: AppSpacing.md),

          // Phone
          AuthUserStreamWidget(
            builder: (context) => _buildInfoRow(
              context,
              phosphorIcon: AppPhosphorIcons.phone,
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
    required PhosphorIconData phosphorIcon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          // Just icon, no container background
          AppIcon(
            icon: phosphorIcon,
            color: AppColors.textMuted,
            size: AppIconSize.md,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.medium,
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: AppColors.navyLight),
            ),
            child: Column(
              children: [
                _buildSettingsRow(
                  context,
                  phosphorIcon: AppPhosphorIcons.notifications,
                  label: 'Notifications',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pushNamed(
                      NotificationSettingsWidget.routeName,
                      extra: <String, dynamic>{
                        kTransitionInfoKey: TransitionInfo(
                          hasTransition: true,
                          transitionType: AppTransitionType.fade,
                          enterDuration: Duration(milliseconds: 200),
                          exitDuration: Duration(milliseconds: 170),
                          scaleOnPush: true,
                        ),
                      },
                    );
                  },
                ),
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  context,
                  phosphorIcon: AppPhosphorIcons.standing,
                  label: 'Your Standing',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pushNamed(
                      YourStandingScreen.routeName,
                      extra: <String, dynamic>{
                        kTransitionInfoKey: TransitionInfo(
                          hasTransition: true,
                          transitionType: AppTransitionType.fade,
                          enterDuration: const Duration(milliseconds: 200),
                          exitDuration: const Duration(milliseconds: 170),
                          scaleOnPush: false,
                        ),
                      },
                    );
                  },
                ),
                Divider(height: 1, color: AppColors.navyLight, indent: 56),
                _buildSettingsRow(
                  context,
                  phosphorIcon: AppPhosphorIcons.logOut,
                  label: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    HapticFeedback.mediumImpact();

                    // Show confirmation dialog
                    final shouldLogout = await showPremiumDialog(
                      context: context,
                      variant: PremiumDialogVariant.destructive,
                      icon: PhosphorIconsRegular.signOut,
                      title: 'Log Out',
                      body: 'You will need to sign in again to access your account.',
                      actionLabel: 'Log Out',
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
    required PhosphorIconData phosphorIcon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    // Muted red for less alarm on destructive actions
    final color = isDestructive
        ? AppColors.error.withValues(alpha: 0.85)
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppIcon(
              icon: phosphorIcon,
              color: color,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight:
                      isDestructive ? AppTypography.medium : null,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              SizedBox(width: AppSpacing.xs),
            ],
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppIconSize.md,
            ),
          ],
        ),
      ),
    );
  }
}
