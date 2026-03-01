import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class CourseRecord extends FirestoreRecord {
  CourseRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "picture" field.
  String? _picture;
  String get picture => _picture ?? '';
  bool hasPicture() => _picture != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _location = snapshotData['location'] as LatLng?;
    _picture = snapshotData['picture'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('course');

  static Stream<CourseRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CourseRecord.fromSnapshot(s));

  static Future<CourseRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CourseRecord.fromSnapshot(s));

  static CourseRecord fromSnapshot(DocumentSnapshot snapshot) => CourseRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CourseRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CourseRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CourseRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CourseRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCourseRecordData({
  String? name,
  LatLng? location,
  String? picture,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'location': location,
      'picture': picture,
    }.withoutNulls,
  );

  return firestoreData;
}

class CourseRecordDocumentEquality implements Equality<CourseRecord> {
  const CourseRecordDocumentEquality();

  @override
  bool equals(CourseRecord? e1, CourseRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.location == e2?.location &&
        e1?.picture == e2?.picture;
  }

  @override
  int hash(CourseRecord? e) =>
      const ListEquality().hash([e?.name, e?.location, e?.picture]);

  @override
  bool isValidKey(Object? o) => o is CourseRecord;
}
