import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/utils/firebase_error_utils.dart';

void main() {
  test('isPermissionDenied returns true for FirebaseException code', () {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    );

    expect(FirebaseErrorUtils.isPermissionDenied(error), isTrue);
  });

  test('isPermissionDenied returns true for string fallback', () {
    final error = Exception('permission-denied: Missing permissions');

    expect(FirebaseErrorUtils.isPermissionDenied(error), isTrue);
  });

  test('isPermissionDenied returns false for other errors', () {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'Service unavailable.',
    );

    expect(FirebaseErrorUtils.isPermissionDenied(error), isFalse);
  });
}
