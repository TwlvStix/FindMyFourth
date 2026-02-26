import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class GamesRecord extends FirestoreRecord {
  GamesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name_game" field.
  String? _nameGame;
  String get nameGame => _nameGame ?? '';
  bool hasNameGame() => _nameGame != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "num_players" field.
  int? _numPlayers;
  int get numPlayers => _numPlayers ?? 0;
  bool hasNumPlayers() => _numPlayers != null;

  // "style_game" field.
  String? _styleGame;
  String get styleGame => _styleGame ?? '';
  bool hasStyleGame() => _styleGame != null;

  // "game_type" field.
  String? _gameType;
  String get gameType => _gameType ?? '';
  bool hasGameType() => _gameType != null;

  // "course_play" field.
  String? _coursePlay;
  String get coursePlay => _coursePlay ?? '';
  bool hasCoursePlay() => _coursePlay != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "member_discount" field.
  String? _memberDiscount;
  String get memberDiscount => _memberDiscount ?? '';
  bool hasMemberDiscount() => _memberDiscount != null;

  // "scoring" field.
  String? _scoring;
  String get scoring => _scoring ?? '';
  bool hasScoring() => _scoring != null;

  // "max_players" field.
  int? _maxPlayers;
  int get maxPlayers => _maxPlayers ?? 0;
  bool hasMaxPlayers() => _maxPlayers != null;

  // "courseRef" field.
  DocumentReference? _courseRef;
  DocumentReference? get courseRef => _courseRef;
  bool hasCourseRef() => _courseRef != null;

  // "friend_game" field.
  String? _friendGame;
  String get friendGame => _friendGame ?? '';
  bool hasFriendGame() => _friendGame != null;

  // "joined_players" field.
  List<DocumentReference>? _joinedPlayers;
  List<DocumentReference> get joinedPlayers => _joinedPlayers ?? const [];
  bool hasJoinedPlayers() => _joinedPlayers != null;

  // "guest_players" field.
  List<String>? _guestPlayers;
  List<String> get guestPlayers => _guestPlayers ?? const [];
  bool hasGuestPlayers() => _guestPlayers != null;

  // "rules_setting" field.
  String? _rulesSetting;
  String get rulesSetting => _rulesSetting ?? '';
  bool hasRulesSetting() => _rulesSetting != null;

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "chatRef" field.
  DocumentReference? _chatRef;
  DocumentReference? get chatRef => _chatRef;
  bool hasChatRef() => _chatRef != null;

  // "isCancelled" field.
  bool? _isCancelled;
  bool get isCancelled => _isCancelled ?? false;
  bool hasIsCancelled() => _isCancelled != null;

  // "cancelled_at" field.
  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _cancelledAt;
  bool hasCancelledAt() => _cancelledAt != null;

  // "schedule_type" field.
  String? _scheduleType;
  String get scheduleType => _scheduleType ?? 'confirmed';
  bool hasScheduleType() => _scheduleType != null;

  // "flexible_days" field.
  List<int>? _flexibleDays;
  List<int> get flexibleDays => _flexibleDays ?? const [];
  bool hasFlexibleDays() => _flexibleDays != null;

  // "flexible_time_of_day" field.
  String? _flexibleTimeOfDay;
  String? get flexibleTimeOfDay => _flexibleTimeOfDay;
  bool hasFlexibleTimeOfDay() => _flexibleTimeOfDay != null;

  // "flexible_week" field.
  String? _flexibleWeek;
  String? get flexibleWeek => _flexibleWeek;
  bool hasFlexibleWeek() => _flexibleWeek != null;

  // "flexible_start_date" field. Concrete start date for flexible games.
  DateTime? _flexibleStartDate;
  DateTime? get flexibleStartDate => _flexibleStartDate;
  bool hasFlexibleStartDate() => _flexibleStartDate != null;

  // "flexible_end_date" field. Concrete end date for flexible games.
  DateTime? _flexibleEndDate;
  DateTime? get flexibleEndDate => _flexibleEndDate;
  bool hasFlexibleEndDate() => _flexibleEndDate != null;

  // "is_fun_game" field.
  bool? _isFunGame;
  bool get isFunGame => _isFunGame ?? false;
  bool hasIsFunGame() => _isFunGame != null;

  // "status" field. Lifecycle: open > filled > played > verified | expired.
  // Existing games use 'active'. Default kept as 'active' for backward compatibility.
  String? _status;
  String get status => _status ?? 'active';
  bool hasStatus() => _status != null;

  // "min_app_users" field. Minimum app users required to create the game.
  int? _minAppUsers;
  int get minAppUsers => _minAppUsers ?? 2;
  bool hasMinAppUsers() => _minAppUsers != null;

  // "app_user_count" field. Count of non-guest participants.
  int? _appUserCount;
  int get appUserCount => _appUserCount ?? 0;
  bool hasAppUserCount() => _appUserCount != null;

  // "guest_count" field. Count of guest spots filled.
  int? _guestCount;
  int get guestCount => _guestCount ?? 0;
  bool hasGuestCount() => _guestCount != null;

  // "verified_at" field. Timestamp when round was verified.
  DateTime? _verifiedAt;
  DateTime? get verifiedAt => _verifiedAt;
  bool hasVerifiedAt() => _verifiedAt != null;

  // "verification_status" field.
  String? _verificationStatus;
  String get verificationStatus => _verificationStatus ?? 'pending';
  bool hasVerificationStatus() => _verificationStatus != null;

  // "player_eligibility" field.
  String? _playerEligibility;
  String get playerEligibility => _playerEligibility ?? 'open_to_all';
  bool hasPlayerEligibility() => _playerEligibility != null;

  void _initializeFields() {
    _nameGame = snapshotData['name_game'] as String?;
    _date = snapshotData['date'] as DateTime?;
    _numPlayers = castToType<int>(snapshotData['num_players']);
    _styleGame = snapshotData['style_game'] as String?;
    _gameType = snapshotData['game_type'] as String?;
    _coursePlay = snapshotData['course_play'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _memberDiscount = snapshotData['member_discount'] as String?;
    _scoring = snapshotData['scoring'] as String?;
    _maxPlayers = castToType<int>(snapshotData['max_players']);
    _courseRef = snapshotData['courseRef'] as DocumentReference?;
    _friendGame = snapshotData['friend_game'] as String?;
    _joinedPlayers = getDataList(snapshotData['joined_players']);
    _guestPlayers = getDataList(snapshotData['guest_players']);
    _rulesSetting = snapshotData['rules_setting'] as String?;
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _uid = snapshotData['uid'] as String?;
    _chatRef = snapshotData['chatRef'] as DocumentReference?;
    _isCancelled = snapshotData['isCancelled'] as bool?;
    _cancelledAt = snapshotData['cancelled_at'] as DateTime?;
    _scheduleType = snapshotData['schedule_type'] as String?;
    _flexibleDays = getDataList(snapshotData['flexible_days']);
    _flexibleTimeOfDay = snapshotData['flexible_time_of_day'] as String?;
    _flexibleWeek = snapshotData['flexible_week'] as String?;
    _flexibleStartDate = snapshotData['flexible_start_date'] as DateTime?;
    _flexibleEndDate = snapshotData['flexible_end_date'] as DateTime?;
    _isFunGame = snapshotData['is_fun_game'] as bool?;
    _status = snapshotData['status'] as String?;
    _minAppUsers = castToType<int>(snapshotData['min_app_users']);
    _appUserCount = castToType<int>(snapshotData['app_user_count']);
    _guestCount = castToType<int>(snapshotData['guest_count']);
    _verifiedAt = snapshotData['verified_at'] as DateTime?;
    _verificationStatus = snapshotData['verification_status'] as String?;
    _playerEligibility = snapshotData['player_eligibility'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('games');

  static Stream<GamesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GamesRecord.fromSnapshot(s));

  static Future<GamesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => GamesRecord.fromSnapshot(s));

  static GamesRecord fromSnapshot(DocumentSnapshot snapshot) => GamesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GamesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GamesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GamesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GamesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createGamesRecordData({
  String? nameGame,
  DateTime? date,
  int? numPlayers,
  String? styleGame,
  String? gameType,
  String? coursePlay,
  DateTime? createdTime,
  String? memberDiscount,
  String? scoring,
  int? maxPlayers,
  DocumentReference? courseRef,
  String? friendGame,
  List<String>? guestPlayers,
  String? rulesSetting,
  DocumentReference? userRef,
  String? uid,
  DocumentReference? chatRef,
  bool? isCancelled,
  DateTime? cancelledAt,
  String? scheduleType,
  List<int>? flexibleDays,
  String? flexibleTimeOfDay,
  String? flexibleWeek,
  DateTime? flexibleStartDate,
  DateTime? flexibleEndDate,
  bool? isFunGame,
  String? status,
  int? minAppUsers,
  int? appUserCount,
  int? guestCount,
  DateTime? verifiedAt,
  String? verificationStatus,
  String? playerEligibility,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name_game': nameGame,
      'date': date,
      'num_players': numPlayers,
      'style_game': styleGame,
      'game_type': gameType,
      'course_play': coursePlay,
      'created_time': createdTime,
      'member_discount': memberDiscount,
      'scoring': scoring,
      'max_players': maxPlayers,
      'courseRef': courseRef,
      'friend_game': friendGame,
      'guest_players': guestPlayers,
      'rules_setting': rulesSetting,
      'userRef': userRef,
      'uid': uid,
      'chatRef': chatRef,
      'isCancelled': isCancelled,
      'cancelled_at': cancelledAt,
      'schedule_type': scheduleType,
      'flexible_days': flexibleDays,
      'flexible_time_of_day': flexibleTimeOfDay,
      'flexible_week': flexibleWeek,
      'flexible_start_date': flexibleStartDate,
      'flexible_end_date': flexibleEndDate,
      'is_fun_game': isFunGame,
      'status': status,
      'min_app_users': minAppUsers,
      'app_user_count': appUserCount,
      'guest_count': guestCount,
      'verified_at': verifiedAt,
      'verification_status': verificationStatus,
      'player_eligibility': playerEligibility,
    }.withoutNulls,
  );

  return firestoreData;
}

class GamesRecordDocumentEquality implements Equality<GamesRecord> {
  const GamesRecordDocumentEquality();

  @override
  bool equals(GamesRecord? e1, GamesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.nameGame == e2?.nameGame &&
        e1?.date == e2?.date &&
        e1?.numPlayers == e2?.numPlayers &&
        e1?.styleGame == e2?.styleGame &&
        e1?.gameType == e2?.gameType &&
        e1?.coursePlay == e2?.coursePlay &&
        e1?.createdTime == e2?.createdTime &&
        e1?.memberDiscount == e2?.memberDiscount &&
        e1?.scoring == e2?.scoring &&
        e1?.maxPlayers == e2?.maxPlayers &&
        e1?.courseRef == e2?.courseRef &&
        e1?.friendGame == e2?.friendGame &&
        listEquality.equals(e1?.joinedPlayers, e2?.joinedPlayers) &&
        e1?.rulesSetting == e2?.rulesSetting &&
        e1?.userRef == e2?.userRef &&
        e1?.uid == e2?.uid &&
        e1?.chatRef == e2?.chatRef &&
        e1?.isCancelled == e2?.isCancelled &&
        e1?.cancelledAt == e2?.cancelledAt &&
        e1?.flexibleStartDate == e2?.flexibleStartDate &&
        e1?.flexibleEndDate == e2?.flexibleEndDate &&
        e1?.isFunGame == e2?.isFunGame &&
        e1?.status == e2?.status &&
        e1?.minAppUsers == e2?.minAppUsers &&
        e1?.appUserCount == e2?.appUserCount &&
        e1?.guestCount == e2?.guestCount &&
        e1?.verifiedAt == e2?.verifiedAt &&
        e1?.verificationStatus == e2?.verificationStatus &&
        e1?.playerEligibility == e2?.playerEligibility;
  }

  @override
  int hash(GamesRecord? e) => const ListEquality().hash([
        e?.nameGame,
        e?.date,
        e?.numPlayers,
        e?.styleGame,
        e?.gameType,
        e?.coursePlay,
        e?.createdTime,
        e?.memberDiscount,
        e?.scoring,
        e?.maxPlayers,
        e?.courseRef,
        e?.friendGame,
        e?.joinedPlayers,
        e?.rulesSetting,
        e?.userRef,
        e?.uid,
        e?.chatRef,
        e?.isCancelled,
        e?.cancelledAt,
        e?.flexibleStartDate,
        e?.flexibleEndDate,
        e?.isFunGame,
        e?.status,
        e?.minAppUsers,
        e?.appUserCount,
        e?.guestCount,
        e?.verifiedAt,
        e?.verificationStatus,
        e?.playerEligibility,
      ]);

  @override
  bool isValidKey(Object? o) => o is GamesRecord;
}
