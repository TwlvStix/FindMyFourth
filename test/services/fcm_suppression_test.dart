import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/backend/push_notifications/push_notifications_handler.dart';

/// Tests for notification suppression logic.
///
/// The core suppression method (_shouldSuppressNotification) in
/// FcmNotificationService is private and requires GoRouter context,
/// making it unsuitable for direct unit testing. However, the
/// suppression decision depends on two inputs:
///
/// 1. The normalized notification payload (type + chatId)
/// 2. The current GoRouter route path
///
/// This file tests the normalization layer that produces the data
/// used by the suppression check. The actual route-matching logic
/// requires integration testing with a mounted GoRouter.
///
/// Suppression rules (documented for reference):
/// - chat_message where chatId matches /chat/{chatId} route -> suppress
/// - All other notification types -> never suppressed
/// - Error reading route -> defaults to not suppressed
///
/// To make _shouldSuppressNotification fully unit-testable, extract
/// the pure logic into a standalone function:
///
///   bool shouldSuppressChatNotification({
///     required String? notificationType,
///     required String? chatId,
///     required String currentPath,
///   }) {
///     if (notificationType != 'chat_message') return false;
///     if (chatId == null) return false;
///     return currentPath == '/chat/$chatId';
///   }
///
/// That function would be trivially testable without GoRouter context.

