import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    required this.reactions,
    required this.readBy,
  });

  final String id;
  final String senderId;
  final String text;
  final String imageUrl;
  final String videoUrl;
  final DateTime? createdAt;
  final Map<String, List<String>> reactions; // emoji -> [userIds]
  final List<String> readBy;

  static ChatMessage fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      videoUrl: (data['videoUrl'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      reactions: (data['reactions'] as Map<String, dynamic>?)
              ?.map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>?)?.whereType<String>().toList() ?? <String>[],
                ),
              ) ??
          <String, List<String>>{},
      readBy: (data['readBy'] as List<dynamic>?)?.whereType<String>().toList() ?? <String>[],
    );
  }
}
