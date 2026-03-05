import 'package:firebase_auth/firebase_auth.dart';

import '/backend/backend.dart';
import '/core/custom_functions.dart' as functions;
import '/core/utils/app_log.dart';
import '/services/profile_setup_service.dart';
import '/utils/app_util.dart';
import 'progressive_onboarding_result.dart';

/// Controller for ProgressiveOnboarding screen operations.
///
/// Handles pure async operations only:
/// - Form validation
/// - Email update (via injected function)
/// - Profile save via [ProfileSetupService]
/// - Onboarding completion via direct user document update
///
/// Does NOT handle UI concerns (dialogs, snackbars, navigation, mounted checks).
class ProgressiveOnboardingController {
  ProgressiveOnboardingController({
    ProfileSetupService? profileSetupService,
  }) : _profileSetupService = profileSetupService ?? ProfileSetupService();

  final ProfileSetupService _profileSetupService;

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates username field.
  /// Returns error message if invalid, null if valid.
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (!RegExp(kTextValidatorUsernameRegex).hasMatch(value)) {
      return 'Must start with a letter and can only contain letters, digits and - or _.';
    }
    return null;
  }

  /// Validates email field.
  /// Returns error message if invalid, null if valid.
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(kTextValidatorEmailRegex).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT ONBOARDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submits the onboarding form.
  ///
  /// Returns [OnboardingSuccess] on success, or [OnboardingFailure]
  /// with typed error and message on failure. Never throws.
  Future<ProgressiveOnboardingResult> submitOnboarding({
    required DocumentReference userRef,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String currentEmail,
    required String desiredEmail,
    required String? homeCourse,
    required int handicap,
    required int drinks,
    required int music,
    required int playMoney,
    required int pace,
  }) async {
    // Validate required fields
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      return const OnboardingFailure(
        OnboardingFailureType.formInvalid,
        'Please complete all required fields',
      );
    }

    final usernameError = validateUsername(username);
    if (usernameError != null) {
      return OnboardingFailure(
        OnboardingFailureType.formInvalid,
        usernameError,
      );
    }

    final emailError = validateEmail(desiredEmail);
    if (emailError != null) {
      return OnboardingFailure(
        OnboardingFailureType.formInvalid,
        emailError,
      );
    }

    final normalizedUsername = functions.usernameCreator(username);

    // Update email if changed
    final trimmedDesiredEmail = desiredEmail.trim();
    if (trimmedDesiredEmail.isNotEmpty &&
        trimmedDesiredEmail != currentEmail) {
      try {
        await _profileSetupService.updateUserEmail(trimmedDesiredEmail);
      } on FirebaseAuthException catch (e) {
        AppLog.d(
            '❌ ProgressiveOnboardingController.submitOnboarding email error: ${e.code}');
        if (e.code == 'requires-recent-login') {
          return const OnboardingFailure(
            OnboardingFailureType.requiresReauth,
            'Email change requires you to sign in again.',
          );
        }
        return OnboardingFailure(
          OnboardingFailureType.emailUpdateFailed,
          'Unable to update email. ${e.message}',
        );
      }
    }

    // Save profile data
    try {
      await _profileSetupService.saveProgressiveOnboarding(
        userRef: userRef,
        username: normalizedUsername,
        userData: createUsersRecordData(
          displayName: normalizedUsername,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          homeCourse: homeCourse,
          handicap: handicap,
          drinks: drinks,
          music: music,
          playForMoney: playMoney,
          paceOfPlay: pace,
          onboardingCompleted: true,
        ),
        phoneNumber: phone.trim(),
      );
      AppLog.d('✅ ProgressiveOnboardingController.submitOnboarding profile saved');
    } on StateError catch (_) {
      AppLog.d('❌ ProgressiveOnboardingController.submitOnboarding username taken');
      return const OnboardingFailure(
        OnboardingFailureType.usernameTaken,
        'Username already taken',
      );
    } catch (e) {
      AppLog.d('❌ ProgressiveOnboardingController.submitOnboarding save error: $e');
      return OnboardingFailure(
        OnboardingFailureType.unknown,
        'Unable to save profile: $e',
      );
    }

    // Verify user record is ready
    final recordReady = await _ensureUserRecord();
    if (!recordReady) {
      AppLog.d(
          '❌ ProgressiveOnboardingController.submitOnboarding user record not ready');
      return const OnboardingFailure(
        OnboardingFailureType.userRecordNotReady,
        'Finishing setup. Please wait a moment before continuing.',
      );
    }

    AppLog.d('✅ ProgressiveOnboardingController.submitOnboarding success');
    return const OnboardingSuccess();
  }

  /// Ensures the user record exists and is ready.
  Future<bool> _ensureUserRecord() async {
    return _profileSetupService.ensureUserDocumentReady(
      timeout: const Duration(seconds: 1),
    );
  }

  /// Ensures user record exists. Call on init.
  Future<bool> ensureUserRecordOnInit() async {
    return _ensureUserRecord();
  }
}
