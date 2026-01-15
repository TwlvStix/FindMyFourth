import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  Chat({
    required this.id,
    required this.memberIds,
    required this.type,
    required this.directKey,
    required this.gameId,
    required this.gameName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    required this.unreadCountByUser,
    required this.createdAt,
    required this.updatedAt,
    required this.isReadOnly,
    required this.pinnedMessage,
    required this.pinnedAt,
    required this.archivedAt,
    required this.typingUsers,
  });

  final String id;
  final List<String> memberIds;
  final String type;
  final String? directKey;
  final String? gameId;
  final String? gameName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCountByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isReadOnly;
  final String pinnedMessage;
  final DateTime? pinnedAt;
  final DateTime? archivedAt;
  final Map<String, DateTime> typingUsers;

  static Chat fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Chat(
      id: doc.id,
      memberIds: (data['memberIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          <String>[],
      type: (data['type'] as String?) ?? 'direct',
      directKey: data['directKey'] as String?,
      gameId: data['gameId'] as String?,
      gameName: data['gameName'] as String?,
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCountByUser: (data['unreadCountByUser']
                  as Map<String, dynamic>?)
              ?.map(
                (key, value) =>
                    MapEntry(key, (value as num?)?.toInt() ?? 0),
              ) ??
          <String, int>{},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isReadOnly: (data['isReadOnly'] as bool?) ?? false,
      pinnedMessage: (data['pinnedMessage'] as String?) ?? '',
      pinnedAt: (data['pinnedAt'] as Timestamp?)?.toDate(),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
      typingUsers: (data['typingUsers'] as Map<String, dynamic>?)
              ?.map(
                (key, value) =>
                    MapEntry(key, (value as Timestamp).toDate()),
              ) ??
          <String, DateTime>{},
    );
  }
}
