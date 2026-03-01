import 'package:flutter/material.dart';

import 'base_auth_user_provider.dart';

abstract class AuthManager {
  Future<void> signOut();
  Future<void> deleteUser(BuildContext context);
  Future<void> updateEmail({required String email, required BuildContext context});
  Future<void> updatePassword({required String newPassword, required BuildContext context});
  Future<bool> resetPassword(
      {required String email, required BuildContext context});
  Future<void> sendEmailVerification() async => currentUser?.sendEmailVerification();
  Future<void> refreshUser() async => currentUser?.refreshUser();
}

mixin EmailSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  );

  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  );
}

mixin AnonymousSignInManager on AuthManager {
  Future<BaseAuthUser?> signInAnonymously(BuildContext context);
}

mixin AppleSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithApple(BuildContext context);
}

mixin GoogleSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context);
}

mixin JwtSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  );
}

mixin PhoneSignInManager on AuthManager {
  Future<void> beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  });

  Future<void> verifySmsCode({
    required BuildContext context,
    required String smsCode,
  });
}

mixin FacebookSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithFacebook(BuildContext context);
}

mixin MicrosoftSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithMicrosoft(
    BuildContext context,
    List<String> scopes,
    String tenantId,
  );
}

mixin GithubSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithGithub(BuildContext context);
}
