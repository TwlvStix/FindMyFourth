import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/google_logo.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';

class AuthOAuthButtons extends StatelessWidget {
  const AuthOAuthButtons({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AppButtonEnhanced(
            onPressed: onGoogleSignIn,
            text: 'Continue with Google',
            leadingWidget: const GoogleLogo(size: 20),
            variant: AppButtonVariant.navyFilled,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
        ),
        if (!isAndroid)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppButtonEnhanced(
              onPressed: onAppleSignIn,
              text: 'Continue with Apple',
              leadingIcon: AppPhosphorIcons.appleLogo,
              variant: AppButtonVariant.navyFilled,
              size: AppButtonSize.large,
              fullWidth: true,
            ),
          ),
      ],
    );
  }
}
