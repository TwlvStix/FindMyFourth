import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/app_notification_badge_button.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/motion/motion_helpers.dart';
import '/utils/app_util.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/screens/trust/trust_profile_section.dart';

// Extracted components
import 'components/profile_hero_section.dart';
import 'components/profile_stats_section.dart';
import 'components/vibe_completion_banner.dart';
import 'components/profile_quick_actions_grid.dart';
import 'components/profile_golf_info_section.dart';
import 'components/profile_settings_section.dart';
import 'components/profile_streak_section.dart';

/// Main profile page showing user info, stats, and settings.
///
/// Composes extracted sub-widgets for maintainability.
/// Owns the ring animation controller and navigation callbacks.
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

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CALLBACKS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _openChangePhotoSheet() async {
    await showAppBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
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

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: AppPhosphorIcons.logOut,
      title: 'Log Out',
      body: 'You will need to sign in again to access your account.',
      actionLabel: 'Log Out',
    );

    if (shouldLogout != true) return;
    if (!mounted) return;
    GoRouter.of(context).prepareAuthEvent();
    await authManager.signOut();
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();

    if (!mounted) return;
    final router = GoRouter.of(context);
    if (router.shouldRedirect(false)) return;
    context.goSignIn();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

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
          backgroundColor: AppColors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: AppNotificationBadgeButton(
                onTap: () => context.pushNotifications(),
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

                  // Hero Section - Animated Avatar with Gradient Ring
                  ProfileHeroSection(
                    ringController: _ringController,
                    onPhotoTap: _openChangePhotoSheet,
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Stats Cards - Handicap, Friends
                  ProfileStatsSection(
                    onFriendsTap: () {
                      context.pushTabFriends(
                        initialSegment: 'friends',
                        transition: TransitionStandards.noTransition,
                      );
                    },
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Main Content Card
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
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xxs),
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // Vibe completion banner (if needed)
                        VibeCompletionBanner(
                          onTap: () => context.pushEditVibes(),
                        ),

                        // Quick Actions Grid
                        ProfileQuickActionsGrid(
                          onEditProfile: () => context.pushEditProfile(),
                          onGolfVibes: () => context.pushEditVibes(),
                        ),

                        // Trust Profile Section
                        AuthUserStreamWidget(
                          builder: (context) {
                            final userDoc = currentUserDocument;
                            if (userDoc == null) return const SizedBox.shrink();
                            return TrustProfileSection(
                                user: userDoc, isOwnProfile: true);
                          },
                        ),

                        // Streak Profile Section
                        const ProfileStreakSection(),

                        // Golf Info Section
                        const ProfileGolfInfoSection(),

                        // Settings Section
                        ProfileSettingsSection(
                          onNotifications: () =>
                              context.pushNotificationSettings(),
                          onYourStanding: () => context.pushYourStanding(
                            transition: TransitionStandards.flatFadeTransition,
                          ),
                          onLogout: _handleLogout,
                          showDebugOptions: kDebugMode,
                          onDebugNotificationRouting: () =>
                              context.push('/debug/notification-routing'),
                          onDebugStreakPreview: () =>
                              context.push('/debug/streak'),
                        ),

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
}
