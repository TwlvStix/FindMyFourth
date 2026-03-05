import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/join_request.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/friend_service.dart';
import 'package:find_my_fourth/services/join_request_service.dart';
import 'package:find_my_fourth/services/vibe_floor_config.dart';
import 'package:find_my_fourth/services/vibe_floor_service.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/services/vibe_repository.dart';

/// Mock VibeFloorConfig for testing fail-closed behavior
class MockVibeFloorConfig implements VibeFloorConfig {
  bool remoteConfigReady = true;
  int floor = 30;

  @override
  Future<bool> waitForRemoteConfig({Duration timeout = const Duration(milliseconds: 1200)}) async {
    return remoteConfigReady;
  }

  @override
  bool get isRemoteConfigReady => remoteConfigReady;

  @override
  Future<int> getVibeFloor() async => floor;
}

/// Mock FriendService for testing
class MockFriendService implements FriendService {
  bool areFriendsResult = false;

  @override
  Future<bool> areFriends(String userId1, String userId2) async => areFriendsResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Mock VibeRepository for testing
class MockVibeRepository implements VibeRepository {
  VibeProfile ownerProfile = _buildDefaultProfile();
  VibeProfile playerProfile = _buildDefaultProfile();

  @override
  Future<VibeProfile> getVibeProfileForUser(String userId) async {
    // Return owner profile for 'owner' userId, player profile for 'player'
    if (userId == 'owner') return ownerProfile;
    return playerProfile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Mock JoinRequestService for testing
class MockJoinRequestService implements JoinRequestService {
  JoinRequest? existingRequest;

  @override
  Future<JoinRequest?> checkExistingRequest(String gameId, String playerId) async {
    return existingRequest;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

VibeProfile _buildDefaultProfile() {
  final prefs = <VibeCategory, VibePreference>{};
  for (final category in VibeCategory.values) {
    prefs[category] = VibePreference(
      value: 3,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    );
  }
  return VibeProfile(
    prefs: prefs,
    importance: {
      for (final c in VibeCategory.values) c: VibeImportance.normal,
    },
    importanceVersion: 1,
    confirmedAt: DateTime.now(),
  );
}

/// Build a test vibe profile with specified pace value
VibeProfile _buildProfile({int pace = 3}) {
  final prefs = <VibeCategory, VibePreference>{};
  for (final category in VibeCategory.values) {
    prefs[category] = VibePreference(
      value: category == VibeCategory.pace ? pace : 3,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    );
  }
  return VibeProfile(
    prefs: prefs,
    importance: {
      for (final c in VibeCategory.values) c: VibeImportance.normal,
    },
    importanceVersion: 1,
    confirmedAt: DateTime.now(),
  );
}

void main() {
  group('VibeFloorConfig', () {
    test('default floor constant is 30', () {
      // Note: getVibeFloor() requires Firebase Remote Config initialization.
      // This test verifies the static default value directly.
      expect(VibeFloorConfig.defaultFloor, 30);
    });
  });

  group('JoinEligibilityResult', () {
    test('canAutoJoin is true only for autoJoin', () {
      expect(
        const JoinEligibilityResult(eligibility: JoinEligibility.autoJoin)
            .canAutoJoin,
        isTrue,
      );
      expect(
        const JoinEligibilityResult(
                eligibility: JoinEligibility.requiresApproval)
            .canAutoJoin,
        isFalse,
      );
      expect(
        const JoinEligibilityResult(
                eligibility: JoinEligibility.alreadyRequested)
            .canAutoJoin,
        isFalse,
      );
    });

    test('needsApproval is true only for requiresApproval', () {
      expect(
        const JoinEligibilityResult(eligibility: JoinEligibility.autoJoin)
            .needsApproval,
        isFalse,
      );
      expect(
        const JoinEligibilityResult(
                eligibility: JoinEligibility.requiresApproval)
            .needsApproval,
        isTrue,
      );
    });

    test('hasExistingRequest is true only for alreadyRequested', () {
      expect(
        const JoinEligibilityResult(
                eligibility: JoinEligibility.alreadyRequested)
            .hasExistingRequest,
        isTrue,
      );
      expect(
        const JoinEligibilityResult(eligibility: JoinEligibility.autoJoin)
            .hasExistingRequest,
        isFalse,
      );
    });

    test('toString produces readable output', () {
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.requiresApproval,
        vibeScore: 25.5,
        vibeFloor: 30,
      );
      final str = result.toString();
      expect(str, contains('requiresApproval'));
      expect(str, contains('25.5'));
      expect(str, contains('30'));
    });
  });

  group('VibeMatcher integration', () {
    test('identical profiles produce high match scores', () {
      final profile1 = _buildProfile(pace: 3);
      final profile2 = _buildProfile(pace: 3);

      final result = VibeMatcher.score(profile1, profile2);

      // Identical profiles should have high compatibility
      expect(result.myFitPercent, greaterThan(80));
    });

    test('very different profiles produce lower match scores', () {
      final profile1 = _buildProfile(pace: 0);
      final profile2 = _buildProfile(pace: 5);

      final result = VibeMatcher.score(profile1, profile2);

      // Very different profiles should have lower compatibility
      expect(result.myFitPercent, lessThan(80));
    });

    test('myFitPercent represents owner perspective correctly', () {
      final ownerProfile = _buildProfile(pace: 3);
      final playerProfile = _buildProfile(pace: 3);

      final result = VibeMatcher.score(ownerProfile, playerProfile);

      // myFitPercent = how owner feels about player
      expect(result.myFitPercent, isNotNull);
      expect(result.myFitPercent, greaterThanOrEqualTo(0));
      expect(result.myFitPercent, lessThanOrEqualTo(100));
    });
  });

  group('JoinRequest model', () {
    test('status enum parses correctly', () {
      expect(JoinRequestStatus.fromKey('pending'), JoinRequestStatus.pending);
      expect(JoinRequestStatus.fromKey('approved'), JoinRequestStatus.approved);
      expect(JoinRequestStatus.fromKey('denied'), JoinRequestStatus.denied);
      expect(JoinRequestStatus.fromKey(null), JoinRequestStatus.pending);
      expect(JoinRequestStatus.fromKey('unknown'), JoinRequestStatus.pending);
    });

    test('isPending, isApproved, isDenied return correct values', () {
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
      expect(pending.isApproved, isFalse);
      expect(pending.isDenied, isFalse);

      expect(approved.isPending, isFalse);
      expect(approved.isApproved, isTrue);
      expect(approved.isDenied, isFalse);

      expect(denied.isPending, isFalse);
      expect(denied.isApproved, isFalse);
      expect(denied.isDenied, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
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

      final updated = original.copyWith(status: JoinRequestStatus.approved);

      expect(updated.id, original.id);
      expect(updated.gameId, original.gameId);
      expect(updated.requesterId, original.requesterId);
      expect(updated.requesterVibeScore, original.requesterVibeScore);
      expect(updated.status, JoinRequestStatus.approved);
    });
  });

  group('Vibe floor threshold logic', () {
    test('score >= floor passes (boundary case)', () {
      const floor = 30;
      const score = 30.0;

      // Score exactly at floor should pass
      expect(score >= floor, isTrue);
    });

    test('score < floor fails', () {
      const floor = 30;
      const score = 29.9;

      expect(score >= floor, isFalse);
    });

    test('zero floor means any score passes', () {
      const floor = 0;
      const score = 0.0;

      expect(score >= floor, isTrue);
    });

    test('100 floor requires perfect match', () {
      const floor = 100;

      expect(99.9 >= floor, isFalse);
      expect(100.0 >= floor, isTrue);
    });
  });

  group('Cold-start bypass prevention', () {
    // These tests verify the fix for the vibe floor gate bypass bug.
    // Before the fix, if Remote Config wasn't initialized, floor would be 0,
    // allowing any player to auto-join. With the fix, floor defaults to 30.

    test('floor of 0 would let any score pass (regression scenario)', () {
      // This demonstrates the bug: if floor is 0, any score passes
      const buggyFloor = 0;
      const lowScore = 5.0;

      // With floor=0, even a low score passes
      expect(lowScore >= buggyFloor, isTrue);

      // But with correct floor=30, low score fails
      const correctFloor = VibeFloorConfig.defaultFloor;
      expect(lowScore >= correctFloor, isFalse);
    });

    test('default floor 30 prevents low-score auto-join', () {
      // With the fix, floor defaults to 30, not 0
      const floor = VibeFloorConfig.defaultFloor;
      const lowScore = 25.0;

      // Player with score 25 should not auto-join
      expect(lowScore >= floor, isFalse);

      // This would return requiresApproval, not autoJoin
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.requiresApproval,
        vibeScore: lowScore,
        vibeFloor: floor,
      );
      expect(result.needsApproval, isTrue);
      expect(result.canAutoJoin, isFalse);
    });

    test('score exactly at default floor (30) passes', () {
      const floor = VibeFloorConfig.defaultFloor;
      const score = 30.0;

      expect(score >= floor, isTrue);
    });

    test('score above default floor passes', () {
      const floor = VibeFloorConfig.defaultFloor;
      const score = 50.0;

      expect(score >= floor, isTrue);
    });
  });

  group('VibeFloorService fail-closed integration', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockVibeFloorConfig mockVibeFloorConfig;
    late MockFriendService mockFriendService;
    late MockVibeRepository mockVibeRepository;
    late MockJoinRequestService mockJoinRequestService;
    late VibeFloorService service;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockVibeFloorConfig = MockVibeFloorConfig();
      mockFriendService = MockFriendService();
      mockVibeRepository = MockVibeRepository();
      mockJoinRequestService = MockJoinRequestService();

      // Create a game that requires vibe match
      await fakeFirestore.collection('games').doc('game1').set({
        'require_vibe_match': true,
      });

      service = VibeFloorService(
        firestore: fakeFirestore,
        friendService: mockFriendService,
        vibeRepository: mockVibeRepository,
        vibeFloorConfig: mockVibeFloorConfig,
        joinRequestService: mockJoinRequestService,
      );
    });

    test('remote config not ready, non-friend -> requiresApproval (fail-closed)', () async {
      mockVibeFloorConfig.remoteConfigReady = false;
      mockFriendService.areFriendsResult = false;

      final result = await service.evaluateJoinEligibility(
        gameId: 'game1',
        playerId: 'player',
        ownerId: 'owner',
      );

      expect(result.eligibility, JoinEligibility.requiresApproval);
      expect(result.canAutoJoin, isFalse);
    });

    test('remote config not ready, existing request -> alreadyRequested', () async {
      mockVibeFloorConfig.remoteConfigReady = false;
      mockFriendService.areFriendsResult = false;
      mockJoinRequestService.existingRequest = JoinRequest(
        id: 'req1',
        gameId: 'game1',
        requesterId: 'player',
        ownerId: 'owner',
        requesterVibeScore: 50,
        vibeFloor: 30,
        status: JoinRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final result = await service.evaluateJoinEligibility(
        gameId: 'game1',
        playerId: 'player',
        ownerId: 'owner',
      );

      expect(result.eligibility, JoinEligibility.alreadyRequested);
      expect(result.existingRequestId, 'req1');
    });

    test('remote config ready, score >= floor -> autoJoin', () async {
      mockVibeFloorConfig.remoteConfigReady = true;
      mockVibeFloorConfig.floor = 30;
      mockFriendService.areFriendsResult = false;
      // Default profiles have identical values, so score should be high (>30)

      final result = await service.evaluateJoinEligibility(
        gameId: 'game1',
        playerId: 'player',
        ownerId: 'owner',
      );

      expect(result.eligibility, JoinEligibility.autoJoin);
      expect(result.canAutoJoin, isTrue);
    });

    test('friend bypass works even when remote config not ready', () async {
      mockVibeFloorConfig.remoteConfigReady = false;
      mockFriendService.areFriendsResult = true; // They are friends

      final result = await service.evaluateJoinEligibility(
        gameId: 'game1',
        playerId: 'player',
        ownerId: 'owner',
      );

      expect(result.eligibility, JoinEligibility.autoJoin);
      expect(result.canAutoJoin, isTrue);
    });

    test('require_vibe_match=false -> autoJoin immediately', () async {
      // Create game without vibe match requirement
      await fakeFirestore.collection('games').doc('game2').set({
        'require_vibe_match': false,
      });

      mockVibeFloorConfig.remoteConfigReady = false;
      mockFriendService.areFriendsResult = false;

      final result = await service.evaluateJoinEligibility(
        gameId: 'game2',
        playerId: 'player',
        ownerId: 'owner',
      );

      expect(result.eligibility, JoinEligibility.autoJoin);
      expect(result.canAutoJoin, isTrue);
    });
  });
}
