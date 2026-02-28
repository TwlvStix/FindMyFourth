import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/alert_subscription.dart';
import '/core/utils/app_log.dart';

/// Service for managing alert subscriptions in Firestore
///
/// Collection: alertSubs
/// Document ID: userId (one subscription per user)
class AlertSubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'alertSubs';

  /// Get reference to alertSubs collection
  static CollectionReference get _alertSubsCollection =>
      _firestore.collection(_collection);

  /// Get reference to a specific user's alert subscription document
  static DocumentReference getDocRef(String userId) {
    return _alertSubsCollection.doc(userId);
  }

  /// Load user's alert subscription
  /// Returns null if no subscription exists yet
  static Future<AlertSubscription?> loadSubscription(String userId) async {
    try {
      final doc = await getDocRef(userId).get();

      if (!doc.exists) {
        return null;
      }

      return AlertSubscription.fromFirestore(doc);
    } on FirebaseException catch (e) {
      AppLog.d('❌ AlertSubscriptionService.loadSubscription error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Save or update user's alert subscription
  static Future<void> saveSubscription(AlertSubscription subscription) async {
    try {
      final doc = getDocRef(subscription.userId);
      final exists = (await doc.get()).exists;

      await doc.set(
        subscription.toFirestore(isUpdate: exists),
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      AppLog.d('❌ AlertSubscriptionService.saveSubscription error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Delete user's alert subscription
  static Future<void> deleteSubscription(String userId) async {
    try {
      await getDocRef(userId).delete();
    } on FirebaseException catch (e) {
      AppLog.d('❌ AlertSubscriptionService.deleteSubscription error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Stream user's alert subscription
  /// Returns a stream that emits the subscription whenever it changes
  static Stream<AlertSubscription?> streamSubscription(String userId) {
    return getDocRef(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return AlertSubscription.fromFirestore(doc);
    });
  }

  /// Reset subscription to defaults (disabled, all filters empty)
  static Future<void> resetSubscription(String userId) async {
    try {
      final defaultSub = AlertSubscription.defaults(userId);
      await saveSubscription(defaultSub);
    } on FirebaseException catch (e) {
      AppLog.d('❌ AlertSubscriptionService.resetSubscription error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Enable or disable subscription without changing filters
  static Future<void> setEnabled(String userId, bool enabled) async {
    try {
      await getDocRef(userId).set(
        {
          'enabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      AppLog.d('❌ AlertSubscriptionService.setEnabled error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get all enabled subscriptions (for admin/testing purposes)
  /// NOTE: This may be expensive with many users
  static Future<List<AlertSubscription>> getAllEnabledSubscriptions() async {
    try {
      final snapshot = await _alertSubsCollection
          .where('enabled', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertSubscription.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLog.d('❌ AlertSubscriptionService.getAllEnabledSubscriptions error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Batch update: migrate old notification preferences to new alert subscriptions
  /// This is a one-time migration helper
  static Future<void> migrateFromOldPreferences({
    required String userId,
    required bool enabled,
    required List<String> oldStyles,
  }) async {
    // Map old style tokens to new categories
    // Old: money, vegas, competitive, for_fun, friends, member_discount
    // New: separate categories for vibe, stakes, etc.

    final gameVibes = <String>[];
    final stakes = <String>[];

    // Map old styles to new categories
    for (final style in oldStyles) {
      switch (style.toLowerCase()) {
        case 'competitive':
          gameVibes.add('Competitive');
          break;
        case 'for_fun':
          gameVibes.add('Casual');
          break;
        case 'money':
        case 'vegas':
          stakes.add('High Stakes');
          break;
        case 'friends':
          // Friends was a visibility setting, not a notification filter
          // We could map this to something or ignore it
          break;
        case 'member_discount':
          // Member discount was a course perk, not a core category
          // We could create a special filter for this or ignore it
          break;
      }
    }

    // Create new subscription with migrated data
    final subscription = AlertSubscription(
      userId: userId,
      enabled: enabled,
      gameVibes: gameVibes,
      stakes: stakes,
      formats: const [], // No mapping from old system
      handicapUses: const [], // No mapping from old system
      courses: const [], // No mapping from old system
      special: AlertSpecialOptions.defaults(),
    );

    await saveSubscription(subscription);
  }
}
