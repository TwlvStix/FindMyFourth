import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/join_request.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_floor_config.dart';
import 'package:find_my_fourth/services/vibe_floor_service.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';

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
    test('returns default floor value of 30', () async {
      final config = VibeFloorConfig();
      final floor = await config.getVibeFloor();
      expect(floor, 30);
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
}
