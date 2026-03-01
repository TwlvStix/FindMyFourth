import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/services/notification_crud_service.dart';
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
  final _notificationService = NotificationCrudService();
  static const int _pageSizeStep = 50;
  int _pageSize = _pageSizeStep;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onRefresh() async {
    // Reset page size to trigger fresh query
    setState(() => _pageSize = _pageSizeStep);
    // Brief delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _markAllAsRead(DocumentReference userRef) async {
    await _notificationService.markAllAsRead(userRef);
  }

  Future<void> _markReadIfNeeded(
    DocumentReference reference,
    bool isRead,
  ) async {
    await _notificationService.markReadIfNeeded(reference, isRead);
  }

  Future<void> _markAsUnread(DocumentReference reference) async {
    await _notificationService.markAsUnread(reference);
  }

  Future<void> _deleteNotification(DocumentReference reference) async {
    try {
      await _notificationService.deleteNotification(reference);
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

  Future<void> _deleteAllNotifications(DocumentReference userRef) async {
    try {
      final deletedCount =
          await _notificationService.deleteAllNotifications(userRef);

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
    return _notificationService.shouldBlockFriendsOnlyGame(
      gameRef: gameRef,
      currentUserRef: currentUserRef,
    );
  }

  Future<void> _showDeleteAllConfirmDialog(DocumentReference userRef) async {
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

    if (shouldDelete == true) {
      await _deleteAllNotifications(userRef);
    }
  }

  Map<String, dynamic> _extractDataMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
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

  Future<void> _handleNotificationTap(
    QueryDocumentSnapshot doc,
  ) async {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    final isRead = data['read'] == true;
    await _markReadIfNeeded(doc.reference, isRead);
    if (!mounted) {
      return;
    }
    final type = (data['type'] as String?) ?? '';
    final payload = _extractDataMap(data['data']);
    if (_isGameNotification(type)) {
      final gameRef = _notificationService.resolveGameRefFromPayload(payload);
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
      final gameRef = _notificationService.resolveGameRefFromPayload(payload);
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

  List<Widget> _buildAppBarActions(DocumentReference userRef) {
    // Only show actions when there are notifications
    if (_notificationCount == 0) {
      return [];
    }

    return [
      StreamBuilder<QuerySnapshot>(
        stream: _notificationService.streamUnreadNotifications(userRef),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data?.docs.length ?? 0;
          final hasUnread = unreadCount > 0;
          return AppButtonEnhanced(
            text: 'Mark all read',
            variant: AppButtonVariant.ghostDark,
            size: AppButtonSize.small,
            enabled: hasUnread,
            onPressed: hasUnread ? () => _markAllAsRead(userRef) : null,
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
            _showDeleteAllConfirmDialog(userRef);
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          leading: const PremiumBackButton(),
          title: Text(
            'Notifications',
            style: AppTypography.headlineMediumSans.copyWith(
              color: Colors.white,
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
                : StreamBuilder<QuerySnapshot>(
                    stream: _notificationService.streamNotifications(
                      userRef: userRef,
                      limit: _pageSize,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load notifications.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.pure,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ??
                          const <QueryDocumentSnapshot>[];

                      // Update notification count for app bar actions
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _notificationCount != docs.length) {
                          setState(() => _notificationCount = docs.length);
                        }
                      });

                      if (docs.isEmpty) {
                        // Wrap in scrollable for pull-to-refresh on empty state
                        return RefreshIndicator(
                          color: AppColors.green,
                          backgroundColor: AppColors.navy,
                          onRefresh: _onRefresh,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top +
                                        100,
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
                      return RefreshIndicator(
                        color: AppColors.green,
                        backgroundColor: AppColors.navy,
                        onRefresh: _onRefresh,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.extentAfter < 200 &&
                                docs.length >= _pageSize) {
                              setState(() {
                                _pageSize += _pageSizeStep;
                              });
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
                            itemCount: docs.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data =
                                  (doc.data() as Map<String, dynamic>?) ??
                                      <String, dynamic>{};
                              final type = (data['type'] as String?) ?? '';
                              final title = (data['title'] as String?)?.trim();
                              final body = (data['body'] as String?)?.trim();
                              final isRead = data['read'] == true;
                              final createdAt =
                                  (data['createdAt'] as Timestamp?)?.toDate();
                              final timeLabel =
                                  dateTimeFormat('relative', createdAt);
                              return Dismissible(
                                key: Key(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding:
                                      EdgeInsets.only(right: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.md),
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
                                        variant:
                                            PremiumDialogVariant.destructive,
                                        icon: PhosphorIconsRegular.trash,
                                        title: 'Delete Notification',
                                        body:
                                            'Are you sure you want to delete this notification?',
                                        actionLabel: 'Delete',
                                        cancelLabel: 'Cancel',
                                      ) ??
                                      false;
                                },
                                onDismissed: (direction) {
                                  _deleteNotification(doc.reference);
                                },
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.md),
                                  onTap: () async {
                                    await _handleNotificationTap(doc);
                                  },
                                  onLongPress: isRead
                                      ? () async {
                                          final result =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (dialogContext) =>
                                                AlertDialog(
                                              title:
                                                  Text('Notification Actions'),
                                              backgroundColor: AppColors.navy,
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: AppIcon(
                                                      icon: AppPhosphorIcons
                                                          .notifications,
                                                      color: AppColors
                                                          .textSecondary,
                                                      size: AppIconSize.md,
                                                    ),
                                                    title:
                                                        Text('Mark as unread'),
                                                    onTap: () => Navigator.of(
                                                            dialogContext)
                                                        .pop('unread'),
                                                  ),
                                                  ListTile(
                                                    leading: AppIcon(
                                                      icon: AppPhosphorIcons
                                                          .trash,
                                                      color: AppColors.error,
                                                      size: AppIconSize.md,
                                                    ),
                                                    title: Text('Delete'),
                                                    onTap: () => Navigator.of(
                                                            dialogContext)
                                                        .pop('delete'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          if (result == 'unread') {
                                            await _markAsUnread(doc.reference);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text('Marked as unread'),
                                                  backgroundColor:
                                                      AppColors.navy,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          } else if (result == 'delete') {
                                            await _deleteNotification(
                                                doc.reference);
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.navy,
                                      borderRadius: BorderRadius.circular(
                                          AppBorderRadius.md),
                                      border: Border.all(
                                        color: AppColors.navyLight,
                                        width: 1.0,
                                      ),
                                      boxShadow: [AppElevation.xs],
                                    ),
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: AppIconSize.xl,
                                          height: AppIconSize.xl,
                                          decoration: BoxDecoration(
                                            color: _iconBgColorForType(
                                                context, type),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title?.isNotEmpty == true
                                                          ? title!
                                                          : _titleFallback(
                                                              type),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTypography
                                                          .bodyLarge
                                                          .copyWith(
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (timeLabel.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .only(
                                                        start: AppSpacing.xs,
                                                      ),
                                                      child: Text(
                                                        timeLabel,
                                                        style: AppTypography
                                                            .labelSmall
                                                            .copyWith(
                                                          color: AppColors
                                                              .textMuted,
                                                        ),
                                                      ),
                                                    ),
                                                  if (!isRead)
                                                    Container(
                                                      margin:
                                                          EdgeInsetsDirectional
                                                              .only(
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
                                                  padding: EdgeInsetsDirectional
                                                      .only(
                                                    top: AppSpacing.xxs,
                                                  ),
                                                  child: Text(
                                                    body!,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppTypography
                                                        .bodyMedium
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              if (type ==
                                                  'dispute_resolved_upheld')
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .only(
                                                    top: AppSpacing.sm,
                                                  ),
                                                  child: AppButtonEnhanced(
                                                    text: 'View Your Standing',
                                                    variant:
                                                        AppButtonVariant.ghost,
                                                    size: AppButtonSize.small,
                                                    onPressed: () {
                                                      context
                                                          .pushYourStanding();
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
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
