import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime? date;
  final DateTime? createdTime;
  final DocumentReference? chatRef;
  final DocumentReference? courseRef;
  final DocumentReference? userRef;
  final String uid;

  static Game fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
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
      date: (data['date'] as Timestamp?)?.toDate(),
      createdTime: (data['created_time'] as Timestamp?)?.toDate(),
      chatRef: data['chatRef'] as DocumentReference?,
      courseRef: data['courseRef'] as DocumentReference?,
      userRef: data['userRef'] as DocumentReference?,
      uid: (data['uid'] as String?) ?? doc.id,
    );
  }
}
