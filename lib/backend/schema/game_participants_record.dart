import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class GameParticipantsRecord extends FirestoreRecord {
  GameParticipantsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "game_ref" field.
  DocumentReference? _gameRef;
  DocumentReference? get gameRef => _gameRef;
  bool hasGameRef() => _gameRef != null;

  // "user_ref" field. Null for guest participants.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "guest_name" field. Non-null only when userRef is null (guest slot).
  String? _guestName;
  String? get guestName => _guestName;
  bool hasGuestName() => _guestName != null;

  // "role" field. 'host' | 'player' | 'guest'
  String? _role;
  String get role => _role ?? 'player';
  bool hasRole() => _role != null;

  // "status" field. 'joined' | 'cancelled' | 'no_show'
  String? _status;
  String get status => _status ?? 'joined';
  bool hasStatus() => _status != null;

  // "joined_at" field.
  DateTime? _joinedAt;
  DateTime? get joinedAt => _joinedAt;
  bool hasJoinedAt() => _joinedAt != null;

  // "cancelled_at" field. Null unless participant cancelled.
  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _cancelledAt;
  bool hasCancelledAt() => _cancelledAt != null;

  void _initializeFields() {
    _gameRef = snapshotData['game_ref'] as DocumentReference?;
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _guestName = snapshotData['guest_name'] as String?;
    _role = snapshotData['role'] as String?;
    _status = snapshotData['status'] as String?;
    _joinedAt = snapshotData['joined_at'] as DateTime?;
    _cancelledAt = snapshotData['cancelled_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('game_participants');

  static Stream<GameParticipantsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GameParticipantsRecord.fromSnapshot(s));

  static Future<GameParticipantsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => GameParticipantsRecord.fromSnapshot(s));

  static GameParticipantsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      GameParticipantsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GameParticipantsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GameParticipantsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GameParticipantsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GameParticipantsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createGameParticipantsRecordData({
  DocumentReference? gameRef,
  DocumentReference? userRef,
  String? guestName,
  String? role,
  String? status,
  DateTime? joinedAt,
  DateTime? cancelledAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'game_ref': gameRef,
      'user_ref': userRef,
      'guest_name': guestName,
      'role': role,
      'status': status,
      'joined_at': joinedAt,
      'cancelled_at': cancelledAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class GameParticipantsRecordDocumentEquality
    implements Equality<GameParticipantsRecord> {
  const GameParticipantsRecordDocumentEquality();

  @override
  bool equals(GameParticipantsRecord? e1, GameParticipantsRecord? e2) {
    return e1?.gameRef == e2?.gameRef &&
        e1?.userRef == e2?.userRef &&
        e1?.guestName == e2?.guestName &&
        e1?.role == e2?.role &&
        e1?.status == e2?.status &&
        e1?.joinedAt == e2?.joinedAt &&
        e1?.cancelledAt == e2?.cancelledAt;
  }

  @override
  int hash(GameParticipantsRecord? e) => const ListEquality().hash([
        e?.gameRef,
        e?.userRef,
        e?.guestName,
        e?.role,
        e?.status,
        e?.joinedAt,
        e?.cancelledAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is GameParticipantsRecord;
}
