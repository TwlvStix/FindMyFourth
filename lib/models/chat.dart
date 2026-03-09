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
    required this.deletesAt,
    required this.typingUsers,
    required this.memberJoinedAt,
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
  final DateTime? deletesAt;
  final Map<String, DateTime> typingUsers;
  /// Per-member join timestamps. Used to implement "fresh start on rejoin":
  /// a member only sees messages with createdAt >= memberJoinedAt[uid].
  /// Null entry means the member has been present since chat creation (see all messages).
  final Map<String, DateTime> memberJoinedAt;

  static Chat fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final rawTypingUsers = data['typingUsers'];
    final typingUsers = <String, DateTime>{};
    if (rawTypingUsers is Map) {
      rawTypingUsers.forEach((key, value) {
        if (value is Timestamp) {
          typingUsers[key.toString()] = value.toDate();
        } else {
          assert(
            value == null || value is Timestamp,
            'Chat.fromDoc: typingUsers[$key] expected Timestamp or null, got ${value.runtimeType}',
          );
        }
      });
    }
    final rawMemberJoinedAt = data['memberJoinedAt'];
    final memberJoinedAt = <String, DateTime>{};
    if (rawMemberJoinedAt is Map) {
      rawMemberJoinedAt.forEach((key, value) {
        if (value is Timestamp) {
          memberJoinedAt[key.toString()] = value.toDate();
        }
      });
    }

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
      lastMessage: (data['lastMessage'] as String?) ??
          (data['last_message'] as String?) ??
          '',
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
      deletesAt: (data['deletesAt'] as Timestamp?)?.toDate(),
      typingUsers: typingUsers,
      memberJoinedAt: memberJoinedAt,
    );
  }
}
