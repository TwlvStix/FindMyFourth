import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/games_record.dart';

class Game {
  Game({
    required this.reference,
    required this.nameGame,
    required this.coursePlay,
    required this.gameType,
    required this.styleGame,
    required this.rulesSetting,
    required this.scoring,
    required this.memberDiscount,
    required this.friendGame,
    required this.numPlayers,
    required this.maxPlayers,
    required this.joinedPlayers,
    required this.guestPlayers,
    required this.isCancelled,
    required this.status,
    required this.date,
    required this.createdTime,
    required this.chatRef,
    required this.courseRef,
    required this.userRef,
    required this.uid,
  });

  final DocumentReference reference;
  final String nameGame;
  final String coursePlay;
  final String gameType;
  final String styleGame;
  final String rulesSetting;
  final String scoring;
  final String memberDiscount;
  final String friendGame;
  final int numPlayers;
  final int maxPlayers;
  final List<DocumentReference> joinedPlayers;
  final List<String> guestPlayers;
  final bool isCancelled;
  final String status; // 'active', 'completed', 'cancelled', 'expired'
  final DateTime? date;
  final DateTime? createdTime;
  final DocumentReference? chatRef;
  final DocumentReference? courseRef;
  final DocumentReference? userRef;
  final String uid;

  static Game fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    // For backward compatibility, derive status from isCancelled if status field doesn't exist
    String gameStatus = (data['status'] as String?) ?? 'active';
    if (gameStatus == 'active') {
      // Check if game should be marked as expired based on date
      final gameDate = (data['date'] as Timestamp?)?.toDate();
      final isCancelled = (data['isCancelled'] as bool?) ?? false;

      if (isCancelled) {
        gameStatus = 'cancelled';
      } else if (gameDate != null && gameDate.isBefore(DateTime.now())) {
        gameStatus = 'expired';
      }
    }

    return Game(
      reference: doc.reference,
      nameGame: (data['name_game'] as String?) ?? '',
      coursePlay: (data['course_play'] as String?) ?? '',
      gameType: (data['game_type'] as String?) ?? '',
      styleGame: (data['style_game'] as String?) ?? '',
      rulesSetting: (data['rules_setting'] as String?) ?? '',
      scoring: (data['scoring'] as String?) ?? '',
      memberDiscount: (data['member_discount'] as String?) ?? '',
      friendGame: (data['friend_game'] as String?) ?? '',
      numPlayers: (data['num_players'] as int?) ?? 0,
      maxPlayers: (data['max_players'] as int?) ?? 0,
      joinedPlayers: (data['joined_players'] as List<dynamic>?)
              ?.whereType<DocumentReference>()
              .toList() ??
          [],
      guestPlayers: (data['guest_players'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
      isCancelled: (data['isCancelled'] as bool?) ?? false,
      status: gameStatus,
      date: (data['date'] as Timestamp?)?.toDate(),
      createdTime: (data['created_time'] as Timestamp?)?.toDate(),
      chatRef: data['chatRef'] as DocumentReference?,
      courseRef: data['courseRef'] as DocumentReference?,
      userRef: data['userRef'] as DocumentReference?,
      uid: (data['uid'] as String?) ?? doc.id,
    );
  }

  static Game fromRecord(GamesRecord record) {
    String gameStatus = record.snapshotData['status'] as String? ?? 'active';
    if (gameStatus == 'active') {
      final gameDate = record.date;
      final isCancelled = record.isCancelled;

      if (isCancelled) {
        gameStatus = 'cancelled';
      } else if (gameDate != null && gameDate.isBefore(DateTime.now())) {
        gameStatus = 'expired';
      }
    }

    return Game(
      reference: record.reference,
      nameGame: record.nameGame,
      coursePlay: record.coursePlay,
      gameType: record.gameType,
      styleGame: record.styleGame,
      rulesSetting: record.rulesSetting,
      scoring: record.scoring,
      memberDiscount: record.memberDiscount,
      friendGame: record.friendGame,
      numPlayers: record.numPlayers,
      maxPlayers: record.maxPlayers,
      joinedPlayers: record.joinedPlayers,
      guestPlayers: record.guestPlayers,
      isCancelled: record.isCancelled,
      status: gameStatus,
      date: record.date,
      createdTime: record.createdTime,
      chatRef: record.chatRef,
      courseRef: record.courseRef,
      userRef: record.userRef,
      uid: record.uid,
    );
  }

  // Helper getters
  bool get isActive => status == 'active';
  bool get isCancelledStatus => status == 'cancelled';
  bool get isExpired => status == 'expired';
  bool get isCompleted => status == 'completed';
}
