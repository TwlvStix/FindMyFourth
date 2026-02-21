import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class CancellationRecordsRecord extends FirestoreRecord {
  CancellationRecordsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "player_ref" field.
  DocumentReference? _playerRef;
  DocumentReference? get playerRef => _playerRef;
  bool hasPlayerRef() => _playerRef != null;

  // "game_ref" field.
  DocumentReference? _gameRef;
  DocumentReference? get gameRef => _gameRef;
  bool hasGameRef() => _gameRef != null;

  // "cancelled_at" field.
  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _cancelledAt;
  bool hasCancelledAt() => _cancelledAt != null;

  // "tee_time" field. Copy of the game's tee time at time of cancellation.
  DateTime? _teeTime;
  DateTime? get teeTime => _teeTime;
  bool hasTeeTime() => _teeTime != null;

  // "hours_before_tee_time" field. Calculated at write time by Cloud Function.
  double? _hoursBeforeTeeTime;
  double? get hoursBeforeTeeTime => _hoursBeforeTeeTime;
  bool hasHoursBeforeTeeTime() => _hoursBeforeTeeTime != null;

  // "tier" field. 'early' | 'late' | 'day_of'. Computed and stored by Cloud Function.
  String? _tier;
  String get tier => _tier ?? 'day_of';
  bool hasTier() => _tier != null;

  // "game_type" field. Denormalized from game for querying.
  String? _gameType;
  String get gameType => _gameType ?? '';
  bool hasGameType() => _gameType != null;

  // "is_ghost" field. True for no-shows marked after tee time passed.
  bool? _isGhost;
  bool get isGhost => _isGhost ?? false;
  bool hasIsGhost() => _isGhost != null;

  void _initializeFields() {
    _playerRef = snapshotData['player_ref'] as DocumentReference?;
    _gameRef = snapshotData['game_ref'] as DocumentReference?;
    _cancelledAt = snapshotData['cancelled_at'] as DateTime?;
    _teeTime = snapshotData['tee_time'] as DateTime?;
    _hoursBeforeTeeTime =
        castToType<double>(snapshotData['hours_before_tee_time']);
    _tier = snapshotData['tier'] as String?;
    _gameType = snapshotData['game_type'] as String?;
    _isGhost = snapshotData['is_ghost'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('cancellation_records');

  static Stream<CancellationRecordsRecord> getDocument(
          DocumentReference ref) =>
      ref.snapshots().map((s) => CancellationRecordsRecord.fromSnapshot(s));

  static Future<CancellationRecordsRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => CancellationRecordsRecord.fromSnapshot(s));

  static CancellationRecordsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CancellationRecordsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CancellationRecordsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CancellationRecordsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CancellationRecordsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CancellationRecordsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCancellationRecordsRecordData({
  DocumentReference? playerRef,
  DocumentReference? gameRef,
  DateTime? cancelledAt,
  DateTime? teeTime,
  double? hoursBeforeTeeTime,
  String? tier,
  String? gameType,
  bool? isGhost,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'player_ref': playerRef,
      'game_ref': gameRef,
      'cancelled_at': cancelledAt,
      'tee_time': teeTime,
      'hours_before_tee_time': hoursBeforeTeeTime,
      'tier': tier,
      'game_type': gameType,
      'is_ghost': isGhost,
    }.withoutNulls,
  );

  return firestoreData;
}

class CancellationRecordsRecordDocumentEquality
    implements Equality<CancellationRecordsRecord> {
  const CancellationRecordsRecordDocumentEquality();

  @override
  bool equals(CancellationRecordsRecord? e1, CancellationRecordsRecord? e2) {
    return e1?.playerRef == e2?.playerRef &&
        e1?.gameRef == e2?.gameRef &&
        e1?.cancelledAt == e2?.cancelledAt &&
        e1?.teeTime == e2?.teeTime &&
        e1?.hoursBeforeTeeTime == e2?.hoursBeforeTeeTime &&
        e1?.tier == e2?.tier &&
        e1?.gameType == e2?.gameType &&
        e1?.isGhost == e2?.isGhost;
  }

  @override
  int hash(CancellationRecordsRecord? e) => const ListEquality().hash([
        e?.playerRef,
        e?.gameRef,
        e?.cancelledAt,
        e?.teeTime,
        e?.hoursBeforeTeeTime,
        e?.tier,
        e?.gameType,
        e?.isGhost,
      ]);

  @override
  bool isValidKey(Object? o) => o is CancellationRecordsRecord;
}
