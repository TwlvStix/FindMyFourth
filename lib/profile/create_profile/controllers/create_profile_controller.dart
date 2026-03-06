import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/users_record.dart';
import '/core/utils/app_log.dart';
import '/services/profile_setup_service.dart';
import '/core/custom_functions.dart' as functions;
import '/utils/app_util.dart';

/// Form data for creating a profile.
class CreateProfileFormData {
  const CreateProfileFormData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.phone,
    required this.email,
    required this.photoUrl,
    this.gender,
    this.dateOfBirth,
    this.handicap,
    this.homeCourse,
    this.golfCanadaNumber,
    this.hometownName,
    this.hometownRef,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String phone;
  final String email;
  final String photoUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final int? handicap;
  final String? homeCourse;
  final String? golfCanadaNumber;
  final String? hometownName;
  final DocumentReference? hometownRef;

  /// Creates the username using the username creator function.
  String get processedUsername => functions.usernameCreator(username);
}

/// Failure types for profile creation.
enum CreateProfileFailure {
  formInvalid,
  genderRequired,
  dateOfBirthRequired,
  userNotAuthenticated,
  invalidUsername,
  usernameTaken,
  emailMismatch,
  permissionDenied,
  onboardingFailed,
  unknown,
}

/// Result of a profile creation attempt.
class CreateProfileResult {
  const CreateProfileResult._({
    required this.success,
    this.failure,
    this.message,
    this.userRecord,
  });

  final bool success;
  final CreateProfileFailure? failure;
  final String? message;
  final UsersRecord? userRecord;

  factory CreateProfileResult.success({required UsersRecord userRecord}) {
    return CreateProfileResult._(
      success: true,
      userRecord: userRecord,
    );
  }

  factory CreateProfileResult.fail(
    CreateProfileFailure failure,
    String message,
  ) {
    return CreateProfileResult._(
      success: false,
      failure: failure,
      message: message,
    );
  }
}

/// Controller for create profile form submission.
///
/// Coordinates username reservation, profile data saving, and onboarding
/// completion. Returns typed results for UI consumption.
class CreateProfileController {
  CreateProfileController({
    ProfileSetupService? profileSetupService,
  }) : _profileSetupService = profileSetupService ?? ProfileSetupService();

  final ProfileSetupService _profileSetupService;

  /// Validates username format.
  ///
  /// Returns null if valid, error message if invalid.
  String? validateUsername(String? val) {
    if (val == null || val.isEmpty) {
      return 'Username is required';
    }
    if (!RegExp(kTextValidatorUsernameRegex).hasMatch(val)) {
      return 'Must start with a letter and contain only letters, digits, -, or _';
    }
    return null;
  }

  /// Validates email format.
  ///
  /// Returns null if valid, error message if invalid.
  String? validateEmail(String? val) {
    if (val == null || val.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Must be a valid email address';
    }
    return null;
  }

  /// Submits the profile creation.
  ///
  /// Validates form data, reserves username, and saves profile data.
  Future<CreateProfileResult> submitProfile({
    required CreateProfileFormData formData,
    required bool isFormValid,
    required String currentUserEmail,
  }) async {
    // Validate form
    if (!isFormValid) {
      return CreateProfileResult.fail(
        CreateProfileFailure.formInvalid,
        'Please fix form errors before submitting.',
      );
    }

    // Validate required behavioural dataset fields
    if (formData.gender == null || formData.gender!.isEmpty) {
      return CreateProfileResult.fail(
        CreateProfileFailure.genderRequired,
        'Gender is required.',
      );
    }

    if (formData.dateOfBirth == null) {
      return CreateProfileResult.fail(
        CreateProfileFailure.dateOfBirthRequired,
        'Date of birth is required.',
      );
    }

    // Process username
    final desiredUsername = formData.processedUsername;
    if (desiredUsername.isEmpty) {
      return CreateProfileResult.fail(
        CreateProfileFailure.invalidUsername,
        'Username cannot be empty.',
      );
    }

    if (!RegExp(kTextValidatorUsernameRegex).hasMatch(desiredUsername)) {
      return CreateProfileResult.fail(
        CreateProfileFailure.invalidUsername,
        'Must start with a letter and contain only letters, digits, -, or _',
      );
    }

    // Validate email matches auth email
    final desiredEmail = formData.email.trim();
    if (desiredEmail.isNotEmpty && desiredEmail != currentUserEmail) {
      return CreateProfileResult.fail(
        CreateProfileFailure.emailMismatch,
        'Please update your Firebase Auth email ($currentUserEmail) before saving your profile.',
      );
    }

    // Get current user
    final firebaseUser = await _profileSetupService.currentUserOrWait();
    if (firebaseUser == null) {
      return CreateProfileResult.fail(
        CreateProfileFailure.userNotAuthenticated,
        'Sign-in not ready. Please try again.',
      );
    }

    final userRef = UsersRecord.collection.doc(firebaseUser.uid);

    try {
      // Reserve username
      await _profileSetupService.reserveUsername(
        username: desiredUsername,
        userRef: userRef,
      );

      try {
        // Save profile data
        final golfCanadaRaw = formData.golfCanadaNumber?.trim() ?? '';
        AppLog.d('📖 Creating user document with friend fields initialized...');

        await _profileSetupService.saveCreateProfileData(
          userRef: userRef,
          userData: createUsersRecordData(
            photoUrl: formData.photoUrl,
            handicap: formData.handicap,
            golfCanadaNumber: golfCanadaRaw.isEmpty ? null : golfCanadaRaw,
            homeCourse: formData.homeCourse,
            firstName: formData.firstName,
            lastName: formData.lastName,
            displayName: desiredUsername,
            onboardingCompleted: true,
            gender: formData.gender,
            dateOfBirth: formData.dateOfBirth,
            hometown: formData.hometownRef,
            hometownName: formData.hometownName,
            friends: [],
            friendRequests: [],
          ),
          phoneNumber: formData.phone,
        );

        AppLog.d('✅ User document created with friend fields initialized');
      } catch (e) {
        // Rollback username reservation on failure
        await _profileSetupService.releaseUsernameIfOwned(
          username: desiredUsername,
          userRef: userRef,
        );
        rethrow;
      }

      // Get the created user document
      final userRecord = await UsersRecord.getDocumentOnce(userRef);

      return CreateProfileResult.success(userRecord: userRecord);
    } on StateError catch (_) {
      return CreateProfileResult.fail(
        CreateProfileFailure.usernameTaken,
        'This username is taken. Please choose another.',
      );
    } on FirebaseException catch (e, stackTrace) {
      AppLog.d('❌ CreateProfile save failed: $e');
      AppLog.d('❌ CreateProfile save stackTrace: $stackTrace');

      final message = e.code == 'permission-denied'
          ? 'Unable to save profile due to permissions. Please try again.'
          : 'Unable to save profile. Please try again.';

      return CreateProfileResult.fail(
        CreateProfileFailure.permissionDenied,
        message,
      );
    } catch (e, stackTrace) {
      AppLog.d('❌ CreateProfile save failed: $e');
      AppLog.d('❌ CreateProfile save stackTrace: $stackTrace');

      return CreateProfileResult.fail(
        CreateProfileFailure.unknown,
        'Unable to save profile. Please try again.',
      );
    }
  }
}
