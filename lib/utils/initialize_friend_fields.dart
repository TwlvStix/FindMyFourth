import 'package:firebase_auth/firebase_auth.dart';
import '/core/utils/app_log.dart';
import '/services/friend_service.dart';

/// One-time utility to initialize friend_requests field for current user.
/// Call this once from your app to fix existing users.
///
/// Accepts optional [friendService] and [auth] parameters for testability.
Future<void> initializeFriendFieldsForCurrentUser({
  FriendService? friendService,
  FirebaseAuth? auth,
}) async {
  final resolvedAuth = auth ?? FirebaseAuth.instance;
  final user = resolvedAuth.currentUser;
  if (user == null) {
    AppLog.d('📖 initializeFriendFields: No user logged in');
    return;
  }

  final service = friendService ?? FriendService();
  await service.initializeFriendFields(user.uid);
}
