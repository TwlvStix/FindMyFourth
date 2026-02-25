import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/games_record.dart';
import '/models/player_eligibility.dart';

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
    required this.scheduleType,
    required this.isFunGame,
    required this.playerEligibility,
    this.flexibleDays,
    this.flexibleTimeOfDay,
    this.flexibleWeek,
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
  final String scheduleType;
  final bool isFunGame;
  final PlayerEligibility playerEligibility;
  final List<int>? flexibleDays;
  final String? flexibleTimeOfDay;
  final String? flexibleWeek;

  static String resolveGameStatus({
    required String rawStatus,
    required bool isCancelled,
    required String scheduleType,
    required DateTime? date,
    required DateTime? createdTime,
    required String? flexibleWeek,
  }) {
    if (rawStatus != 'active') {
      return rawStatus;
    }

    if (isCancelled) {
      return 'cancelled';
    }

    if (scheduleType == 'flexible') {
      // Flexible game expiration logic
      if (flexibleWeek == 'this_week') {
        final endOfWeek = _getEndOfWeek(DateTime.now());
        if (DateTime.now().isAfter(endOfWeek)) {
          return 'expired';
        }
      } else if (flexibleWeek == 'next_week') {
        final endOfNextWeek =
            _getEndOfWeek(DateTime.now().add(Duration(days: 7)));
        if (DateTime.now().isAfter(endOfNextWeek)) {
          return 'expired';
        }
      } else if (flexibleWeek == 'flexible' && createdTime != null) {
        // Expire after 30 days
        final expireDate = createdTime.add(Duration(days: 30));
        if (DateTime.now().isAfter(expireDate)) {
          return 'expired';
        }
      }
    } else if (date != null && date.isBefore(DateTime.now())) {
      // Confirmed game expiration logic
      return 'expired';
    }

    return rawStatus;
  }

  static Game fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Parse raw fields
    final scheduleType = (data['schedule_type'] as String?) ?? 'confirmed';
    final rawStatus = (data['status'] as String?) ?? 'active';
    final isCancelled = (data['isCancelled'] as bool?) ?? false;
    final gameDate = (data['date'] as Timestamp?)?.toDate();
    final createdTime = (data['created_time'] as Timestamp?)?.toDate();
    final flexibleWeek = data['flexible_week'] as String?;

    // Resolve status using shared logic
    final gameStatus = resolveGameStatus(
      rawStatus: rawStatus,
      isCancelled: isCancelled,
      scheduleType: scheduleType,
      date: gameDate,
      createdTime: createdTime,
      flexibleWeek: flexibleWeek,
    );

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
      scheduleType: scheduleType,
      isFunGame: (data['is_fun_game'] as bool?) ?? false,
      playerEligibility: PlayerEligibilityExtension.fromFirestoreValue(
        data['player_eligibility'] as String?,
      ),
      flexibleDays: (data['flexible_days'] as List<dynamic>?)
              ?.whereType<int>()
              .toList(),
      flexibleTimeOfDay: data['flexible_time_of_day'] as String?,
      flexibleWeek: data['flexible_week'] as String?,
    );
  }

  static Game fromRecord(GamesRecord record) {
    final rawStatus = record.snapshotData['status'] as String? ?? 'active';

    // Resolve status using shared logic
    final gameStatus = resolveGameStatus(
      rawStatus: rawStatus,
      isCancelled: record.isCancelled,
      scheduleType: record.scheduleType,
      date: record.date,
      createdTime: record.createdTime,
      flexibleWeek: record.flexibleWeek,
    );

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
      scheduleType: record.scheduleType,
      isFunGame: record.isFunGame,
      playerEligibility: PlayerEligibilityExtension.fromFirestoreValue(
        record.playerEligibility,
      ),
      flexibleDays: record.flexibleDays.isEmpty ? null : record.flexibleDays,
      flexibleTimeOfDay: record.flexibleTimeOfDay,
      flexibleWeek: record.flexibleWeek,
    );
  }

  // Helper getters
  bool get isActive => status == 'active';
  bool get isCancelledStatus => status == 'cancelled';
  bool get isExpired => status == 'expired';
  bool get isCompleted => status == 'completed';
  bool get isFlexible => scheduleType == 'flexible';
  bool get isConfirmed => scheduleType == 'confirmed';

  String get flexibleSummary {
    if (!isFlexible) return '';

    final parts = <String>[];

    if (flexibleWeek != null) {
      switch (flexibleWeek) {
        case 'this_week':
          parts.add('This Week');
          break;
        case 'next_week':
          parts.add('Next Week');
          break;
        case 'flexible':
          parts.add('Flexible');
          break;
      }
    }

    if (flexibleDays != null && flexibleDays!.isNotEmpty) {
      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      parts.add(flexibleDays!.map((d) => dayNames[d]).join(', '));
    }

    if (flexibleTimeOfDay != null) {
      switch (flexibleTimeOfDay) {
        case 'morning':
          parts.add('Morning');
          break;
        case 'afternoon':
          parts.add('Afternoon');
          break;
        case 'twilight':
          parts.add('Twilight');
          break;
      }
    }

    return parts.isEmpty ? 'Flexible' : parts.join(' · ');
  }

  static DateTime _getEndOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day + (7 - date.weekday),
      23,
      59,
      59,
    );
  }
}
