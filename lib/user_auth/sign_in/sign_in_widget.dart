import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_text.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/user_auth/recover_password/recover_password_widget.dart';
import '/user_auth/sign_up_account/sign_up_account_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        body: FairwayBackgroundSunset(
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
                          color: Colors.transparent,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.xl, 90.0, AppSpacing.xl, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.screenTitle('Sign In'),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: AppSpacing.xs,
                                    bottom: AppSpacing.lg,
                                ),
                                child: AppText.bodySmall(
                                  'Welcome Back. Ready to Play a game?',
                                  color: AppColors.navyText,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, AppSpacing.md),
                                child: Container(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: emailAddressTextController,
                                    focusNode: emailAddressFocusNode,
                                    autofocus: false,
                                    autofillHints: [AutofillHints.email],
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: AppTypography.labelLarge
                                          .override(
                                            font: TextStyle(fontFamily: 'Manrope',
                                              fontWeight:
                                                  AppTypography.labelLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTypography.labelLarge
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTypography.labelLarge
                                                    .fontWeight,
                                            fontStyle:
                                                AppTypography.labelLarge
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.sand,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.navyDark,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.error,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.error,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.sand,
                                    ),
                                    style: AppTypography.bodyLarge
                                        .override(
                                          font: TextStyle(fontFamily: 'Manrope',
                                            fontWeight:
                                                AppTypography.bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                AppTypography.bodyLarge
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              AppTypography.bodyLarge
                                                  .fontWeight,
                                          fontStyle:
                                              AppTypography.bodyLarge
                                                  .fontStyle,
                                        ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: emailAddressTextControllerValidator
                                        .asValidator(context),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, AppSpacing.md),
                                child: Container(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: passwordTextController,
                                    focusNode: passwordFocusNode,
                                    autofocus: false,
                                    autofillHints: [AutofillHints.password],
                                    obscureText: !passwordVisibility,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: AppTypography.labelLarge
                                          .override(
                                            font: TextStyle(fontFamily: 'Manrope',
                                              fontWeight:
                                                  AppTypography.labelLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTypography.labelLarge
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTypography.labelLarge
                                                    .fontWeight,
                                            fontStyle:
                                                AppTypography.labelLarge
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.sand,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.navyDark,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.error,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.error,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.sand,
                                      suffixIcon: InkWell(
                                        onTap: () {
                                          if (mounted) {
                                            setState(() => passwordVisibility =
                                                !passwordVisibility);
                                          }
                                        },
                                        focusNode:
                                            passwordVisibilityIconFocusNode,
                                        child: Icon(
                                          passwordVisibility
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.slate,
                                          size: 24.0,
                                        ),
                                      ),
                                    ),
                                    style: AppTypography.bodyLarge
                                        .override(
                                          font: TextStyle(fontFamily: 'Manrope',
                                            fontWeight:
                                                AppTypography.bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                AppTypography.bodyLarge
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              AppTypography.bodyLarge
                                                  .fontWeight,
                                          fontStyle:
                                              AppTypography.bodyLarge
                                                  .fontStyle,
                                        ),
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
                                    await authManager.handlePostAuthNavigation(
                                      context,
                                      fallbackRouteName: GamesListWidget.routeName,
                                      fallbackExtra: <String, dynamic>{
                                        kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
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
                                child: Container(
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
                                                  0.0, AppSpacing.sm, 0.0, AppSpacing.sm),
                                          child: Container(
                                            width: double.infinity,
                                            height: 2.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.cloud,
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
                                            color: AppColors.pure,
                                          ),
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Text(
                                            'OR',
                                            style: AppTypography.labelLarge
                                                .override(
                                                  font: TextStyle(fontFamily: 'Manrope',
                                                    fontWeight:
                                                        AppTypography.labelLarge
                                                            .fontWeight,
                                                    fontStyle:
                                                        AppTypography.labelLarge
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      AppTypography.labelLarge
                                                          .fontWeight,
                                                  fontStyle:
                                                      AppTypography.labelLarge
                                                          .fontStyle,
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
                                    await authManager.handlePostAuthNavigation(
                                      context,
                                      fallbackRouteName: GamesListWidget.routeName,
                                      fallbackExtra: <String, dynamic>{
                                        kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
                                      },
                                      replaceRoute: true,
                                    );
                                  },
                                  text: 'Continue with Google',
                                  leadingIcon: FontAwesomeIcons.google,
                                  variant: AppButtonVariant.gradient,
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
                                                    PageTransitionType.fade,
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
                                        text: 'Continue with Apple',
                                        leadingIcon: FontAwesomeIcons.apple,
                                        variant: AppButtonVariant.gradient,
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
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                        SignUpAccountWidget.routeName,
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
                                    child: RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Don\'t have an account? ',
                                            style: TextStyle(),
                                          ),
                                          TextSpan(
                                            text: ' Sign Up here',
                                            style: AppTypography.bodyMedium
                                                .override(
                                                  font: TextStyle(fontFamily: 'Manrope',
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        AppTypography
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: AppColors.navyDark,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:
                                                      AppTypography
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                          )
                                        ],
                                        style: AppTypography.bodyMedium
                                            .override(
                                              font: TextStyle(fontFamily: 'Manrope',
                                                fontWeight:
                                                    AppTypography.bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTypography.bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  AppColors.onyx,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTypography.bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTypography.bodyMedium
                                                      .fontStyle,
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
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                        RecoverPasswordWidget.routeName,
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
                                    child: RichText(
                                      textScaler:
                                          MediaQuery.of(context).textScaler,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Forgot Password?',
                                            style: TextStyle(),
                                          )
                                        ],
                                        style: AppTypography.bodyMedium
                                            .override(
                                              font: TextStyle(fontFamily: 'Manrope',
                                                fontWeight:
                                                    AppTypography.bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTypography.bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: AppColors.navyDarkBtnText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTypography.bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTypography.bodyMedium
                                                      .fontStyle,
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
                        colors: [
                          AppColors.navyDark,
                          AppColors.navy
                        ],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(1.0, -1.0),
                        end: AlignmentDirectional(-1.0, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.md),
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
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 3.0,
                                  color: AppColors.overlayDark,
                                  offset: Offset(
                                    0.0,
                                    2.0,
                                  ),
                                )
                              ],
                              borderRadius: BorderRadius.circular(AppSpacing.xs),
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
                                        AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
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
                                                  .fromSTEB(0.0, 0.0, AppSpacing.xs, 0.0),
                                              child: Container(
                                                width: 40.0,
                                                height: 40.0,
                                                decoration: BoxDecoration(
                                                  color: AppColors.cloud,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  color: AppColors.navyDark,
                                                  size: 24.0,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'UserName',
                                              style:
                                                  AppTypography.titleMedium
                                                      .override(
                                                        font:
                                                            TextStyle(fontFamily: 'Manrope',
                                                          fontWeight:
                                                              AppTypography.titleMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTypography.titleMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            AppTypography.titleMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTypography.titleMedium
                                                                .fontStyle,
                                                      ),
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
                                              style:
                                                  AppTypography.bodySmall
                                                      .override(
                                                        font:
                                                            TextStyle(fontFamily: 'Manrope',
                                                          fontWeight:
                                                              AppTypography.bodySmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTypography.bodySmall
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            AppTypography.bodySmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTypography.bodySmall
                                                                .fontStyle,
                                                      ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, AppSpacing.xxs, 0.0),
                                                  child: Text(
                                                    '5',
                                                    style: AppTypography.headlineMedium
                                                        .override(
                                                          font: TextStyle(
                                                            fontFamily: 'Manrope',
                                                            fontWeight:
                                                                AppTypography.headlineMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTypography.headlineMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              AppTypography.headlineMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTypography.headlineMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.star_rounded,
                                                  color: AppColors.navyDark,
                                                  size: 20.0,
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
                                        AppSpacing.sm, 0.0, AppSpacing.sm, AppSpacing.xs),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: AutoSizeText(
                                            'Nice outdoor courts, solid concrete and good hoops for the neighborhood.',
                                            style: AppTypography.bodyMedium
                                                .override(
                                                  font: TextStyle(fontFamily: 'Manrope',
                                                    fontWeight:
                                                        AppTypography.bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        AppTypography.bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      AppTypography.bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      AppTypography.bodyMedium
                                                          .fontStyle,
                                                ),
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
