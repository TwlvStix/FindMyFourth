import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/user_auth/shared/auth_link_text.dart';
import '/user_auth/shared/auth_oauth_buttons.dart';
import '/user_auth/shared/auth_or_divider.dart';
import 'package:flutter/material.dart';

class SignInActions extends StatelessWidget {
  const SignInActions({
    super.key,
    required this.onSignIn,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.onSignUpTap,
    required this.onForgotPasswordTap,
    required this.onBrowseGamesTap,
    required this.onHowItWorksTap,
  });

  final VoidCallback onSignIn;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final VoidCallback onSignUpTap;
  final VoidCallback onForgotPasswordTap;
  final VoidCallback onBrowseGamesTap;
  final VoidCallback onHowItWorksTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AppButtonEnhanced(
            onPressed: onSignIn,
            text: 'Sign In',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xl),
          child: const AuthOrDivider(),
        ),
        AuthOAuthButtons(
          onGoogleSignIn: onGoogleSignIn,
          onAppleSignIn: onAppleSignIn,
        ),
        AuthLinkText(
          leadText: 'Don\'t have an account?',
          linkText: 'Sign Up here',
          onTap: onSignUpTap,
        ),
        _buildForgotPassword(context),
        _buildFooterLinks(),
      ],
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(-1.0, 0.0),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: InkWell(
          splashColor: AppColors.transparent,
          focusColor: AppColors.transparent,
          hoverColor: AppColors.transparent,
          highlightColor: AppColors.transparent,
          onTap: onForgotPasswordTap,
          child: RichText(
            textScaler: MediaQuery.of(context).textScaler,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Forgot Password?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              ],
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBrowseGamesTap,
            child: Text(
              'Browse games',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '\u00B7',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          GestureDetector(
            onTap: onHowItWorksTap,
            child: Text(
              'How it works',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
