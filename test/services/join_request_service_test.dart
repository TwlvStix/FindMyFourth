import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/join_request.dart';

void main() {
  group('JoinRequestStatus', () {
    test('fromKey parses pending correctly', () {
      expect(JoinRequestStatus.fromKey('pending'), JoinRequestStatus.pending);
    });

    test('fromKey parses approved correctly', () {
      expect(JoinRequestStatus.fromKey('approved'), JoinRequestStatus.approved);
    });

    test('fromKey parses denied correctly', () {
      expect(JoinRequestStatus.fromKey('denied'), JoinRequestStatus.denied);
    });

    test('fromKey defaults to pending for unknown values', () {
      expect(JoinRequestStatus.fromKey('unknown'), JoinRequestStatus.pending);
      expect(JoinRequestStatus.fromKey(null), JoinRequestStatus.pending);
      expect(JoinRequestStatus.fromKey(''), JoinRequestStatus.pending);
    });

    test('key returns correct string representation', () {
      expect(JoinRequestStatus.pending.key, 'pending');
      expect(JoinRequestStatus.approved.key, 'approved');
      expect(JoinRequestStatus.denied.key, 'denied');
    });
  });

  group('JoinRequest', () {
    test('constructor creates valid instance', () {
      final now = DateTime.now();
      final request = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: now,
      );

      expect(request.id, 'req123');
      expect(request.gameId, 'game456');
      expect(request.requesterId, 'player789');
      expect(request.ownerId, 'owner012');
      expect(request.requesterVibeScore, 25.5);
      expect(request.vibeFloor, 30);
      expect(request.status, JoinRequestStatus.pending);
      expect(request.createdAt, now);
      expect(request.respondedAt, isNull);
    });

    test('isPending returns correct value', () {
      final pending = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 25,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      final approved = pending.copyWith(status: JoinRequestStatus.approved);
      final denied = pending.copyWith(status: JoinRequestStatus.denied);

      expect(pending.isPending, isTrue);
      expect(approved.isPending, isFalse);
      expect(denied.isPending, isFalse);
    });

    test('isApproved returns correct value', () {
      final pending = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 25,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      final approved = pending.copyWith(status: JoinRequestStatus.approved);
      final denied = pending.copyWith(status: JoinRequestStatus.denied);

      expect(pending.isApproved, isFalse);
      expect(approved.isApproved, isTrue);
      expect(denied.isApproved, isFalse);
    });

    test('isDenied returns correct value', () {
      final pending = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 25,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      final approved = pending.copyWith(status: JoinRequestStatus.approved);
      final denied = pending.copyWith(status: JoinRequestStatus.denied);

      expect(pending.isDenied, isFalse);
      expect(approved.isDenied, isFalse);
      expect(denied.isDenied, isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime(2024, 1, 1),
      );

      final respondedAt = DateTime(2024, 1, 2);
      final updated = original.copyWith(
        status: JoinRequestStatus.approved,
        respondedAt: respondedAt,
      );

      // Original unchanged
      expect(original.status, JoinRequestStatus.pending);
      expect(original.respondedAt, isNull);

      // Updated has new values
      expect(updated.status, JoinRequestStatus.approved);
      expect(updated.respondedAt, respondedAt);

      // Unchanged fields preserved
      expect(updated.id, original.id);
      expect(updated.gameId, original.gameId);
      expect(updated.requesterId, original.requesterId);
      expect(updated.requesterVibeScore, original.requesterVibeScore);
    });

    test('toMap produces correct structure for Firestore', () {
      final request = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final map = request.toMap();

      expect(map['gameId'], 'game456');
      expect(map['requesterId'], 'player789');
      expect(map['ownerId'], 'owner012');
      expect(map['requesterVibeScore'], 25.5);
      expect(map['vibeFloor'], 30);
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<FieldValue>()); // Server timestamp
      expect(map.containsKey('respondedAt'), isFalse); // Not included when null
    });

    test('toMap includes respondedAt when present', () {
      final respondedAt = DateTime(2024, 1, 2);
      final request = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.approved,
        createdAt: DateTime(2024, 1, 1),
        respondedAt: respondedAt,
      );

      final map = request.toMap();

      expect(map.containsKey('respondedAt'), isTrue);
      expect(map['respondedAt'], isA<Timestamp>());
    });

    test('toString produces readable output', () {
      final request = JoinRequest(
        id: 'req123',
        gameId: 'game456',
        requesterId: 'player789',
        ownerId: 'owner012',
        requesterVibeScore: 25.5,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final str = request.toString();

      expect(str, contains('req123'));
      expect(str, contains('game456'));
      expect(str, contains('player789'));
      expect(str, contains('pending'));
    });
  });

  group('JoinRequest status transitions', () {
    test('pending can transition to approved', () {
      final request = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 25,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final approved = request.copyWith(
        status: JoinRequestStatus.approved,
        respondedAt: DateTime.now(),
      );

      expect(approved.isApproved, isTrue);
      expect(approved.respondedAt, isNotNull);
    });

    test('pending can transition to denied', () {
      final request = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 25,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final denied = request.copyWith(
        status: JoinRequestStatus.denied,
        respondedAt: DateTime.now(),
      );

      expect(denied.isDenied, isTrue);
      expect(denied.respondedAt, isNotNull);
    });
  });

  group('JoinRequest edge cases', () {
    test('handles zero vibe score', () {
      final request = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 0,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(request.requesterVibeScore, 0);
    });

    test('handles 100 vibe score', () {
      final request = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 100,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(request.requesterVibeScore, 100);
    });

    test('handles zero floor', () {
      final request = JoinRequest(
        id: '1',
        gameId: 'g',
        requesterId: 'p',
        ownerId: 'o',
        requesterVibeScore: 25,
        vibeFloor: 0,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(request.vibeFloor, 0);
    });
  });
}
