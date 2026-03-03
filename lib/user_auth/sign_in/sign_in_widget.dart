import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/google_logo.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_text.dart';
import '/main_function/games_list/games_list_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

class SignInWidget extends StatefulWidget {
  const SignInWidget({super.key});

  static String routeName = 'SignIn';
  static String routePath = '/signIn';

  @override
  State<SignInWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  bool passwordVisibility = false;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  FocusNode? passwordVisibilityIconFocusNode;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    emailAddressTextController = TextEditingController();
    emailAddressFocusNode = FocusNode();

    passwordTextController = TextEditingController();
    passwordFocusNode = FocusNode();
    passwordVisibilityIconFocusNode = FocusNode(skipTraversal: true);

    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    passwordVisibilityIconFocusNode?.dispose();

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
                          constraints: BoxConstraints(
                            maxWidth: 430.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.transparent,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                AppSpacing.xl, 90.0, AppSpacing.xl, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, AppSpacing.md),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: emailAddressTextController,
                                      focusNode: emailAddressFocusNode,
                                      autofocus: false,
                                      autofillHints: [AutofillHints.email],
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle:
                                            AppTypography.labelLarge.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.inputBorderIdle,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.inputBorderFocused,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.inputBackground,
                                      ),
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      cursorColor: AppColors.green,
                                      validator:
                                          emailAddressTextControllerValidator
                                              .asValidator(context),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, AppSpacing.md),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: passwordTextController,
                                      focusNode: passwordFocusNode,
                                      autofocus: false,
                                      autofillHints: [AutofillHints.password],
                                      obscureText: !passwordVisibility,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle:
                                            AppTypography.labelLarge.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.inputBorderIdle,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.inputBorderFocused,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.md),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.inputBackground,
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() =>
                                                  passwordVisibility =
                                                      !passwordVisibility);
                                            }
                                          },
                                          focusNode:
                                              passwordVisibilityIconFocusNode,
                                          child: Icon(
                                            passwordVisibility
                                                ? AppPhosphorIcons.eye
                                                : AppPhosphorIcons.eyeSlash,
                                            color: AppColors.textMuted,
                                            size: AppIconSize.md,
                                          ),
                                        ),
                                      ),
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      cursorColor: AppColors.green,
                                      validator: passwordTextControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, AppSpacing.md),
                                  child: AppButtonEnhanced(
                                    onPressed: () async {
                                      GoRouter.of(context).prepareAuthEvent();

                                      final user =
                                          await authManager.signInWithEmail(
                                        context,
                                        emailAddressTextController.text,
                                        passwordTextController.text,
                                      );
                                      if (user == null) {
                                        return;
                                      }

                                      if (!context.mounted) {
                                        return;
                                      }
                                      final router = GoRouter.of(context);
                                      if (router.shouldRedirect(false)) {
                                        return;
                                      }
                                      await authManager
                                          .handlePostAuthNavigation(
                                        context,
                                        fallbackRouteName:
                                            GamesListWidget.routeName,
                                        fallbackExtra: <String, dynamic>{
                                          kTransitionInfoKey: TransitionInfo(
                                            hasTransition: true,
                                            transitionType:
                                                AppTransitionType.fade,
                                            enterDuration:
                                                Duration(milliseconds: 200),
                                            exitDuration:
                                                Duration(milliseconds: 170),
                                            scaleOnPush: true,
                                          ),
                                        },
                                        replaceRoute: true,
                                      );
                                    },
                                    text: 'Sign In',
                                    variant: AppButtonVariant.primary,
                                    size: AppButtonSize.large,
                                    fullWidth: true,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, AppSpacing.xl),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Stack(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0,
                                                    AppSpacing.sm,
                                                    0.0,
                                                    AppSpacing.sm),
                                            child: Container(
                                              width: double.infinity,
                                              height: 1.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.inputBorderIdle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Container(
                                            width: 70.0,
                                            height: 32.0,
                                            decoration: BoxDecoration(
                                              color: AppColors.navyLight,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppBorderRadius.xs),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Text(
                                              'OR',
                                              style: AppTypography.labelLarge
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, AppSpacing.md),
                                  child: AppButtonEnhanced(
                                    onPressed: () async {
                                      GoRouter.of(context).prepareAuthEvent();
                                      final user = await authManager
                                          .signInWithGoogle(context);
                                      if (user == null) {
                                        return;
                                      }

                                      if (!context.mounted) {
                                        return;
                                      }
                                      final router = GoRouter.of(context);
                                      if (router.shouldRedirect(false)) {
                                        return;
                                      }
                                      await authManager
                                          .handlePostAuthNavigation(
                                        context,
                                        fallbackRouteName:
                                            GamesListWidget.routeName,
                                        fallbackExtra: <String, dynamic>{
                                          kTransitionInfoKey: TransitionInfo(
                                            hasTransition: true,
                                            transitionType:
                                                AppTransitionType.fade,
                                            enterDuration:
                                                Duration(milliseconds: 200),
                                            exitDuration:
                                                Duration(milliseconds: 170),
                                            scaleOnPush: true,
                                          ),
                                        },
                                        replaceRoute: true,
                                      );
                                    },
                                    text: 'Continue with Google',
                                    leadingWidget: const GoogleLogo(size: 20),
                                    variant: AppButtonVariant.navyFilled,
                                    size: AppButtonSize.large,
                                    fullWidth: true,
                                  ),
                                ),
                                isAndroid
                                    ? Container()
                                    : Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, AppSpacing.md),
                                        child: AppButtonEnhanced(
                                          onPressed: () async {
                                            GoRouter.of(context)
                                                .prepareAuthEvent();
                                            final user = await authManager
                                                .signInWithApple(context);
                                            if (user == null) {
                                              return;
                                            }

                                            if (!context.mounted) {
                                              return;
                                            }
                                            final router = GoRouter.of(context);
                                            if (router.shouldRedirect(false)) {
                                              return;
                                            }
                                            await authManager
                                                .handlePostAuthNavigation(
                                              context,
                                              fallbackRouteName:
                                                  GamesListWidget.routeName,
                                              fallbackExtra: <String, dynamic>{
                                                kTransitionInfoKey:
                                                    TransitionInfo(
                                                  hasTransition: true,
                                                  transitionType:
                                                      AppTransitionType.fade,
                                                  enterDuration: Duration(
                                                      milliseconds: 200),
                                                  exitDuration: Duration(
                                                      milliseconds: 170),
                                                  scaleOnPush: true,
                                                ),
                                              },
                                              replaceRoute: true,
                                            );
                                          },
                                          text: 'Continue with Apple',
                                          leadingIcon:
                                              AppPhosphorIcons.appleLogo,
                                          variant: AppButtonVariant.navyFilled,
                                          size: AppButtonSize.large,
                                          fullWidth: true,
                                        ),
                                      ),

                                // You will have to add an action on this rich text to go to your login page.
                                Align(
                                  alignment: AlignmentDirectional(-1.0, 0.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, AppSpacing.sm, 0.0, AppSpacing.sm),
                                    child: InkWell(
                                      splashColor: AppColors.transparent,
                                      focusColor: AppColors.transparent,
                                      hoverColor: AppColors.transparent,
                                      highlightColor: AppColors.transparent,
                                      onTap: () async {
                                        context.pushSignUpAccount(
                                          transition: TransitionStandards
                                              .modalTransition,
                                        );
                                      },
                                      child: RichText(
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Don\'t have an account? ',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' Sign Up here',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.greenLight,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ],
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // You will have to add an action on this rich text to go to your login page.
                                Align(
                                  alignment: AlignmentDirectional(-1.0, 0.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, AppSpacing.sm, 0.0, AppSpacing.sm),
                                    child: InkWell(
                                      splashColor: AppColors.transparent,
                                      focusColor: AppColors.transparent,
                                      hoverColor: AppColors.transparent,
                                      highlightColor: AppColors.transparent,
                                      onTap: () async {
                                        context.pushRecoverPassword(
                                          transition: TransitionStandards
                                              .modalTransition,
                                        );
                                      },
                                      child: RichText(
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Forgot Password?',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            )
                                          ],
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Container(
                      width: 100.0,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.navyDark, AppColors.navy],
                          stops: [0.0, 1.0],
                          begin: AlignmentDirectional(1.0, -1.0),
                          end: AlignmentDirectional(-1.0, 1.0),
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxWidth: 400.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pure,
                                boxShadow: [AppElevation.sm],
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.sm),
                                border: Border.all(
                                  color: AppColors.sand,
                                  width: 2.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.xxs),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          AppSpacing.sm,
                                          AppSpacing.sm,
                                          AppSpacing.sm,
                                          AppSpacing.xs),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0.0, 0.0,
                                                        AppSpacing.xs, 0.0),
                                                child: Container(
                                                  width: 40.0,
                                                  height: 40.0,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.cloud,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    AppPhosphorIcons.profile,
                                                    color: AppColors.navyDark,
                                                    size: AppIconSize.md,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'UserName',
                                                style:
                                                    AppTypography.titleMedium,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Overall',
                                                style: AppTypography.bodySmall,
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                0.0,
                                                                0.0,
                                                                AppSpacing.xxs,
                                                                0.0),
                                                    child: Text(
                                                      '5',
                                                      style: AppTypography
                                                          .headlineMedium,
                                                    ),
                                                  ),
                                                  Icon(
                                                    AppPhosphorIcons.starFill,
                                                    color: AppColors.navyDark,
                                                    size: AppIconSize.button,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          AppSpacing.sm,
                                          0.0,
                                          AppSpacing.sm,
                                          AppSpacing.xs),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: AutoSizeText(
                                              'Nice outdoor courts, solid concrete and good hoops for the neighborhood.',
                                              style: AppTypography.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
