import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/backend/api_requests/trust_repository.dart';
import 'package:find_my_fourth/backend/schema/trust_profile.dart';
import 'package:find_my_fourth/providers/trust_provider.dart';

/// Mock TrustRepository for testing batch operations
class MockTrustRepository extends TrustRepository {
  MockTrustRepository();

  int batchCallCount = 0;
  List<String> lastRequestedIds = [];
  List<List<String>> requestedBatches = [];
  Map<String, TrustProfile?> mockResponses = {};
  bool shouldThrow = false;
  bool holdBatchResponses = false;

  final List<Completer<Map<String, TrustProfile?>>> _pendingBatchCompleters =
      [];
  final List<List<String>> _pendingBatchIds = [];

  @override
  Future<Map<String, TrustProfile?>> batchGetTrustProfiles(
    List<String> userIds,
  ) async {
    batchCallCount++;
    lastRequestedIds = List<String>.from(userIds);
    requestedBatches.add(List<String>.from(userIds));
    if (shouldThrow) throw Exception('Repository error');
    if (holdBatchResponses) {
      final completer = Completer<Map<String, TrustProfile?>>();
      _pendingBatchCompleters.add(completer);
      _pendingBatchIds.add(List<String>.from(userIds));
      return completer.future;
    }
    return {
      for (final id in userIds) id: mockResponses[id],
    };
  }

  @override
  Future<TrustProfile?> getTrustProfile(String userId) async {
    return mockResponses[userId];
  }

  void resolveNextBatch() {
    if (_pendingBatchCompleters.isEmpty) return;
    final completer = _pendingBatchCompleters.removeAt(0);
    final ids = _pendingBatchIds.removeAt(0);
    if (!completer.isCompleted) {
      completer.complete({
        for (final id in ids) id: mockResponses[id],
      });
    }
  }
}

TrustProfile _buildTrustProfile({
  int verifiedRounds = 5,
  BadgeTier badge = BadgeTier.confirmed,
}) {
  return TrustProfile(
    verifiedRounds: verifiedRounds,
    weightedRounds: verifiedRounds.toDouble(),
    uniqueCoPlayers: 3,
    gamesHosted: 2,
    joinDate: DateTime.now(),
    currentBadge: badge,
    nextBadgeProgress: BadgeProgress.empty,
    cancellationWarning: CancellationWarning.none,
  );
}

