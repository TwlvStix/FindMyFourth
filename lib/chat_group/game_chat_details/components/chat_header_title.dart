import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/models/chat.dart';
import '/providers/profile_provider.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_text.dart';

/// Chat header title component displaying appropriate title based on chat type.
///
/// Displays:
/// - Game name for game chats
/// - Other user's name and avatar for 1:1 chats
/// - "Group Chat" for group chats
/// - "Chat" for empty chats
///
/// Generic for any chat context - not game-specific.
class ChatHeaderTitle extends StatelessWidget {
  final Chat chat;
  final String? currentUserId;

  const ChatHeaderTitle({
    super.key,
    required this.chat,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Game chat: show game name
    if (chat.type == 'game') {
      final title =
          (chat.gameName ?? '').trim().isNotEmpty ? chat.gameName! : 'Group Chat';
      return AppText.cardTitle(title);
    }

    final memberIds = chat.memberIds;

    // Empty or single-member chat
    if (memberIds.length <= 1) {
      return AppText.cardTitle('Chat');
    }

    // 1:1 chat: show other user's name and avatar
    if (memberIds.length == 2) {
      final otherUserId = memberIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => memberIds.first,
      );

      return FutureBuilder<UsersRecord?>(
        future: context.read<ProfileProvider>().getProfile(otherUserId),
        builder: (context, snapshot) {
          final otherData = snapshot.data;
          final displayName =
              (otherData?.displayName ?? '').trim().isNotEmpty
                  ? otherData!.displayName
                  : 'Golfer';
          final photoUrl = otherData?.photoUrl;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundImage: CachedNetworkImageProvider(photoUrl),
                  ),
                ),
              AppText.cardTitle(displayName),
            ],
          );
        },
      );
    }

    // Group chat (3+ members)
    return AppText.cardTitle('Group Chat');
  }
}
