import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/core/app_util.dart';

class RolesRecord extends FirestoreRecord {
  RolesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "role_id" field.
  String? _roleId;
  String get roleId => _roleId ?? '';
  bool hasRoleId() => _roleId != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "members" field.
  List<String>? _members;
  List<String> get members => _members ?? const [];
  bool hasMembers() => _members != null;

  void _initializeFields() {
    _createdTime = snapshotData['created_time'] as DateTime?;
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _roleId = snapshotData['role_id'] as String?;
    _name = snapshotData['name'] as String?;
    _members = getDataList(snapshotData['members']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('roles');

  static Stream<RolesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => RolesRecord.fromSnapshot(s));

  static Future<RolesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => RolesRecord.fromSnapshot(s));

  static RolesRecord fromSnapshot(DocumentSnapshot snapshot) => RolesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static RolesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      RolesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'RolesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is RolesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createRolesRecordData({
  DateTime? createdTime,
  DocumentReference? userRef,
  String? roleId,
  String? name,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'created_time': createdTime,
      'userRef': userRef,
      'role_id': roleId,
      'name': name,
    }.withoutNulls,
  );

  return firestoreData;
}

class RolesRecordDocumentEquality implements Equality<RolesRecord> {
  const RolesRecordDocumentEquality();

  @override
  bool equals(RolesRecord? e1, RolesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.createdTime == e2?.createdTime &&
        e1?.userRef == e2?.userRef &&
        e1?.roleId == e2?.roleId &&
        e1?.name == e2?.name &&
        listEquality.equals(e1?.members, e2?.members);
  }

  @override
  int hash(RolesRecord? e) => const ListEquality()
      .hash([e?.createdTime, e?.userRef, e?.roleId, e?.name, e?.members]);

  @override
  bool isValidKey(Object? o) => o is RolesRecord;
}
