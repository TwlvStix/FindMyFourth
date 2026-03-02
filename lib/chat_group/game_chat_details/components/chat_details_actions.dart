import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_popup_menu.dart';

/// Actions menu for chat details screen.
///
/// Always shows "Leave Chat" for all members. When the last member leaves,
/// the chat is automatically deleted by the leave logic.
class ChatDetailsActions extends StatelessWidget {
  const ChatDetailsActions({
    super.key,
    required this.onLeaveSelected,
  });

  final VoidCallback onLeaveSelected;

  @override
  Widget build(BuildContext context) {
    return AppPopupMenu(
      icon: AppPhosphorIcons.more,
      tooltip: 'More options',
      items: [
        AppPopupMenuItem(
          label: 'Leave Chat',
          value: 'leave',
          icon: AppPhosphorIcons.logOut,
          isDestructive: true,
        ),
      ],
      onSelected: (value) {
        if (value == 'leave') {
          onLeaveSelected();
        }
      },
    );
  }
}
