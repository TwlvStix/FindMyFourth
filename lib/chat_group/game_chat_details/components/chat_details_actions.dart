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
    this.onReportSelected,
    this.onBlockSelected,
    this.isDirect = false,
  });

  final VoidCallback onLeaveSelected;
  final VoidCallback? onReportSelected;
  final VoidCallback? onBlockSelected;
  final bool isDirect;

  @override
  Widget build(BuildContext context) {
    return AppPopupMenu(
      icon: AppPhosphorIcons.more,
      tooltip: 'More options',
      items: [
        if (isDirect && onReportSelected != null)
          AppPopupMenuItem(
            label: 'Report User',
            value: 'report',
            icon: AppPhosphorIcons.securityWarning,
          ),
        if (isDirect && onBlockSelected != null)
          AppPopupMenuItem(
            label: 'Block User',
            value: 'block',
            icon: AppPhosphorIcons.blocked,
            isDestructive: true,
          ),
        AppPopupMenuItem(
          label: 'Leave Chat',
          value: 'leave',
          icon: AppPhosphorIcons.logOut,
          isDestructive: true,
        ),
      ],
      onSelected: (value) {
        if (value == 'leave') onLeaveSelected();
        if (value == 'report') onReportSelected?.call();
        if (value == 'block') onBlockSelected?.call();
      },
    );
  }
}
