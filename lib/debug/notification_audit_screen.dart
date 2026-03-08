import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/models/notification_receipt_event.dart';
import '/services/notification_audit_service.dart';
import '/services/notification_test_service.dart';

/// All 31 notification event types in the system.
const _allEventTypes = [
  'host_checkin_due',
  'player_rate_due',
  'host_checkin_fallback',
  'player_fallback_confirm',
  'no_show_flagged',
  'dispute_resolved',
  'strike_issued',
  'cooldown_started',
  'restriction_started',
  'suspension_started',
  'restriction_ended',
  'badge_earned',
  'badge_progress',
  'game_spot_opened',
  'game_cancelled',
  'game_alert_deferred',
  'friend_request_received',
  'friend_request_accepted',
  'join_request_new',
  'join_request_approved',
  'join_request_declined',
  'join_request_round_filled',
  'join_request_expired',
  'streak_weekend_nudge',
  'streak_freeze_unlocked',
  'streak_freeze_prompt',
  'streak_milestone_reached',
  'streak_broken',
  'player_added_by_host',
  'player_declined_spot',
  'host_pre_game_confirm',
];

/// Debug screen showing notification receipt audit trail.
///
/// Displays recent notification receipt events from Firestore, with
/// summary cards, filter chips, and the ability to send test notifications.
class NotificationAuditScreen extends StatefulWidget {
  const NotificationAuditScreen({super.key});

  static const routeName = 'NotificationAudit';
  static const routePath = '/debug/notification-audit';

  @override
  State<NotificationAuditScreen> createState() =>
      _NotificationAuditScreenState();
}

class _NotificationAuditScreenState extends State<NotificationAuditScreen> {
  final _testService = NotificationTestService();
  List<NotificationReceiptEvent> _events = [];
  bool _loading = true;
  String _filter = 'All';
  bool _smokeTesting = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      final events = await NotificationAuditService.instance.fetchRecent(
        uid,
        since: DateTime.now().subtract(const Duration(hours: 24)),
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      AppLog.d('❌ NotificationAuditScreen: Error loading receipts: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<NotificationReceiptEvent> get _filteredEvents {
    if (_filter == 'All') return _events;
    return _events.where((e) {
      switch (_filter) {
        case 'Foreground':
          return e.appState == NotificationAppState.foreground;
        case 'Background':
          return e.appState == NotificationAppState.backgroundOpen;
        case 'Cold Start':
          return e.appState == NotificationAppState.terminatedOpen;
        case 'Taps':
          return e.eventType == NotificationReceiptEventType.fgLocalTap ||
              e.eventType == NotificationReceiptEventType.bgOpened ||
              e.eventType == NotificationReceiptEventType.coldOpened;
        default:
          return true;
      }
    }).toList();
  }

  int _countByState(NotificationAppState state) =>
      _events.where((e) => e.appState == state).length;

  int _countTaps() => _events
      .where((e) =>
          e.eventType == NotificationReceiptEventType.fgLocalTap ||
          e.eventType == NotificationReceiptEventType.bgOpened ||
          e.eventType == NotificationReceiptEventType.coldOpened)
      .length;

  Future<void> _sendTestNotification(String eventType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _testService.sendTestNotification(
        eventType: eventType,
        recipientUserId: uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent $eventType'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _runFullSmokeTest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _smokeTesting = true);

    int sent = 0;
    int failed = 0;
    for (final eventType in _allEventTypes) {
      try {
        await _testService.sendTestNotification(
          eventType: eventType,
          recipientUserId: uid,
        );
        sent++;
      } catch (e) {
        AppLog.d('❌ Smoke test failed for $eventType: $e');
        failed++;
      }
      // Brief pause between sends to avoid overwhelming the pipeline
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Smoke test complete: $sent sent, $failed failed. '
            'Waiting 30s for delivery...'),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 5),
      ),
    );

    // Wait for notifications to be delivered
    await Future<void>.delayed(const Duration(seconds: 30));
    if (!mounted) return;

    await _loadReceipts();
    setState(() => _smokeTesting = false);
  }

  void _showSendTestBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.modal),
        ),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Send Test Notification',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _allEventTypes.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.navyLight),
                itemBuilder: (context, index) {
                  final type = _allEventTypes[index];
                  return ListTile(
                    title: Text(
                      type,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: AppIcon(
                      icon: PhosphorIconsRegular.paperPlaneTilt,
                      size: AppIconSize.sm,
                      color: AppColors.green,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _sendTestNotification(type);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        title: Text(
          'Notification Audit',
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSendTestBottomSheet,
        backgroundColor: AppColors.green,
        child: AppIcon(
          icon: PhosphorIconsRegular.paperPlaneTilt,
          size: AppIconSize.md,
          color: AppColors.textPrimary,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReceipts,
        color: AppColors.green,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.screen,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: AppSpacing.md),
                  _buildSmokeTestButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildFilterChips(),
                  const SizedBox(height: AppSpacing.md),
                  ..._filteredEvents.map(_buildEventRow),
                  if (_filteredEvents.isEmpty) _buildEmptyState(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildSummaryCard(
          'Foreground',
          _countByState(NotificationAppState.foreground),
          AppColors.green,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildSummaryCard(
          'Background',
          _countByState(NotificationAppState.backgroundOpen),
          AppColors.info,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildSummaryCard(
          'Cold Start',
          _countByState(NotificationAppState.terminatedOpen),
          AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildSummaryCard(
          'Taps',
          _countTaps(),
          AppColors.gold,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.monoDisplay.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTypography.labelMicro.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmokeTestButton() {
    return AppButtonEnhanced(
      text: _smokeTesting
          ? 'Running Smoke Test...'
          : 'Run Full Smoke Test (31 types)',
      variant: AppButtonVariant.secondary,
      onPressed: _smokeTesting ? null : _runFullSmokeTest,
      isLoading: _smokeTesting,
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Foreground', 'Background', 'Cold Start', 'Taps'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(
                f,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.green,
              backgroundColor: AppColors.navy,
              checkmarkColor: AppColors.textPrimary,
              side: BorderSide(
                color: isSelected ? AppColors.green : AppColors.navyLight,
              ),
              onSelected: (_) => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventRow(NotificationReceiptEvent event) {
    final badge = _eventTypeBadge(event.eventType);
    final time = _formatTime(event.eventAt);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs),
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badge.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xxs),
                      ),
                      child: Text(
                        badge.label,
                        style: AppTypography.labelMicro.copyWith(
                          color: badge.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        event.notificationType ?? 'unknown',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$time  ${event.messageId ?? event.dedupeKey ?? ''}',
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          AppIcon(
            icon: PhosphorIconsRegular.bellSlash,
            size: AppIconSize.xl,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No receipt events in the last 24 hours.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use the send button to trigger test notifications.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _EventBadge _eventTypeBadge(NotificationReceiptEventType type) {
    switch (type) {
      case NotificationReceiptEventType.fgReceived:
        return _EventBadge('FG Recv', AppColors.green);
      case NotificationReceiptEventType.fgLocalShown:
        return _EventBadge('FG Show', AppColors.info);
      case NotificationReceiptEventType.fgLocalTap:
        return _EventBadge('FG Tap', AppColors.gold);
      case NotificationReceiptEventType.bgOpened:
        return _EventBadge('BG Open', AppColors.warning);
      case NotificationReceiptEventType.coldOpened:
        return _EventBadge('Cold', AppColors.error);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _EventBadge {
  const _EventBadge(this.label, this.color);
  final String label;
  final Color color;
}
