import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/app_router.dart';
import '/core/widgets/fairway_background.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
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

  IconData _iconForType(String type) {
    if (type == 'chat_message') {
      return Icons.chat_bubble_outline;
    }
    if (_isGameNotification(type)) {
      return Icons.sports_golf;
    }
    return Icons.notifications_none;
  }

  String _titleFallback(String type) {
    if (type == 'chat_message') {
      return 'New message';
    }
    if (_isGameNotification(type)) {
      return 'New game posted';
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
        backgroundColor: AppTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.of(context).primaryText,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Notifications',
            style: AppTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight: AppTheme.of(context).headlineLarge.fontWeight,
                    fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: AppTheme.of(context).headlineLarge.fontWeight,
                  fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
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
                          style: AppTheme.of(context).labelLarge.override(
                                font: GoogleFonts.outfit(
                                  fontWeight:
                                      AppTheme.of(context).labelLarge.fontWeight,
                                  fontStyle:
                                      AppTheme.of(context).labelLarge.fontStyle,
                                ),
                                color: hasUnread
                                    ? AppTheme.of(context).primary
                                    : AppTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                              ),
                        ),
                      );
                    },
                  ),
                ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          child: userRef == null
              ? Center(
                  child: Text(
                    'Please sign in to view notifications.',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
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
                                font: GoogleFonts.outfit(
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
                                font: GoogleFonts.outfit(
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
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xxxl,
                        ),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final doc = docs[index] as QueryDocumentSnapshot;
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
                          return InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () async {
                              await _handleNotificationTap(doc);
                            },
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
                                      color: AppTheme.of(context).primary,
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
                                                      font: GoogleFonts.outfit(
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
                                                            GoogleFonts.outfit(
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
                                                    font: GoogleFonts.outfit(
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
                                      ],
                                    ),
                                  ),
                                ],
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
    );
  }
}
