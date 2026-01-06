import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class VerificationDashRecord extends FirestoreRecord {
  VerificationDashRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "usernames" field.
  List<String>? _usernames;
  List<String> get usernames => _usernames ?? const [];
  bool hasUsernames() => _usernames != null;

  void _initializeFields() {
    _usernames = getDataList(snapshotData['usernames']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('VerificationDash');

  static Stream<VerificationDashRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => VerificationDashRecord.fromSnapshot(s));

  static Future<VerificationDashRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => VerificationDashRecord.fromSnapshot(s));

  static VerificationDashRecord fromSnapshot(DocumentSnapshot snapshot) =>
      VerificationDashRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static VerificationDashRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      VerificationDashRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'VerificationDashRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is VerificationDashRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createVerificationDashRecordData() {
  final firestoreData = mapToFirestore(
    <String, dynamic>{}.withoutNulls,
  );

  return firestoreData;
}

class VerificationDashRecordDocumentEquality
    implements Equality<VerificationDashRecord> {
  const VerificationDashRecordDocumentEquality();

  @override
  bool equals(VerificationDashRecord? e1, VerificationDashRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.usernames, e2?.usernames);
  }

  @override
  int hash(VerificationDashRecord? e) =>
      const ListEquality().hash([e?.usernames]);

  @override
  bool isValidKey(Object? o) => o is VerificationDashRecord;
}
