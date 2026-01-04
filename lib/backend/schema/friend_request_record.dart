import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/core/app_util.dart';

class FriendRequestRecord extends FirestoreRecord {
  FriendRequestRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "request_status" field.
  String? _requestStatus;
  String get requestStatus => _requestStatus ?? '';
  bool hasRequestStatus() => _requestStatus != null;

  // "receiver_id" field.
  DocumentReference? _receiverId;
  DocumentReference? get receiverId => _receiverId;
  bool hasReceiverId() => _receiverId != null;

  // "requester_id" field.
  DocumentReference? _requesterId;
  DocumentReference? get requesterId => _requesterId;
  bool hasRequesterId() => _requesterId != null;

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  void _initializeFields() {
    _requestStatus = snapshotData['request_status'] as String?;
    _receiverId = snapshotData['receiver_id'] as DocumentReference?;
    _requesterId = snapshotData['requester_id'] as DocumentReference?;
    _userRef = snapshotData['userRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('friend_request');

  static Stream<FriendRequestRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FriendRequestRecord.fromSnapshot(s));

  static Future<FriendRequestRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FriendRequestRecord.fromSnapshot(s));

  static FriendRequestRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FriendRequestRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FriendRequestRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FriendRequestRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FriendRequestRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FriendRequestRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFriendRequestRecordData({
  String? requestStatus,
  DocumentReference? receiverId,
  DocumentReference? requesterId,
  DocumentReference? userRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'request_status': requestStatus,
      'receiver_id': receiverId,
      'requester_id': requesterId,
      'userRef': userRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class FriendRequestRecordDocumentEquality
    implements Equality<FriendRequestRecord> {
  const FriendRequestRecordDocumentEquality();

  @override
  bool equals(FriendRequestRecord? e1, FriendRequestRecord? e2) {
    return e1?.requestStatus == e2?.requestStatus &&
        e1?.receiverId == e2?.receiverId &&
        e1?.requesterId == e2?.requesterId &&
        e1?.userRef == e2?.userRef;
  }

  @override
  int hash(FriendRequestRecord? e) => const ListEquality()
      .hash([e?.requestStatus, e?.receiverId, e?.requesterId, e?.userRef]);

  @override
  bool isValidKey(Object? o) => o is FriendRequestRecord;
}
