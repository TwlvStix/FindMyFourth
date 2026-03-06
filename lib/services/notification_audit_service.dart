import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';
import '/models/notification_receipt_event.dart';

/// Service for recording notification receipt audit events.
///
/// Writes events to `users/{uid}/notification_receipts` for later analysis.
/// Features:
/// - Batched writes (flushes after 10 events or 5s)
/// - Deduplication within 60s window
/// - Safe no-op when unauthenticated
/// - Singleton pattern for global access
class NotificationAuditService {
  NotificationAuditService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Singleton instance.
  static NotificationAuditService? _instance;

  /// Get singleton instance.
  static NotificationAuditService get instance {
    _instance ??= NotificationAuditService._();
    return _instance!;
  }

  /// Reset instance (for testing).
  static void resetInstance() {
    _instance?._flushTimer?.cancel();
    _instance = null;
  }

  /// Create instance with custom dependencies (for testing).
  static void setInstance(NotificationAuditService service) {
    _instance = service;
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Pending events waiting to be flushed.
  final List<NotificationReceiptEvent> _pendingEvents = [];

  /// Timer for auto-flush after timeout.
  Timer? _flushTimer;

  /// Deduplication cache: compositeKey -> timestamp.
  final Map<String, DateTime> _dedupeCache = {};

  /// Maximum events before auto-flush.
  static const int _maxBatchSize = 10;

  /// Timeout before auto-flush.
  static const Duration _flushTimeout = Duration(seconds: 5);

  /// Deduplication window.
  static const Duration _dedupeWindow = Duration(seconds: 60);

  /// Record a notification receipt event.
  ///
  /// Events are batched and written to Firestore after [_maxBatchSize]
  /// events or [_flushTimeout], whichever comes first.
  ///
  /// Silently no-ops if user is not authenticated.
  Future<void> record(NotificationReceiptEvent event) async {
    // No-op if no authenticated user
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('🔔 NotificationAuditService: Skipping record - no auth user');
      return;
    }

    // Verify event UID matches current user (safety check)
    if (event.uid != uid) {
      AppLog.d('🔔 NotificationAuditService: UID mismatch, skipping');
      return;
    }

    // Dedupe check
    final compositeKey = event.compositeKey;
    _pruneDedupeCache();
    if (_dedupeCache.containsKey(compositeKey)) {
      AppLog.d(
        '🔔 NotificationAuditService: Deduped ${event.eventType.firestoreValue} '
        'with key $compositeKey',
      );
      return;
    }
    _dedupeCache[compositeKey] = DateTime.now();

    // Add to pending batch
    _pendingEvents.add(event);
    AppLog.d(
      '🔔 NotificationAuditService: Queued ${event.eventType.firestoreValue} '
      '(${_pendingEvents.length}/$_maxBatchSize)',
    );

    // Start flush timer if not running
    _flushTimer ??= Timer(_flushTimeout, () {
      flush();
    });

    // Flush immediately if batch is full
    if (_pendingEvents.length >= _maxBatchSize) {
      await flush();
    }
  }

  /// Force flush all pending events to Firestore.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_pendingEvents.isEmpty) {
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppLog.d('🔔 NotificationAuditService: Flush skipped - no auth user');
      _pendingEvents.clear();
      return;
    }

    final eventsToWrite = List<NotificationReceiptEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    AppLog.d(
      '🔔 NotificationAuditService: Flushing ${eventsToWrite.length} events',
    );

    try {
      final batch = _firestore.batch();
      final collectionRef =
          _firestore.collection('users').doc(uid).collection('notification_receipts');

      for (final event in eventsToWrite) {
        final docRef = collectionRef.doc();
        batch.set(docRef, event.toFirestore());
      }

      await batch.commit();
      AppLog.d(
        '✅ NotificationAuditService: Wrote ${eventsToWrite.length} receipts',
      );
    } on FirebaseException catch (e) {
      AppLog.d(
        '❌ NotificationAuditService.flush error: ${e.code} - ${e.message}',
      );
      // Re-add events to retry on next flush (with limit to prevent infinite growth)
      if (_pendingEvents.length < _maxBatchSize * 2) {
        _pendingEvents.addAll(eventsToWrite);
      }
    }
  }

  /// Fetch recent receipt events for a user.
  ///
  /// Used for debug/admin audit queries.
  Future<List<NotificationReceiptEvent>> fetchRecent(
    String uid, {
    DateTime? since,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_receipts')
        .orderBy('event_at', descending: true)
        .limit(limit);

    if (since != null) {
      query = query.where('event_at', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NotificationReceiptEvent.fromFirestore(doc, uid))
        .toList();
  }

  /// Prune stale entries from deduplication cache.
  void _pruneDedupeCache() {
    final cutoff = DateTime.now().subtract(_dedupeWindow);
    _dedupeCache.removeWhere((_, timestamp) => timestamp.isBefore(cutoff));
  }
}
