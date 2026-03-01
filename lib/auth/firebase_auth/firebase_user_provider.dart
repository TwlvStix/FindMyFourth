import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../base_auth_user_provider.dart';

export '../base_auth_user_provider.dart';

class FindMyFourthFirebaseUser extends BaseAuthUser {
  FindMyFourthFirebaseUser(this.user);
  User? user;
  @override
  bool get loggedIn => user != null;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
        uid: user?.uid,
        email: user?.email,
        displayName: user?.displayName,
        photoUrl: user?.photoURL,
        phoneNumber: user?.phoneNumber,
      );

  @override
  Future<void>? delete() => user?.delete();

  @override
  Future<void>? updateEmail(String email) async {
    await user?.verifyBeforeUpdateEmail(email);
  }

  @override
  Future<void>? updatePassword(String newPassword) async {
    await user?.updatePassword(newPassword);
  }

  @override
  Future<void>? sendEmailVerification() => user?.sendEmailVerification();

  @override
  bool get emailVerified {
    // Reloads the user when checking in order to get the most up to date
    // email verified status.
    if (loggedIn && !user!.emailVerified) {
      refreshUser();
    }
    return user?.emailVerified ?? false;
  }

  @override
  Future<void> refreshUser() async {
    await FirebaseAuth.instance.currentUser
        ?.reload()
        .then((_) => user = FirebaseAuth.instance.currentUser);
  }

  static BaseAuthUser fromUserCredential(UserCredential userCredential) =>
      fromFirebaseUser(userCredential.user);
  static BaseAuthUser fromFirebaseUser(User? user) =>
      FindMyFourthFirebaseUser(user);
}

Stream<BaseAuthUser> findMyFourthFirebaseUserStream() => FirebaseAuth.instance
        .authStateChanges()
        .debounce((user) => user == null && !loggedIn
            ? Future<void>.delayed(const Duration(seconds: 1)).asStream()
            : const Stream<void>.empty())
        .map<BaseAuthUser>(
      (user) {
        currentUser = FindMyFourthFirebaseUser(user);
        return currentUser!;
      },
    );
