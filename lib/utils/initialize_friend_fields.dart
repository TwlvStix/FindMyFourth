import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time utility to initialize friend_requests field for current user
/// Call this once from your app to fix existing users
Future<void> initializeFriendFieldsForCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user logged in');
    return;
  }

  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      print('User document does not exist');
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    final updates = <String, dynamic>{};

    // Initialize friend_requests if it doesn't exist
    if (data != null && !data.containsKey('friend_requests')) {
      updates['friend_requests'] = [];
      print('Will initialize friend_requests');
    }

    // Initialize friends if it doesn't exist
    if (data != null && !data.containsKey('friends')) {
      updates['friends'] = [];
      print('Will initialize friends');
    }

    if (updates.isNotEmpty) {
      await userRef.update(updates);
      print('✓ Initialized fields: ${updates.keys.join(", ")}');
    } else {
      print('All fields already initialized');
    }
  } catch (e) {
    print('Error initializing fields: $e');
  }
}
