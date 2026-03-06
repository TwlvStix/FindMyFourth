import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/providers/notification_list_provider.dart';
import '/providers/provider_extensions.dart';
import 'components/notification_list_item_card.dart';
import 'components/notification_tap_router.dart';
import 'components/notifications_list_app_bar_actions.dart';
import 'components/notifications_list_content.dart';

class NotificationsListWidget extends StatefulWidget {
  const NotificationsListWidget({super.key});

  static String routeName = 'NotificationsList';
  static String routePath = '/notificationsList';

  @override
  State<NotificationsListWidget> createState() =>
      _NotificationsListWidgetState();
}

class _NotificationsListWidgetState extends State<NotificationsListWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  NotificationListProvider? _notificationListProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationListProvider ??= context.read<NotificationListProvider>();
    final userRef = currentUserReference;
    if (userRef != null) {
      _notificationListProvider!.startListening(userRef);
    }
  }

  @override
  void dispose() {
    _notificationListProvider?.stopListening();
    super.dispose();
  }

  // --- Action Methods ---

  Future<void> _markAllAsRead() async {
    await _notificationListProvider!.markAllAsRead();
  }

  Future<void> _markReadIfNeeded(NotificationListItem item) async {
    await _notificationListProvider!.markReadIfNeeded(item);
  }

  Future<void> _markAsUnread(NotificationListItem item) async {
    await _notificationListProvider!.markAsUnread(item);
  }

  Future<void> _deleteNotification(NotificationListItem item) async {
    try {
      await _notificationListProvider!.deleteNotification(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: AppColors.navy,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    try {
      final deletedCount =
          await _notificationListProvider!.deleteAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deletedCount > 0
                ? 'All notifications deleted'
                : 'No notifications to delete'),
            backgroundColor: AppColors.navy,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notifications'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllConfirmDialog() async {
    final shouldDelete = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: PhosphorIconsRegular.trash,
      title: 'Delete All Notifications',
      body:
          'Are you sure you want to delete all notifications? This action cannot be undone.',
      actionLabel: 'Delete All',
      cancelLabel: 'Cancel',
    );

    if (shouldDelete == true && mounted) {
      await _deleteAllNotifications();
    }
  }

  // --- Tap Handler ---

  Future<void> _handleNotificationTap(NotificationListItem item) async {
    await NotificationTapRouter.handleTap(
      context: context,
      item: item,
      provider: _notificationListProvider!,
      currentUserRef: currentUserReference,
      onMarkRead: () => _markReadIfNeeded(item),
    );
  }

  // --- Build Methods ---

  Widget _buildAppBarActions() {
    final userRef = currentUserReference;
    if (userRef == null) return const SizedBox.shrink();

    final hasNotifications =
        context.selectNotificationList((p) => p.hasNotifications);

    return NotificationsListAppBarActions(
      userRef: userRef,
      provider: _notificationListProvider!,
      hasNotifications: hasNotifications,
      onMarkAllRead: _markAllAsRead,
      onDeleteAll: _showDeleteAllConfirmDialog,
    );
  }

  Widget _buildNotificationItem(NotificationListItem item) {
    return NotificationListItemCard(
      item: item,
      onTap: () => _handleNotificationTap(item),
      onDelete: () => _deleteNotification(item),
      onMarkUnread: () => _markAsUnread(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRef = currentUserReference;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          leading: const PremiumBackButton(),
          title: Text(
            'Notifications',
            style: AppTypography.headlineMediumSans.copyWith(
              color: AppColors.pure,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [_buildAppBarActions()],
          centerTitle: false,
        ),
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: false,
            child: userRef == null
                ? Center(
                    child: Text(
                      'Please sign in to view notifications.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.pure,
                      ),
                    ),
                  )
                : _buildNotificationsContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsContent() {
    final state = context.selectNotificationList((p) => p.listViewState);

    return NotificationsListContent(
      state: state,
      onRetry: () => _notificationListProvider!.retryInitialLoad(),
      onRefresh: () => _notificationListProvider!.refresh(),
      onLoadMore: () => _notificationListProvider!.loadMore(),
      itemBuilder: _buildNotificationItem,
    );
  }
}
