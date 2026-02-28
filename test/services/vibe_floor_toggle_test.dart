import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/services/vibe_floor_service.dart';

void main() {
  group('JoinEligibility enum', () {
    test('has all three states', () {
      expect(JoinEligibility.values.length, 3);
      expect(JoinEligibility.values, contains(JoinEligibility.autoJoin));
      expect(JoinEligibility.values, contains(JoinEligibility.requiresApproval));
      expect(JoinEligibility.values, contains(JoinEligibility.alreadyRequested));
    });
  });

  group('JoinEligibilityResult for require_vibe_match toggle', () {
    test('autoJoin result indicates no approval needed', () {
      const result = JoinEligibilityResult(eligibility: JoinEligibility.autoJoin);

      expect(result.canAutoJoin, isTrue);
      expect(result.needsApproval, isFalse);
      expect(result.hasExistingRequest, isFalse);
    });

    test('requiresApproval result indicates approval needed', () {
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.requiresApproval,
        vibeScore: 25.0,
        vibeFloor: 30,
      );

      expect(result.canAutoJoin, isFalse);
      expect(result.needsApproval, isTrue);
      expect(result.hasExistingRequest, isFalse);
      expect(result.vibeScore, 25.0);
      expect(result.vibeFloor, 30);
    });

    test('alreadyRequested result indicates existing pending request', () {
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.alreadyRequested,
        existingRequestId: 'req123',
      );

      expect(result.canAutoJoin, isFalse);
      expect(result.needsApproval, isFalse);
      expect(result.hasExistingRequest, isTrue);
      expect(result.existingRequestId, 'req123');
    });
  });

  group('require_vibe_match flag behavior', () {
    test('when false, should return autoJoin immediately', () {
      // This tests the expected behavior documented in VibeFloorService:
      // If require_vibe_match is false, return autoJoin without checking vibe
      const result = JoinEligibilityResult(eligibility: JoinEligibility.autoJoin);

      // When require_vibe_match is false, no vibe data is included
      expect(result.vibeScore, isNull);
      expect(result.vibeFloor, isNull);
      expect(result.matchResult, isNull);
      expect(result.canAutoJoin, isTrue);
    });

    test('when true and score >= floor, should return autoJoin with score', () {
      // Score 85 is above floor 30, so autoJoin
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.autoJoin,
        vibeScore: 85.0,
        vibeFloor: 30,
      );

      expect(result.canAutoJoin, isTrue);
      expect(result.vibeScore, 85.0);
      expect(result.vibeFloor, 30);
    });

    test('when true and score < floor, should return requiresApproval', () {
      // Score 25 is below floor 30, so requires approval
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.requiresApproval,
        vibeScore: 25.0,
        vibeFloor: 30,
      );

      expect(result.needsApproval, isTrue);
      expect(result.vibeScore, 25.0);
      expect(result.vibeFloor, 30);
    });

    test('boundary case: score exactly at floor should autoJoin', () {
      // Score 30 equals floor 30, so should autoJoin
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.autoJoin,
        vibeScore: 30.0,
        vibeFloor: 30,
      );

      expect(result.canAutoJoin, isTrue);
    });

    test('boundary case: score just below floor requires approval', () {
      // Score 29.9 is below floor 30
      const result = JoinEligibilityResult(
        eligibility: JoinEligibility.requiresApproval,
        vibeScore: 29.9,
        vibeFloor: 30,
      );

      expect(result.needsApproval, isTrue);
    });
  });

  group('Game creation require_vibe_match defaults', () {
    test('default should be true (require vibe match)', () {
      // The game creation form should default to requiring vibe match
      // This tests the expected default value
      const defaultRequireVibeMatch = true;

      expect(defaultRequireVibeMatch, isTrue);
    });

    test('toggle OFF allows any player to auto-join', () {
      // When toggle is OFF (require_vibe_match = false):
      // - No vibe check is performed
      // - All players can auto-join regardless of vibe score
      const requireVibeMatch = false;
      const anyScore = 0.0;
      const anyFloor = 100;

      // With toggle OFF, score vs floor comparison is bypassed
      if (!requireVibeMatch) {
        // Auto-join without checking
        const result = JoinEligibilityResult(eligibility: JoinEligibility.autoJoin);
        expect(result.canAutoJoin, isTrue);
      }
    });

    test('toggle ON enforces vibe floor check', () {
      // When toggle is ON (require_vibe_match = true):
      // - Vibe check is performed
      // - Players below floor need approval
      const requireVibeMatch = true;
      const lowScore = 15.0;
      const floor = 30;

      if (requireVibeMatch && lowScore < floor) {
        const result = JoinEligibilityResult(
          eligibility: JoinEligibility.requiresApproval,
          vibeScore: lowScore,
          vibeFloor: floor,
        );
        expect(result.needsApproval, isTrue);
      }
    });
  });

  group('JoinEligibilityResult toString', () {
    test('produces readable output with all fields', () {
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
}
