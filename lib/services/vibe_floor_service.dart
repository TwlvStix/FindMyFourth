import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';
import '/models/vibe_profile.dart';
import '/services/friend_service.dart';
import '/services/join_request_service.dart';
import '/services/vibe_floor_config.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

/// Result of evaluating a player's eligibility to join a game
enum JoinEligibility {
  /// Player can auto-join (friend or above vibe floor)
  autoJoin,

  /// Player is below vibe floor and needs owner approval
  requiresApproval,

  /// Player already has a pending request for this game
  alreadyRequested,
}

/// Result of vibe floor eligibility evaluation
class JoinEligibilityResult {
  final JoinEligibility eligibility;
  final double? vibeScore;
  final int? vibeFloor;
  final String? existingRequestId;

  /// The full match result with per-category scores and top differences.
  /// Only populated when eligibility == requiresApproval.
  final VibeMatchResult? matchResult;

  /// The game owner's vibe profile (for rendering spectrum bars).
  /// Only populated when eligibility == requiresApproval.
  final VibeProfile? ownerProfile;

  /// The requesting player's vibe profile (for rendering spectrum bars).
  /// Only populated when eligibility == requiresApproval.
  final VibeProfile? playerProfile;

  const JoinEligibilityResult({
    required this.eligibility,
    this.vibeScore,
    this.vibeFloor,
    this.existingRequestId,
    this.matchResult,
    this.ownerProfile,
    this.playerProfile,
  });

  bool get canAutoJoin => eligibility == JoinEligibility.autoJoin;
  bool get needsApproval => eligibility == JoinEligibility.requiresApproval;
  bool get hasExistingRequest => eligibility == JoinEligibility.alreadyRequested;

  @override
  String toString() =>
      'JoinEligibilityResult(eligibility: $eligibility, vibeScore: $vibeScore, vibeFloor: $vibeFloor)';
}

/// Service that evaluates whether a player can auto-join a game or needs approval
///
/// This is the orchestration layer for the vibe floor gate. It coordinates:
/// - Friend check (friends bypass vibe floor)
/// - Vibe score calculation (owner's perspective)
/// - Threshold comparison
/// - Existing request detection
///
/// It does NOT create join requests — that's the provider's responsibility.
class VibeFloorService {
  VibeFloorService({
    FirebaseFirestore? firestore,
    FriendService? friendService,
    VibeRepository? vibeRepository,
    VibeFloorConfig? vibeFloorConfig,
    JoinRequestService? joinRequestService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _friendService = friendService ?? FriendService(),
        _vibeRepository = vibeRepository ?? VibeRepository(),
        _vibeFloorConfig = vibeFloorConfig ?? VibeFloorConfig(),
        _joinRequestService = joinRequestService ?? JoinRequestService();

  final FirebaseFirestore _firestore;
  final FriendService _friendService;
  final VibeRepository _vibeRepository;
  final VibeFloorConfig _vibeFloorConfig;
  final JoinRequestService _joinRequestService;

  /// Evaluate whether a player can auto-join a game or needs owner approval
  ///
  /// The evaluation follows this order:
  /// 1. Friends bypass — if player and owner are friends, auto-join
  /// 2. Vibe floor check — calculate owner's score for the player
  /// 3. Score >= floor — auto-join
  /// 4. Score < floor — check for existing request, then return requiresApproval
  ///
  /// Returns a [JoinEligibilityResult] with the outcome and relevant data.
  Future<JoinEligibilityResult> evaluateJoinEligibility({
    required String gameId,
    required String playerId,
    required String ownerId,
  }) async {
    AppLog.d('🚦 VibeFloorService: Evaluating eligibility for player $playerId to join game $gameId');

    // 0. Check if game requires vibe match
    final gameDoc = await _firestore.collection('games').doc(gameId).get();
    final requireVibeMatch = gameDoc.data()?['require_vibe_match'] ?? true;

    if (!requireVibeMatch) {
      AppLog.d('✅ VibeFloorService: Game does not require vibe match — auto-join');
      return const JoinEligibilityResult(eligibility: JoinEligibility.autoJoin);
    }

    // 1. Check if player and owner are friends
    final areFriends = await _friendService.areFriends(ownerId, playerId);
    if (areFriends) {
      AppLog.d('✅ VibeFloorService: Player is friends with owner — auto-join');
      return const JoinEligibilityResult(eligibility: JoinEligibility.autoJoin);
    }

    // 2. Fetch both vibe profiles
    final ownerProfile = await _vibeRepository.getVibeProfileForUser(ownerId);
    final playerProfile = await _vibeRepository.getVibeProfileForUser(playerId);

    // 3. Calculate owner's score for the player
    // VibeMatcher.score(mine, theirs) returns myFitPercent = how "mine" feels about "theirs"
    final matchResult = VibeMatcher.score(ownerProfile, playerProfile);
    final ownerScore = matchResult.myFitPercent;

    // 4. Get the vibe floor threshold
    final floor = await _vibeFloorConfig.getVibeFloor();

    AppLog.d('📖 VibeFloorService: Owner score for player = $ownerScore, floor = $floor');

    // 5. Compare score to floor
    if (ownerScore >= floor) {
      AppLog.d('✅ VibeFloorService: Score >= floor — auto-join');
      return JoinEligibilityResult(
        eligibility: JoinEligibility.autoJoin,
        vibeScore: ownerScore,
        vibeFloor: floor,
      );
    }

    // 6. Score is below floor — check for existing pending request
    final existingRequest =
        await _joinRequestService.checkExistingRequest(gameId, playerId);
    if (existingRequest != null) {
      AppLog.d('📖 VibeFloorService: Player already has pending request ${existingRequest.id}');
      return JoinEligibilityResult(
        eligibility: JoinEligibility.alreadyRequested,
        vibeScore: ownerScore,
        vibeFloor: floor,
        existingRequestId: existingRequest.id,
        matchResult: matchResult,
        ownerProfile: ownerProfile,
        playerProfile: playerProfile,
      );
    }

    // 7. Return requiresApproval with the score data and profiles for UI rendering
    AppLog.d('🚦 VibeFloorService: Score < floor — requires approval');
    return JoinEligibilityResult(
      eligibility: JoinEligibility.requiresApproval,
      vibeScore: ownerScore,
      vibeFloor: floor,
      matchResult: matchResult,
      ownerProfile: ownerProfile,
      playerProfile: playerProfile,
    );
  }
}
