import '/backend/backend.dart';
import '/core/utils/app_log.dart';

/// ProfileService provides stateless, centralized access to user profile data in Firestore
///
/// This service follows the established pattern from ChatService and GameService:
/// - Static methods only (no instance state)
/// - Pure functions without UI dependencies
/// - Firestore error handling with try-catch, AppLog.d(), and rethrow
/// - No business logic (vibe matching, filtering) - that stays in providers
///
/// Usage:
/// - Create instance: final service = ProfileService();
/// - Or inject for testing: ProfileService(firestore: mockFirestore)
/// - Wrap with ProfileProvider for caching and state management
class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get a user profile by ID (one-time fetch)
  ///
  /// Returns null if user doesn't exist
  Future<UsersRecord?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      return doc.exists ? UsersRecord.fromSnapshot(doc) : null;
    } on FirebaseException catch (e) {
      AppLog.d('ProfileService.getUserProfile error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Watch a user profile by ID for reactive updates
  ///
  /// Returns `Stream<UsersRecord?>` that emits null if user doesn't exist
  Stream<UsersRecord?> watchUserProfile(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists ? UsersRecord.fromSnapshot(doc) : null);
    } on FirebaseException catch (e) {
      AppLog.d(
          'ProfileService.watchUserProfile error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update user profile (partial update)
  ///
  /// Automatically adds updated_at timestamp to updates
  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);
    } on FirebaseException catch (e) {
      AppLog.d('ProfileService.updateProfile error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Update vibe profile data (partial update of vibe_profile map)
  ///
  /// Updates nested fields in vibe_profile map
  /// Example: {'vibe_profile.music': 5, 'vibe_profile.drinks': 3}
  Future<void> updateVibeProfile(
      String userId, Map<String, dynamic> vibeData) async {
    try {
      // Prefix all keys with 'vibe_profile.' for nested update
      final updateData = <String, dynamic>{};
      vibeData.forEach((key, value) {
        updateData['vibe_profile.$key'] = value;
      });
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);
    } on FirebaseException catch (e) {
      AppLog.d(
          'ProfileService.updateVibeProfile error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Mark onboarding as completed for a user
  ///
  /// Sets onboarding_completed = true on the user document.
  Future<void> markOnboardingCompleted(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        <String, dynamic>{'onboarding_completed': true},
        SetOptions(merge: true),
      );
      AppLog.d('✅ ProfileService.markOnboardingCompleted for $userId');
    } on FirebaseException catch (e) {
      AppLog.d(
          'ProfileService.markOnboardingCompleted error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get user statistics (games played, friends count, etc.)
  ///
  /// Returns aggregated stats from user document and related collections
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get user document
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {
          'gamesPlayed': 0,
          'friendsCount': 0,
          'friendRequestsCount': 0,
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Count friends (array length)
      final friends = (userData['friends'] as List<dynamic>?)?.length ?? 0;

      // Count friend requests (array length)
      final friendRequests =
          (userData['friend_requests'] as List<dynamic>?)?.length ?? 0;

      // Count games played (query games where user is in joined_players)
      final userRef =
          _firestore.collection('users').doc(userId);
      final gamesSnapshot = await _firestore
          .collection('games')
          .where('joined_players', arrayContains: userRef)
          .where('isCancelled', isEqualTo: false)
          .get();

      return {
        'gamesPlayed': gamesSnapshot.docs.length,
        'friendsCount': friends,
        'friendRequestsCount': friendRequests,
        'handicap': userData['handicap'] ?? 0,
        'homeCourse': userData['home_course'] ?? '',
      };
    } on FirebaseException catch (e) {
      AppLog.d('ProfileService.getUserStats error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Query users by name (search)
  ///
  /// Returns `Stream<List<UsersRecord>>` matching the search query
  /// Uses search_tokens array-contains for substring matching
  Stream<List<UsersRecord>> searchUsersByName(String searchQuery) {
    try {
      if (searchQuery.isEmpty) {
        return Stream.value([]);
      }

      final searchLower = searchQuery.toLowerCase();

      return _firestore
          .collection('users')
          .where('search_tokens', arrayContains: searchLower)
          .orderBy('display_name_lowercase')
          .limit(20)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UsersRecord.fromSnapshot(doc))
              .toList());
    } on FirebaseException catch (e) {
      AppLog.d(
          'ProfileService.searchUsersByName error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Batch get multiple user profiles by IDs
  ///
  /// Returns `Map<String, UsersRecord>` where key is userId
  /// Efficiently fetches multiple users in a single read batch
  Future<Map<String, UsersRecord>> batchGetUserProfiles(
      List<String> userIds) async {
    try {
      if (userIds.isEmpty) {
        return {};
      }

      // Firestore 'in' query limit is 10 items, so batch in chunks
      final result = <String, UsersRecord>{};

      for (var i = 0; i < userIds.length; i += 10) {
        final end = (i + 10) > userIds.length ? userIds.length : i + 10;
        final batchIds = userIds.sublist(i, end);

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in snapshot.docs) {
          result[doc.id] = UsersRecord.fromSnapshot(doc);
        }
      }

      return result;
    } on FirebaseException catch (e) {
      AppLog.d(
          'ProfileService.batchGetUserProfiles error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
