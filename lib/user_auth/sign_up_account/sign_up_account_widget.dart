import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import '/user_auth/shared/auth_desktop_sidebar.dart';
import '/user_auth/sign_up_account/components/sign_up_actions.dart';
import '/user_auth/sign_up_account/components/sign_up_form_fields.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';

class SignUpAccountWidget extends StatefulWidget {
  const SignUpAccountWidget({super.key});

  static String routeName = 'SignUpAccount';
  static String routePath = '/signUpAccount';

  @override
  State<SignUpAccountWidget> createState() => _SignUpAccountWidgetState();
}

class _SignUpAccountWidgetState extends State<SignUpAccountWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formFieldsKey = GlobalKey<SignUpFormFieldsState>();

  Future<void> _handleCreateAccount() async {
    GoRouter.of(context).prepareAuthEvent();

    final fields = _formFieldsKey.currentState!;
    if (fields.password != fields.confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords don\'t match!'),
        ),
      );
      return;
    }

    final user = await authManager.createAccountWithEmail(
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
      fallbackRouteName: AppRouteNames.createProfile,
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

    context.pushCreateProfile(
      transition: TransitionStandards.modalTransition,
    );
  }

  Future<void> _handleAppleSignIn() async {
    GoRouter.of(context).prepareAuthEvent();
    final user = await authManager.signInWithApple(context);
    if (user == null) return;

    if (!mounted) return;
    final router = GoRouter.of(context);
    if (router.shouldRedirect(false)) return;

    context.pushCreateProfile(
      transition: TransitionStandards.modalTransition,
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
                          child: Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: AppSpacing.lg,
                                top: 90.0,
                                right: AppSpacing.lg,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  AppText.screenTitle(
                                    'Create an account',
                                    color: AppColors.textPrimary,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: AppSpacing.xs,
                                      bottom: AppSpacing.lg,
                                    ),
                                    child: AppText.bodySmall(
                                      'Let\'s get started by filling out the form below.',
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SignUpFormFields(key: _formFieldsKey),
                                  SignUpActions(
                                    onCreateAccount: _handleCreateAccount,
                                    onGoogleSignIn: _handleGoogleSignIn,
                                    onAppleSignIn: _handleAppleSignIn,
                                    onSignInTap: () {
                                      context.pushSignIn(
                                        transition: TransitionStandards
                                            .modalTransition,
                                      );
                                    },
                                  ),
                                ],
                              ),
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