void main() {
  group('TrustProvider.batchGetTrustProfiles', () {
    group('cache behavior', () {
      test('returns empty map for empty input', () async {
        final provider = TrustProvider();
        final result = await provider.batchGetTrustProfiles([]);
        expect(result, isEmpty);
        provider.dispose();
      });

      test('fetches all profiles on first call (cache miss)', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {
          'user-a': _buildTrustProfile(badge: BadgeTier.confirmed),
          'user-b': _buildTrustProfile(badge: BadgeTier.regular),
          'user-c': _buildTrustProfile(badge: BadgeTier.anchor),
        };

        final provider = TrustProvider.withRepository(mockRepo);
        final result = await provider.batchGetTrustProfiles(
          ['user-a', 'user-b', 'user-c'],
        );

        expect(result.length, 3);
        expect(result['user-a']?.currentBadge, BadgeTier.confirmed);
        expect(result['user-b']?.currentBadge, BadgeTier.regular);
        expect(result['user-c']?.currentBadge, BadgeTier.anchor);
        expect(mockRepo.batchCallCount, 1);
        expect(mockRepo.lastRequestedIds, ['user-a', 'user-b', 'user-c']);
        provider.dispose();
      });

      test('returns cached profiles on second call (cache hit)', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {
          'user-a': _buildTrustProfile(),
          'user-b': _buildTrustProfile(),
        };

        final provider = TrustProvider.withRepository(mockRepo);

        // First call - fetches from repository
        await provider.batchGetTrustProfiles(['user-a', 'user-b']);
        expect(mockRepo.batchCallCount, 1);

        // Second call - should return cached, no repository call
        final result =
            await provider.batchGetTrustProfiles(['user-a', 'user-b']);
        expect(result.length, 2);
        expect(mockRepo.batchCallCount, 1); // Still 1, no new fetch
        provider.dispose();
      });

      test('fetches only missing profiles (partial cache hit)', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {
          'user-a': _buildTrustProfile(),
          'user-b': _buildTrustProfile(),
          'user-c': _buildTrustProfile(),
        };

        final provider = TrustProvider.withRepository(mockRepo);

        // First call - cache user-a and user-b
        await provider.batchGetTrustProfiles(['user-a', 'user-b']);
        expect(mockRepo.batchCallCount, 1);

        // Second call - includes cached (a, b) and new (c)
        mockRepo.lastRequestedIds = [];
        final result = await provider.batchGetTrustProfiles(
          ['user-a', 'user-b', 'user-c'],
        );

        expect(result.length, 3);
        expect(mockRepo.batchCallCount, 2);
        expect(mockRepo.lastRequestedIds, ['user-c']); // Only fetched c
        provider.dispose();
      });

      test('cache expires after TTL (5 minutes)', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {'user-a': _buildTrustProfile()};

        final provider = TrustProvider.withRepository(mockRepo);

        // First call
        await provider.batchGetTrustProfiles(['user-a']);
        expect(mockRepo.batchCallCount, 1);

        // Simulate cache expiry
        provider.expireCacheForTest('user-a');

        // Second call - should fetch again after TTL
        await provider.batchGetTrustProfiles(['user-a']);
        expect(mockRepo.batchCallCount, 2);
        provider.dispose();
      });
    });

    group('deduplication', () {
      test('deduplicates repeated user IDs in same request', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {'user-a': _buildTrustProfile()};

        final provider = TrustProvider.withRepository(mockRepo);
        final result = await provider.batchGetTrustProfiles(
          ['user-a', 'user-a', 'user-a'],
        );

        expect(result.containsKey('user-a'), isTrue);
        expect(result.length, 1);
        expect(mockRepo.batchCallCount, 1);
        expect(mockRepo.lastRequestedIds, ['user-a']);
        provider.dispose();
      });

      test('coalesces concurrent identical requests into one batch call',
          () async {
        final mockRepo = MockTrustRepository()
          ..holdBatchResponses = true
          ..mockResponses = {
            'user-a': _buildTrustProfile(),
            'user-b': _buildTrustProfile(),
          };

        final provider = TrustProvider.withRepository(mockRepo);

        final futureA = provider.batchGetTrustProfiles(['user-a', 'user-b']);
        final futureB = provider.batchGetTrustProfiles(['user-a', 'user-b']);
        await Future<void>.delayed(Duration.zero);

        expect(mockRepo.batchCallCount, 1);

        mockRepo.resolveNextBatch();
        final results = await Future.wait([futureA, futureB]);
        expect(results[0]['user-a'], isNotNull);
        expect(results[1]['user-b'], isNotNull);
        provider.dispose();
      });

      test('only fetches newly missing IDs when requests overlap', () async {
        final mockRepo = MockTrustRepository()
          ..holdBatchResponses = true
          ..mockResponses = {
            'user-a': _buildTrustProfile(),
            'user-b': _buildTrustProfile(),
            'user-c': _buildTrustProfile(),
          };

        final provider = TrustProvider.withRepository(mockRepo);

        final futureA = provider.batchGetTrustProfiles(['user-a', 'user-b']);
        await Future<void>.delayed(Duration.zero);

        final futureB = provider.batchGetTrustProfiles(['user-b', 'user-c']);
        await Future<void>.delayed(Duration.zero);

        expect(mockRepo.batchCallCount, 2);
        expect(mockRepo.requestedBatches[0], ['user-a', 'user-b']);
        expect(mockRepo.requestedBatches[1], ['user-c']);

        mockRepo.resolveNextBatch();
        mockRepo.resolveNextBatch();

        final results = await Future.wait([futureA, futureB]);
        expect(results[0]['user-a'], isNotNull);
        expect(results[1]['user-b'], isNotNull);
        expect(results[1]['user-c'], isNotNull);
        provider.dispose();
      });
    });

    group('error handling', () {
      test('returns null for users not found in repository', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {
          'user-a': _buildTrustProfile(),
          'user-b': null, // Not found
        };

        final provider = TrustProvider.withRepository(mockRepo);
        final result =
            await provider.batchGetTrustProfiles(['user-a', 'user-b']);

        expect(result.length, 2);
        expect(result['user-a'], isNotNull);
        expect(result['user-b'], isNull);
        provider.dispose();
      });

      test('returns nulls for all on repository error (partial failure)',
          () async {
        final mockRepo = MockTrustRepository();
        mockRepo.shouldThrow = true;

        final provider = TrustProvider.withRepository(mockRepo);
        final result =
            await provider.batchGetTrustProfiles(['user-a', 'user-b']);

        expect(result.length, 2);
        expect(result['user-a'], isNull);
        expect(result['user-b'], isNull);
        provider.dispose();
      });

      test('returns partial results when some cached and fetch fails',
          () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {
          'user-a': _buildTrustProfile(badge: BadgeTier.anchor),
        };

        final provider = TrustProvider.withRepository(mockRepo);

        // Cache user-a
        await provider.batchGetTrustProfiles(['user-a']);

        // Now fail for user-b
        mockRepo.shouldThrow = true;
        final result =
            await provider.batchGetTrustProfiles(['user-a', 'user-b']);

        expect(result.length, 2);
        expect(result['user-a']?.currentBadge, BadgeTier.anchor); // From cache
        expect(result['user-b'], isNull); // Failed fetch
        provider.dispose();
      });
    });

    group('cache population', () {
      test('populates cache for subsequent getCachedProfile calls', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {
          'user-a': _buildTrustProfile(badge: BadgeTier.starter),
        };

        final provider = TrustProvider.withRepository(mockRepo);

        // Before batch fetch
        expect(provider.getCachedProfile('user-a'), isNull);

        // Batch fetch
        await provider.batchGetTrustProfiles(['user-a']);

        // After batch fetch - should be in cache
        expect(provider.getCachedProfile('user-a')?.currentBadge,
            BadgeTier.starter);
        provider.dispose();
      });

      test('does not cache null profiles', () async {
        final mockRepo = MockTrustRepository();
        mockRepo.mockResponses = {'user-a': null};

        final provider = TrustProvider.withRepository(mockRepo);
        await provider.batchGetTrustProfiles(['user-a']);

        expect(provider.getCachedProfile('user-a'), isNull);
        provider.dispose();
      });
    });
  });
}
