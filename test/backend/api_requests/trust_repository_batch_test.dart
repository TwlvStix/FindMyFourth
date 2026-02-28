import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/backend/api_requests/trust_repository.dart';
import 'package:find_my_fourth/backend/schema/trust_profile.dart';

void main() {
  group('TrustRepository.batchGetTrustProfiles', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TrustRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = TrustRepository(firestore: fakeFirestore);
    });

    Future<void> seedUser(
      String userId, {
      String badgeLevel = 'confirmed',
      int verifiedRounds = 5,
    }) async {
      await fakeFirestore.collection('users').doc(userId).set({
        'badge_level': badgeLevel,
        'verified_round_count': verifiedRounds,
        'weighted_rounds': verifiedRounds.toDouble(),
        'unique_co_players': ['u1', 'u2'],
        'games_hosted': 2,
        'created_time': Timestamp.now(),
      });
    }

    test('returns empty map for empty input', () async {
      final result = await repository.batchGetTrustProfiles([]);
      expect(result, isEmpty);
    });

    test('returns profile for existing user', () async {
      await seedUser('user-a', badgeLevel: 'anchor', verifiedRounds: 12);

      final result = await repository.batchGetTrustProfiles(['user-a']);

      expect(result.length, 1);
      expect(result['user-a'], isNotNull);
      expect(result['user-a']!.currentBadge, BadgeTier.anchor);
      expect(result['user-a']!.verifiedRounds, 12);
    });

    test('returns null for missing users', () async {
      final result = await repository.batchGetTrustProfiles(['missing-user']);

      expect(result.length, 1);
      expect(result.containsKey('missing-user'), isTrue);
      expect(result['missing-user'], isNull);
    });

    test('deduplicates duplicate IDs before query execution', () async {
      await seedUser('user-a', badgeLevel: 'regular');

      final result = await repository
          .batchGetTrustProfiles(['user-a', 'user-a', 'user-a']);

      expect(result.length, 1);
      expect(result['user-a']?.currentBadge, BadgeTier.regular);
    });

    test('handles multiple chunks above Firestore whereIn limit', () async {
      final userIds = List.generate(12, (index) => 'user-$index');
      for (final userId in userIds) {
        await seedUser(userId, badgeLevel: 'confirmed');
      }

      final result = await repository.batchGetTrustProfiles(userIds);

      expect(result.length, 12);
      for (final userId in userIds) {
        expect(result[userId], isNotNull);
      }
    });

    test('returns mixed real profiles and nulls across chunks', () async {
      final userIds = List.generate(12, (index) => 'user-$index');
      for (var i = 0; i < userIds.length; i++) {
        if (i.isEven) {
          await seedUser(userIds[i],
              badgeLevel: 'starter', verifiedRounds: i + 1);
        }
      }

      final result = await repository.batchGetTrustProfiles(userIds);

      expect(result.length, 12);
      for (var i = 0; i < userIds.length; i++) {
        final profile = result[userIds[i]];
        if (i.isEven) {
          expect(profile, isNotNull);
          expect(profile?.currentBadge, BadgeTier.starter);
        } else {
          expect(profile, isNull);
        }
      }
    });
  });
}
