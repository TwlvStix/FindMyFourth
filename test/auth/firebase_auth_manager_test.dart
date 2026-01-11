import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/auth/firebase_auth/firebase_auth_manager.dart';

class _FakeUserCredential implements UserCredential {
  _FakeUserCredential({
    this.user,
    this.credential,
    this.additionalUserInfo,
  });

  @override
  final User? user;

  @override
  final AuthCredential? credential;

  @override
  final AdditionalUserInfo? additionalUserInfo;
}

void main() {
  group('attemptEmailSignInWithRetries', () {
    test('retries after a transient failure and succeeds', () async {
      var attempts = 0;
      final resultCredential = _FakeUserCredential();

      final result = await attemptEmailSignInWithRetries(
        signInFunc: () async {
          attempts += 1;
          if (attempts == 1) {
            throw FirebaseAuthException(
              code: 'network-request-failed',
              message: 'transient',
            );
          }
          return resultCredential;
        },
      );

      expect(result, same(resultCredential));
      expect(attempts, 2);
    });

    test('propagates user-not-found immediately', () async {
      var attempts = 0;

      await expectLater(
        () => attemptEmailSignInWithRetries(
          signInFunc: () async {
            attempts += 1;
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'missing',
            );
          },
        ),
        throwsA(isA<FirebaseAuthException>()),
      );

      expect(attempts, 1);
    });
  });
}
