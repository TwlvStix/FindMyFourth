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
  final String type; // 'text', 'image', or 'system'
  final String thumbnailUrl; // optional; falls back to imageUrl

  /// True if this is a system-generated message (no sender).
  bool get isSystemMessage => type == 'system';
  final double? imageWidth; // stored pixel width for pre-sizing skeleton
  final double? imageHeight; // stored pixel height for pre-sizing skeleton

  static ChatMessage fromDoc(dynamic doc) {
    final data = _asMap(doc.data()) ?? <String, dynamic>{};
    return ChatMessage(
      id: _docId(doc),
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      videoUrl: (data['videoUrl'] as String?) ?? '',
      createdAt: _asDateTime(data['createdAt']),
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>?)?.whereType<String>().toList() ??
                  <String>[],
            ),
          ) ??
          <String, List<String>>{},
      readBy:
          (data['readBy'] as List<dynamic>?)?.whereType<String>().toList() ??
              <String>[],
      type: (data['type'] as String?) ?? 'text',
      thumbnailUrl: (data['thumbnailUrl'] as String?) ?? '',
      imageWidth: (data['imageWidth'] as num?)?.toDouble(),
      imageHeight: (data['imageHeight'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }

  static String _docId(dynamic doc) {
    final dynamic id = doc.id;
    if (id is String) {
      return id;
    }
    return '';
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    try {
      final converted = (value as dynamic).toDate();
      return converted is DateTime ? converted : null;
    } catch (_) {
      return null;
    }
  }
}
