import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/backend/backend.dart' as backend;
import '/core/utils/app_log.dart';
import '/core/utils/input_sanitizer.dart';

/// Encapsulates profile/onboarding Firestore/Auth write flows so widgets stay UI-only.
class ProfileSetupService {
  ProfileSetupService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<User?> currentUserOrWait({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      return user;
    }
    try {
      return await _auth
          .authStateChanges()
          .firstWhere((candidate) => candidate != null)
          .timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  /// Updates the current user's email address.
  ///
  /// Sends a verification email to the new address before updating.
  /// Throws [FirebaseAuthException] on failure (e.g., requires-recent-login).
  Future<void> updateUserEmail(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.verifyBeforeUpdateEmail(email);
    AppLog.d('✅ ProfileSetupService: Email update initiated for $email');
  }

  /// Ensures the user document exists and is ready.
  ///
  /// Waits for auth state if needed, then ensures the Firestore user doc exists.
  /// Returns true if successful, false if user not authenticated or doc creation failed.
  Future<bool> ensureUserDocumentReady({
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final user = await currentUserOrWait(timeout: timeout);
    if (user == null) {
      return false;
    }
    try {
      await backend.ensureUserDocReady(user);
      return true;
    } catch (error, stackTrace) {
      AppLog.d('❌ ProfileSetupService.ensureUserDocumentReady error: $error');
      AppLog.d('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> reserveUsername({
    required String username,
    required DocumentReference userRef,
  }) async {
    final sanitizedUsername = InputSanitizer.username(username) ?? username;
    final usernamesRef = _firestore.collection('usernames').doc(sanitizedUsername);
    await _firestore.runTransaction((transaction) async {
      final usernameSnap = await transaction.get(usernamesRef);
      if (usernameSnap.exists) {
        final existingUid = usernameSnap.get('uid') as String?;
        if (existingUid != null && existingUid != userRef.id) {
          throw StateError('username_taken');
        }
      } else {
        transaction.set(usernamesRef, <String, dynamic>{
          'uid': userRef.id,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> releaseUsernameIfOwned({
    required String username,
    required DocumentReference userRef,
  }) async {
    final usernamesRef = _firestore.collection('usernames').doc(username);
    try {
      final usernameDoc = await usernamesRef.get();
      if (!usernameDoc.exists) {
        return;
      }
      final existingUid = usernameDoc.get('uid') as String?;
      if (existingUid != null && existingUid == userRef.id) {
        await usernamesRef.delete();
      }
    } catch (_) {
      // Best-effort rollback only.
    }
  }

  Future<void> saveCreateProfileData({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    String? phoneNumber,
  }) async {
    final sanitizedPhone = InputSanitizer.phoneNumber(phoneNumber);
    await Future.wait([
      userRef.set(userData, SetOptions(merge: true)),
      if (sanitizedPhone != null && sanitizedPhone.isNotEmpty)
        userRef.collection('private').doc('info').set(
          <String, dynamic>{'phone_number': sanitizedPhone},
          SetOptions(merge: true),
        ),
    ]);
  }

  Future<void> saveEditProfile({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required String? phoneNumber,
  }) async {
    final sanitizedPhone = InputSanitizer.phoneNumber(phoneNumber);
    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, userData);
      transaction.set(
        userRef.collection('private').doc('info'),
        <String, dynamic>{'phone_number': sanitizedPhone ?? ''},
        SetOptions(merge: true),
      );
    });
  }

  Future<void> saveProgressiveOnboarding({
    required DocumentReference userRef,
    required String username,
    required Map<String, dynamic> userData,
    String? phoneNumber,
  }) async {
    final sanitizedPhone = InputSanitizer.phoneNumber(phoneNumber);

    // Step 1: Reserve the username in a separate transaction so Firestore
    // rules can see the committed username doc when evaluating the user
    // doc update (rules use get() which reads pre-transaction state).
    await reserveUsername(username: username, userRef: userRef);

    // Step 2: Update the user doc + private info in a second transaction.
    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, userData);
      if (sanitizedPhone != null && sanitizedPhone.isNotEmpty) {
        transaction.set(
          userRef.collection('private').doc('info'),
          <String, dynamic>{'phone_number': sanitizedPhone},
          SetOptions(merge: true),
        );
      }
    });
  }
}
