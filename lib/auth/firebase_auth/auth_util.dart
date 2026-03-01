import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import 'package:stream_transform/stream_transform.dart';
import 'firebase_auth_manager.dart';

export 'firebase_auth_manager.dart';

final _authManager = FirebaseAuthManager();
FirebaseAuthManager get authManager => _authManager;

String get currentUserEmail =>
    (_currentUserPrivateData?['email'] as String?) ??
    currentUser?.email ??
    '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName =>
    currentUserDocument?.displayName ?? currentUser?.displayName ?? '';

String get currentUserPhoto =>
    currentUserDocument?.photoUrl ?? currentUser?.photoUrl ?? '';

String get currentPhoneNumber =>
    (_currentUserPrivateData?['phone_number'] as String?) ??
    currentUser?.phoneNumber ??
    '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
final jwtTokenStream = FirebaseAuth.instance
    .idTokenChanges()
    .asyncMap((user) async {
      if (user == null) {
        _currentJwtToken = null;
        return null;
      }

      try {
        _currentJwtToken = await user.getIdToken();
      } catch (_) {
        // Token fetch failures can happen during transient auth/session changes,
        // including platform-level errors (FlutterError) not just FirebaseAuthException.
        // Keep app state stable and let the next auth event retry.
        _currentJwtToken = null;
      }

      return _currentJwtToken;
    })
    .asBroadcastStream();

DocumentReference? get currentUserReference =>
    loggedIn ? UsersRecord.collection.doc(currentUser!.uid) : null;

UsersRecord? currentUserDocument;
final authenticatedUserStream = FirebaseAuth.instance
    .authStateChanges()
    .map<String>((user) => user?.uid ?? '')
    .switchMap(
      (uid) => uid.isEmpty
          ? Stream.value(null)
          : UsersRecord.getDocument(UsersRecord.collection.doc(uid))
              .handleError((_) {}),
    )
    .map((user) {
  currentUserDocument = user;

  return currentUserDocument;
}).asBroadcastStream();

Map<String, dynamic>? _currentUserPrivateData;
final privateUserDataStream = FirebaseAuth.instance
    .authStateChanges()
    .switchMap((user) {
      if (user == null) {
        return Stream<Map<String, dynamic>?>.value(null);
      }
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('private')
          .doc('info')
          .snapshots()
          .map((snap) => snap.exists ? snap.data() : null);
    })
    .map((data) {
      _currentUserPrivateData = data;
      return _currentUserPrivateData;
    })
    .asBroadcastStream();

class AuthUserStreamWidget extends StatelessWidget {
  const AuthUserStreamWidget({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: authenticatedUserStream,
        initialData: currentUserDocument,
        builder: (context, _) => builder(context),
      );
}
