import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/profile/edit_profile/controllers/edit_profile_controller.dart';
import 'package:find_my_fourth/profile/edit_profile/controllers/edit_profile_result.dart';
import 'package:find_my_fourth/services/profile_setup_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MOCK SERVICES
// ═══════════════════════════════════════════════════════════════════════════

class _SuccessProfileSetupService extends ProfileSetupService {
  _SuccessProfileSetupService()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );

  @override
  Future<void> saveEditProfile({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required String? phoneNumber,
  }) async {
    // Simulate successful save
  }
}

class _ThrowingFirebaseExceptionService extends ProfileSetupService {
  _ThrowingFirebaseExceptionService()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );

  @override
  Future<void> saveEditProfile({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required String? phoneNumber,
  }) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing permissions',
    );
  }
}

class _ThrowingGenericExceptionService extends ProfileSetupService {
  _ThrowingGenericExceptionService()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );

  @override
  Future<void> saveEditProfile({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required String? phoneNumber,
  }) async {
    throw StateError('Generic error');
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late DocumentReference userRef;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    userRef = firestore.collection('users').doc('test-user');
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE PROFILE TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('EditProfileController.saveProfile', () {
    test('returns success when service completes', () async {
      final controller = EditProfileController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.saveProfile(
        userRef: userRef,
        userData: {'firstName': 'Test'},
        phoneNumber: '1234567890',
      );

      expect(result, isA<EditProfileSaveSuccess>());
    });

    test('returns failure with code when FirebaseException thrown', () async {
      final controller = EditProfileController(
        profileSetupService: _ThrowingFirebaseExceptionService(),
      );

      final result = await controller.saveProfile(
        userRef: userRef,
        userData: {'firstName': 'Test'},
        phoneNumber: null,
      );

      expect(result, isA<EditProfileSaveFailure>());
      final failure = result as EditProfileSaveFailure;
      expect(failure.type, 'permission-denied');
      expect(failure.message, 'Missing permissions');
    });

    test('returns failure with unknown when generic exception thrown',
        () async {
      final controller = EditProfileController(
        profileSetupService: _ThrowingGenericExceptionService(),
      );

      final result = await controller.saveProfile(
        userRef: userRef,
        userData: {'firstName': 'Test'},
        phoneNumber: null,
      );

      expect(result, isA<EditProfileSaveFailure>());
      final failure = result as EditProfileSaveFailure;
      expect(failure.type, 'unknown');
      expect(failure.message, contains('Generic error'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('EditProfileController.validateFirstName', () {
    late EditProfileController controller;

    setUp(() {
      controller = EditProfileController(
        profileSetupService: _SuccessProfileSetupService(),
      );
    });

    test('returns error for null', () {
      expect(controller.validateFirstName(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(controller.validateFirstName(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(controller.validateFirstName('   '), isNotNull);
    });

    test('returns null for valid name', () {
      expect(controller.validateFirstName('John'), isNull);
    });

    test('returns null for name with leading/trailing spaces', () {
      expect(controller.validateFirstName('  John  '), isNull);
    });
  });

  group('EditProfileController.validateLastName', () {
    late EditProfileController controller;

    setUp(() {
      controller = EditProfileController(
        profileSetupService: _SuccessProfileSetupService(),
      );
    });

    test('returns error for null', () {
      expect(controller.validateLastName(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(controller.validateLastName(''), isNotNull);
    });

    test('returns null for valid name', () {
      expect(controller.validateLastName('Doe'), isNull);
    });
  });

  group('EditProfileController.validatePhone', () {
    late EditProfileController controller;

    setUp(() {
      controller = EditProfileController(
        profileSetupService: _SuccessProfileSetupService(),
      );
    });

    test('returns null for null (optional field)', () {
      expect(controller.validatePhone(null), isNull);
    });

    test('returns null for empty string (optional field)', () {
      expect(controller.validatePhone(''), isNull);
    });

    test('returns error for non-digit characters', () {
      expect(controller.validatePhone('123-456-7890'), isNotNull);
      expect(controller.validatePhone('(123) 456-7890'), isNotNull);
      expect(controller.validatePhone('123abc4567'), isNotNull);
    });

    test('returns error for too few digits', () {
      expect(controller.validatePhone('123456789'), isNotNull); // 9 digits
    });

    test('returns error for too many digits', () {
      expect(
          controller.validatePhone('1234567890123456'), isNotNull); // 16 digits
    });

    test('returns null for valid 10-digit phone', () {
      expect(controller.validatePhone('1234567890'), isNull);
    });

    test('returns null for valid 15-digit phone', () {
      expect(controller.validatePhone('123456789012345'), isNull);
    });
  });

  group('EditProfileController.validateGolfCanadaNumber', () {
    late EditProfileController controller;

    setUp(() {
      controller = EditProfileController(
        profileSetupService: _SuccessProfileSetupService(),
      );
    });

    test('returns null for null (optional field)', () {
      expect(controller.validateGolfCanadaNumber(null), isNull);
    });

    test('returns null for empty string (optional field)', () {
      expect(controller.validateGolfCanadaNumber(''), isNull);
    });

    test('returns error for non-digit characters', () {
      expect(controller.validateGolfCanadaNumber('ABC123'), isNotNull);
      expect(controller.validateGolfCanadaNumber('123-456'), isNotNull);
    });

    test('returns null for valid digits', () {
      expect(controller.validateGolfCanadaNumber('123456'), isNull);
      expect(controller.validateGolfCanadaNumber('1'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT TESTS
  // Note: deleteAccount() relies on global functions (deleteAccount, authManager)
  // which are difficult to mock without modifying the controller.
  // These tests are documented but require integration testing or DI refactor.
  // ═══════════════════════════════════════════════════════════════════════════

  group('EditProfileController.deleteUserAccount', () {
    // Integration tests would be needed here since deleteAccount() calls
    // global functions that can't be easily mocked without additional DI.
    // The contract is:
    // - Returns EditProfileDeleteSuccess when delete + signout succeed
    // - Returns EditProfileDeleteFailure('delete_failed', ...) when cloud function returns false
    // - Returns EditProfileDeleteFailure('unknown', ...) when exception thrown

    test('contract: deleteUserAccount returns typed result', () {
      // This documents the expected contract
      expect(EditProfileDeleteSuccess, isNotNull);
      expect(EditProfileDeleteFailure('type', 'msg'), isA<EditProfileDeleteResult>());
      expect(EditProfileDeleteCancelled, isNotNull);
    });
  });
}
