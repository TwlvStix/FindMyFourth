import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_icon_button.dart';
import '/providers/notification_list_provider.dart';

/// A notification bell button with real-time unread badge.
///
/// Auth-reactive: automatically resets on sign-out and resubscribes on account
/// switch via [AuthUserStreamWidget] wrapper.
///
/// Uses [NotificationCrudService.streamUnreadNotifications] to stream unread
/// count and [NotificationBadge] for consistent badge rendering.
class AppNotificationBadgeButton extends StatelessWidget {
  const AppNotificationBadgeButton({super.key, this.onTap});

  /// Called when the notification bell is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        if (currentUserReference == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<int>(
          stream: context.read<NotificationListProvider>().unreadCountStream(
            currentUserReference!,
          ),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Bell button - no background/border (matches filter icon style)
                AppIconButton(
                  borderColor: AppColors.transparent,
                  borderRadius: 30.0,
                  borderWidth: 0,
                  buttonSize: 44.0,
                  fillColor: AppColors.transparent,
                  tooltip: 'Notifications',
                  icon: AppIcon(
                    icon: AppPhosphorIcons.notifications,
                    color: AppColors.pure,
                    size: AppIconSize.md,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onTap?.call();
                  },
                ),
                // Badge using existing NotificationBadge
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: NotificationBadge(count: unreadCount),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
