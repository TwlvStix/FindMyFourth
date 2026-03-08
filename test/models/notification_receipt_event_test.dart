import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/notification_receipt_event.dart';

void main() {
  group('NotificationReceiptEventType', () {
    test('firestoreValue returns correct snake_case strings', () {
      expect(
        NotificationReceiptEventType.fgReceived.firestoreValue,
        'fg_received',
      );
      expect(
        NotificationReceiptEventType.fgLocalShown.firestoreValue,
        'fg_local_shown',
      );
      expect(
        NotificationReceiptEventType.fgLocalTap.firestoreValue,
        'fg_local_tap',
      );
      expect(
        NotificationReceiptEventType.bgOpened.firestoreValue,
        'bg_opened',
      );
      expect(
        NotificationReceiptEventType.coldOpened.firestoreValue,
        'cold_opened',
      );
    });

    test('fromFirestore round-trips correctly for all 5 types', () {
      for (final type in NotificationReceiptEventType.values) {
        final firestoreValue = type.firestoreValue;
        final roundTripped =
            NotificationReceiptEventTypeX.fromFirestore(firestoreValue);
        expect(roundTripped, type,
            reason: '$type should round-trip through firestoreValue');
      }
    });

    test('fromFirestore defaults to fgReceived for unknown value', () {
      final result =
          NotificationReceiptEventTypeX.fromFirestore('unknown_type');
      expect(result, NotificationReceiptEventType.fgReceived);
    });
  });

  group('NotificationAppState', () {
    test('firestoreValue returns correct snake_case strings', () {
      expect(
        NotificationAppState.foreground.firestoreValue,
        'foreground',
      );
      expect(
        NotificationAppState.backgroundOpen.firestoreValue,
        'background_open',
      );
      expect(
        NotificationAppState.terminatedOpen.firestoreValue,
        'terminated_open',
      );
    });

    test('fromFirestore round-trips correctly for all 3 states', () {
      for (final state in NotificationAppState.values) {
        final firestoreValue = state.firestoreValue;
        final roundTripped =
            NotificationAppStateX.fromFirestore(firestoreValue);
        expect(roundTripped, state,
            reason: '$state should round-trip through firestoreValue');
      }
    });

    test('fromFirestore defaults to foreground for unknown value', () {
      final result = NotificationAppStateX.fromFirestore('unknown_state');
      expect(result, NotificationAppState.foreground);
    });
  });

  group('NotificationReceiptEvent factories', () {
    test('foregroundReceived sets correct eventType and appState', () {
      final event = NotificationReceiptEvent.foregroundReceived(
        uid: 'user-1',
        messageId: 'msg-1',
        notificationType: 'game_created',
      );

      expect(event.eventType, NotificationReceiptEventType.fgReceived);
      expect(event.appState, NotificationAppState.foreground);
      expect(event.uid, 'user-1');
      expect(event.messageId, 'msg-1');
      expect(event.notificationType, 'game_created');
    });

    test('foregroundLocalShown sets correct eventType and appState', () {
      final event = NotificationReceiptEvent.foregroundLocalShown(
        uid: 'user-2',
        messageId: 'msg-2',
        notificationType: 'chat_message',
      );

      expect(event.eventType, NotificationReceiptEventType.fgLocalShown);
      expect(event.appState, NotificationAppState.foreground);
      expect(event.uid, 'user-2');
    });

    test('foregroundLocalTap sets correct eventType and appState', () {
      final event = NotificationReceiptEvent.foregroundLocalTap(
        uid: 'user-3',
        dedupeKey: 'dedupe-1',
      );

      expect(event.eventType, NotificationReceiptEventType.fgLocalTap);
      expect(event.appState, NotificationAppState.foreground);
      expect(event.uid, 'user-3');
      expect(event.dedupeKey, 'dedupe-1');
    });

    test('backgroundOpened sets correct eventType and appState', () {
      final event = NotificationReceiptEvent.backgroundOpened(
        uid: 'user-4',
        messageId: 'msg-4',
        notificationType: 'peer_rating',
        payloadSummary: {'has_type': true},
      );

      expect(event.eventType, NotificationReceiptEventType.bgOpened);
      expect(event.appState, NotificationAppState.backgroundOpen);
      expect(event.uid, 'user-4');
      expect(event.payloadSummary, {'has_type': true});
    });

    test('coldOpened sets correct eventType and appState', () {
      final event = NotificationReceiptEvent.coldOpened(
        uid: 'user-5',
        messageId: 'msg-5',
        notificationType: 'host_checkin_due',
        payloadSummary: {'data_keys': ['type']},
      );

      expect(event.eventType, NotificationReceiptEventType.coldOpened);
      expect(event.appState, NotificationAppState.terminatedOpen);
      expect(event.uid, 'user-5');
    });
  });

  group('toFirestore()', () {
    test('produces correct map with all fields', () {
      final eventAt = DateTime(2026, 3, 8, 10, 30);
      final event = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.fgReceived,
        uid: 'user-1',
        eventAt: eventAt,
        platform: 'iOS',
        appState: NotificationAppState.foreground,
        messageId: 'msg-123',
        notificationType: 'game_created',
        dedupeKey: 'dedupe-abc',
        appVersion: '2.1.0',
        buildNumber: '42',
        payloadSummary: {'data_keys': ['type', 'gameId']},
      );

      final map = event.toFirestore();

      expect(map['event_type'], 'fg_received');
      expect(map['event_at'], isA<Timestamp>());
      expect(
        (map['event_at'] as Timestamp).toDate(),
        eventAt,
      );
      expect(map['platform'], 'iOS');
      expect(map['app_state'], 'foreground');
      expect(map['message_id'], 'msg-123');
      expect(map['notification_type'], 'game_created');
      expect(map['dedupe_key'], 'dedupe-abc');
      expect(map['app_version'], '2.1.0');
      expect(map['build_number'], '42');
      expect(map['payload_summary'], {'data_keys': ['type', 'gameId']});
    });

    test('omits null optional fields', () {
      final event = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.bgOpened,
        uid: 'user-1',
        eventAt: DateTime(2026, 3, 8),
        platform: 'Android',
        appState: NotificationAppState.backgroundOpen,
      );

      final map = event.toFirestore();

      expect(map.containsKey('message_id'), isFalse);
      expect(map.containsKey('notification_type'), isFalse);
      expect(map.containsKey('dedupe_key'), isFalse);
      expect(map.containsKey('app_version'), isFalse);
      expect(map.containsKey('build_number'), isFalse);
      expect(map.containsKey('payload_summary'), isFalse);

      // Required fields are always present
      expect(map.containsKey('event_type'), isTrue);
      expect(map.containsKey('event_at'), isTrue);
      expect(map.containsKey('platform'), isTrue);
      expect(map.containsKey('app_state'), isTrue);
    });
  });

  group('fromFirestore()', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('parses all fields from Firestore document', () async {
      final eventAt = DateTime(2026, 3, 8, 14, 0);
      await fakeFirestore.collection('test_receipts').doc('receipt-1').set({
        'event_type': 'bg_opened',
        'event_at': Timestamp.fromDate(eventAt),
        'platform': 'iOS',
        'app_state': 'background_open',
        'message_id': 'msg-abc',
        'notification_type': 'chat_message',
        'dedupe_key': 'dk-123',
        'app_version': '2.0.0',
        'build_number': '10',
        'payload_summary': {'has_type': true, 'has_game_id': false},
      });

      final doc =
          await fakeFirestore.collection('test_receipts').doc('receipt-1').get();
      final event = NotificationReceiptEvent.fromFirestore(doc, 'user-x');

      expect(event.eventType, NotificationReceiptEventType.bgOpened);
      expect(event.uid, 'user-x');
      expect(event.eventAt, eventAt);
      expect(event.platform, 'iOS');
      expect(event.appState, NotificationAppState.backgroundOpen);
      expect(event.messageId, 'msg-abc');
      expect(event.notificationType, 'chat_message');
      expect(event.dedupeKey, 'dk-123');
      expect(event.appVersion, '2.0.0');
      expect(event.buildNumber, '10');
      expect(event.payloadSummary, {'has_type': true, 'has_game_id': false});
    });

    test('uses defaults for missing or null fields', () async {
      // Minimal document with no optional fields
      await fakeFirestore.collection('test_receipts').doc('receipt-2').set({});

      final doc =
          await fakeFirestore.collection('test_receipts').doc('receipt-2').get();
      final event = NotificationReceiptEvent.fromFirestore(doc, 'user-y');

      expect(event.eventType, NotificationReceiptEventType.fgReceived);
      expect(event.uid, 'user-y');
      expect(event.platform, 'unknown');
      expect(event.appState, NotificationAppState.foreground);
      expect(event.messageId, isNull);
      expect(event.notificationType, isNull);
      expect(event.dedupeKey, isNull);
      expect(event.appVersion, isNull);
      expect(event.buildNumber, isNull);
      expect(event.payloadSummary, isNull);
    });

    test('round-trips through toFirestore/fromFirestore', () async {
      final original = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.coldOpened,
        uid: 'user-rt',
        eventAt: DateTime(2026, 6, 15, 9, 45),
        platform: 'Android',
        appState: NotificationAppState.terminatedOpen,
        messageId: 'msg-rt',
        notificationType: 'host_checkin_due',
        dedupeKey: 'dk-rt',
        appVersion: '3.0.0',
        buildNumber: '99',
        payloadSummary: {'data_keys': ['type', 'gameRef']},
      );

      final firestoreData = original.toFirestore();
      await fakeFirestore
          .collection('test_receipts')
          .doc('round-trip')
          .set(firestoreData);

      final doc = await fakeFirestore
          .collection('test_receipts')
          .doc('round-trip')
          .get();
      final restored =
          NotificationReceiptEvent.fromFirestore(doc, 'user-rt');

      expect(restored.eventType, original.eventType);
      expect(restored.eventAt, original.eventAt);
      expect(restored.platform, original.platform);
      expect(restored.appState, original.appState);
      expect(restored.messageId, original.messageId);
      expect(restored.notificationType, original.notificationType);
      expect(restored.dedupeKey, original.dedupeKey);
      expect(restored.appVersion, original.appVersion);
      expect(restored.buildNumber, original.buildNumber);
      expect(restored.payloadSummary, original.payloadSummary);
    });
  });

  group('compositeKey', () {
    test('uses messageId when present', () {
      final event = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.fgReceived,
        uid: 'u1',
        eventAt: DateTime.now(),
        platform: 'iOS',
        appState: NotificationAppState.foreground,
        messageId: 'msg-100',
        dedupeKey: 'dk-fallback',
      );

      expect(event.compositeKey, 'fg_received_msg-100');
    });

    test('falls back to dedupeKey when messageId is null', () {
      final event = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.bgOpened,
        uid: 'u1',
        eventAt: DateTime.now(),
        platform: 'Android',
        appState: NotificationAppState.backgroundOpen,
        dedupeKey: 'dk-200',
      );

      expect(event.compositeKey, 'bg_opened_dk-200');
    });

    test('falls back to "no_id" when both messageId and dedupeKey are null',
        () {
      final event = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.coldOpened,
        uid: 'u1',
        eventAt: DateTime.now(),
        platform: 'iOS',
        appState: NotificationAppState.terminatedOpen,
      );

      expect(event.compositeKey, 'cold_opened_no_id');
    });

    test('includes event type in composite key', () {
      final fgEvent = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.fgReceived,
        uid: 'u1',
        eventAt: DateTime.now(),
        platform: 'iOS',
        appState: NotificationAppState.foreground,
        messageId: 'same-msg',
      );

      final bgEvent = NotificationReceiptEvent(
        eventType: NotificationReceiptEventType.bgOpened,
        uid: 'u1',
        eventAt: DateTime.now(),
        platform: 'iOS',
        appState: NotificationAppState.backgroundOpen,
        messageId: 'same-msg',
      );

      // Same messageId but different event types produce different keys
      expect(fgEvent.compositeKey, isNot(bgEvent.compositeKey));
      expect(fgEvent.compositeKey, 'fg_received_same-msg');
      expect(bgEvent.compositeKey, 'bg_opened_same-msg');
    });
  });

  group('summarizePayload()', () {
    test('returns empty map for null input', () {
      final result = summarizePayload(null);
      expect(result, isEmpty);
    });

    test('returns empty map for empty input', () {
      final result = summarizePayload({});
      expect(result, {
        'data_keys': <String>[],
        'has_type': false,
        'has_game_id': false,
        'has_chat_id': false,
      });
    });

    test('detects type key', () {
      final result = summarizePayload({'type': 'game_created'});
      expect(result['has_type'], true);
    });

    test('detects camelCase gameId key', () {
      final result = summarizePayload({
        'type': 'game_created',
        'gameId': 'g123',
      });
      expect(result['has_game_id'], true);
    });

    test('detects snake_case game_id key', () {
      final result = summarizePayload({
        'type': 'game_alert',
        'game_id': 'g456',
      });
      expect(result['has_game_id'], true);
    });

    test('detects camelCase chatId key', () {
      final result = summarizePayload({
        'type': 'chat_message',
        'chatId': 'c123',
      });
      expect(result['has_chat_id'], true);
    });

    test('detects snake_case chat_id key', () {
      final result = summarizePayload({
        'type': 'chat_message',
        'chat_id': 'c456',
      });
      expect(result['has_chat_id'], true);
    });

    test('detects threadId key as chat_id', () {
      final result = summarizePayload({
        'type': 'chat_message',
        'threadId': 'thread-1',
      });
      expect(result['has_chat_id'], true);
    });

    test('includes all data keys', () {
      final result = summarizePayload({
        'type': 'game_created',
        'gameId': 'g123',
        'custom_field': 'value',
      });
      expect(result['data_keys'], containsAll(['type', 'gameId', 'custom_field']));
    });
  });
}