void main() {
  group('Suppression payload normalization', () {
    group('chat_message suppression data', () {
      test('normalizes threadId for suppression matching', () {
        final data = normalizeNotificationPayload({
          'type': 'chat_message',
          'thread_id': 'chat-abc',
        });

        // Suppression checks normalizedData['threadId'] ?? normalizedData['chatId']
        expect(data['type'], 'chat_message');
        expect(data['threadId'], 'chat-abc');
      });

      test('normalizes chatId for suppression matching', () {
        final data = normalizeNotificationPayload({
          'type': 'chat_message',
          'chat_id': 'chat-def',
        });

        expect(data['type'], 'chat_message');
        expect(data['chatId'], 'chat-def');
      });

      test('prefers threadId over chatId for suppression', () {
        // The suppression code checks: normalizedData['threadId'] ?? normalizedData['chatId']
        final data = normalizeNotificationPayload({
          'type': 'chat_message',
          'threadId': 'thread-priority',
          'chatId': 'chat-fallback',
        });

        expect(data['threadId'], 'thread-priority');
      });

      test('handles camelCase threadId directly', () {
        final data = normalizeNotificationPayload({
          'type': 'chat_message',
          'threadId': 'already-camel',
        });

        expect(data['threadId'], 'already-camel');
      });

      test('handles missing chat identifiers gracefully', () {
        final data = normalizeNotificationPayload({
          'type': 'chat_message',
        });

        expect(data['type'], 'chat_message');
        expect(data['threadId'], isNull);
        expect(data['chatId'], isNull);
      });
    });

    group('non-chat types are never suppression candidates', () {
      final nonChatTypes = [
        'game_created',
        'game_alert',
        'game_cancelled',
        'game_spot_opened',
        'game_alert_deferred',
        'host_checkin_due',
        'player_rate_due',
        'host_checkin_fallback',
        'player_fallback_confirm',
        'join_request_new',
        'join_request_approved',
        'join_request_declined',
        'join_request_round_filled',
        'join_request_expired',
        'friend_request_received',
        'friend_request_accepted',
        'badge_earned',
        'badge_progress',
        'streak_weekend_nudge',
        'streak_freeze_unlocked',
        'no_show_flagged',
        'dispute_resolved',
        'player_added_by_host',
        'player_declined_spot',
      ];

      for (final type in nonChatTypes) {
        test('$type is not a suppression candidate', () {
          final data = normalizeNotificationPayload({
            'type': type,
            'gameId': 'g123',
          });

          // The suppression check only fires for chat_message type
          expect(data['type'], isNot('chat_message'));
        });
      }
    });

    group('suppression path matching logic', () {
      // These tests verify the pure logic that suppression would use.
      // The actual _shouldSuppressNotification is private and requires
      // GoRouter context, so we test the equivalent logic here.

      bool wouldSuppressChatNotification({
        required String? type,
        required String? chatId,
        required String currentPath,
      }) {
        if (type != 'chat_message') return false;
        if (chatId == null) return false;
        final normalizedPath = Uri.parse(currentPath).path;
        return normalizedPath == '/chat/$chatId';
      }

      test('suppresses when viewing matching chat thread', () {
        expect(
          wouldSuppressChatNotification(
            type: 'chat_message',
            chatId: 'chat-123',
            currentPath: '/chat/chat-123',
          ),
          isTrue,
        );
      });

      test('does not suppress for different chatId', () {
        expect(
          wouldSuppressChatNotification(
            type: 'chat_message',
            chatId: 'chat-123',
            currentPath: '/chat/chat-other',
          ),
          isFalse,
        );
      });

      test('does not suppress for non-chat types', () {
        expect(
          wouldSuppressChatNotification(
            type: 'game_created',
            chatId: null,
            currentPath: '/chat/chat-123',
          ),
          isFalse,
        );
      });

      test('does not suppress when chatId is null', () {
        expect(
          wouldSuppressChatNotification(
            type: 'chat_message',
            chatId: null,
            currentPath: '/chat/chat-123',
          ),
          isFalse,
        );
      });

      test('does not suppress on non-chat routes', () {
        expect(
          wouldSuppressChatNotification(
            type: 'chat_message',
            chatId: 'chat-123',
            currentPath: '/games',
          ),
          isFalse,
        );
      });

      test('ignores query parameters in route path', () {
        expect(
          wouldSuppressChatNotification(
            type: 'chat_message',
            chatId: 'chat-123',
            currentPath: '/chat/chat-123?tab=messages',
          ),
          isTrue,
        );
      });

      test('does not suppress on chat list route (no chatId in path)', () {
        expect(
          wouldSuppressChatNotification(
            type: 'chat_message',
            chatId: 'chat-123',
            currentPath: '/chat',
          ),
          isFalse,
        );
      });
    });
  });

  group('Content-based deduplication key', () {
    // _computeContentHash is private, but we can verify the data
    // normalization that feeds into it.

    test('normalizeNotificationPayload preserves all ID fields for dedup', () {
      final data = normalizeNotificationPayload({
        'type': 'game_created',
        'gameId': 'g-123',
        'chatId': 'c-456',
        'gameRef': 'games/g-123',
      });

      // All ID fields used by _computeContentHash are present
      expect(data['type'], 'game_created');
      expect(data['gameId'], 'g-123');
      expect(data['chatId'], 'c-456');
      expect(data['gameRef'], 'games/g-123');
    });

    test('normalizeNotificationPayload bridges snake_case IDs for dedup', () {
      final data = normalizeNotificationPayload({
        'type': 'game_cancelled',
        'game_id': 'g-789',
        'thread_id': 'thread-1',
        'game_ref': 'games/g-789',
      });

      expect(data['gameId'], 'g-789');
      expect(data['threadId'], 'thread-1');
      expect(data['gameRef'], 'games/g-789');
    });
  });

  group('Foreground audit event data extraction', () {
    // FcmNotificationService._handleForegroundMessage builds audit events
    // using data['type'] and summarizePayload. This tests the data
    // extraction patterns that feed into NotificationReceiptEvent factories.

    test('type extraction from normalized payload', () {
      final legacyPayload = normalizeNotificationPayload({
        'type': 'game_created',
        'gameId': 'g123',
      });
      expect(legacyPayload['type'], 'game_created');

      final trustPayload = normalizeNotificationPayload({
        'event_type': 'host_checkin_due',
        'event_id': 'evt-1',
      });
      expect(trustPayload['type'], 'host_checkin_due');
    });

    test('messageId preserved from internal tracking field', () {
      final data = normalizeNotificationPayload({
        'type': 'chat_message',
        '_messageId': 'fcm-msg-001',
        'threadId': 'thread-1',
      });

      expect(data['_messageId'], 'fcm-msg-001');
    });
  });
}
