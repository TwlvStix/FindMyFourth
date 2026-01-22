import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_manager.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

const _genericAuthErrorMessage = 'Unable to complete the request. Please try again later.';

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
  Future signOut() {
    return FirebaseAuth.instance.signOut();
  }

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        print('Error: delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
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
  Future updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        print('Error: update email attempted with no logged in user!');
        return;
      }
      await currentUser?.updateEmail(email);
      await updateUserDocument(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
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
  Future updatePassword({
    required String newPassword,
    required BuildContext context,
  }) async {
    try {
      if (!loggedIn) {
        print('Error: update password attempted with no logged in user!');
        return;
      }
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message!}')),
      );
      return false;
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
    phoneAuthManager.addListener(() {
      if (!context.mounted) {
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
    });
  }

  @override
  Future beginPhoneAuth({
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

    return completer.future;
  }

  @override
  Future verifySmsCode({
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

  /// Tries to sign in or create an account using Firebase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<UserCredential?> Function() signInFunc,
    String authProvider,
  ) async {
    try {
      debugPrint('🔐 AUTH: Starting sign in/create account with provider: $authProvider');
      final userCredential = await signInFunc();
      debugPrint('🔐 AUTH: Received user credential.');
      final firebaseUser = userCredential?.user;
      if (firebaseUser != null) {
        debugPrint('🔐 AUTH: Creating/updating user document.');
        await ensureUserDocReady(firebaseUser);
        debugPrint('🔐 AUTH: User document created/updated successfully');
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
      FirebaseMessaging.instance.getToken().then((token) {
        debugPrint(
            '🔐 AUTH ERROR: $authProviderInfo, userDocPath=$userDocPath, fcmToken=$token');
      }).catchError((tokenError) {
        debugPrint(
            '🔐 AUTH ERROR: $authProviderInfo, userDocPath=$userDocPath, fcmToken=failed');
        debugPrint('🔐 AUTH ERROR: token fetch error: $tokenError');
      });
      final errorMsg = _firebaseAuthErrorMessage(e);
      _showAuthError(context, errorMsg);
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ AUTH: Unexpected error during sign in/create account');
      debugPrint('❌ AUTH: Error: $e');
      debugPrint('❌ AUTH: Stack trace: $stackTrace');
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
    debugPrint('🔐 AUTH: Email sign-in attempt for $trimmedEmail');
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
      debugPrint('❌ AUTH: Email sign-in failed (attempt $attempt/$maxAttempts).');
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
    debugPrint('🔐 AUTH: Email create attempt for $trimmedEmail');
    if (!_allowAuthAttempt(trimmedEmail)) {
      _showAuthError(context, _genericAuthErrorMessage);
      return null;
    }

    try {
      debugPrint('🔐 AUTH: Calling createUserWithEmailAndPassword for $trimmedEmail');
      final userCredential = await emailCreateAccountFunc(trimmedEmail, password);
      final firebaseUser = userCredential?.user;
      if (firebaseUser != null) {
        await ensureUserDocReady(firebaseUser);
        debugPrint('🔐 AUTH: Email account created.');
      }
      return userCredential == null
          ? null
          : FindMyFourthFirebaseUser.fromUserCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AUTH: create email failed.');
      final errorMsg = e.code == 'email-already-in-use'
          ? 'An account already exists for that email. Please sign in instead.'
          : _firebaseAuthErrorMessage(e);
      _showAuthError(context, errorMsg);
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ AUTH: Unexpected error during account creation');
      debugPrint('❌ AUTH: Error: $e');
      debugPrint('❌ AUTH: Stack trace: $stackTrace');
      _showAuthError(context, 'Error: An unexpected error occurred');
      return null;
    }
  }

  void _showAuthError(BuildContext context, String message) {
    debugPrint('❌ AUTH: Showing error to user: $message');
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

  Future<bool> _hasCompletedOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return true;
    }

    try {
      final userDoc = await UsersRecord.getDocumentOnce(
        UsersRecord.collection.doc(user.uid),
      );
      return userDoc.onboardingCompleted;
    } catch (_) {
      return false;
    }
  }

  Future<void> handlePostAuthNavigation(
    BuildContext context, {
    required String fallbackRouteName,
    Object? fallbackExtra,
    bool replaceRoute = true,
  }) async {
    final completedOnboarding = await _hasCompletedOnboarding();
    if (!context.mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final userDocPath =
        user != null ? UsersRecord.collection.doc(user.uid).path : '';
    final backendConfirmed = userDocPath.isNotEmpty
        ? await _verifyOnboardingCompleted(userDocPath)
        : false;

    if (!completedOnboarding || !backendConfirmed) {
      if (user != null) {
        try {
          final userDoc = await UsersRecord.getDocumentOnce(
            UsersRecord.collection.doc(user.uid),
          );
          final hasProfileData =
              userDoc.displayName.isNotEmpty ||
              userDoc.firstName.isNotEmpty ||
              userDoc.lastName.isNotEmpty;
          if (hasProfileData) {
            await makeCloudCall(
              'completeOnboarding',
              {'userDocPath': userDocPath},
            );
            if (replaceRoute) {
              context.goNamed(fallbackRouteName, extra: fallbackExtra);
            } else {
              context.pushNamed(fallbackRouteName, extra: fallbackExtra);
            }
            return;
          }
        } catch (_) {}
      }
      context.goNamed(
        'UserOnboarding',
        queryParameters: {
          'next': fallbackRouteName,
        },
      );
      return;
    }

    if (replaceRoute) {
      context.goNamed(fallbackRouteName, extra: fallbackExtra);
    } else {
      context.pushNamed(fallbackRouteName, extra: fallbackExtra);
    }
  }

  Future<bool> _verifyOnboardingCompleted(String userDocPath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      await user.getIdToken(true);
      final result = await makeCloudCall(
        'checkOnboardingComplete',
        {'userDocPath': userDocPath},
      );
      return result['completed'] == true;
    } catch (e) {
      debugPrint('❌ AUTH: Onboarding verification call failed: $e');
      return false;
    }
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
      debugPrint(
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
