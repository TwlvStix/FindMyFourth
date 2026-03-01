import '/models/chat_message.dart';

/// View model for chat messages with resolved profile data.
///
/// This combines a [ChatMessage] with sender display metadata so UI layers
/// can render message rows without nested profile builders.
class ChatMessageViewModel {
  ChatMessageViewModel({
    required this.message,
    required this.senderDisplayName,
    required this.senderPhotoUrl,
  });

  final ChatMessage message;
  final String senderDisplayName;
  final String senderPhotoUrl;

  String get id => message.id;
  String get senderId => message.senderId;
  String get text => message.text;
  String get imageUrl => message.imageUrl;
  String get videoUrl => message.videoUrl;
  DateTime? get createdAt => message.createdAt;
  Map<String, List<String>> get reactions => message.reactions;
  List<String> get readBy => message.readBy;

  ChatMessageViewModel copyWith({
    ChatMessage? message,
    String? senderDisplayName,
    String? senderPhotoUrl,
  }) {
    return ChatMessageViewModel(
      message: message ?? this.message,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }
}
