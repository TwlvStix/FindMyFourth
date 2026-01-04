import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/core/app_util.dart';

class AddPlayersRecord extends FirestoreRecord {
  AddPlayersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "create_time" field.
  DateTime? _createTime;
  DateTime? get createTime => _createTime;
  bool hasCreateTime() => _createTime != null;

  // "players" field.
  List<DocumentReference>? _players;
  List<DocumentReference> get players => _players ?? const [];
  bool hasPlayers() => _players != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _uid = snapshotData['uid'] as String?;
    _createTime = snapshotData['create_time'] as DateTime?;
    _players = getDataList(snapshotData['players']);
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('addPlayers')
          : FirebaseFirestore.instance.collectionGroup('addPlayers');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('addPlayers').doc(id);

  static Stream<AddPlayersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AddPlayersRecord.fromSnapshot(s));

  static Future<AddPlayersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AddPlayersRecord.fromSnapshot(s));

  static AddPlayersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AddPlayersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AddPlayersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AddPlayersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AddPlayersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AddPlayersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAddPlayersRecordData({
  String? uid,
  DateTime? createTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'uid': uid,
      'create_time': createTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class AddPlayersRecordDocumentEquality implements Equality<AddPlayersRecord> {
  const AddPlayersRecordDocumentEquality();

  @override
  bool equals(AddPlayersRecord? e1, AddPlayersRecord? e2) {
    const listEquality = ListEquality();
    return e1?.uid == e2?.uid &&
        e1?.createTime == e2?.createTime &&
        listEquality.equals(e1?.players, e2?.players);
  }

  @override
  int hash(AddPlayersRecord? e) =>
      const ListEquality().hash([e?.uid, e?.createTime, e?.players]);

  @override
  bool isValidKey(Object? o) => o is AddPlayersRecord;
}
