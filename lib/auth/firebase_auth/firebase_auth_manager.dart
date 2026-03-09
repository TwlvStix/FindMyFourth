import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../auth_manager.dart';
import 'auth_util.dart';
import '/core/utils/app_log.dart';
import '/providers/user_provider.dart';

import '/backend/backend.dart';
import 'anonymous_auth.dart';
import 'apple_auth.dart';
import 'email_auth.dart';
import 'firebase_user_provider.dart';
import 'google_auth.dart';
import 'jwt_token_auth.dart';
import 'github_auth.dart';

export '../base_auth_user_provider.dart';

class FirebasePhoneAuthManager extends ChangeNotifier {
  bool? _triggerOnCodeSent;
  FirebaseAuthException? phoneAuthError;
  // Set when using phone verification (after phone number is provided).
  String? phoneAuthVerificationCode;
  // Set when using phone sign in in web mode (ignored otherwise).
  ConfirmationResult? webPhoneAuthConfirmationResult;
  // Used for handling verification codes for phone sign in.
  void Function(BuildContext)? _onCodeSent;

  bool get triggerOnCodeSent => _triggerOnCodeSent ?? false;
  set triggerOnCodeSent(bool val) => _triggerOnCodeSent = val;

  void Function(BuildContext) get onCodeSent =>
      _onCodeSent == null ? (_) {} : _onCodeSent!;
  set onCodeSent(void Function(BuildContext) func) => _onCodeSent = func;

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}

const _genericAuthErrorMessage =
    'Unable to complete the request. Please try again later.';

