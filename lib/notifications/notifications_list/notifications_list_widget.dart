import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
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
  static const int _pageSizeStep = 50;
  int _pageSize = _pageSizeStep;

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _markAllAsRead(DocumentReference userRef) async {
    final unreadSnapshot = await userRef
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (unreadSnapshot.docs.isEmpty) {
      return;
    }
    var batch = FirebaseFirestore.instance.batch();
    var opCount = 0;
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'read': true});
      opCount += 1;
      if (opCount >= 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) {
      await batch.commit();
    }
  }

  Future<void> _markReadIfNeeded(
    DocumentReference reference,
    bool isRead,
  ) async {
    if (isRead) {
      return;
    }
    await reference.update({'read': true});
  }

  Future<void> _markAsUnread(DocumentReference reference) async {
    await reference.update({'read': false});
  }

  Future<void> _deleteNotification(DocumentReference reference) async {
    try {
      await reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: AppColors.fairway,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications(DocumentReference userRef) async {
    try {
      // Get all notifications in batches of 500 to stay under Firestore limits
      final allSnapshot = await userRef
          .collection('notifications')
          .orderBy('createdAt')
          .get();

      if (allSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No notifications to delete'),
              backgroundColor: AppColors.fairway,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      var batch = FirebaseFirestore.instance.batch();
      var opCount = 0;

      for (final doc in allSnapshot.docs) {
        batch.delete(doc.reference);
        opCount += 1;
        // Commit batch at 500 operations (Firestore limit)
        if (opCount >= 500) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          opCount = 0;
        }
      }

      // Commit remaining operations
      if (opCount > 0) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications deleted'),
            backgroundColor: AppColors.fairway,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notifications'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showFriendsOnlyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (alertDialogContext) {
        return AlertDialog(
          title: Text('Friends Only Game'),
          content: Text(
            'This game is visible to friends only. Add the host as a friend to view details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(alertDialogContext),
              child: Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _shouldBlockFriendsOnlyGame(DocumentReference gameRef) async {
    final currentUserRef = currentUserReference;
    if (currentUserRef == null) {
      return false;
    }

    Map<String, dynamic>? data;
    try {
      final gameSnap = await gameRef.get();
      data = gameSnap.data() as Map<String, dynamic>?;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
    if (data == null) {
      return false;
    }

    final friendGameValue = (data['friendGame'] as String?) ?? '';
    final isFriendsOnly = friendGameValue.trim().toLowerCase() == 'friends';
    if (!isFriendsOnly) {
      return false;
    }

    final ownerRef = data['userRef'];
    if (ownerRef is! DocumentReference) {
      return true;
    }

    final userSnap = await currentUserRef.get();
    final userData = userSnap.data() as Map<String, dynamic>? ?? {};
    final friends = userData['friends'];
    if (friends is List) {
      return !friends.any((entry) {
        if (entry is DocumentReference) {
          return entry.id == ownerRef.id;
        }
        if (entry is String) {
          if (entry.contains('/')) {
            final parts = entry.split('/');
            return parts.isNotEmpty && parts.last == ownerRef.id;
          }
          return entry == ownerRef.id;
        }
        return false;
      });
    }
    return true;
  }

  Future<void> _showDeleteAllConfirmDialog(DocumentReference userRef) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete All Notifications'),
        content: Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        backgroundColor: AppTheme.of(context).secondaryBackground,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.of(context).secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
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

  bool _isDisputeNotification(String type) {
    return type == 'attendance_dispute' ||
        type == 'dispute_resolved_cleared' ||
        type == 'dispute_resolved_upheld';
  }

  IconData _iconForType(String type) {
    if (type == 'chat_message') {
      return Icons.chat_bubble_outline;
    }
    if (_isGameNotification(type)) {
      return Icons.sports_golf;
    }
    if (type == 'attendance_dispute') {
      return Icons.info_outline_rounded;
    }
    if (type == 'dispute_resolved_cleared') {
      return Icons.check_circle_rounded;
    }
    if (type == 'dispute_resolved_upheld') {
      return Icons.warning_amber_rounded;
    }
    return Icons.notifications_none;
  }

  Color _iconBgColorForType(BuildContext context, String type) {
    if (type == 'attendance_dispute') return AppColors.info;
    if (type == 'dispute_resolved_cleared') return AppColors.success;
    if (type == 'dispute_resolved_upheld') return AppColors.sunsetRose;
    return AppTheme.of(context).primary;
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
      final gameId = payload['gameId'] ?? payload['game_id'];
      final gameRefPath = payload['gameRef'];
      DocumentReference? gameRef;
      if (gameRefPath is String && gameRefPath.isNotEmpty) {
        gameRef = FirebaseFirestore.instance.doc(gameRefPath);
      } else if (gameId is String && gameId.isNotEmpty) {
        gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);
      }
      if (gameRef != null) {
        final shouldBlock = await _shouldBlockFriendsOnlyGame(gameRef);
        if (shouldBlock) {
          await _showFriendsOnlyDialog();
          return;
        }
        context.pushNamed(
          JoinGameDetailedWidget.routeName,
          extra: <String, dynamic>{
            'gameRef': gameRef,
            kTransitionInfoKey: TransitionStandards.detailTransition,
          },
        );
      }
      return;
    }
    if (type == 'chat_message') {
      final chatId = payload['threadId'] ?? payload['chatId'];
      if (chatId is String && chatId.isNotEmpty) {
        context.pushNamed(
          'ChatDetails',
          pathParameters: {'chatId': chatId},
          extra: <String, dynamic>{
            kTransitionInfoKey: TransitionStandards.detailTransition,
          },
        );
      }
    }
    if (type == 'dispute_resolved_upheld') {
      context.pushNamed('YourStanding');
    }
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
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: userRef == null
              ? []
              : [
                  StreamBuilder<QuerySnapshot>(
                    stream: userRef
                        .collection('notifications')
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data?.docs.length ?? 0;
                      final hasUnread = unreadCount > 0;
                      return TextButton(
                        onPressed:
                            hasUnread ? () => _markAllAsRead(userRef) : null,
                        child: Text(
                          'Mark all read',
                          style: AppTypography.labelLarge.copyWith(
                            color: hasUnread
                                ? AppColors.sunsetGold
                                : Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    color: AppTheme.of(context).secondaryBackground,
                    onSelected: (value) {
                      if (value == 'delete_all') {
                        _showDeleteAllConfirmDialog(userRef);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Colors.red,
                              size: 20.0,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Delete all',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
          centerTitle: false,
        ),
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: false,
            child: userRef == null
              ? Center(
                  child: Text(
                    'Please sign in to view notifications.',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: TextStyle(fontFamily: 'Manrope',
                            fontWeight:
                                AppTheme.of(context).bodyMedium.fontWeight,
                            fontStyle:
                                AppTheme.of(context).bodyMedium.fontStyle,
                          ),
                          color: AppTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                        ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: userRef
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .limit(_pageSize)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load notifications.',
                          style: AppTheme.of(context).bodyMedium.override(
                                font: TextStyle(fontFamily: 'Manrope',
                                  fontWeight:
                                      AppTheme.of(context).bodyMedium.fontWeight,
                                  fontStyle:
                                      AppTheme.of(context).bodyMedium.fontStyle,
                                ),
                                color: AppTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                              ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.of(context).primary,
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications yet.',
                          style: AppTheme.of(context).bodyMedium.override(
                                font: TextStyle(fontFamily: 'Manrope',
                                  fontWeight:
                                      AppTheme.of(context).bodyMedium.fontWeight,
                                  fontStyle:
                                      AppTheme.of(context).bodyMedium.fontStyle,
                                ),
                                color: AppTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                              ),
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
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
                              padding: EdgeInsets.only(right: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28.0,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text('Delete Notification'),
                                  content: Text('Are you sure you want to delete this notification?'),
                                  backgroundColor: AppTheme.of(context).secondaryBackground,
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: AppTheme.of(context).secondaryText),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                            },
                            onDismissed: (direction) {
                              _deleteNotification(doc.reference);
                            },
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              onTap: () async {
                                await _handleNotificationTap(doc);
                              },
                              onLongPress: isRead ? () async {
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text('Notification Actions'),
                                    backgroundColor: AppTheme.of(context).secondaryBackground,
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            Icons.mark_email_unread,
                                            color: AppTheme.of(context).primary,
                                          ),
                                          title: Text('Mark as unread'),
                                          onTap: () => Navigator.of(dialogContext).pop('unread'),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          title: Text('Delete'),
                                          onTap: () => Navigator.of(dialogContext).pop('delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (result == 'unread') {
                                  await _markAsUnread(doc.reference);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Marked as unread'),
                                        backgroundColor: AppColors.fairway,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else if (result == 'delete') {
                                  await _deleteNotification(doc.reference);
                                }
                              } : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.of(context).secondaryBackground,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: AppTheme.of(context).alternate,
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 3.0,
                                      color: Color(0x33000000),
                                      offset: Offset(0.0, 1.0),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36.0,
                                      height: 36.0,
                                      decoration: BoxDecoration(
                                        color: _iconBgColorForType(context, type),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _iconForType(type),
                                        color:
                                            AppTheme.of(context).primaryBtnText,
                                        size: 18.0,
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
                                                      : _titleFallback(type),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTheme.of(context)
                                                      .bodyLarge
                                                      .override(
                                                        font: TextStyle(fontFamily: 'Manrope',
                                                          fontWeight: AppTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontWeight,
                                                          fontStyle: AppTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            AppTheme.of(context)
                                                                .bodyLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                              if (timeLabel.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      EdgeInsetsDirectional.only(
                                                    start: AppSpacing.xs,
                                                  ),
                                                  child: Text(
                                                    timeLabel,
                                                    style: AppTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          font:
                                                              TextStyle(fontFamily: 'Manrope',
                                                            fontWeight:
                                                                AppTheme.of(context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTheme.of(context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme.of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              if (!isRead)
                                                Container(
                                                  margin:
                                                      EdgeInsetsDirectional.only(
                                                    start: AppSpacing.xs,
                                                  ),
                                                  width: 8.0,
                                                  height: 8.0,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.of(context).primary,
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
                                                style: AppTheme.of(context)
                                                    .bodyMedium
                                                    .override(
                                                      font: TextStyle(fontFamily: 'Manrope',
                                                        fontWeight:
                                                            AppTheme.of(context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          AppTheme.of(context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          AppTheme.of(context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodyMedium
                                                              .fontStyle,
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
                                                  context.pushNamed('YourStanding');
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
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }
}
