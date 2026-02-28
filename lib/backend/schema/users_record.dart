import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "last_active_time" field.
  DateTime? _lastActiveTime;
  DateTime? get lastActiveTime => _lastActiveTime;
  bool hasLastActiveTime() => _lastActiveTime != null;

  // "handicap" field.
  int? _handicap;
  int get handicap => _handicap ?? 0;
  bool hasHandicap() => _handicap != null;

  // "golf_canada_number" field.
  String? _golfCanadaNumber;
  String get golfCanadaNumber => _golfCanadaNumber ?? '';
  bool hasGolfCanadaNumber() => _golfCanadaNumber != null;

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

  // "vibe_profile" field.
  Map<String, dynamic>? _vibeProfile;
  Map<String, dynamic> get vibeProfile => _vibeProfile ?? const {};
  bool hasVibeProfile() => _vibeProfile != null;

  // "onboarding_completed" field.
  bool? _onboardingCompleted;
  bool get onboardingCompleted => _onboardingCompleted ?? false;
  bool hasOnboardingCompleted() => _onboardingCompleted != null;

  // "profile_completeness" field.
  int? _profileCompleteness;
  int get profileCompleteness => _profileCompleteness ?? 0;
  bool hasProfileCompleteness() => _profileCompleteness != null;

  // "total_verified_rounds" field.
  int? _totalVerifiedRounds;
  int get totalVerifiedRounds => _totalVerifiedRounds ?? 0;
  bool hasTotalVerifiedRounds() => _totalVerifiedRounds != null;

  // "unique_co_players" field. Array of UIDs of app users played with.
  List<String>? _uniqueCoPlayers;
  List<String> get uniqueCoPlayers => _uniqueCoPlayers ?? const [];
  bool hasUniqueCoPlayers() => _uniqueCoPlayers != null;

  // "games_hosted" field.
  int? _gamesHosted;
  int get gamesHosted => _gamesHosted ?? 0;
  bool hasGamesHosted() => _gamesHosted != null;

  // "show_up_rate" field. Null until player has 5+ verified rounds.
  double? _showUpRate;
  double? get showUpRate => _showUpRate;
  bool hasShowUpRate() => _showUpRate != null;

  // "badge_level" field.
  String? _badgeLevel;
  String get badgeLevel => _badgeLevel ?? 'new';
  bool hasBadgeLevel() => _badgeLevel != null;

  // "verified_round_count" field. Canonical count written by confirmation_flow.js.
  // Note: total_verified_rounds is a separate (unpopulated) field kept for compat.
  int? _verifiedRoundCount;
  int get verifiedRoundCount => _verifiedRoundCount ?? 0;
  bool hasVerifiedRoundCount() => _verifiedRoundCount != null;

  // "weighted_rounds" field. Computed by trust_profile.js Stage 5.
  double? _weightedRounds;
  double get weightedRounds => _weightedRounds ?? 0.0;
  bool hasWeightedRounds() => _weightedRounds != null;

  // "cancellation_warning" field. True when 2+ bad cancels in rolling 90 days.
  bool? _cancellationWarning;
  bool get cancellationWarning => _cancellationWarning ?? false;
  bool hasCancellationWarning() => _cancellationWarning != null;

  // "cancellation_warning_count" field. Count of late/day_of/ghost in last 90 days.
  int? _cancellationWarningCount;
  int get cancellationWarningCount => _cancellationWarningCount ?? 0;
  bool hasCancellationWarningCount() => _cancellationWarningCount != null;

  // "cancellation_rate" field. 0.0–1.0, computed by Stage 5. Null until data exists.
  double? _cancellationRate;
  double? get cancellationRate => _cancellationRate;
  bool hasCancellationRate() => _cancellationRate != null;

  // "show_up_rate_denominator" field. Total commitments used alongside show_up_rate.
  int? _showUpRateDenominator;
  int get showUpRateDenominator => _showUpRateDenominator ?? 0;
  bool hasShowUpRateDenominator() => _showUpRateDenominator != null;

  // "gender" field.
  String? _gender;
  String get gender => _gender ?? '';
  bool hasGender() => _gender != null;

  // "date_of_birth" field.
  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;
  bool hasDateOfBirth() => _dateOfBirth != null;

  // "vibe_edit_count" field. Number of times user has confirmed vibe profile edits.
  int? _vibeEditCount;
  int get vibeEditCount => _vibeEditCount ?? 0;
  bool hasVibeEditCount() => _vibeEditCount != null;

  // "last_vibe_edit_at" field. Timestamp of most recent vibe profile confirmation.
  DateTime? _lastVibeEditAt;
  DateTime? get lastVibeEditAt => _lastVibeEditAt;
  bool hasLastVibeEditAt() => _lastVibeEditAt != null;

  void _initializeFields() {
    _photoUrl = snapshotData['photo_url'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _lastActiveTime = snapshotData['last_active_time'] as DateTime?;
    _handicap = castToType<int>(snapshotData['handicap']);
    _golfCanadaNumber = snapshotData['golf_canada_number'] as String?;
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
    final friendsRaw = snapshotData['friends'];
    if (friendsRaw is List) {
      _friends = friendsRaw
          .map((item) {
            if (item is DocumentReference) {
              return item;
            }
            if (item is String && item.isNotEmpty) {
              return UsersRecord.collection.doc(item);
            }
            return null;
          })
          .whereType<DocumentReference>()
          .toList();
    } else {
      _friends = getDataList(snapshotData['friends']);
    }
    final friendRequestsRaw = snapshotData['friend_requests'];
    if (friendRequestsRaw is List) {
      _friendRequests = friendRequestsRaw
          .map((item) {
            if (item is DocumentReference) {
              return item;
            }
            if (item is String && item.isNotEmpty) {
              return UsersRecord.collection.doc(item);
            }
            return null;
          })
          .whereType<DocumentReference>()
          .toList();
    } else {
      _friendRequests = getDataList(snapshotData['friend_requests']);
    }
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
    final vibeProfileRaw = snapshotData['vibe_profile'];
    if (vibeProfileRaw is Map) {
      _vibeProfile = Map<String, dynamic>.from(vibeProfileRaw);
    }
    _onboardingCompleted = snapshotData['onboarding_completed'] as bool?;
    _profileCompleteness = castToType<int>(snapshotData['profile_completeness']);
    _totalVerifiedRounds = castToType<int>(snapshotData['total_verified_rounds']);
    _uniqueCoPlayers = getDataList(snapshotData['unique_co_players']);
    _gamesHosted = castToType<int>(snapshotData['games_hosted']);
    _showUpRate = castToType<double>(snapshotData['show_up_rate']);
    _badgeLevel = snapshotData['badge_level'] as String?;
    _verifiedRoundCount =
        castToType<int>(snapshotData['verified_round_count']);
    _weightedRounds = castToType<double>(snapshotData['weighted_rounds']);
    _cancellationWarning = snapshotData['cancellation_warning'] as bool?;
    _cancellationWarningCount =
        castToType<int>(snapshotData['cancellation_warning_count']);
    _cancellationRate = castToType<double>(snapshotData['cancellation_rate']);
    _showUpRateDenominator =
        castToType<int>(snapshotData['show_up_rate_denominator']);
    _gender = snapshotData['gender'] as String?;
    _dateOfBirth = snapshotData['date_of_birth'] as DateTime?;
    _vibeEditCount = castToType<int>(snapshotData['vibe_edit_count']);
    _lastVibeEditAt = snapshotData['last_vibe_edit_at'] as DateTime?;
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
  String? photoUrl,
  DateTime? createdTime,
  DateTime? lastActiveTime,
  int? handicap,
  String? golfCanadaNumber,
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
  Map<String, dynamic>? vibeProfile,
  bool? onboardingCompleted,
  List<String>? friends,
  List<String>? friendRequests,
  int? profileCompleteness,
  int? totalVerifiedRounds,
  List<String>? uniqueCoPlayers,
  int? gamesHosted,
  double? showUpRate,
  String? badgeLevel,
  int? verifiedRoundCount,
  double? weightedRounds,
  bool? cancellationWarning,
  int? cancellationWarningCount,
  double? cancellationRate,
  int? showUpRateDenominator,
  String? gender,
  DateTime? dateOfBirth,
  int? vibeEditCount,
  DateTime? lastVibeEditAt,
}) {
  final displayNameLower = displayName?.toLowerCase();
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'photo_url': photoUrl,
      'created_time': createdTime,
      'last_active_time': lastActiveTime,
      'handicap': handicap,
      'golf_canada_number': golfCanadaNumber,
      'home_course': homeCourse,
      'music': music,
      'drinks': drinks,
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'display_name_lower': displayNameLower,
      'display_name_lowercase': displayNameLower,
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
      'vibe_profile': vibeProfile,
      'onboarding_completed': onboardingCompleted,
      'friends': friends,
      'friend_requests': friendRequests,
      'profile_completeness': profileCompleteness,
      'total_verified_rounds': totalVerifiedRounds,
      'unique_co_players': uniqueCoPlayers,
      'games_hosted': gamesHosted,
      'show_up_rate': showUpRate,
      'badge_level': badgeLevel,
      'verified_round_count': verifiedRoundCount,
      'weighted_rounds': weightedRounds,
      'cancellation_warning': cancellationWarning,
      'cancellation_warning_count': cancellationWarningCount,
      'cancellation_rate': cancellationRate,
      'show_up_rate_denominator': showUpRateDenominator,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'vibe_edit_count': vibeEditCount,
      'last_vibe_edit_at': lastVibeEditAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    const listEquality = ListEquality();
    const mapEquality = DeepCollectionEquality();
    return e1?.photoUrl == e2?.photoUrl &&
        e1?.createdTime == e2?.createdTime &&
        e1?.lastActiveTime == e2?.lastActiveTime &&
        e1?.handicap == e2?.handicap &&
        e1?.golfCanadaNumber == e2?.golfCanadaNumber &&
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
        e1?.playForMoney == e2?.playForMoney &&
        mapEquality.equals(e1?.vibeProfile, e2?.vibeProfile) &&
        e1?.onboardingCompleted == e2?.onboardingCompleted &&
        e1?.profileCompleteness == e2?.profileCompleteness &&
        e1?.totalVerifiedRounds == e2?.totalVerifiedRounds &&
        listEquality.equals(e1?.uniqueCoPlayers, e2?.uniqueCoPlayers) &&
        e1?.gamesHosted == e2?.gamesHosted &&
        e1?.showUpRate == e2?.showUpRate &&
        e1?.badgeLevel == e2?.badgeLevel &&
        e1?.verifiedRoundCount == e2?.verifiedRoundCount &&
        e1?.weightedRounds == e2?.weightedRounds &&
        e1?.cancellationWarning == e2?.cancellationWarning &&
        e1?.cancellationWarningCount == e2?.cancellationWarningCount &&
        e1?.cancellationRate == e2?.cancellationRate &&
        e1?.showUpRateDenominator == e2?.showUpRateDenominator &&
        e1?.gender == e2?.gender &&
        e1?.dateOfBirth == e2?.dateOfBirth &&
        e1?.vibeEditCount == e2?.vibeEditCount &&
        e1?.lastVibeEditAt == e2?.lastVibeEditAt;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.photoUrl,
        e?.createdTime,
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
        e?.playForMoney,
        const DeepCollectionEquality().hash(e?.vibeProfile),
        e?.onboardingCompleted,
        e?.profileCompleteness,
        e?.totalVerifiedRounds,
        e?.uniqueCoPlayers,
        e?.gamesHosted,
        e?.showUpRate,
        e?.badgeLevel,
        e?.verifiedRoundCount,
        e?.weightedRounds,
        e?.cancellationWarning,
        e?.cancellationWarningCount,
        e?.cancellationRate,
        e?.showUpRateDenominator,
        e?.gender,
        e?.dateOfBirth,
        e?.vibeEditCount,
        e?.lastVibeEditAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
