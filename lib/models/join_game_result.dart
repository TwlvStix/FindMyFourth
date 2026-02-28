import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';

/// Result of attempting to join a game through the provider
///
/// This enum represents the outcome of the join flow including vibe floor checks.
enum JoinGameResult {
  /// Successfully joined the game (friend or above vibe floor)
  joined,

  /// Player is below vibe floor and needs owner approval
  /// The UI should prompt the player to submit a join request
  requiresApproval,

  /// Player already has a pending join request for this game
  alreadyRequested,
}

/// Full result of attempting to join a game, including profile data for UI.
///
/// When the result is [JoinGameResult.requiresApproval], the optional fields
/// are populated with data needed to render the vibe floor bottom sheet.
class JoinGameEligibilityData {
  const JoinGameEligibilityData({
    required this.result,
    this.matchResult,
    this.ownerProfile,
    this.playerProfile,
    this.vibeScore,
    this.vibeFloor,
  });

  /// The join outcome
  final JoinGameResult result;

  /// The full match result with per-category scores and top differences.
  /// Only populated when result == requiresApproval.
  final VibeMatchResult? matchResult;

  /// The game owner's vibe profile (for rendering spectrum bars).
  /// Only populated when result == requiresApproval.
  final VibeProfile? ownerProfile;

  /// The requesting player's vibe profile (for rendering spectrum bars).
  /// Only populated when result == requiresApproval.
  final VibeProfile? playerProfile;

  /// The owner's vibe score for the player (0-100).
  /// Only populated when vibe floor check was performed.
  final double? vibeScore;

  /// The vibe floor threshold at the time of evaluation.
  /// Only populated when vibe floor check was performed.
  final int? vibeFloor;

  /// Convenience factory for simple joined result
  factory JoinGameEligibilityData.joined() =>
      const JoinGameEligibilityData(result: JoinGameResult.joined);

  /// Convenience factory for already requested result
  factory JoinGameEligibilityData.alreadyRequested() =>
      const JoinGameEligibilityData(result: JoinGameResult.alreadyRequested);
}
