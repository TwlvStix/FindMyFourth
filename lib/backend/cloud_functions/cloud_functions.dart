import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '/core/utils/app_log.dart';

/// Retries a cloud function call on UNAUTHENTICATED errors.
///
/// This helper encapsulates the retry logic for testing purposes.
/// On each retry, it calls [onRetry] to allow token refresh.
///
/// Throws the final exception if all retries fail.
@visibleForTesting
Future<Map<String, dynamic>> attemptAuthenticatedCallWithRetries({
  required Future<Map<String, dynamic>> Function() callFunc,
  required Future<void> Function() onRetry,
  int maxRetries = 2,
  Duration retryDelay = const Duration(milliseconds: 500),
}) async {
  var attempt = 0;

  while (attempt < maxRetries) {
    attempt++;

    try {
      return await callFunc();
    } on FirebaseFunctionsException catch (e) {
      final isAuthError =
          e.code == 'unauthenticated' || e.code == 'UNAUTHENTICATED';

      if (isAuthError && attempt < maxRetries) {
        AppLog.d(
          '🔄 AUTH RETRY: Call failed with ${e.code} '
          '(attempt $attempt/$maxRetries), retrying...',
        );

        await onRetry();
        await Future<void>.delayed(retryDelay);
        continue;
      }

      rethrow;
    }
  }

  // Should not reach here
  throw FirebaseFunctionsException(
    code: 'internal',
    message: 'Max retries exceeded',
  );
}

/// Makes an authenticated cloud function call with idToken in payload and retry logic.
///
/// Used for post-signup flows where context.auth may not be populated due to SDK
/// race conditions. Sends explicit idToken that the backend can verify as fallback.
///
/// Throws [FirebaseFunctionsException] on final failure (after retry).
Future<Map<String, dynamic>> callAuthenticatedCloudFunction(
  String callName,
  Map<String, dynamic> input, {
  int maxRetries = 2,
  Duration retryDelay = const Duration(milliseconds: 500),
}) async {
  return attemptAuthenticatedCallWithRetries(
    maxRetries: maxRetries,
    retryDelay: retryDelay,
    onRetry: () async {
      try {
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {
        // Best-effort only. Retry will still attempt token refresh.
      }
      try {
        await FirebaseAuth.instance
            .idTokenChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Timeout waiting for token event; proceed with retry.
      }
    },
    callFunc: () async {
      // Ensure we have a current user.
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Timeout waiting for auth state.
        }
      }

      if (user == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'No authenticated user',
        );
      }

      // Use the forced-refresh token directly to avoid sending stale/null token.
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Unable to acquire ID token',
        );
      }

      final payload = <String, dynamic>{
        ...input,
        'idToken': idToken,
      };

      try {
        final response = await FirebaseFunctions.instanceFor(region: 'us-west2')
            .httpsCallable(callName, options: HttpsCallableOptions())
            .call(payload);

        return response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : {};
      } on FirebaseFunctionsException catch (e) {
        final isAuthError =
            e.code == 'unauthenticated' || e.code == 'UNAUTHENTICATED';
        if (isAuthError) {
          AppLog.d(
            '❌ Authenticated cloud call auth rejection\n'
            'Call: $callName\n'
            'Project: ${Firebase.app().options.projectId}\n'
            'Uid: ${user.uid}\n'
            'Token length: ${idToken.length}\n'
            'Code: ${e.code}\n'
            'Message: ${e.message}',
          );
        }
        rethrow;
      }
    },
  );
}

Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    final response = await FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable(callName, options: HttpsCallableOptions())
        .call(input);
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  } on FirebaseFunctionsException catch (e) {
    AppLog.d(
      'Cloud call error!\n'
      'Call: $callName\n'
      'Code: ${e.code}\n'
      'Details: ${e.details}\n'
      'Message: ${e.message}',
    );
  } catch (e) {
    AppLog.d('Cloud call error:$callName $e');
  }
  return {};
}

Future<bool> deleteAccount() async {
  try {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    if (user == null) {
      AppLog.d('deleteAccount error: no current user');
      return false;
    }
    await user.getIdToken(true);
    final token = await user.getIdToken();
    AppLog.d('deleteAccount auth uid: ${user.uid}');
    AppLog.d('deleteAccount auth token length: ${token?.length ?? 0}');
    final response = await FirebaseFunctions.instanceFor(region: 'us-west2')
        .httpsCallable('deleteAccount', options: HttpsCallableOptions())
        .call({'idToken': token});
    final data =
        response.data is Map ? Map<String, dynamic>.from(response.data as Map) : {};
    AppLog.d('deleteAccount response: $data');
    return data['ok'] == true;
  } on FirebaseFunctionsException catch (e) {
    AppLog.d(
      'deleteAccount error!\n'
      'Code: ${e.code}\n'
      'Details: ${e.details}\n'
      'Message: ${e.message}',
    );
    return false;
  } catch (e) {
    AppLog.d('deleteAccount error: $e');
    return false;
  }
}
