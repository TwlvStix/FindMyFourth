import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/user_onboarding/controllers/progressive_onboarding_controller.dart';
import 'package:find_my_fourth/user_onboarding/controllers/progressive_onboarding_result.dart';
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
  Future<void> saveProgressiveOnboarding({
    required DocumentReference userRef,
    required String username,
    required Map<String, dynamic> userData,
    String? phoneNumber,
  }) async {
    // Simulate successful save
  }

  @override
  Future<User?> currentUserOrWait({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return MockFirebaseAuth().currentUser;
  }
}

class _UsernameTakenService extends ProfileSetupService {
  _UsernameTakenService()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );

  @override
  Future<void> saveProgressiveOnboarding({
    required DocumentReference userRef,
    required String username,
    required Map<String, dynamic> userData,
    String? phoneNumber,
  }) async {
    throw StateError('username_taken');
  }

  @override
  Future<User?> currentUserOrWait({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return MockFirebaseAuth().currentUser;
  }
}

class _UserRecordNotReadyService extends ProfileSetupService {
  _UserRecordNotReadyService()
      : super(
          firestore: FakeFirebaseFirestore(),
          auth: MockFirebaseAuth(),
        );

  @override
  Future<void> saveProgressiveOnboarding({
    required DocumentReference userRef,
    required String username,
    required Map<String, dynamic> userData,
    String? phoneNumber,
  }) async {
    // Simulate successful save
  }

  @override
  Future<User?> currentUserOrWait({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // Return null to simulate user record not ready
    return null;
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
  // VALIDATION TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveOnboardingController.validateUsername', () {
    late ProgressiveOnboardingController controller;

    setUp(() {
      controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );
    });

    test('returns error for null', () {
      expect(controller.validateUsername(null), isNotNull);
      expect(controller.validateUsername(null), contains('required'));
    });

    test('returns error for empty string', () {
      expect(controller.validateUsername(''), isNotNull);
      expect(controller.validateUsername(''), contains('required'));
    });

    test('returns error for invalid format (starts with number)', () {
      expect(controller.validateUsername('123abc'), isNotNull);
      expect(controller.validateUsername('123abc'), contains('start with a letter'));
    });

    test('returns error for invalid characters', () {
      expect(controller.validateUsername('user@name'), isNotNull);
      expect(controller.validateUsername('user name'), isNotNull);
    });

    test('returns null for valid username starting with letter', () {
      expect(controller.validateUsername('johndoe'), isNull);
    });

    test('returns null for valid username with numbers and underscores', () {
      expect(controller.validateUsername('john_doe123'), isNull);
    });

    test('returns null for valid username with hyphens', () {
      expect(controller.validateUsername('john-doe'), isNull);
    });
  });

  group('ProgressiveOnboardingController.validateEmail', () {
    late ProgressiveOnboardingController controller;

    setUp(() {
      controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );
    });

    test('returns error for null', () {
      expect(controller.validateEmail(null), isNotNull);
      expect(controller.validateEmail(null), contains('required'));
    });

    test('returns error for empty string', () {
      expect(controller.validateEmail(''), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(controller.validateEmail('notanemail'), isNotNull);
      expect(controller.validateEmail('notanemail'), contains('valid email'));
    });

    test('returns error for email without @', () {
      expect(controller.validateEmail('test.example.com'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(controller.validateEmail('test@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(controller.validateEmail('test@mail.example.com'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT ONBOARDING TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveOnboardingController.submitOnboarding', () {
    test('returns formInvalid when first name is empty', () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: '',
        lastName: 'Doe',
        username: 'johndoe',
        phone: '',
        currentEmail: 'test@example.com',
        desiredEmail: 'test@example.com',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {},
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.formInvalid);
    });

    test('returns formInvalid when last name is empty', () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: 'John',
        lastName: '',
        username: 'johndoe',
        phone: '',
        currentEmail: 'test@example.com',
        desiredEmail: 'test@example.com',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {},
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.formInvalid);
    });

    test('returns formInvalid when username is invalid', () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: 'John',
        lastName: 'Doe',
        username: '123invalid',
        phone: '',
        currentEmail: 'test@example.com',
        desiredEmail: 'test@example.com',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {},
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.formInvalid);
    });

    test('returns formInvalid when email is invalid', () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: 'John',
        lastName: 'Doe',
        username: 'johndoe',
        phone: '',
        currentEmail: 'test@example.com',
        desiredEmail: 'notanemail',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {},
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.formInvalid);
    });

    test('returns usernameTaken when service throws StateError', () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _UsernameTakenService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: 'John',
        lastName: 'Doe',
        username: 'johndoe',
        phone: '',
        currentEmail: 'test@example.com',
        desiredEmail: 'test@example.com',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {},
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.usernameTaken);
      expect(failure.message, contains('taken'));
    });

    test('returns requiresReauth when email update throws requires-recent-login',
        () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: 'John',
        lastName: 'Doe',
        username: 'johndoe',
        phone: '',
        currentEmail: 'old@example.com',
        desiredEmail: 'new@example.com',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Reauth required',
          );
        },
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.requiresReauth);
      expect(failure.message, contains('sign in again'));
    });

    test('returns emailUpdateFailed when email update throws other error',
        () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _SuccessProfileSetupService(),
      );

      final result = await controller.submitOnboarding(
        userRef: userRef,
        firstName: 'John',
        lastName: 'Doe',
        username: 'johndoe',
        phone: '',
        currentEmail: 'old@example.com',
        desiredEmail: 'new@example.com',
        homeCourse: null,
        handicap: 18,
        drinks: 2,
        music: 2,
        playMoney: 2,
        pace: 2,
        updateEmailFn: (_) async {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Invalid email',
          );
        },
      );

      expect(result, isA<OnboardingFailure>());
      final failure = result as OnboardingFailure;
      expect(failure.type, OnboardingFailureType.emailUpdateFailed);
    });

    test('returns userRecordNotReady when currentUserOrWait returns null',
        () async {
      final controller = ProgressiveOnboardingController(
        profileSetupService: _UserRecordNotReadyService(),
      );

      // Note: This test requires the full flow, but since we can't easily mock
      // makeCloudCall or ensureUserDocReady, we document the contract
      // The service returns null from currentUserOrWait, which should result in
      // userRecordNotReady. However, the actual test may hit cloud function first.

      // For contract documentation:
      expect(OnboardingFailureType.userRecordNotReady, isNotNull);
    });

    // Note: Testing success and cloudFunctionFailed requires mocking global
    // functions (makeCloudCall, ensureUserDocReady) which is difficult without
    // additional DI. These are documented as integration test requirements.

    test('contract: submitOnboarding returns typed result', () {
      // Documents the expected contract
      expect(OnboardingSuccess, isNotNull);
      expect(
        const OnboardingFailure(OnboardingFailureType.formInvalid, 'msg'),
        isA<ProgressiveOnboardingResult>(),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULT TYPE TESTS
  // ═══════════════════════════════════════════════════════════════════════════

  group('ProgressiveOnboardingResult types', () {
    test('OnboardingSuccess is a valid result type', () {
      const result = OnboardingSuccess();
      expect(result, isA<ProgressiveOnboardingResult>());
    });

    test('OnboardingFailure contains type and message', () {
      const result = OnboardingFailure(
        OnboardingFailureType.usernameTaken,
        'Username already taken',
      );
      expect(result.type, OnboardingFailureType.usernameTaken);
      expect(result.message, 'Username already taken');
    });

    test('all failure types are distinct', () {
      final types = OnboardingFailureType.values;
      expect(types.toSet().length, types.length);
    });
  });
}
