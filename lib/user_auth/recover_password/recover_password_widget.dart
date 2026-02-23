import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/elevation.dart';
import '/core/widgets/app_text.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import 'package:flutter/material.dart';

class RecoverPasswordWidget extends StatefulWidget {
  const RecoverPasswordWidget({super.key});

  static String routeName = 'RecoverPassword';
  static String routePath = '/recoverPassword';

  @override
  State<RecoverPasswordWidget> createState() => _RecoverPasswordWidgetState();
}

class _RecoverPasswordWidgetState extends State<RecoverPasswordWidget> {
  FocusNode? enterEmailFocusNode;
  TextEditingController? enterEmailTextController;
  String? Function(BuildContext, String?)? enterEmailTextControllerValidator;
  bool emailSent = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  void _returnToSignIn() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.goNamed(
      SignInWidget.routeName,
      extra: <String, dynamic>{
        kTransitionInfoKey: TransitionStandards.modalTransition,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    enterEmailTextController = TextEditingController();
    enterEmailFocusNode = FocusNode();

    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    enterEmailFocusNode?.dispose();
    enterEmailTextController?.dispose();

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
        backgroundColor: AppColors.navyDark,
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
          automaticallyImplyLeading: false,
          leading: PremiumBackButton(
            onTap: _returnToSignIn,
          ),
          title: AppText.screenTitle(
            'Recover Password',
            color: AppColors.textPrimary,
            textAlign: TextAlign.center,
          ),
          actions: [],
          centerTitle: true,
          elevation: 10.0,
        ),
        body: FairwayBackgroundLight(
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: AppSpacing.md,
                        ),
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: AppSpacing.md,
                              top: AppSpacing.md,
                              right: AppSpacing.md,
                          ),
                          child: AppText.body(
                            'We will send you an email with a link to reset your password, please enter the email associated with your account below. ',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Padding(
                      padding: AppSpacing.horizontalMd,
                      child: Container(
                        width: 100.0,
                        height: 75.0,
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          boxShadow: [AppElevation.md],
                          borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional(-1.0, 0.0),
                          child: Padding(
                            padding: AppSpacing.horizontalMd,
                            child: TextFormField(
                              controller: enterEmailTextController,
                              focusNode: enterEmailFocusNode,
                              autofocus: true,
                              obscureText: false,
                              decoration: InputDecoration(
                                labelText: 'Enter Email Here',
                                labelStyle: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.pure,
                                  fontWeight: FontWeight.w500,
                                ),
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                              ),
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.pure,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.emailAddress,
                              validator: enterEmailTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: AppSpacing.md,
                ),
                child: AppButtonEnhanced(
                  onPressed: () async {
                    if (enterEmailTextController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Email required!',
                          ),
                        ),
                      );
                      return;
                    }
                    final didSend = await authManager.resetPassword(
                      email: enterEmailTextController.text,
                      context: context,
                    );
                    if (didSend && mounted) {
                      setState(() => emailSent = true);
                    }
                  },
                  text: 'Send Link',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                ),
              ),
              if (emailSent)
                Padding(
                  padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      top: AppSpacing.sm,
                      right: AppSpacing.lg,
                  ),
                  child: AppText.body(
                    'Check your email for the reset link. You can return to sign in once you receive it.',
                    color: AppColors.pure,
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                    top: AppSpacing.xs,
                ),
                child: TextButton(
                  onPressed: _returnToSignIn,
                  child: AppText.label(
                    'Back to Sign In',
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
