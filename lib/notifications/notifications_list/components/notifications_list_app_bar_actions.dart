import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_popup_menu.dart';
import '/providers/notification_list_provider.dart';

/// Builds the app bar action widgets for the notifications list.
///
/// Includes:
/// - "Mark all read" button (enabled when there are unread notifications)
/// - Overflow menu with "Delete all" option
class NotificationsListAppBarActions extends StatelessWidget {
  const NotificationsListAppBarActions({
    super.key,
    required this.userRef,
    required this.provider,
    required this.hasNotifications,
    required this.onMarkAllRead,
    required this.onDeleteAll,
  });

  final DocumentReference userRef;
  final NotificationListProvider provider;
  final bool hasNotifications;
  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    // Only show actions when there are notifications
    if (!hasNotifications) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<int>(
          stream: provider.unreadCountStream(userRef),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            final hasUnread = unreadCount > 0;
            return AppButtonEnhanced(
              text: 'Mark all read',
              variant: AppButtonVariant.ghostDark,
              size: AppButtonSize.small,
              enabled: hasUnread,
              onPressed: hasUnread ? onMarkAllRead : null,
            );
          },
        ),
        AppPopupMenu(
          icon: AppPhosphorIcons.more,
          tooltip: 'More actions',
          items: [
            AppPopupMenuItem(
              label: 'Delete all',
              value: 'delete_all',
              icon: AppPhosphorIcons.trash,
              isDestructive: true,
            ),
          ],
          onSelected: (value) {
            if (value == 'delete_all') {
              onDeleteAll();
            }
          },
        ),
      ],
    );
  }
}
