import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/user_auth/shared/auth_desktop_sidebar.dart';
import '/user_auth/sign_in/components/sign_in_actions.dart';
import '/user_auth/sign_in/components/sign_in_form_fields.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';

class SignInWidget extends StatefulWidget {
  const SignInWidget({super.key});

  static String routeName = 'SignIn';
  static String routePath = '/signIn';

  @override
  State<SignInWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formFieldsKey = GlobalKey<SignInFormFieldsState>();

  Future<void> _handleEmailSignIn() async {
    GoRouter.of(context).prepareAuthEvent();

    final fields = _formFieldsKey.currentState!;
    final user = await authManager.signInWithEmail(
      context,
      fields.email,
      fields.password,
    );
    if (user == null) return;

    if (!mounted) return;
    final router = GoRouter.of(context);
    if (router.shouldRedirect(false)) return;

    await authManager.handlePostAuthNavigation(
      context,
      fallbackRouteName: GamesListWidget.routeName,
      fallbackExtra: <String, dynamic>{
        kTransitionInfoKey: TransitionInfo(
          hasTransition: true,
          transitionType: AppTransitionType.fade,
          enterDuration: Duration(milliseconds: 200),
          exitDuration: Duration(milliseconds: 170),
          scaleOnPush: true,
        ),
      },
      replaceRoute: true,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.signInWithGoogle(context);
    if (user == null) return;

    if (!mounted) return;
    final router = GoRouter.of(context);
    if (router.shouldRedirect(false)) return;

    await authManager.handlePostAuthNavigation(
      context,
      fallbackRouteName: GamesListWidget.routeName,
      fallbackExtra: <String, dynamic>{
        kTransitionInfoKey: TransitionInfo(
          hasTransition: true,
          transitionType: AppTransitionType.fade,
          enterDuration: Duration(milliseconds: 200),
          exitDuration: Duration(milliseconds: 170),
          scaleOnPush: true,
        ),
      },
      replaceRoute: true,
    );
  }

  Future<void> _handleAppleSignIn() async {
    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.signInWithApple(context);
    if (user == null) return;

    if (!mounted) return;
    final router = GoRouter.of(context);
    if (router.shouldRedirect(false)) return;

    await authManager.handlePostAuthNavigation(
      context,
      fallbackRouteName: GamesListWidget.routeName,
      fallbackExtra: <String, dynamic>{
        kTransitionInfoKey: TransitionInfo(
          hasTransition: true,
          transitionType: AppTransitionType.fade,
          enterDuration: Duration(milliseconds: 200),
          exitDuration: Duration(milliseconds: 170),
          scaleOnPush: true,
        ),
      },
      replaceRoute: true,
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
        body: FairwayBackgroundClubhouse(
          showOrganic: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  width: 100.0,
                  height: double.infinity,
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(maxWidth: 430.0),
                          decoration: BoxDecoration(
                            color: AppColors.transparent,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                AppSpacing.xl, 90.0, AppSpacing.xl, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                AppText.screenTitle('Sign In',
                                    color: AppColors.textPrimary),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: AppSpacing.xs,
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: AppText.bodySmall(
                                    'Welcome Back. Ready to Play a game?',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SignInFormFields(key: _formFieldsKey),
                                SignInActions(
                                  onSignIn: _handleEmailSignIn,
                                  onGoogleSignIn: _handleGoogleSignIn,
                                  onAppleSignIn: _handleAppleSignIn,
                                  onSignUpTap: () {
                                    context.pushSignUpAccount(
                                      transition: TransitionStandards
                                          .modalTransition,
                                    );
                                  },
                                  onForgotPasswordTap: () {
                                    context.pushRecoverPassword(
                                      transition: TransitionStandards
                                          .modalTransition,
                                    );
                                  },
                                  onBrowseGamesTap: () =>
                                      context.pushGuestBrowse(),
                                  onHowItWorksTap: () =>
                                      context.pushHowItWorks(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (responsiveVisibility(
                context: context,
                phone: false,
                tablet: false,
              ))
                Expanded(
                  flex: 8,
                  child: const AuthDesktopSidebar(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
