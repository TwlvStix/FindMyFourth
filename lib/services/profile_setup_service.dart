import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> reserveUsername({
    required String username,
    required DocumentReference userRef,
  }) async {
    final usernamesRef = _firestore.collection('usernames').doc(username);
    await _firestore.runTransaction((transaction) async {
      final usernameSnap = await transaction.get(usernamesRef);
      if (usernameSnap.exists) {
        final existingRef = usernameSnap.get('uid') as DocumentReference?;
        if (existingRef != null && existingRef.path != userRef.path) {
          throw StateError('username_taken');
        }
      } else {
        transaction.set(usernamesRef, <String, dynamic>{
          'uid': userRef,
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
      final existingRef = usernameDoc.get('uid') as DocumentReference?;
      if (existingRef != null && existingRef.path == userRef.path) {
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
    await Future.wait([
      userRef.set(userData, SetOptions(merge: true)),
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        userRef.collection('private').doc('info').set(
          <String, dynamic>{'phone_number': phoneNumber},
          SetOptions(merge: true),
        ),
    ]);
  }

  Future<void> saveEditProfile({
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required String? phoneNumber,
  }) async {
    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, userData);
      transaction.set(
        userRef.collection('private').doc('info'),
        <String, dynamic>{'phone_number': phoneNumber ?? ''},
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
    final usernamesRef = _firestore.collection('usernames').doc(username);
    await _firestore.runTransaction((transaction) async {
      final usernameSnap = await transaction.get(usernamesRef);
      if (usernameSnap.exists) {
        final existingRef = usernameSnap.get('uid') as DocumentReference?;
        if (existingRef != null && existingRef.path != userRef.path) {
          throw StateError('username_taken');
        }
      } else {
        transaction.set(usernamesRef, <String, dynamic>{
          'uid': userRef,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(userRef, userData);
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        transaction.set(
          userRef.collection('private').doc('info'),
          <String, dynamic>{'phone_number': phoneNumber},
          SetOptions(merge: true),
        );
      }
    });
  }
}
