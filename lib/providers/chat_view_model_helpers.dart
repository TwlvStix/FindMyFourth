// Pure data classes for chat view model streams.
// Extracted from ChatProvider to keep it under the 500-line limit.

/// Member info for group avatar display.
class ChatMemberInfo {
  const ChatMemberInfo({
    required this.name,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
}

/// View model for chat list rows with resolved profile data.
///
/// This class combines Chat with resolved user profile data,
/// avoiding the need for nested builders in the UI and moving
/// profile fetching out of the build method.
class ChatRowViewModel {
  ChatRowViewModel({
    required this.chatId,
    required this.displayName,
    required this.photoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.members,
  });

  final String chatId;
  final String displayName;
  final String photoUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Members for group avatar display (1-4 members).
  final List<ChatMemberInfo> members;
}