class FirebaseAuthManager extends AuthManager
    with
        EmailSignInManager,
        GoogleSignInManager,
        AppleSignInManager,
        AnonymousSignInManager,
        JwtSignInManager,
        GithubSignInManager,
        PhoneSignInManager {
  FirebasePhoneAuthManager phoneAuthManager = FirebasePhoneAuthManager();
  final Map<String, DateTime> _authRequestExpiry = {};
  static const _authThrottleDuration = Duration(milliseconds: 1200);
  VoidCallback? _phoneAuthListener;

  bool _allowAuthAttempt(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final now = DateTime.now();
    final expiry = _authRequestExpiry[normalizedEmail];
    if (expiry != null && now.isBefore(expiry)) {
      return false;
    }
    _authRequestExpiry[normalizedEmail] = now.add(_authThrottleDuration);
    return true;
  }

  @override
  Future<void> signOut() {
    return FirebaseAuth.instance.signOut();
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        AppLog.d('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Too long since most recent sign in. Sign in again before deleting your account.')),
        );
      }
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        AppLog.d('Error: update email attempted with no logged in user!');
        return;
      }
      await currentUser?.updateEmail(email);
      await updateUserDocument(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Too long since most recent sign in. Sign in again before updating your email.')),
        );
      }
    }
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        AppLog.d('Error: update password attempted with no logged in user!');
        return;
      }
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message!}')),
        );
      }
    }
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message!}')),
      );
      return false;
    }
    if (!context.mounted) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset email sent')),
    );
    return true;
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _signInWithEmail(context, email, password);

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) =>
      _createAccountWithEmail(context, email, password);

  @override
  Future<BaseAuthUser?> signInAnonymously(
    BuildContext context,
  ) =>
      _signInOrCreateAccount(context, anonymousSignInFunc, 'ANONYMOUS');

  @override
  Future<BaseAuthUser?> signInWithApple(BuildContext context) =>
      _signInOrCreateAccount(context, appleSignIn, 'APPLE');

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) =>
      _signInOrCreateAccount(context, googleSignInFunc, 'GOOGLE');

  @override
  Future<BaseAuthUser?> signInWithGithub(BuildContext context) =>
      _signInOrCreateAccount(context, githubSignInFunc, 'GITHUB');

  @override
  Future<BaseAuthUser?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  ) =>
      _signInOrCreateAccount(context, () => jwtTokenSignIn(jwtToken), 'JWT');

  void handlePhoneAuthStateChanges(BuildContext context) {
    if (_phoneAuthListener != null) {
      phoneAuthManager.removeListener(_phoneAuthListener!);
    }

    VoidCallback? listener;
    listener = () {
      if (!context.mounted) {
        if (listener != null) {
          phoneAuthManager.removeListener(listener);
          if (identical(_phoneAuthListener, listener)) {
            _phoneAuthListener = null;
          }
        }
        return;
      }

      if (phoneAuthManager.triggerOnCodeSent) {
        phoneAuthManager.onCodeSent(context);
        phoneAuthManager
            .update(() => phoneAuthManager.triggerOnCodeSent = false);
      } else if (phoneAuthManager.phoneAuthError != null) {
        final e = phoneAuthManager.phoneAuthError!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message!}'),
        ));
        phoneAuthManager.update(() => phoneAuthManager.phoneAuthError = null);
      }
    };

    _phoneAuthListener = listener;
    phoneAuthManager.addListener(listener);
  }

  @override
  Future<void> beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  }) async {
    phoneAuthManager.update(() => phoneAuthManager.onCodeSent = onCodeSent);
    if (kIsWeb) {
      phoneAuthManager.webPhoneAuthConfirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
      phoneAuthManager.update(() => phoneAuthManager.triggerOnCodeSent = true);
      return;
    }
    final completer = Completer<bool>();
    // If you'd like auto-verification, without the user having to enter the SMS
    // code manually. Follow these instructions:
    // * For Android: https://firebase.google.com/docs/auth/android/phone-auth?authuser=0#enable-app-verification (SafetyNet set up)
    // * For iOS: https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0#start-receiving-silent-notifications
    // * Finally modify verificationCompleted below as instructed.
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout:
          Duration(seconds: 0), // Skips Android's default auto-verification
      verificationCompleted: (phoneAuthCredential) async {
        await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
        phoneAuthManager.update(() {
          phoneAuthManager.triggerOnCodeSent = false;
          phoneAuthManager.phoneAuthError = null;
        });
        if (!context.mounted) return;
        await handlePostAuthNavigation(
          context,
          fallbackRouteName: 'GamesList',
        );
      },
      verificationFailed: (e) {
        phoneAuthManager.update(() {
          phoneAuthManager.triggerOnCodeSent = false;
          phoneAuthManager.phoneAuthError = e;
        });
        completer.complete(false);
      },
      codeSent: (verificationId, _) {
        phoneAuthManager.update(() {
          phoneAuthManager.phoneAuthVerificationCode = verificationId;
          phoneAuthManager.triggerOnCodeSent = true;
          phoneAuthManager.phoneAuthError = null;
        });
        completer.complete(true);
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    await completer.future;
  }

  @override
  Future<void> verifySmsCode({
    required BuildContext context,
    required String smsCode,
  }) {
    if (kIsWeb) {
      return _signInOrCreateAccount(
        context,
        () => phoneAuthManager.webPhoneAuthConfirmationResult!.confirm(smsCode),
        'PHONE',
      );
    } else {
      final authCredential = PhoneAuthProvider.credential(
        verificationId: phoneAuthManager.phoneAuthVerificationCode!,
        smsCode: smsCode,
      );
      return _signInOrCreateAccount(
        context,
        () => FirebaseAuth.instance.signInWithCredential(authCredential),
        'PHONE',
      );
    }
  }

  /// Requests signup confirmation email (non-blocking, fire-and-forget).
  /// Server enforces idempotency - safe to call multiple times.
  Future<void> _requestSignupConfirmationEmail() async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-west2')
          .httpsCallable('sendSignupConfirmationEmail');
      final result = await callable.call<Map<String, dynamic>>();
      final status = result.data['status'] as String?;
      AppLog.d('✅ AUTH: Signup email result: $status');
    } catch (e) {
      AppLog.d('⚠️ AUTH: Signup email request failed: $e');
      // Non-blocking - don't rethrow
    }
  }

  /// Tries to sign in or create an account using Firebase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<UserCredential?> Function() signInFunc,
    String authProvider,
  ) async {
    try {
      AppLog.d(
          '🔐 AUTH: Starting sign in/create account with provider: $authProvider');
      final userCredential = await signInFunc();
      AppLog.d('🔐 AUTH: Received user credential.');
      final firebaseUser = userCredential?.user;
      if (firebaseUser != null) {
        AppLog.d('🔐 AUTH: Creating/updating user document.');
        await ensureUserDocReady(firebaseUser);
        AppLog.d('🔐 AUTH: User document created/updated successfully');

        // Request signup confirmation email for new users (non-blocking).
        // Server enforces idempotency - safe even if called multiple times.
        if (userCredential?.additionalUserInfo?.isNewUser == true) {
          unawaited(_requestSignupConfirmationEmail());
        }
      }
      return userCredential == null
          ? null
          : FindMyFourthFirebaseUser.fromUserCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      final userDocPath =
          user != null ? UsersRecord.collection.doc(user.uid).path : 'unknown';
      final authProviderInfo =
          'authProvider=$authProvider, code=${e.code}, message=${e.message}';
      AppLog.d('🔐 AUTH ERROR: $authProviderInfo, userDocPath=$userDocPath');
      if (!context.mounted) return null;
      final errorMsg = _firebaseAuthErrorMessage(e);
      _showAuthError(context, errorMsg);
      return null;
    } on GoogleSignInException catch (e) {
      final authProviderInfo =
          'authProvider=$authProvider, code=${e.code}, description=${e.description}';
      AppLog.d('🔐 AUTH ERROR: $authProviderInfo');
      if (!context.mounted) return null;
      _showAuthError(context, _googleSignInErrorMessage(e));
      return null;
    } catch (e, stackTrace) {
      AppLog.d('❌ AUTH: Unexpected error during sign in/create account');
      AppLog.d('❌ AUTH: Error: $e');
      AppLog.d('❌ AUTH: Stack trace: $stackTrace');
      if (!context.mounted) return null;
      _showAuthError(context, 'Error: An unexpected error occurred');
      return null;
    }
  }

  Future<BaseAuthUser?> _signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim();
    AppLog.d('🔐 AUTH: Email sign-in attempt for $trimmedEmail');
    if (trimmedEmail.isEmpty) {
      _showAuthError(context, 'Please enter an email address.');
      return null;
    }
    if (!_allowAuthAttempt(trimmedEmail)) {
      _showAuthError(context, _genericAuthErrorMessage);
      return null;
    }

    return _signInOrCreateAccount(
      context,
      () => _attemptEmailSignIn(trimmedEmail, password),
      'EMAIL',
    );
  }

  Future<UserCredential?> _attemptEmailSignIn(
    String email,
    String password,
  ) =>
      attemptEmailSignInWithRetries(
        signInFunc: () => emailSignInFunc(email, password),
      );

  @visibleForTesting
  Future<UserCredential?> attemptEmailSignInWithRetries({
    required Future<UserCredential?> Function() signInFunc,
    int maxAttempts = 2,
  }) async {
    var attempt = 0;
    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        return await signInFunc();
      } on FirebaseAuthException catch (e) {
        AppLog.d(
            '❌ AUTH: Email sign-in failed (attempt $attempt/$maxAttempts).');
        if (attempt >= maxAttempts || e.code != 'user-not-found') {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    return null;
  }

  Future<BaseAuthUser?> _createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim();
    AppLog.d('🔐 AUTH: Email create attempt for $trimmedEmail');
    if (!_allowAuthAttempt(trimmedEmail)) {
      _showAuthError(context, _genericAuthErrorMessage);
      return null;
    }

    try {
      AppLog.d(
          '🔐 AUTH: Calling createUserWithEmailAndPassword for $trimmedEmail');
      final userCredential =
          await emailCreateAccountFunc(trimmedEmail, password);
      final firebaseUser = userCredential?.user;
      if (firebaseUser != null) {
        await ensureUserDocReady(firebaseUser);
        AppLog.d('🔐 AUTH: Email account created.');

        // Email signup is always a new user - request confirmation email.
        // Server enforces idempotency - safe even if called multiple times.
        unawaited(_requestSignupConfirmationEmail());
      }
      return userCredential == null
          ? null
          : FindMyFourthFirebaseUser.fromUserCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      AppLog.d('❌ AUTH: create email failed.');
      if (!context.mounted) return null;
      final errorMsg = e.code == 'email-already-in-use'
          ? 'An account already exists for that email. Please sign in instead.'
          : _firebaseAuthErrorMessage(e);
      _showAuthError(context, errorMsg);
      return null;
    } catch (e, stackTrace) {
      AppLog.d('❌ AUTH: Unexpected error during account creation');
      AppLog.d('❌ AUTH: Error: $e');
      AppLog.d('❌ AUTH: Stack trace: $stackTrace');
      if (!context.mounted) return null;
      _showAuthError(context, 'Error: An unexpected error occurred');
      return null;
    }
  }

  void _showAuthError(BuildContext context, String message) {
    if (!context.mounted) return;
    AppLog.d('❌ AUTH: Showing error to user: $message');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'user-not-found':
      case 'email-already-in-use':
        return _genericAuthErrorMessage;
      case 'user-disabled':
        return 'This account has been disabled. Contact support if you believe this is a mistake.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is temporarily unavailable.';
      case 'weak-password':
        return 'Password is too weak. Choose a stronger password.';
      default:
        return 'Error: ${e.message ?? 'An unexpected error occurred'}';
    }
  }

  String _googleSignInErrorMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In is not configured correctly for this build.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In is unavailable right now. Please try again.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Google account mismatch. Please try signing in again.';
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was canceled. Please try again.';
      case GoogleSignInExceptionCode.unknownError:
        return e.description ?? _genericAuthErrorMessage;
    }
  }

  Future<void> handlePostAuthNavigation(
    BuildContext context, {
    required String fallbackRouteName,
    Object? fallbackExtra,
    bool replaceRoute = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      context.goNamed(
        'UserOnboarding',
        queryParameters: {'next': fallbackRouteName},
      );
      return;
    }

    // Use already-loaded document when available (populated by maybeCreateUser
    // via authenticatedUserStream), fall back to fresh fetch.
    UsersRecord? userDoc = currentUserDocument;
    if (userDoc == null) {
      try {
        userDoc = await UsersRecord.getDocumentOnce(
          UsersRecord.collection.doc(user.uid),
        );
      } catch (e) {
        AppLog.d('📖 AUTH: Profile fetch failed for ${user.uid}: $e');
      }
    }

    if (!context.mounted) return;

    // Fast path: returning user with onboarding already completed.
    // Check this FIRST to avoid stale-cache issues with profile field checks.
    if (userDoc != null && userDoc.onboardingCompleted) {
      AppLog.d('📖 AUTH: onboarding_completed=true, routing to $fallbackRouteName');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setOnboardingCompletedOverride();
      if (replaceRoute) {
        context.goNamed(fallbackRouteName, extra: fallbackExtra);
      } else {
        context.pushNamed(fallbackRouteName, extra: fallbackExtra);
      }
      return;
    }

    // Onboarding not marked complete — check if profile fields are filled
    // (handles edge case where user completed profile but flag wasn't set).
    bool hasProfileData = false;
    if (userDoc != null) {
      hasProfileData = userDoc.firstName.isNotEmpty &&
          userDoc.lastName.isNotEmpty &&
          userDoc.hasGender() &&
          userDoc.hasDateOfBirth();
      AppLog.d('📖 AUTH: Profile check: firstName=${userDoc.firstName.isNotEmpty}, '
          'lastName=${userDoc.lastName.isNotEmpty}, '
          'gender=${userDoc.hasGender()}, dob=${userDoc.hasDateOfBirth()}');
    }

    if (hasProfileData) {
      // Profile complete but onboarding flag missing — fix it and proceed.
      AppLog.d('📖 AUTH: Profile complete, marking onboarding_completed');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.markOnboardingCompleted();
      if (!context.mounted) return;
      if (replaceRoute) {
        context.goNamed(fallbackRouteName, extra: fallbackExtra);
      } else {
        context.pushNamed(fallbackRouteName, extra: fallbackExtra);
      }
      return;
    }

    // No profile data — send to onboarding.
    AppLog.d('📖 AUTH: No profile data, routing to onboarding');
    context.goNamed(
      'UserOnboarding',
      queryParameters: {'next': fallbackRouteName},
    );
  }

}

@visibleForTesting
Future<UserCredential?> attemptEmailSignInWithRetries({
  required Future<UserCredential?> Function() signInFunc,
  int maxAttempts = 2,
}) async {
  var attempt = 0;
  while (attempt < maxAttempts) {
    attempt += 1;
    try {
      return await signInFunc();
    } on FirebaseAuthException catch (e) {
      AppLog.d(
        '❌ AUTH: Email sign-in failed (attempt $attempt/$maxAttempts).',
      );
      if (e.code == 'user-not-found' || attempt >= maxAttempts) {
        rethrow;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
  return null;
}
