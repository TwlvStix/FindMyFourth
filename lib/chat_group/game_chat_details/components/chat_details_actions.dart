import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_popup_menu.dart';
import '/models/chat.dart';

class ChatDetailsActions extends StatelessWidget {
  const ChatDetailsActions({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.gameOwnerFuture,
    required this.onDeleteSelected,
  });

  final Chat chat;
  final String? currentUserId;
  final Future<GamesRecord?>? gameOwnerFuture;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    if (chat.type != 'game') {
      return _deleteMenu();
    }

    if (currentUserId == null || gameOwnerFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<GamesRecord?>(
      future: gameOwnerFuture,
      builder: (context, snapshot) {
        final game = snapshot.data;
        final ownerUid = game?.uid;
        final ownerRefId = game?.userRef?.id;
        final isOwner =
            ownerUid == currentUserId || ownerRefId == currentUserId;

        if (!isOwner) {
          return const SizedBox.shrink();
        }
        return _deleteMenu();
      },
    );
  }

  Widget _deleteMenu() {
    return AppPopupMenu(
      icon: AppPhosphorIcons.more,
      tooltip: 'More options',
      items: const [
        AppPopupMenuItem(
          label: 'Delete Chat',
          value: 'delete',
          icon: AppPhosphorIcons.trash,
          isDestructive: true,
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          onDeleteSelected();
        }
      },
    );
  }
}
