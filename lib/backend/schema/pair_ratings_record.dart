import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class PairRatingsRecord extends FirestoreRecord {
  PairRatingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "rater_ref" field. The player who submitted the rating.
  DocumentReference? _raterRef;
  DocumentReference? get raterRef => _raterRef;
  bool hasRaterRef() => _raterRef != null;

  // "rated_ref" field. The player being rated.
  DocumentReference? _ratedRef;
  DocumentReference? get ratedRef => _ratedRef;
  bool hasRatedRef() => _ratedRef != null;

  // "game_ref" field.
  DocumentReference? _gameRef;
  DocumentReference? get gameRef => _gameRef;
  bool hasGameRef() => _gameRef != null;

  // "round_ref" field.
  DocumentReference? _roundRef;
  DocumentReference? get roundRef => _roundRef;
  bool hasRoundRef() => _roundRef != null;

  // "would_play_again" field. Thumbs up / thumbs down.
  // Backend only — never displayed publicly. Feeds Phase 3 vibe matching ML.
  bool? _wouldPlayAgain;
  bool get wouldPlayAgain => _wouldPlayAgain ?? false;
  bool hasWouldPlayAgain() => _wouldPlayAgain != null;

  // "rated_at" field.
  DateTime? _ratedAt;
  DateTime? get ratedAt => _ratedAt;
  bool hasRatedAt() => _ratedAt != null;

  // "game_type" field. Denormalized for querying.
  String? _gameType;
  String get gameType => _gameType ?? '';
  bool hasGameType() => _gameType != null;

  void _initializeFields() {
    _raterRef = snapshotData['rater_ref'] as DocumentReference?;
    _ratedRef = snapshotData['rated_ref'] as DocumentReference?;
    _gameRef = snapshotData['game_ref'] as DocumentReference?;
    _roundRef = snapshotData['round_ref'] as DocumentReference?;
    _wouldPlayAgain = snapshotData['would_play_again'] as bool?;
    _ratedAt = snapshotData['rated_at'] as DateTime?;
    _gameType = snapshotData['game_type'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('pair_ratings');

  static Stream<PairRatingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PairRatingsRecord.fromSnapshot(s));

  static Future<PairRatingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PairRatingsRecord.fromSnapshot(s));

  static PairRatingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PairRatingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PairRatingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PairRatingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PairRatingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PairRatingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPairRatingsRecordData({
  DocumentReference? raterRef,
  DocumentReference? ratedRef,
  DocumentReference? gameRef,
  DocumentReference? roundRef,
  bool? wouldPlayAgain,
  DateTime? ratedAt,
  String? gameType,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'rater_ref': raterRef,
      'rated_ref': ratedRef,
      'game_ref': gameRef,
      'round_ref': roundRef,
      'would_play_again': wouldPlayAgain,
      'rated_at': ratedAt,
      'game_type': gameType,
    }.withoutNulls,
  );

  return firestoreData;
}

class PairRatingsRecordDocumentEquality
    implements Equality<PairRatingsRecord> {
  const PairRatingsRecordDocumentEquality();

  @override
  bool equals(PairRatingsRecord? e1, PairRatingsRecord? e2) {
    return e1?.raterRef == e2?.raterRef &&
        e1?.ratedRef == e2?.ratedRef &&
        e1?.gameRef == e2?.gameRef &&
        e1?.roundRef == e2?.roundRef &&
        e1?.wouldPlayAgain == e2?.wouldPlayAgain &&
        e1?.ratedAt == e2?.ratedAt &&
        e1?.gameType == e2?.gameType;
  }

  @override
  int hash(PairRatingsRecord? e) => const ListEquality().hash([
        e?.raterRef,
        e?.ratedRef,
        e?.gameRef,
        e?.roundRef,
        e?.wouldPlayAgain,
        e?.ratedAt,
        e?.gameType,
      ]);

  @override
  bool isValidKey(Object? o) => o is PairRatingsRecord;
}
