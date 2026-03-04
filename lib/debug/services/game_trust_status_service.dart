import 'package:cloud_firestore/cloud_firestore.dart';

/// Status indicators for trust flow prerequisites.
class GameTrustStatus {
  final int participantCount;
  final bool hasRoundJob;
  final bool hasAttendanceRecords;

  const GameTrustStatus({
    required this.participantCount,
    required this.hasRoundJob,
    required this.hasAttendanceRecords,
  });

  /// Valid for HostCheckin if game has joined participants.
  bool get validForHostCheckin => participantCount > 0;

  /// Valid for PeerRating if round_job exists and attendance has been recorded.
  bool get validForPeerRating => hasRoundJob && hasAttendanceRecords;

  static const empty = GameTrustStatus(
    participantCount: 0,
    hasRoundJob: false,
    hasAttendanceRecords: false,
  );
}

/// Service to check trust flow prerequisites for games.
///
/// Used by debug screens to show which games are valid test candidates
/// for HostCheckin and PeerRating screens.
class GameTrustStatusService {
  final FirebaseFirestore _firestore;

  GameTrustStatusService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches trust status for a game by checking:
  /// - Participant count from game_participants
  /// - Whether round_jobs document exists
  /// - Whether attendance_records have been populated
  Future<GameTrustStatus> fetchGameTrustStatus(
    DocumentReference gameRef,
  ) async {
    // Run queries in parallel for efficiency
    final results = await Future.wait([
      _getParticipantCount(gameRef),
      _checkRoundJobAndAttendance(gameRef),
    ]);

    final participantCount = results[0] as int;
    final roundStatus = results[1] as _RoundStatus;

    return GameTrustStatus(
      participantCount: participantCount,
      hasRoundJob: roundStatus.hasRoundJob,
      hasAttendanceRecords: roundStatus.hasAttendanceRecords,
    );
  }

  /// Fetches trust status for multiple games.
  Future<Map<String, GameTrustStatus>> fetchStatusesForGames(
    List<DocumentReference> gameRefs,
  ) async {
    final statuses = await Future.wait(
      gameRefs.map((ref) => fetchGameTrustStatus(ref)),
    );

    return Map.fromIterables(
      gameRefs.map((ref) => ref.id),
      statuses,
    );
  }

  Future<int> _getParticipantCount(DocumentReference gameRef) async {
    final snap = await _firestore
        .collection('game_participants')
        .where('game_ref', isEqualTo: gameRef)
        .where('status', isEqualTo: 'joined')
        .count()
        .get();

    return snap.count ?? 0;
  }

  Future<_RoundStatus> _checkRoundJobAndAttendance(
    DocumentReference gameRef,
  ) async {
    // Check if round_jobs document exists for this game
    final jobSnap = await _firestore
        .collection('round_jobs')
        .where('game_ref', isEqualTo: gameRef)
        .limit(1)
        .get();

    if (jobSnap.docs.isEmpty) {
      return const _RoundStatus(
        hasRoundJob: false,
        hasAttendanceRecords: false,
      );
    }

    // Get the round_ref and check for attendance_records
    final job = jobSnap.docs.first.data();
    final roundRef = job['round_ref'] as DocumentReference?;

    if (roundRef == null) {
      return const _RoundStatus(
        hasRoundJob: true,
        hasAttendanceRecords: false,
      );
    }

    final roundSnap = await roundRef.get();
    if (!roundSnap.exists) {
      return const _RoundStatus(
        hasRoundJob: true,
        hasAttendanceRecords: false,
      );
    }

    final roundData = roundSnap.data() as Map<String, dynamic>?;
    final attendanceRecords =
        roundData?['attendance_records'] as Map<String, dynamic>?;

    return _RoundStatus(
      hasRoundJob: true,
      hasAttendanceRecords:
          attendanceRecords != null && attendanceRecords.isNotEmpty,
    );
  }
}

class _RoundStatus {
  final bool hasRoundJob;
  final bool hasAttendanceRecords;

  const _RoundStatus({
    required this.hasRoundJob,
    required this.hasAttendanceRecords,
  });
}
