import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button.dart';
import '/profile/home/home_widget.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final userRef = currentUserReference;
    if (userRef != null) {
      await userRef.update(createUsersRecordData(
        onboardingCompleted: true,
      ));
    }

    if (!mounted) {
      return;
    }

    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    if (nextRoute != null && nextRoute.isNotEmpty) {
      context.goNamed(nextRoute);
    } else {
      context.goNamed(HomeWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(24.0, 32.0, 24.0, 32.0),
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
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
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
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 0.0),
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
              AppButton(
                onPressed: _completeOnboarding,
                text: 'Get Started',
                options: AppButtonOptions(
                  width: double.infinity,
                  height: 48.0,
                  padding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  iconPadding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: AppTheme.of(context).primary,
                  textStyle: AppTheme.of(context).titleSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).titleSmall.fontWeight,
                          fontStyle: AppTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: Colors.white,
                        letterSpacing: 0.0,
                        fontWeight: AppTheme.of(context).titleSmall.fontWeight,
                        fontStyle: AppTheme.of(context).titleSmall.fontStyle,
                      ),
                  elevation: 2.0,
                  borderSide: BorderSide(
                    color: Colors.transparent,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 20.0),
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
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
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
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
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
