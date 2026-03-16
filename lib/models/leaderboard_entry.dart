import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable model representing a single entry in the season leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.roundsPlayed,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromDoc(
    DocumentSnapshot doc, {
    required int rank,
    bool isCurrentUser = false,
  }) {
    final data = doc.data() as Map<String, dynamic>?;
    return LeaderboardEntry(
      rank: rank,
      userId: doc.id,
      displayName: (data?['display_name'] as String?) ?? '',
      photoUrl: (data?['photo_url'] as String?) ?? '',
      roundsPlayed: (data?['season_rounds_played'] as num?)?.toInt() ?? 0,
      isCurrentUser: isCurrentUser,
    );
  }

  final int rank;
  final String userId;
  final String displayName;
  final String photoUrl;
  final int roundsPlayed;
  final bool isCurrentUser;

  LeaderboardEntry copyWith({
    int? rank,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      roundsPlayed: roundsPlayed,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
