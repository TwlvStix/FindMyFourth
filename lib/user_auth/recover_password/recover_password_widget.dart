import '/auth/firebase_auth/auth_util.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_text.dart';
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
    context.goSignIn(
      transition: TransitionStandards.modalTransition,
    );
  }

  @override
  void initState() {
    super.initState();
    enterEmailTextController = TextEditingController();
    enterEmailFocusNode = FocusNode();
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
        body: FairwayBackgroundClubhouse(
          showOrganic: true,
          child: SizedBox.expand(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.sm),
                      // Back button in body (like sign-in has no AppBar)
                      PremiumBackButton(onTap: _returnToSignIn),
                      SizedBox(height: AppSpacing.lg),
                      // Title in body
                      AppText.screenTitle(
                        'Recover Password',
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      AppText.bodySmall(
                        'Enter the email associated with your account and we\'ll send you a link to reset your password.',
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: enterEmailTextController,
                        focusNode: enterEmailFocusNode,
                        autofocus: true,
                        autofillHints: const [AutofillHints.email],
                        obscureText: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.inputBorderIdle,
                              width: 1.5,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.inputBorderFocused,
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
                          fillColor: AppColors.inputBackground,
                        ),
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: AppColors.green,
                        validator: enterEmailTextControllerValidator
                            ?.asValidator(context),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      AppButtonEnhanced(
                        onPressed: () async {
                          if (enterEmailTextController!.text.isEmpty) {
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
                            email: enterEmailTextController!.text,
                            context: context,
                          );
                          if (didSend && mounted) {
                            setState(() => emailSent = true);
                          }
                        },
                        text: 'Send Link',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        fullWidth: true,
                      ),
                      if (emailSent)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: AppText.body(
                            'Check your email for the reset link. You can return to sign in once you receive it.',
                            color: AppColors.success,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: AppSpacing.md),
                      Center(
                        child: AppButtonEnhanced(
                          text: 'Back to Sign In',
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.medium,
                          onPressed: _returnToSignIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
