import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/utils/app_util.dart';

class ChatsRecord extends FirestoreRecord {
  ChatsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "users" field.
  List<DocumentReference>? _users;
  List<DocumentReference> get users => _users ?? const [];
  bool hasUsers() => _users != null;

  // "memberIds" field.
  List<String>? _memberIds;
  List<String> get memberIds => _memberIds ?? const [];
  bool hasMemberIds() => _memberIds != null;

  // "user_a" field.
  DocumentReference? _userA;
  DocumentReference? get userA => _userA;
  bool hasUserA() => _userA != null;

  // "user_b" field.
  DocumentReference? _userB;
  DocumentReference? get userB => _userB;
  bool hasUserB() => _userB != null;

  // "lastMessage" field.
  String? _lastMessage;
  String get lastMessage => _lastMessage ?? '';
  bool hasLastMessage() => _lastMessage != null;

  // "lastMessageAt" field.
  DateTime? _lastMessageAt;
  DateTime? get lastMessageAt => _lastMessageAt;
  bool hasLastMessageAt() => _lastMessageAt != null;

  /// Compatibility getters for the legacy naming.
  DateTime? get lastMessageTime => lastMessageAt;
  bool hasLastMessageTime() => hasLastMessageAt();

  // "lastMessageSenderId" field.
  String? _lastMessageSenderId;
  String get lastMessageSenderId => _lastMessageSenderId ?? '';
  bool hasLastMessageSenderId() => _lastMessageSenderId != null;

  // Legacy DocumentReference for back-compat.
  DocumentReference? _lastMessageSentBy;
  DocumentReference? get lastMessageSentBy => _lastMessageSentBy;
  bool hasLastMessageSentBy() => _lastMessageSentBy != null;

  // "lastMessageSeenBy" field.
  List<DocumentReference>? _lastMessageSeenBy;
  List<DocumentReference> get lastMessageSeenBy =>
      _lastMessageSeenBy ?? const [];
  bool hasLastMessageSeenBy() => _lastMessageSeenBy != null;

  // "group_chat_id" field.
  int? _groupChatId;
  int get groupChatId => _groupChatId ?? 0;
  bool hasGroupChatId() => _groupChatId != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "directKey" field.
  String? _directKey;
  String get directKey => _directKey ?? '';
  bool hasDirectKey() => _directKey != null;

  // "gameId" field.
  String? _gameId;
  String get gameId => _gameId ?? '';
  bool hasGameId() => _gameId != null;

  // "unreadCountByUser" field.
  Map<String, int>? _unreadCountByUser;
  Map<String, int> get unreadCountByUser => _unreadCountByUser ?? const {};
  bool hasUnreadCountByUser() => _unreadCountByUser != null;

  // "createdAt" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updatedAt" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  void _initializeFields() {
    _users = getDataList(snapshotData['users']);
    _memberIds = (snapshotData['memberIds'] as List?)
        ?.whereType<String>()
        .toList();
    _userA = snapshotData['user_a'] as DocumentReference?;
    _userB = snapshotData['user_b'] as DocumentReference?;
    _type = snapshotData['type'] as String?;
    _directKey = snapshotData['directKey'] as String?;
    _gameId = snapshotData['gameId'] as String?;
    _lastMessage = snapshotData['lastMessage'] as String? ??
        snapshotData['last_message'] as String?;
    _lastMessageAt = snapshotData['lastMessageAt'] as DateTime? ??
        snapshotData['last_message_time'] as DateTime?;
    _lastMessageSenderId = snapshotData['lastMessageSenderId'] as String?;
    _lastMessageSentBy = _lastMessageSenderId != null
        ? FirebaseFirestore.instance.doc('users/$_lastMessageSenderId')
        : null;
    _lastMessageSeenBy =
        getDataList(snapshotData['lastMessageSeenBy']) ??
            getDataList(snapshotData['last_message_seen_by']);
    _groupChatId = castToType<int>(snapshotData['group_chat_id']);
    _unreadCountByUser = (snapshotData['unreadCountByUser']
            as Map<String, dynamic>?)
        ?.map((key, value) =>
            MapEntry(key, (value as num?)?.toInt() ?? 0));
    _createdAt = snapshotData['createdAt'] as DateTime?;
    _updatedAt = snapshotData['updatedAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('chats');

  static Stream<ChatsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ChatsRecord.fromSnapshot(s));

  static Future<ChatsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ChatsRecord.fromSnapshot(s));

  static ChatsRecord fromSnapshot(DocumentSnapshot snapshot) => ChatsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ChatsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ChatsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ChatsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ChatsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createChatsRecordData({
  DocumentReference? userA,
  DocumentReference? userB,
  List<String>? memberIds,
  String? type,
  String? directKey,
  String? gameId,
  String? lastMessage,
  DateTime? lastMessageAt,
  String? lastMessageSenderId,
  int? groupChatId,
  Map<String, int>? unreadCountByUser,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'user_a': userA,
      'user_b': userB,
      'memberIds': memberIds,
      'type': type,
      'directKey': directKey,
      'gameId': gameId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'lastMessageSenderId': lastMessageSenderId,
      'group_chat_id': groupChatId,
      'unreadCountByUser': unreadCountByUser,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class ChatsRecordDocumentEquality implements Equality<ChatsRecord> {
  const ChatsRecordDocumentEquality();

  @override
  bool equals(ChatsRecord? e1, ChatsRecord? e2) {
    const listEquality = ListEquality();
    return listEquality.equals(e1?.users, e2?.users) &&
        listEquality.equals(e1?.memberIds, e2?.memberIds) &&
        e1?.userA == e2?.userA &&
        e1?.userB == e2?.userB &&
        e1?.lastMessage == e2?.lastMessage &&
        e1?.lastMessageAt == e2?.lastMessageAt &&
        e1?.lastMessageSenderId == e2?.lastMessageSenderId &&
        listEquality.equals(e1?.lastMessageSeenBy, e2?.lastMessageSeenBy) &&
        e1?.groupChatId == e2?.groupChatId;
  }

  @override
  int hash(ChatsRecord? e) => const ListEquality().hash([
        e?.users,
        e?.userA,
        e?.userB,
        e?.memberIds,
        e?.lastMessage,
        e?.lastMessageAt,
        e?.lastMessageSenderId,
        e?.lastMessageSeenBy,
        e?.groupChatId,
        e?.type,
        e?.directKey,
        e?.gameId,
        e?.unreadCountByUser,
        e?.createdAt,
        e?.updatedAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is ChatsRecord;
}
