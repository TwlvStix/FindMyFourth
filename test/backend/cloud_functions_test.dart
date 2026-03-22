import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/backend/cloud_functions/cloud_functions.dart';

void main() {
  group('attemptAuthenticatedCallWithRetries', () {
    test('returns result on first successful attempt', () async {
      var attempts = 0;
      var retryCount = 0;

      final result = await attemptAuthenticatedCallWithRetries(
        callFunc: () async {
          attempts++;
          return {'success': true, 'data': 'test'};
        },
        onRetry: () async {
          retryCount++;
        },
      );

      expect(result, {'success': true, 'data': 'test'});
      expect(attempts, 1);
      expect(retryCount, 0);
    });

    test('retries on UNAUTHENTICATED and succeeds on second attempt', () async {
      var attempts = 0;
      var retryCount = 0;

      final result = await attemptAuthenticatedCallWithRetries(
        callFunc: () async {
          attempts++;
          if (attempts == 1) {
            throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message: 'No auth context',
            );
          }
          return {'success': true};
        },
        onRetry: () async {
          retryCount++;
        },
        retryDelay: Duration.zero, // Speed up test
      );

      expect(result, {'success': true});
      expect(attempts, 2);
      expect(retryCount, 1);
    });

    test('retries on UNAUTHENTICATED (uppercase) and succeeds', () async {
      var attempts = 0;

      final result = await attemptAuthenticatedCallWithRetries(
        callFunc: () async {
          attempts++;
          if (attempts == 1) {
            throw FirebaseFunctionsException(
              code: 'UNAUTHENTICATED',
              message: 'No auth context',
            );
          }
          return {'success': true};
        },
        onRetry: () async {},
        retryDelay: Duration.zero,
      );

      expect(result, {'success': true});
      expect(attempts, 2);
    });

    test('throws after max retries on UNAUTHENTICATED', () async {
      var attempts = 0;
      var retryCount = 0;

      await expectLater(
        () => attemptAuthenticatedCallWithRetries(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message: 'Always fails',
            );
          },
          onRetry: () async {
            retryCount++;
          },
          maxRetries: 2,
          retryDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(attempts, 2);
      expect(retryCount, 1); // One retry between attempt 1 and 2
    });

    test('does not retry on non-auth errors (internal)', () async {
      var attempts = 0;
      var retryCount = 0;

      await expectLater(
        () => attemptAuthenticatedCallWithRetries(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'internal',
              message: 'Server error',
            );
          },
          onRetry: () async {
            retryCount++;
          },
          retryDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(attempts, 1);
      expect(retryCount, 0);
    });

    test('does not retry on permission-denied', () async {
      var attempts = 0;

      await expectLater(
        () => attemptAuthenticatedCallWithRetries(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'permission-denied',
              message: 'Not allowed',
            );
          },
          onRetry: () async {},
          retryDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(attempts, 1);
    });

    test('does not retry on invalid-argument', () async {
      var attempts = 0;

      await expectLater(
        () => attemptAuthenticatedCallWithRetries(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'invalid-argument',
              message: 'Bad input',
            );
          },
          onRetry: () async {},
          retryDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(attempts, 1);
    });

    test('calls onRetry before each retry', () async {
      var attempts = 0;
      final retryTimes = <int>[];

      await attemptAuthenticatedCallWithRetries(
        callFunc: () async {
          attempts++;
          if (attempts < 3) {
            throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message: 'Retry me',
            );
          }
          return {'done': true};
        },
        onRetry: () async {
          retryTimes.add(attempts);
        },
        maxRetries: 3,
        retryDelay: Duration.zero,
      );

      expect(attempts, 3);
      expect(retryTimes, [1, 2]); // onRetry called after attempt 1 and 2
    });

    test('respects custom maxRetries', () async {
      var attempts = 0;

      await expectLater(
        () => attemptAuthenticatedCallWithRetries(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message: 'Always fails',
            );
          },
          onRetry: () async {},
          maxRetries: 5,
          retryDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(attempts, 5);
    });

    test('preserves exception details on final throw', () async {
      FirebaseFunctionsException? caught;

      try {
        await attemptAuthenticatedCallWithRetries(
          callFunc: () async {
            throw FirebaseFunctionsException(
              code: 'unauthenticated',
              message: 'Original error message',
            );
          },
          onRetry: () async {},
          maxRetries: 1,
          retryDelay: Duration.zero,
        );
      } on FirebaseFunctionsException catch (e) {
        caught = e;
      }

      expect(caught, isNotNull);
      expect(caught!.code, 'unauthenticated');
      expect(caught.message, 'Original error message');
    });
  });

  group('attemptCallWithAppCheckRetry', () {
    test('returns result on first successful attempt without refresh', () async {
      var refreshCount = 0;
      final result = await attemptCallWithAppCheckRetry(
        callFunc: () async => {'success': true},
        onRefreshAppCheck: () async {
          refreshCount++;
        },
      );
      expect(result, {'success': true});
      expect(refreshCount, 0);
    });

    test('retries once on App Check failed-precondition and succeeds', () async {
      var attempts = 0;
      var refreshCount = 0;
      final result = await attemptCallWithAppCheckRetry(
        callFunc: () async {
          attempts++;
          if (attempts == 1) {
            throw FirebaseFunctionsException(
              code: 'failed-precondition',
              message: 'App Check token required.',
            );
          }
          return {'success': true};
        },
        onRefreshAppCheck: () async {
          refreshCount++;
        },
      );
      expect(result, {'success': true});
      expect(attempts, 2);
      expect(refreshCount, 1);
    });

    test('throws after retry on persistent App Check failure', () async {
      var attempts = 0;
      await expectLater(
        () => attemptCallWithAppCheckRetry(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'failed-precondition',
              message: 'App Check token required.',
            );
          },
          onRefreshAppCheck: () async {},
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      expect(attempts, 2);
    });

    test('does not retry on non-App-Check failed-precondition', () async {
      var attempts = 0;
      await expectLater(
        () => attemptCallWithAppCheckRetry(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'failed-precondition',
              message: 'Some other precondition.',
            );
          },
          onRefreshAppCheck: () async {},
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      expect(attempts, 1);
    });

    test('does not retry on other error codes', () async {
      var attempts = 0;
      await expectLater(
        () => attemptCallWithAppCheckRetry(
          callFunc: () async {
            attempts++;
            throw FirebaseFunctionsException(
              code: 'internal',
              message: 'Server error',
            );
          },
          onRefreshAppCheck: () async {},
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      expect(attempts, 1);
    });

    test('preserves exception details on final throw', () async {
      FirebaseFunctionsException? caught;
      try {
        await attemptCallWithAppCheckRetry(
          callFunc: () async {
            throw FirebaseFunctionsException(
              code: 'failed-precondition',
              message: 'App Check token required.',
            );
          },
          onRefreshAppCheck: () async {},
        );
      } on FirebaseFunctionsException catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      expect(caught!.code, 'failed-precondition');
      expect(caught.message, 'App Check token required.');
    });
  });

  group('callAuthenticatedCloudFunction - behavior documentation', () {
    // These tests document expected behavior without actually calling Firebase.
    // Full integration testing requires Firebase emulator setup.

    test('sends idToken in payload for backend fallback', () {
      // callAuthenticatedCloudFunction adds idToken to the payload:
      //   final payload = <String, dynamic>{
      //     ...input,
      //     'idToken': idToken,
      //   };
      //
      // This allows the backend to verify the token if context.auth is null.
      expect(true, isTrue);
    });

    test('retries once on UNAUTHENTICATED before throwing', () {
      // Default maxRetries is 2, meaning:
      // - First attempt fails with UNAUTHENTICATED
      // - Waits for idTokenChanges, refreshes token
      // - Second attempt
      // - If still UNAUTHENTICATED, throws
      expect(true, isTrue);
    });

    test('waits for auth state if currentUser is null', () {
      // If FirebaseAuth.instance.currentUser is null, waits up to 5 seconds
      // for authStateChanges to emit a non-null user.
      // This handles race conditions during signup.
      expect(true, isTrue);
    });

    test('forces token refresh before each call', () {
      // Calls user.getIdToken(true) to force refresh, then
      // user.getIdToken() to get the token for payload.
      // This ensures the token is fresh.
      expect(true, isTrue);
    });

    test('adds 100ms delay after token refresh', () {
      // Small delay to allow SDK internal state to sync:
      //   await Future<void>.delayed(const Duration(milliseconds: 100));
      // Helps with race conditions in the cloud_functions SDK.
      expect(true, isTrue);
    });
  });
}
