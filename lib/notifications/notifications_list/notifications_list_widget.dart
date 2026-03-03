import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/providers/notification_list_provider.dart';
import '/providers/provider_extensions.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_empty_state_premium.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_popup_menu.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/utils/app_util.dart';

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

  Future<void> _showFriendsOnlyDialog() async {
    await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.informational,
      icon: PhosphorIconsRegular.lock,
      title: 'Friends Only Game',
      body:
          'This game is visible to friends only. Add the host as a friend to view details.',
      actionLabel: 'Got It',
    );
  }

  Future<bool> _shouldBlockFriendsOnlyGame(DocumentReference gameRef) async {
    final currentUserRef = currentUserReference;
    if (currentUserRef == null) {
      return false;
    }
    return _notificationListProvider!.shouldBlockFriendsOnlyGame(
      gameRef,
      currentUserRef,
    );
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

  bool _isGameNotification(String type) {
    return type == 'game_created' || type == 'game_alert';
  }

  bool _isTrustGameNotification(String type) {
    return const {
      'host_checkin_due',
      'player_rate_due',
      'host_checkin_fallback',
      'player_fallback_confirm',
      'game_spot_opened',
      'game_cancelled',
    }.contains(type);
  }

  bool _isTrustAccountNotification(String type) {
    return const {
      'no_show_flagged',
      'dispute_resolved',
      'strike_issued',
      'cooldown_started',
      'restriction_started',
      'suspension_started',
      'restriction_ended',
    }.contains(type);
  }

  bool _isBadgeNotification(String type) {
    return const {'badge_earned', 'badge_progress'}.contains(type);
  }

  bool _isSocialNotification(String type) {
    return const {'friend_request_received', 'friend_request_accepted'}
        .contains(type);
  }

  PhosphorIconData _iconForType(String type) {
    if (type == 'chat_message') return AppPhosphorIcons.chat;
    if (_isGameNotification(type)) return AppPhosphorIcons.games;
    if (type == 'attendance_dispute') return AppPhosphorIcons.info;
    if (type == 'dispute_resolved_cleared') return AppPhosphorIcons.success;
    if (type == 'dispute_resolved_upheld') return AppPhosphorIcons.warning;
    // Trust System types
    if (type == 'host_checkin_due' ||
        type == 'host_checkin_fallback' ||
        type == 'player_fallback_confirm') {
      return AppPhosphorIcons.calendarCheck;
    }
    if (type == 'player_rate_due') return AppPhosphorIcons.star;
    if (type == 'game_spot_opened' || type == 'game_cancelled') {
      return AppPhosphorIcons.games;
    }
    if (_isTrustAccountNotification(type)) {
      return type == 'dispute_resolved' || type == 'restriction_ended'
          ? AppPhosphorIcons.trust
          : AppPhosphorIcons.warning;
    }
    if (_isBadgeNotification(type)) return AppPhosphorIcons.badge;
    if (type == 'friend_request_received') return AppPhosphorIcons.addPlayer;
    if (type == 'friend_request_accepted') return AppPhosphorIcons.golfers;
    return AppPhosphorIcons.notifications;
  }

  Color _iconBgColorForType(BuildContext context, String type) {
    if (type == 'attendance_dispute') return AppColors.info;
    if (type == 'dispute_resolved_cleared') return AppColors.success;
    if (type == 'dispute_resolved_upheld') return AppColors.error;
    if (_isTrustAccountNotification(type)) return AppColors.error;
    if (_isBadgeNotification(type)) return AppColors.gold;
    if (_isSocialNotification(type)) return AppColors.green;
    return AppColors.navyDark;
  }

  String _titleFallback(String type) {
    if (type == 'chat_message') {
      return 'New message';
    }
    if (_isGameNotification(type)) {
      return 'New game posted';
    }
    if (type == 'attendance_dispute') {
      return 'Attendance Dispute';
    }
    if (type == 'dispute_resolved_cleared') {
      return 'Dispute Resolved';
    }
    if (type == 'dispute_resolved_upheld') {
      return 'Strike Added';
    }
    return 'Notification';
  }

  Future<void> _handleNotificationTap(NotificationListItem item) async {
    final provider = _notificationListProvider!;
    await _markReadIfNeeded(item);
    if (!mounted) {
      return;
    }
    final type = item.type;
    final payload = item.data;
    if (_isGameNotification(type)) {
      final gameRef = provider.resolveGameRefFromPayload(payload);
      if (gameRef != null) {
        final shouldBlock = await _shouldBlockFriendsOnlyGame(gameRef);
        if (shouldBlock) {
          await _showFriendsOnlyDialog();
          return;
        }
        if (!mounted) return;
        context.pushJoinGameDetailed(
          gameRef: gameRef,
        );
      }
      return;
    }
    if (type == 'chat_message') {
      final chatId = payload['threadId'] ?? payload['chatId'];
      if (chatId is String && chatId.isNotEmpty) {
        context.pushChatDetails(
          chatId: chatId,
        );
      }
      return;
    }
    if (type == 'dispute_resolved_upheld') {
      context.pushYourStanding();
      return;
    }
    if (_isTrustGameNotification(type)) {
      final gameRef = provider.resolveGameRefFromPayload(payload);
      if (gameRef != null) {
        final shouldBlock = await _shouldBlockFriendsOnlyGame(gameRef);
        if (shouldBlock) {
          await _showFriendsOnlyDialog();
          return;
        }
        if (!mounted) return;
        context.pushJoinGameDetailed(
          gameRef: gameRef,
        );
      }
      return;
    }
    if (_isTrustAccountNotification(type)) {
      context.pushYourStanding();
      return;
    }
    if (_isBadgeNotification(type)) {
      context.pushMainProfile();
      return;
    }
    if (type == 'friend_request_received') {
      context.pushTabFriends(
        initialSegment: 'requests',
      );
      return;
    }
    if (type == 'friend_request_accepted') {
      context.pushTabFriends(
        initialSegment: 'friends',
      );
      return;
    }
  }

  Widget _buildNotificationsList(BuildContext context) {
    // Select list view state - rebuilds only when this snapshot changes
    final state = context.selectNotificationList((p) => p.listViewState);
    final notifications = state.notifications;

    // Initial loading state - show spinner only while initial load is in progress
    if (state.isInitialLoadInProgress) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.green,
        ),
      );
    }

    // Error or timeout state - show retry UI
    if (state.hasError || state.initialLoadTimedOut) {
      return RefreshIndicator(
        color: AppColors.green,
        backgroundColor: AppColors.navy,
        onRefresh: () async {
          _notificationListProvider!.retryInitialLoad();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 100,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon: AppPhosphorIcons.warning,
                      size: AppIconSize.section,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      state.initialLoadTimedOut
                          ? 'Taking longer than expected'
                          : 'Unable to load notifications',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pull down to refresh or tap retry.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    AppButtonEnhanced(
                      text: 'Retry',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                      onPressed: () {
                        _notificationListProvider!.retryInitialLoad();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state - only show after first load completed with no data
    if (notifications.isEmpty && state.hasReceivedFirstSnapshot) {
      return RefreshIndicator(
        color: AppColors.green,
        backgroundColor: AppColors.navy,
        onRefresh: () => _notificationListProvider!.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 100,
                ),
                child: AppEmptyStatePremium(
                  icon: AppPhosphorIcons.notifications,
                  title: "You're all caught up",
                  message: 'New activity will appear here.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback: if not loading and no data and no error, show empty state
    if (notifications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.green,
        backgroundColor: AppColors.navy,
        onRefresh: () => _notificationListProvider!.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 100,
                ),
                child: AppEmptyStatePremium(
                  icon: AppPhosphorIcons.notifications,
                  title: "You're all caught up",
                  message: 'New activity will appear here.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // List with notifications
    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.navy,
      onRefresh: () => _notificationListProvider!.refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200 &&
              !state.isLoadingMore &&
              state.hasMore) {
            _notificationListProvider!.loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            MediaQuery.of(context).padding.top + 60,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          itemCount: notifications.length +
              (state.isLoadingMore || state.loadMoreError ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            // Show loading indicator or error retry at the end
            if (index == notifications.length) {
              if (state.loadMoreError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: AppButtonEnhanced(
                      text: 'Retry',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      onPressed: () => _notificationListProvider!.loadMore(),
                    ),
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(
                    color: AppColors.green,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final item = notifications[index];
            return _buildNotificationItem(context, item);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, NotificationListItem item) {
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
      onDismissed: (direction) {
        _deleteNotification(item);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        onTap: () async {
          await _handleNotificationTap(item);
        },
        onLongPress: isRead
            ? () async {
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
                          onTap: () =>
                              Navigator.of(dialogContext).pop('unread'),
                        ),
                        ListTile(
                          leading: AppIcon(
                            icon: AppPhosphorIcons.trash,
                            color: AppColors.error,
                            size: AppIconSize.md,
                          ),
                          title: Text('Delete'),
                          onTap: () =>
                              Navigator.of(dialogContext).pop('delete'),
                        ),
                      ],
                    ),
                  ),
                );
                if (!context.mounted) return;
                if (result == 'unread') {
                  await _markAsUnread(item);
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
                  await _deleteNotification(item);
                }
              }
            : null,
        child: Container(
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
              Container(
                width: AppIconSize.xl,
                height: AppIconSize.xl,
                decoration: BoxDecoration(
                  color: _iconBgColorForType(context, type),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(
                    icon: _iconForType(type),
                    color: AppColors.pure,
                    size: AppIconSize.button,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title?.isNotEmpty == true
                                ? title!
                                : _titleFallback(type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: AppSpacing.xs,
                            ),
                            child: Text(
                              timeLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        if (!isRead)
                          Container(
                            margin: EdgeInsetsDirectional.only(
                              start: AppSpacing.xs,
                            ),
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if ((body ?? '').isNotEmpty)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          top: AppSpacing.xxs,
                        ),
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
                        padding: EdgeInsetsDirectional.only(
                          top: AppSpacing.sm,
                        ),
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
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(DocumentReference userRef) {
    // Select hasNotifications - rebuilds only when notifications appear/disappear
    // Note: Use hasNotifications (not isEmpty) to preserve original behavior during error state
    final hasNotifications =
        context.selectNotificationList((p) => p.hasNotifications);

    // Only show actions when there are notifications
    if (!hasNotifications) {
      return [];
    }

    // Get provider without watching (for stream access only)
    final provider = _notificationListProvider!;

    return [
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
            onPressed: hasUnread ? () => _markAllAsRead() : null,
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
            _showDeleteAllConfirmDialog();
          }
        },
      ),
    ];
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
          actions: userRef == null ? [] : _buildAppBarActions(userRef),
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
                : _buildNotificationsList(context),
          ),
        ),
      ),
    );
  }
}
