import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class HometownRecord extends FirestoreRecord {
  HometownRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "province" field.
  String? _province;
  String get province => _province ?? '';
  bool hasProvince() => _province != null;

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _province = snapshotData['province'] as String?;
    _location = snapshotData['location'] as LatLng?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('hometown');

  static Stream<HometownRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => HometownRecord.fromSnapshot(s));

  static Future<HometownRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => HometownRecord.fromSnapshot(s));

  static HometownRecord fromSnapshot(DocumentSnapshot snapshot) =>
      HometownRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static HometownRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      HometownRecord._(reference, mapFromFirestore(data));

  /// Stream all hometown records from Firestore.
  static Stream<List<HometownRecord>> streamAll() => collection
      .snapshots()
      .map((s) => s.docs.map((d) => HometownRecord.fromSnapshot(d)).toList());

  /// Fetch all hometown records once from Firestore.
  static Future<List<HometownRecord>> fetchAll() async {
    final snapshot = await collection.get();
    return snapshot.docs.map((d) => HometownRecord.fromSnapshot(d)).toList();
  }

  @override
  String toString() =>
      'HometownRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is HometownRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createHometownRecordData({
  String? name,
  String? province,
  LatLng? location,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'province': province,
      'location': location,
    }.withoutNulls,
  );

  return firestoreData;
}

class HometownRecordDocumentEquality implements Equality<HometownRecord> {
  const HometownRecordDocumentEquality();

  @override
  bool equals(HometownRecord? e1, HometownRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.province == e2?.province &&
        e1?.location == e2?.location;
  }

  @override
  int hash(HometownRecord? e) =>
      const ListEquality().hash([e?.name, e?.province, e?.location]);

  @override
  bool isValidKey(Object? o) => o is HometownRecord;
}
