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
    required this.type,
    required this.thumbnailUrl,
    this.imageWidth,
    this.imageHeight,
  });

  final String id;
  final String senderId;
  final String text;
  final String imageUrl;
  final String videoUrl;
  final DateTime? createdAt;
  final Map<String, List<String>> reactions; // emoji -> [userIds]
  final List<String> readBy;
  final String type;          // 'text' or 'image'
  final String thumbnailUrl;  // optional; falls back to imageUrl
  final double? imageWidth;   // stored pixel width for pre-sizing skeleton
  final double? imageHeight;  // stored pixel height for pre-sizing skeleton

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
      type: (data['type'] as String?) ?? 'text',
      thumbnailUrl: (data['thumbnailUrl'] as String?) ?? '',
      imageWidth: (data['imageWidth'] as num?)?.toDouble(),
      imageHeight: (data['imageHeight'] as num?)?.toDouble(),
    );
  }
}
