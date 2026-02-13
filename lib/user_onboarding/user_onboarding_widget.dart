import 'package:firebase_auth/firebase_auth.dart';

import '/backend/backend.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/profile/create_profile/create_profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserOnboardingWidget extends StatefulWidget {
  const UserOnboardingWidget({super.key});

  static String routeName = 'UserOnboarding';
  static String routePath = '/onboarding';

  @override
  State<UserOnboardingWidget> createState() => _UserOnboardingWidgetState();
}

class _UserOnboardingWidgetState extends State<UserOnboardingWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _ensureUserRecord();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) {
      return;
    }

    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    final nextAfterVibes = nextRoute == null ||
            nextRoute.isEmpty ||
            nextRoute == CreateProfileWidget.routeName
        ? GamesListWidget.routeName
        : nextRoute;
    final recordReady = await _ensureUserRecord();
    if (!recordReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Finishing setup. Please wait a moment before continuing.',
          ),
          backgroundColor: AppTheme.of(context).error,
        ),
      );
      return;
    }
    context.goNamed(
      CreateProfileWidget.routeName,
      queryParameters: {
        'next': nextAfterVibes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: FairwayBackgroundSunset(
        child: SafeArea(
          top: true,
          child: Padding(
            padding: AppSpacing.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Find My Fourth',
                  style: AppTheme.of(context).headlineMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).headlineMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).headlineMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).headlineMedium.fontWeight,
                        fontStyle: AppTheme.of(context).headlineMedium.fontStyle,
                      ),
                ),
                Padding(
                  padding: AppSpacing.only(top: AppSpacing.sm),
                  child: Text(
                    'A quick primer before you tee off.',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight:
                                AppTheme.of(context).bodyLarge.fontWeight,
                            fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                ),
                Padding(
                  padding: AppSpacing.only(top: AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _OnboardingFeature(
                        icon: Icons.golf_course_rounded,
                        title: 'Join games fast',
                        description:
                            'Find rounds in your area and jump in with a tap.',
                      ),
                      _OnboardingFeature(
                        icon: Icons.people_alt_rounded,
                        title: 'Meet new players',
                        description:
                            'Connect with friends and manage invites easily.',
                      ),
                      _OnboardingFeature(
                        icon: Icons.notifications_active_rounded,
                        title: 'Stay in the loop',
                        description:
                            'Enable alerts so you never miss a tee time.',
                      ),
                    ],
                  ),
                ),
                Spacer(),
                AppButtonEnhanced(
                  text: 'Get Started',
                  onPressed: _completeOnboarding,
                  variant: AppButtonVariant.gradient,
                  size: AppButtonSize.medium,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureUserRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    try {
      await ensureUserDocReady(user);
      return true;
    } catch (error, stackTrace) {
      debugPrint('❌ ONBOARDING: unable to ensure user doc exists: $error');
      debugPrint('❌ ONBOARDING: Stack trace: $stackTrace');
      return false;
    }
  }
}

class _OnboardingFeature extends StatelessWidget {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppTheme.of(context).primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Icon(
              icon,
              color: AppTheme.of(context).primary,
              size: 24.0,
            ),
          ),
          Expanded(
            child: Padding(
              padding: AppSpacing.only(left: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.of(context).titleMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight:
                                AppTheme.of(context).titleMedium.fontWeight,
                            fontStyle:
                                AppTheme.of(context).titleMedium.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).titleMedium.fontWeight,
                          fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                        ),
                  ),
                  Padding(
                    padding: AppSpacing.only(top: AppSpacing.xxs),
                    child: Text(
                      description,
                      style: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.outfit(
                              fontWeight:
                                  AppTheme.of(context).bodyMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).bodyMedium.fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight:
                                AppTheme.of(context).bodyMedium.fontWeight,
                            fontStyle:
                                AppTheme.of(context).bodyMedium.fontStyle,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
