import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/notification_receipt_event.dart';
import 'package:find_my_fourth/services/notification_audit_service.dart';

void main() {
  group('NotificationAuditService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;

    /// Creates a test instance with injected fakes and sets it as the
    /// singleton so that [NotificationAuditService.instance] returns it.
    NotificationAuditService createTestService() {
      // Use the testing constructor path: resetInstance then setInstance
      NotificationAuditService.resetInstance();
      final service = NotificationAuditService.testInstance(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
      NotificationAuditService.setInstance(service);
      return service;
    }

    /// Builds a receipt event with the given parameters. Uses direct
    /// constructor to avoid platform-dependent factory fields (like
    /// _currentPlatform which calls dart:io in tests).
    NotificationReceiptEvent buildEvent({
      NotificationReceiptEventType eventType =
          NotificationReceiptEventType.fgReceived,
      String uid = 'test-user',
      String? messageId,
      String? notificationType,
      String? dedupeKey,
    }) {
      return NotificationReceiptEvent(
        eventType: eventType,
        uid: uid,
        eventAt: DateTime.now(),
        platform: 'iOS',
        appState: NotificationAppState.foreground,
        messageId: messageId,
        notificationType: notificationType,
        dedupeKey: dedupeKey,
        appVersion: '2.1.0',
        buildNumber: '1',
      );
    }

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'test-user'),
      );
    });

    tearDown(() {
      NotificationAuditService.resetInstance();
    });

    group('record()', () {
      test('adds event to pending batch', () async {
        final service = createTestService();
        final event = buildEvent(messageId: 'msg-1');

        await service.record(event);

        // Event is pending (not flushed yet since batch size < 10)
        // Verify by flushing and checking Firestore
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs.length, 1);
        expect(docs.docs.first.data()['message_id'], 'msg-1');
      });

      test('no-ops when no authenticated user', () async {
        mockAuth = MockFirebaseAuth(signedIn: false);
        final service = createTestService();
        final event = buildEvent(messageId: 'msg-no-auth');

        await service.record(event);
        await service.flush();

        // Nothing should be written
        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs, isEmpty);
      });

      test('rejects events with mismatched UID', () async {
        final service = createTestService();
        // Event has uid 'other-user' but auth user is 'test-user'
        final event = buildEvent(uid: 'other-user', messageId: 'msg-mismatch');

        await service.record(event);
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs, isEmpty);
      });

      test('deduplicates events with same compositeKey within window',
          () async {
        final service = createTestService();

        // Two events with the same messageId and eventType
        final event1 = buildEvent(messageId: 'msg-dup');
        final event2 = buildEvent(messageId: 'msg-dup');

        await service.record(event1);
        await service.record(event2);
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        // Only one event should be written (second was deduped)
        expect(docs.docs.length, 1);
      });

      test('allows events with different compositeKeys', () async {
        final service = createTestService();

        final event1 = buildEvent(messageId: 'msg-a');
        final event2 = buildEvent(messageId: 'msg-b');

        await service.record(event1);
        await service.record(event2);
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs.length, 2);
      });

      test('allows same messageId with different event types', () async {
        final service = createTestService();

        final received = buildEvent(
          eventType: NotificationReceiptEventType.fgReceived,
          messageId: 'msg-same',
        );
        final shown = buildEvent(
          eventType: NotificationReceiptEventType.fgLocalShown,
          messageId: 'msg-same',
        );

        await service.record(received);
        await service.record(shown);
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        // Different event types = different composite keys
        expect(docs.docs.length, 2);
      });
    });

    group('flush()', () {
      test('writes batch to Firestore via batch commit', () async {
        final service = createTestService();

        await service.record(buildEvent(messageId: 'msg-f1'));
        await service.record(buildEvent(messageId: 'msg-f2'));
        await service.record(buildEvent(messageId: 'msg-f3'));

        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs.length, 3);
      });

      test('no-ops when pending batch is empty', () async {
        final service = createTestService();

        // Should not throw or write anything
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs, isEmpty);
      });

      test('clears pending events when no auth user at flush time', () async {
        final service = createTestService();

        // Record while signed in
        await service.record(buildEvent(messageId: 'msg-cleared'));

        // Sign out before flush
        await mockAuth.signOut();
        await service.flush();

        // Events should be cleared (not re-queued)
        // Sign back in and flush again - nothing should appear
        // (The mock auth won't have a user after signOut, so nothing is written)
        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs, isEmpty);
      });

      test('writes correct Firestore data structure', () async {
        final service = createTestService();

        await service.record(buildEvent(
          messageId: 'msg-struct',
          notificationType: 'game_created',
        ));
        await service.flush();

        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs.length, 1);
        final data = docs.docs.first.data();

        expect(data['event_type'], 'fg_received');
        expect(data['platform'], 'iOS');
        expect(data['app_state'], 'foreground');
        expect(data['message_id'], 'msg-struct');
        expect(data['notification_type'], 'game_created');
        expect(data.containsKey('event_at'), isTrue);
      });
    });

    group('auto-flush at batch size limit', () {
      test('flushes automatically when 10 events are queued', () async {
        final service = createTestService();

        // Record 10 events (the max batch size)
        for (int i = 0; i < 10; i++) {
          await service.record(buildEvent(messageId: 'msg-batch-$i'));
        }

        // Should have auto-flushed at 10
        final docs = await fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts')
            .get();

        expect(docs.docs.length, 10);
      });
    });

    group('fetchRecent()', () {
      test('returns events ordered by event_at descending', () async {
        final service = createTestService();

        // Seed documents directly into Firestore
        final collection = fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts');

        await collection.doc('old').set({
          'event_type': 'fg_received',
          'event_at': Timestamp.fromDate(DateTime(2026, 3, 1)),
          'platform': 'iOS',
          'app_state': 'foreground',
          'message_id': 'old-msg',
        });
        await collection.doc('new').set({
          'event_type': 'bg_opened',
          'event_at': Timestamp.fromDate(DateTime(2026, 3, 8)),
          'platform': 'Android',
          'app_state': 'background_open',
          'message_id': 'new-msg',
        });

        final results = await service.fetchRecent('test-user');

        expect(results.length, 2);
        // Most recent first
        expect(results[0].messageId, 'new-msg');
        expect(results[1].messageId, 'old-msg');
      });

      test('respects limit parameter', () async {
        final service = createTestService();

        final collection = fakeFirestore
            .collection('users')
            .doc('test-user')
            .collection('notification_receipts');

        for (int i = 0; i < 5; i++) {
          await collection.doc('doc-$i').set({
            'event_type': 'fg_received',
            'event_at': Timestamp.fromDate(
                DateTime(2026, 3, 1).add(Duration(hours: i))),
            'platform': 'iOS',
            'app_state': 'foreground',
            'message_id': 'msg-$i',
          });
        }

        final results = await service.fetchRecent('test-user', limit: 3);

        expect(results.length, 3);
      });

      test('returns empty list when no receipts exist', () async {
        final service = createTestService();

        final results = await service.fetchRecent('test-user');

        expect(results, isEmpty);
      });
    });

    group('singleton management', () {
      test('resetInstance cancels timers and clears instance', () {
        createTestService();

        // Should not throw
        NotificationAuditService.resetInstance();

        // A new call to instance creates a fresh default instance
        // (We can't easily verify this without Firebase initialized,
        // but the reset itself should complete without error)
      });

      test('setInstance replaces singleton', () {
        final service1 = createTestService();
        expect(NotificationAuditService.instance, same(service1));

        final service2 = NotificationAuditService.testInstance(
          firestore: fakeFirestore,
          auth: mockAuth,
        );
        NotificationAuditService.setInstance(service2);
        expect(NotificationAuditService.instance, same(service2));
      });
    });
  });
}
