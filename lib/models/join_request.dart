import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a join request
enum JoinRequestStatus {
  pending,
  approved,
  denied,
  expired;

  String get key => name;

  static JoinRequestStatus fromKey(String? key) {
    switch (key) {
      case 'approved':
        return JoinRequestStatus.approved;
      case 'denied':
        return JoinRequestStatus.denied;
      case 'expired':
        return JoinRequestStatus.expired;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

/// A request from a player to join a game that requires owner approval
///
/// Created when a player's vibe score is below the game owner's vibe floor.
/// The owner can approve or deny the request.
class JoinRequest {
  final String id;
  final String gameId;
  final String requesterId;
  final String ownerId;
  final double requesterVibeScore;
  final int vibeFloor;
  final JoinRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const JoinRequest({
    required this.id,
    required this.gameId,
    required this.requesterId,
    required this.ownerId,
    required this.requesterVibeScore,
    required this.vibeFloor,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Create from Firestore document snapshot
  factory JoinRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JoinRequest(
      id: doc.id,
      gameId: data['gameId'] as String? ?? '',
      requesterId: data['requesterId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      requesterVibeScore: (data['requesterVibeScore'] as num?)?.toDouble() ?? 0,
      vibeFloor: data['vibeFloor'] as int? ?? 30,
      status: JoinRequestStatus.fromKey(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'requesterVibeScore': requesterVibeScore,
      'vibeFloor': vibeFloor,
      'status': status.key,
      'createdAt': FieldValue.serverTimestamp(),
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
    };
  }

  /// Create a copy with updated fields
  JoinRequest copyWith({
    String? id,
    String? gameId,
    String? requesterId,
    String? ownerId,
    double? requesterVibeScore,
    int? vibeFloor,
    JoinRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      requesterId: requesterId ?? this.requesterId,
      ownerId: ownerId ?? this.ownerId,
      requesterVibeScore: requesterVibeScore ?? this.requesterVibeScore,
      vibeFloor: vibeFloor ?? this.vibeFloor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  bool get isPending => status == JoinRequestStatus.pending;
  bool get isApproved => status == JoinRequestStatus.approved;
  bool get isDenied => status == JoinRequestStatus.denied;
  bool get isExpired => status == JoinRequestStatus.expired;

  @override
  String toString() =>
      'JoinRequest(id: $id, gameId: $gameId, requesterId: $requesterId, status: ${status.key})';
}
