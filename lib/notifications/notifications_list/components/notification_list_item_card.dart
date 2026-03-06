import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/providers/notification_list_provider.dart';
import '/utils/app_util.dart';
import 'notification_type_helpers.dart';

/// A card widget that displays a single notification item.
///
/// Features:
/// - Swipe-to-delete with confirmation dialog
/// - Long-press context menu (mark unread, delete) for read items
/// - Unread indicator dot
/// - Type-specific icon and color
/// - Optional inline action button (e.g., for dispute notifications)
class NotificationListItemCard extends StatelessWidget {
  const NotificationListItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onMarkUnread,
  });

  final NotificationListItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<void> Function() onMarkUnread;

  @override
  Widget build(BuildContext context) {
    final type = item.type;
    final title = item.title?.trim();
    final body = item.body?.trim();
    final isRead = item.isRead;
    final timeLabel = dateTimeFormat('relative', item.createdAt);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: AppIcon(
          icon: AppPhosphorIcons.trash,
          color: AppColors.pure,
          size: AppIconSize.md,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showPremiumDialog(
              context: context,
              variant: PremiumDialogVariant.destructive,
              icon: PhosphorIconsRegular.trash,
              title: 'Delete Notification',
              body: 'Are you sure you want to delete this notification?',
              actionLabel: 'Delete',
              cancelLabel: 'Cancel',
            ) ??
            false;
      },
      onDismissed: (direction) => onDelete(),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        onTap: onTap,
        onLongPress: isRead ? () => _showContextMenu(context) : null,
        child: _buildCardContent(
          context,
          type: type,
          title: title,
          body: body,
          isRead: isRead,
          timeLabel: timeLabel,
        ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Notification Actions'),
        backgroundColor: AppColors.navy,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(
                icon: AppPhosphorIcons.notifications,
                color: AppColors.textSecondary,
                size: AppIconSize.md,
              ),
              title: Text('Mark as unread'),
              onTap: () => Navigator.of(dialogContext).pop('unread'),
            ),
            ListTile(
              leading: AppIcon(
                icon: AppPhosphorIcons.trash,
                color: AppColors.error,
                size: AppIconSize.md,
              ),
              title: Text('Delete'),
              onTap: () => Navigator.of(dialogContext).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (result == 'unread') {
      await onMarkUnread();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as unread'),
            backgroundColor: AppColors.navy,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (result == 'delete') {
      onDelete();
    }
  }

  Widget _buildCardContent(
    BuildContext context, {
    required String type,
    required String? title,
    required String? body,
    required bool isRead,
    required String timeLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1.0,
        ),
        boxShadow: [AppElevation.xs],
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconCircle(type),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(
                  type: type,
                  title: title,
                  isRead: isRead,
                  timeLabel: timeLabel,
                ),
                if ((body ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: AppSpacing.xxs),
                    child: Text(
                      body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (type == 'dispute_resolved_upheld')
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: AppSpacing.sm),
                    child: AppButtonEnhanced(
                      text: 'View Your Standing',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      onPressed: () {
                        context.pushYourStanding();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(String type) {
    return Container(
      width: AppIconSize.xl,
      height: AppIconSize.xl,
      decoration: BoxDecoration(
        color: NotificationTypeHelpers.iconBgColorForType(type),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppIcon(
          icon: NotificationTypeHelpers.iconForType(type),
          color: AppColors.pure,
          size: AppIconSize.button,
        ),
      ),
    );
  }

  Widget _buildTitleRow({
    required String type,
    required String? title,
    required bool isRead,
    required String timeLabel,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title?.isNotEmpty == true
                ? title!
                : NotificationTypeHelpers.titleFallback(type),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (timeLabel.isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.only(start: AppSpacing.xs),
            child: Text(
              timeLabel,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        if (!isRead)
          Container(
            margin: EdgeInsetsDirectional.only(start: AppSpacing.xs),
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
