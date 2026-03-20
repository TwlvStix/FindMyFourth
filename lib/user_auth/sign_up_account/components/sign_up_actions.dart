import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/user_auth/shared/auth_link_text.dart';
import '/user_auth/shared/auth_oauth_buttons.dart';
import '/user_auth/shared/auth_or_divider.dart';
import 'package:flutter/material.dart';

class SignUpActions extends StatelessWidget {
  const SignUpActions({
    super.key,
    required this.onCreateAccount,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.onSignInTap,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AppButtonEnhanced(
            onPressed: onCreateAccount,
            text: 'Create Account',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg),
          child: const AuthOrDivider(),
        ),
        AuthOAuthButtons(
          onGoogleSignIn: onGoogleSignIn,
          onAppleSignIn: onAppleSignIn,
        ),
        AuthLinkText(
          leadText: 'Already have an account?',
          linkText: 'Sign In here',
          onTap: onSignInTap,
        ),
      ],
    );
  }
}
