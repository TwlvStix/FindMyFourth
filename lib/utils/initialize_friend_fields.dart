import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/utils/app_log.dart';

/// One-time utility to initialize friend_requests field for current user
/// Call this once from your app to fix existing users
Future<void> initializeFriendFieldsForCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    AppLog.d('No user logged in');
    return;
  }

  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      AppLog.d('User document does not exist');
      return;
    }

    final data = snapshot.data();
    final updates = <String, dynamic>{};

    // Initialize friend_requests if it doesn't exist
    if (data != null && !data.containsKey('friend_requests')) {
      updates['friend_requests'] = [];
      AppLog.d('Will initialize friend_requests');
    }

    // Initialize friends if it doesn't exist
    if (data != null && !data.containsKey('friends')) {
      updates['friends'] = [];
      AppLog.d('Will initialize friends');
    }

    if (updates.isNotEmpty) {
      await userRef.update(updates);
      AppLog.d('✓ Initialized fields: ${updates.keys.join(", ")}');
    } else {
      AppLog.d('All fields already initialized');
    }
  } catch (e) {
    AppLog.d('Error initializing fields: $e');
  }
}
