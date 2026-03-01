import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

final _googleSignIn = GoogleSignIn.instance;
bool _googleSignInInitialized = false;

Future<void> _ensureGoogleSignInInitialized() async {
  if (_googleSignInInitialized) {
    return;
  }
  await _googleSignIn.initialize();
  _googleSignInInitialized = true;
}

Future<UserCredential?> googleSignInFunc() async {
  if (kIsWeb) {
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  await _ensureGoogleSignInInitialized();
  await signOutWithGoogle().catchError((_) => null);
  GoogleSignInAccount account;
  try {
    account = await _googleSignIn.authenticate(
      scopeHint: const ['profile', 'email'],
    );
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled ||
        e.code == GoogleSignInExceptionCode.interrupted) {
      return null;
    }
    rethrow;
  }
  final auth = account.authentication;
  final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
  return FirebaseAuth.instance.signInWithCredential(credential);
}

Future<void> signOutWithGoogle() => _googleSignIn.signOut();
