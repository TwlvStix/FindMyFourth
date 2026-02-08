import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseErrorUtils {
  static bool isPermissionDenied(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    return error.toString().contains('permission-denied');
  }
}
