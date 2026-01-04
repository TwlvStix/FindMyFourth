import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "last_active_time" field.
  DateTime? _lastActiveTime;
  DateTime? get lastActiveTime => _lastActiveTime;
  bool hasLastActiveTime() => _lastActiveTime != null;

  // "handicap" field.
  int? _handicap;
  int get handicap => _handicap ?? 0;
  bool hasHandicap() => _handicap != null;

  // "home_course" field.
  String? _homeCourse;
  String get homeCourse => _homeCourse ?? '';
  bool hasHomeCourse() => _homeCourse != null;

  // "music" field.
  int? _music;
  int get music => _music ?? 0;
  bool hasMusic() => _music != null;

  // "drinks" field.
  int? _drinks;
  int get drinks => _drinks ?? 0;
  bool hasDrinks() => _drinks != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "first_name" field.
  String? _firstName;
  String get firstName => _firstName ?? '';
  bool hasFirstName() => _firstName != null;

  // "last_name" field.
  String? _lastName;
  String get lastName => _lastName ?? '';
  bool hasLastName() => _lastName != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "shortDescription" field.
  String? _shortDescription;
  String get shortDescription => _shortDescription ?? '';
  bool hasShortDescription() => _shortDescription != null;

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  bool hasRole() => _role != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "friends" field.
  List<DocumentReference>? _friends;
  List<DocumentReference> get friends => _friends ?? const [];
  bool hasFriends() => _friends != null;

  // "friend_requests" field.
  List<DocumentReference>? _friendRequests;
  List<DocumentReference> get friendRequests => _friendRequests ?? const [];
  bool hasFriendRequests() => _friendRequests != null;

  // "notify_all" field.
  bool? _notifyAll;
  bool get notifyAll => _notifyAll ?? false;
  bool hasNotifyAll() => _notifyAll != null;

  // "notify_money_game" field.
  bool? _notifyMoneyGame;
  bool get notifyMoneyGame => _notifyMoneyGame ?? false;
  bool hasNotifyMoneyGame() => _notifyMoneyGame != null;

  // "notify_vegas_game" field.
  bool? _notifyVegasGame;
  bool get notifyVegasGame => _notifyVegasGame ?? false;
  bool hasNotifyVegasGame() => _notifyVegasGame != null;

  // "notify_competitive_game" field.
  bool? _notifyCompetitiveGame;
  bool get notifyCompetitiveGame => _notifyCompetitiveGame ?? false;
  bool hasNotifyCompetitiveGame() => _notifyCompetitiveGame != null;

  // "notify_for_fun" field.
  bool? _notifyForFun;
  bool get notifyForFun => _notifyForFun ?? false;
  bool hasNotifyForFun() => _notifyForFun != null;

  // "notify_only_from_friends" field.
  bool? _notifyOnlyFromFriends;
  bool get notifyOnlyFromFriends => _notifyOnlyFromFriends ?? false;
  bool hasNotifyOnlyFromFriends() => _notifyOnlyFromFriends != null;

  // "notify_member_discount" field.
  bool? _notifyMemberDiscount;
  bool get notifyMemberDiscount => _notifyMemberDiscount ?? false;
  bool hasNotifyMemberDiscount() => _notifyMemberDiscount != null;

  // "notify_off" field.
  bool? _notifyOff;
  bool get notifyOff => _notifyOff ?? false;
  bool hasNotifyOff() => _notifyOff != null;

  // "pace_of_play" field.
  int? _paceOfPlay;
  int get paceOfPlay => _paceOfPlay ?? 0;
  bool hasPaceOfPlay() => _paceOfPlay != null;

  // "play_for_money" field.
  int? _playForMoney;
  int get playForMoney => _playForMoney ?? 0;
  bool hasPlayForMoney() => _playForMoney != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _lastActiveTime = snapshotData['last_active_time'] as DateTime?;
    _handicap = castToType<int>(snapshotData['handicap']);
    _homeCourse = snapshotData['home_course'] as String?;
    _music = castToType<int>(snapshotData['music']);
    _drinks = castToType<int>(snapshotData['drinks']);
    _uid = snapshotData['uid'] as String?;
    _firstName = snapshotData['first_name'] as String?;
    _lastName = snapshotData['last_name'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _shortDescription = snapshotData['shortDescription'] as String?;
    _role = snapshotData['role'] as String?;
    _title = snapshotData['title'] as String?;
    _friends = getDataList(snapshotData['friends']);
    _friendRequests = getDataList(snapshotData['friend_requests']);
    _notifyAll = snapshotData['notify_all'] as bool?;
    _notifyMoneyGame = snapshotData['notify_money_game'] as bool?;
    _notifyVegasGame = snapshotData['notify_vegas_game'] as bool?;
    _notifyCompetitiveGame = snapshotData['notify_competitive_game'] as bool?;
    _notifyForFun = snapshotData['notify_for_fun'] as bool?;
    _notifyOnlyFromFriends = snapshotData['notify_only_from_friends'] as bool?;
    _notifyMemberDiscount = snapshotData['notify_member_discount'] as bool?;
    _notifyOff = snapshotData['notify_off'] as bool?;
    _paceOfPlay = castToType<int>(snapshotData['pace_of_play']);
    _playForMoney = castToType<int>(snapshotData['play_for_money']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? email,
  String? photoUrl,
  DateTime? createdTime,
  String? phoneNumber,
  DateTime? lastActiveTime,
  int? handicap,
  String? homeCourse,
  int? music,
  int? drinks,
  String? uid,
  String? firstName,
  String? lastName,
  String? displayName,
  String? shortDescription,
  String? role,
  String? title,
  bool? notifyAll,
  bool? notifyMoneyGame,
  bool? notifyVegasGame,
  bool? notifyCompetitiveGame,
  bool? notifyForFun,
  bool? notifyOnlyFromFriends,
  bool? notifyMemberDiscount,
  bool? notifyOff,
  int? paceOfPlay,
  int? playForMoney,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'photo_url': photoUrl,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'last_active_time': lastActiveTime,
      'handicap': handicap,
      'home_course': homeCourse,
      'music': music,
      'drinks': drinks,
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'shortDescription': shortDescription,
      'role': role,
      'title': title,
      'notify_all': notifyAll,
      'notify_money_game': notifyMoneyGame,
      'notify_vegas_game': notifyVegasGame,
      'notify_competitive_game': notifyCompetitiveGame,
      'notify_for_fun': notifyForFun,
      'notify_only_from_friends': notifyOnlyFromFriends,
      'notify_member_discount': notifyMemberDiscount,
      'notify_off': notifyOff,
      'pace_of_play': paceOfPlay,
      'play_for_money': playForMoney,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    const listEquality = ListEquality();
    return e1?.email == e2?.email &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.lastActiveTime == e2?.lastActiveTime &&
        e1?.handicap == e2?.handicap &&
        e1?.homeCourse == e2?.homeCourse &&
        e1?.music == e2?.music &&
        e1?.drinks == e2?.drinks &&
        e1?.uid == e2?.uid &&
        e1?.firstName == e2?.firstName &&
        e1?.lastName == e2?.lastName &&
        e1?.displayName == e2?.displayName &&
        e1?.shortDescription == e2?.shortDescription &&
        e1?.role == e2?.role &&
        e1?.title == e2?.title &&
        listEquality.equals(e1?.friends, e2?.friends) &&
        listEquality.equals(e1?.friendRequests, e2?.friendRequests) &&
        e1?.notifyAll == e2?.notifyAll &&
        e1?.notifyMoneyGame == e2?.notifyMoneyGame &&
        e1?.notifyVegasGame == e2?.notifyVegasGame &&
        e1?.notifyCompetitiveGame == e2?.notifyCompetitiveGame &&
        e1?.notifyForFun == e2?.notifyForFun &&
        e1?.notifyOnlyFromFriends == e2?.notifyOnlyFromFriends &&
        e1?.notifyMemberDiscount == e2?.notifyMemberDiscount &&
        e1?.notifyOff == e2?.notifyOff &&
        e1?.paceOfPlay == e2?.paceOfPlay &&
        e1?.playForMoney == e2?.playForMoney;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.email,
        e?.photoUrl,
        e?.createdTime,
        e?.phoneNumber,
        e?.lastActiveTime,
        e?.handicap,
        e?.homeCourse,
        e?.music,
        e?.drinks,
        e?.uid,
        e?.firstName,
        e?.lastName,
        e?.displayName,
        e?.shortDescription,
        e?.role,
        e?.title,
        e?.friends,
        e?.friendRequests,
        e?.notifyAll,
        e?.notifyMoneyGame,
        e?.notifyVegasGame,
        e?.notifyCompetitiveGame,
        e?.notifyForFun,
        e?.notifyOnlyFromFriends,
        e?.notifyMemberDiscount,
        e?.notifyOff,
        e?.paceOfPlay,
        e?.playForMoney
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
