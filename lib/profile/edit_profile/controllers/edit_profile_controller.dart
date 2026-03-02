import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/utils/app_log.dart';
import '/services/profile_setup_service.dart';
import 'edit_profile_result.dart';

/// Controller for EditProfile screen operations.
///
/// Handles pure async operations only:
/// - Profile save via [ProfileSetupService]
/// - Account deletion via cloud function
/// - Field validation
///
/// Does NOT handle UI concerns (dialogs, snackbars, navigation).
class EditProfileController {
  EditProfileController({
    ProfileSetupService? profileSetupService,
  }) : _profileSetupService = profileSetupService ?? ProfileSetupService();

  final ProfileSetupService _profileSetupService;

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves profile data to Firestore.
  ///
  /// Returns [EditProfileSaveSuccess] on success, or [EditProfileSaveFailure]
  /// with error type and message on failure. Never throws.
  Future<EditProfileSaveResult> saveProfile({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required String? phoneNumber,
  }) async {
    try {
      await _profileSetupService.saveEditProfile(
        userRef: userRef,
        userData: userData,
        phoneNumber: phoneNumber,
      );
      AppLog.d('✅ EditProfileController.saveProfile success');
      return const EditProfileSaveSuccess();
    } on FirebaseException catch (e) {
      AppLog.d(
          '❌ EditProfileController.saveProfile error: ${e.code} - ${e.message}');
      return EditProfileSaveFailure(e.code, e.message ?? 'Save failed');
    } catch (e) {
      AppLog.d('❌ EditProfileController.saveProfile error: $e');
      return EditProfileSaveFailure('unknown', e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Deletes the user account via cloud function and signs out.
  ///
  /// Returns [EditProfileDeleteSuccess] on success, or [EditProfileDeleteFailure]
  /// with error type and message on failure. Never throws.
  Future<EditProfileDeleteResult> deleteUserAccount() async {
    try {
      final deleted = await deleteAccount();
      if (!deleted) {
        AppLog.d('❌ EditProfileController.deleteUserAccount: cloud function returned false');
        return const EditProfileDeleteFailure(
          'delete_failed',
          'Unable to delete account',
        );
      }
      await authManager.signOut();
      AppLog.d('✅ EditProfileController.deleteUserAccount success');
      return const EditProfileDeleteSuccess();
    } catch (e) {
      AppLog.d('❌ EditProfileController.deleteUserAccount error: $e');
      return EditProfileDeleteFailure('unknown', e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates first name field.
  /// Returns error message if invalid, null if valid.
  String? validateFirstName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'First name is required';
    }
    return null;
  }

  /// Validates last name field.
  /// Returns error message if invalid, null if valid.
  String? validateLastName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Last name is required';
    }
    return null;
  }

  /// Validates phone number field.
  /// Returns error message if invalid, null if valid.
  /// Phone is optional; if provided, must be 10-15 digits.
  String? validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null; // Optional field
    }
    // Must be digits only
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Phone number must contain only digits';
    }
    // Must be 10-15 digits
    if (trimmed.length < 10 || trimmed.length > 15) {
      return 'Phone number must be 10-15 digits';
    }
    return null;
  }

  /// Validates Golf Canada number field.
  /// Returns error message if invalid, null if valid.
  /// Golf Canada number is optional; if provided, must be digits only.
  String? validateGolfCanadaNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null; // Optional field
    }
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Golf Canada number must contain only digits';
    }
    return null;
  }
}
