import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class ChatMessagesRecord extends FirestoreRecord {
  ChatMessagesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "senderId" field.
  String? _senderId;
  String get senderId => _senderId ?? '';
  bool hasSenderId() => _senderId != null;

  // "text" field.
  String? _text;
  String get text => _text ?? '';
  bool hasText() => _text != null;

  // "imageUrl" field.
  String? _imageUrl;
  String get imageUrl => _imageUrl ?? '';
  bool hasImageUrl() => _imageUrl != null;

  // "videoUrl" field.
  String? _videoUrl;
  String get videoUrl => _videoUrl ?? '';
  bool hasVideoUrl() => _videoUrl != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "type" field.
  String? _type;
  String get type => _type ?? 'text';
  bool hasType() => _type != null;

  /// True if this is a system-generated message (no sender).
  bool get isSystemMessage => type == 'system';

  void _initializeFields() {
    _senderId = snapshotData['senderId'] as String?;
    _text = snapshotData['text'] as String?;
    _imageUrl = snapshotData['imageUrl'] as String?;
    _videoUrl = snapshotData['videoUrl'] as String?;
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _type = snapshotData['type'] as String?;
  }

  static Query get collection =>
      FirebaseFirestore.instance.collectionGroup('messages');

  static Stream<ChatMessagesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChatMessagesRecord.fromSnapshot(s));

  static Future<ChatMessagesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChatMessagesRecord.fromSnapshot(s));

  static ChatMessagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ChatMessagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatMessagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatMessagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatMessagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatMessagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatMessagesRecordData({
  String? senderId,
  String? text,
  String? imageUrl,
  String? videoUrl,
  DateTime? createdAt,
  String? type,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': createdAt,
      'type': type,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatMessagesRecordDocumentEquality
    implements Equality<ChatMessagesRecord> {
  const ChatMessagesRecordDocumentEquality();

  @override
  bool equals(ChatMessagesRecord? e1, ChatMessagesRecord? e2) {
    return e1?.senderId == e2?.senderId &&
        e1?.text == e2?.text &&
        e1?.imageUrl == e2?.imageUrl &&
        e1?.videoUrl == e2?.videoUrl &&
        e1?.createdAt == e2?.createdAt &&
        e1?.type == e2?.type;
  }

  @override
  int hash(ChatMessagesRecord? e) => const ListEquality().hash([
        e?.senderId,
        e?.text,
        e?.imageUrl,
        e?.videoUrl,
        e?.createdAt,
        e?.type,
      ]);

  @override
  bool isValidKey(Object? o) => o is ChatMessagesRecord;
}
