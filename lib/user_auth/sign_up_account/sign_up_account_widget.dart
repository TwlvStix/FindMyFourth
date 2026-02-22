import '/auth/firebase_auth/auth_util.dart';
import '/core/widgets/fairway_background.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_text.dart';
import '/profile/create_profile/create_profile_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUpAccountWidget extends StatefulWidget {
  const SignUpAccountWidget({super.key});

  static String routeName = 'SignUpAccount';
  static String routePath = '/signUpAccount';

  @override
  State<SignUpAccountWidget> createState() => _SignUpAccountWidgetState();
}

class _SignUpAccountWidgetState extends State<SignUpAccountWidget> {
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  bool passwordVisibility = false;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  FocusNode? passwordVisibilityIconFocusNode;
  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  bool passwordConfirmVisibility = false;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;
  FocusNode? passwordConfirmVisibilityIconFocusNode;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    emailAddressTextController = TextEditingController();
    emailAddressFocusNode = FocusNode();

    passwordTextController = TextEditingController();
    passwordFocusNode = FocusNode();
    passwordVisibilityIconFocusNode = FocusNode(skipTraversal: true);

    passwordConfirmTextController = TextEditingController();
    passwordConfirmFocusNode = FocusNode();
    passwordConfirmVisibilityIconFocusNode = FocusNode(skipTraversal: true);

    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    passwordVisibilityIconFocusNode?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();
    passwordConfirmVisibilityIconFocusNode?.dispose();

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
        body: FairwayBackgroundLight(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.screenTitle('Create an account'),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: AppSpacing.xs,
                                      bottom: AppSpacing.lg,
                                  ),
                                  child: AppText.bodySmall(
                                    'Let\'s get started by filling out the form below.',
                                    color: AppColors.pure,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: emailAddressTextController,
                                      focusNode: emailAddressFocusNode,
                                      onChanged: (_) => EasyDebounce.debounce(
                                        'emailAddressTextController',
                                        Duration(milliseconds: 2000),
                                        () {
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      autofocus: false,
                                      autofillHints: [AutofillHints.email],
                                      textInputAction: TextInputAction.next,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: AppTypography.labelMedium,
                                        alignLabelWithHint: false,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.sand,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.navyDark,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.sand,
                                        suffixIcon: emailAddressTextController!
                                                .text
                                                .isNotEmpty
                                            ? InkWell(
                                                onTap: () async {
                                                  emailAddressTextController
                                                      ?.clear();
                                                  if (mounted) setState(() {});
                                                },
                                                child: Icon(
                                                  Icons.clear,
                                                  color: AppColors.stone,
                                                  size: AppIconSize.md,
                                                ),
                                              )
                                            : null,
                                      ),
                                      style: AppTypography.bodyMedium,
                                      keyboardType: TextInputType.emailAddress,
                                      cursorColor: AppColors.onyx,
                                      validator: emailAddressTextControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: passwordTextController,
                                      focusNode: passwordFocusNode,
                                      autofocus: false,
                                      autofillHints: [AutofillHints.password],
                                      textInputAction: TextInputAction.next,
                                      obscureText: !passwordVisibility,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: AppTypography.labelMedium,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.sand,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.navyDark,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.sand,
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
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.slate,
                                            size: AppIconSize.md,
                                          ),
                                        ),
                                      ),
                                      style: AppTypography.bodyMedium,
                                      cursorColor: AppColors.onyx,
                                      validator: passwordTextControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: passwordConfirmTextController,
                                      focusNode: passwordConfirmFocusNode,
                                      autofocus: false,
                                      autofillHints: [AutofillHints.password],
                                      textInputAction: TextInputAction.next,
                                      obscureText: !passwordConfirmVisibility,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        labelStyle: AppTypography.labelMedium,
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.sand,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.navyDark,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.sand,
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() =>
                                                  passwordConfirmVisibility =
                                                      !passwordConfirmVisibility);
                                            }
                                          },
                                          focusNode:
                                              passwordConfirmVisibilityIconFocusNode,
                                          child: Icon(
                                            passwordConfirmVisibility
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.slate,
                                            size: 24.0,
                                          ),
                                        ),
                                      ),
                                      style: AppTypography.bodyMedium,
                                      minLines: 1,
                                      cursorColor: AppColors.onyx,
                                      validator:
                                          passwordConfirmTextControllerValidator
                                          .asValidator(context),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                  ),
                                  child: AppButtonEnhanced(
                                    onPressed: () async {
                                      GoRouter.of(context).prepareAuthEvent();
                                      if (passwordTextController.text !=
                                          passwordConfirmTextController.text) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Passwords don\'t match!',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final user = await authManager
                                          .createAccountWithEmail(
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
                                            CreateProfileWidget.routeName,
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
                                    text: 'Create Account',
                                    variant: AppButtonVariant.primary,
                                    size: AppButtonSize.large,
                                    fullWidth: true,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppSpacing.lg,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    child: Stack(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional(0.0, 0.0),
                                          child: Padding(
                                            padding: AppSpacing.verticalXs,
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
                                              color:
                                                  AppColors.pure,
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: AppText.label('OR'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                  ),
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
                                      router.pushNamed(
                                        CreateProfileWidget.routeName,
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
                                        padding: EdgeInsets.only(
                                            bottom: AppSpacing.md,
                                        ),
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
                                            router.pushNamed(
                                              MainProfileWidget.routeName,
                                              extra: <String, dynamic>{
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
                                            );
                                          },
                                          text: 'Continue with Apple',
                                          leadingIcon: FontAwesomeIcons.apple,
                                          variant: AppButtonVariant.gradient,
                                          size: AppButtonSize.large,
                                          fullWidth: true,
                                        ),
                                      ),
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Padding(
                                    padding: AppSpacing.verticalXs,
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        context.pushNamed(
                                          SignInWidget.routeName,
                                          extra: <String, dynamic>{
                                            kTransitionInfoKey: TransitionInfo(
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
                                        );
                                      },
                                      child: RichText(
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Already have an account? ',
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: AppColors.pure,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' Sign In here',
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: AppColors.navyDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ],
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.pure,
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
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
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
                              boxShadow: [AppElevation.xs],
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
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
                                    padding: EdgeInsets.only(
                                        left: AppSpacing.xs,
                                        top: AppSpacing.xs,
                                        right: AppSpacing.xs,
                                        bottom: AppSpacing.xxs,
                                    ),
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
                                              padding: EdgeInsets.only(
                                                  right: AppSpacing.xxs,
                                              ),
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
                                                  size: AppIconSize.md,
                                                ),
                                              ),
                                            ),
                                            AppText.cardTitle('UserName'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            AppText.bodySmall('Overall'),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      right: AppSpacing.xxs,
                                                  ),
                                                  child: AppText.screenTitle('5'),
                                                ),
                                                Icon(
                                                  Icons.star_rounded,
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
                                    padding: EdgeInsets.only(
                                        left: AppSpacing.xs,
                                        right: AppSpacing.xs,
                                        bottom: AppSpacing.xxs,
                                    ),
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
