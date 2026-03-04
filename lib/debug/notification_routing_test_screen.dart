import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/debug/components/game_picker_bottom_sheet.dart';
import '/debug/services/game_trust_status_service.dart';

/// Debug screen for testing notification tap → navigation routing.
///
/// Lists all notification types grouped by category. Tap any type to
/// navigate to the destination screen and verify routing works correctly.
class NotificationRoutingTestScreen extends StatefulWidget {
  const NotificationRoutingTestScreen({super.key});

  static const routeName = 'NotificationRoutingTest';
  static const routePath = '/debug/notification-routing';

  @override
  State<NotificationRoutingTestScreen> createState() =>
      _NotificationRoutingTestScreenState();
}

class _NotificationRoutingTestScreenState
    extends State<NotificationRoutingTestScreen> {
  static const _defaultGamePath = 'games/Z2tRgD57KF6R2nXVQFn6';

  final _trustService = GameTrustStatusService();

  DocumentReference? _selectedGameRef;
  String _selectedGameName = 'Default test game';
  GameTrustStatus? _trustStatus;
  bool _loadingStatus = false;

  DocumentReference get _testGameRef =>
      _selectedGameRef ?? FirebaseFirestore.instance.doc(_defaultGamePath);

  @override
  void initState() {
    super.initState();
    _loadTrustStatus();
  }

  Future<void> _loadTrustStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final status = await _trustService.fetchGameTrustStatus(_testGameRef);
      if (!mounted) return;
      setState(() {
        _trustStatus = status;
        _loadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _showGamePicker() async {
    final selected = await GamePickerBottomSheet.show(
      context,
      currentSelection: _selectedGameRef,
    );

    if (!mounted) return;
    if (selected != null) {
      // Fetch the game name
      final gameDoc = await selected.get();
      final gameName =
          (gameDoc.data() as Map<String, dynamic>?)?['name_game'] as String? ??
              'Selected game';

      if (!mounted) return;
      setState(() {
        _selectedGameRef = selected;
        _selectedGameName = gameName;
        _trustStatus = null;
      });
      _loadTrustStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        title: Text(
          'Notification Routing Test',
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          _buildInfoCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildCategory('Game Notifications', _gameNotifications),
          _buildCategory('Chat Notifications', _chatNotifications),
          _buildCategory('Trust Game Notifications', _trustGameNotifications),
          _buildCategory(
              'Account Standing Notifications', _accountNotifications),
          _buildCategory('Badge Notifications', _badgeNotifications),
          _buildCategory('Social Notifications', _socialNotifications),
          _buildCategory('Dispute Notifications', _disputeNotifications),
          _buildCategory(
              'Join Request Notifications', _joinRequestNotifications),
          _buildCategory('Streak Notifications', _streakNotifications),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                icon: PhosphorIconsRegular.info,
                color: AppColors.info,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'How to use',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap any notification type to navigate to its destination screen. '
            'This tests the routing logic used when users tap real notifications.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Selected game section
          _buildSelectedGameSection(),
        ],
      ),
    );
  }

  Widget _buildSelectedGameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected game:',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Game name + change button
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedGameName,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _showGamePicker,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon: PhosphorIconsRegular.caretDown,
                      size: AppIconSize.xs,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Change',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Trust status chips
        _buildTrustStatusChips(),
      ],
    );
  }

  Widget _buildTrustStatusChips() {
    if (_loadingStatus) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Checking prerequisites...',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    if (_trustStatus == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        _buildStatusChip(
          label: 'HostCheckin',
          valid: _trustStatus!.validForHostCheckin,
          detail: '${_trustStatus!.participantCount} participants',
        ),
        _buildStatusChip(
          label: 'PeerRating',
          valid: _trustStatus!.validForPeerRating,
          detail: _trustStatus!.hasAttendanceRecords
              ? 'attendance recorded'
              : 'no attendance',
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool valid,
    required String detail,
  }) {
    final color = valid ? AppColors.success : AppColors.textMuted;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: valid
                ? PhosphorIconsRegular.checkCircle
                : PhosphorIconsRegular.xCircle,
            size: AppIconSize.xs,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$label ($detail)',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    String title,
    List<_NotificationType> types,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...types.map((type) => _buildNotificationTile(type)),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildNotificationTile(_NotificationType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: InkWell(
          onTap: () => _navigateToDestination(type),
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.navyLight),
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: type.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Center(
                    child: AppIcon(
                      icon: type.icon,
                      color: type.iconColor,
                      size: AppIconSize.md,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.typeName,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '→ ${type.destinationScreen}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  color: AppColors.textMuted,
                  size: AppIconSize.sm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDestination(_NotificationType type) {
    switch (type.routeType) {
      case _RouteType.gameRef:
        context.pushNamed(
          type.routeName,
          extra: {'gameRef': _testGameRef},
        );
      case _RouteType.chatId:
        context.pushNamed(
          type.routeName,
          pathParameters: {'chatId': 'test-chat-id'},
        );
      case _RouteType.friendsRequests:
        context.pushNamed(
          type.routeName,
          extra: {'initialSegment': 'requests'},
        );
      case _RouteType.friendsFriends:
        context.pushNamed(
          type.routeName,
          extra: {'initialSegment': 'friends'},
        );
      case _RouteType.noParams:
        context.pushNamed(type.routeName);
      case _RouteType.gamesList:
        context.pushNamed(type.routeName);
    }
  }

  // Game Notifications
  List<_NotificationType> get _gameNotifications => [
        _NotificationType(
          typeName: 'game_created',
          destinationScreen: 'JoinGameDetailed',
          routeName: 'JoinGameDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'game_alert',
          destinationScreen: 'JoinGameDetailed',
          routeName: 'JoinGameDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.info,
        ),
      ];

  // Chat Notifications
  List<_NotificationType> get _chatNotifications => [
        _NotificationType(
          typeName: 'chat_message',
          destinationScreen: 'ChatDetails',
          routeName: 'ChatDetails',
          routeType: _RouteType.chatId,
          icon: PhosphorIconsRegular.chatCircle,
          iconColor: AppColors.navy,
        ),
      ];

  // Trust Game Notifications
  List<_NotificationType> get _trustGameNotifications => [
        _NotificationType(
          typeName: 'host_checkin_due',
          destinationScreen: 'HostCheckin',
          routeName: 'HostCheckin',
          routeType: _RouteType.gameRef,
          icon: PhosphorIconsRegular.calendarCheck,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'host_checkin_fallback',
          destinationScreen: 'HostCheckin',
          routeName: 'HostCheckin',
          routeType: _RouteType.gameRef,
          icon: PhosphorIconsRegular.calendarCheck,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'player_rate_due',
          destinationScreen: 'PeerRating',
          routeName: 'PeerRating',
          routeType: _RouteType.gameRef,
          icon: PhosphorIconsRegular.star,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'player_fallback_confirm',
          destinationScreen: 'FallbackConfirmation',
          routeName: 'FallbackConfirmation',
          routeType: _RouteType.gameRef,
          icon: PhosphorIconsRegular.calendarCheck,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'game_spot_opened',
          destinationScreen: 'JoinGameDetailed',
          routeName: 'JoinGameDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'game_cancelled',
          destinationScreen: 'JoinGameDetailed',
          routeName: 'JoinGameDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.info,
        ),
      ];

  // Account Standing Notifications
  List<_NotificationType> get _accountNotifications => [
        _NotificationType(
          typeName: 'no_show_flagged',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
        _NotificationType(
          typeName: 'dispute_resolved',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
        _NotificationType(
          typeName: 'strike_issued',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
        _NotificationType(
          typeName: 'cooldown_started',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
        _NotificationType(
          typeName: 'restriction_started',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
        _NotificationType(
          typeName: 'restriction_ended',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: AppPhosphorIcons.trust,
          iconColor: AppColors.success,
        ),
        _NotificationType(
          typeName: 'suspension_started',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
      ];

  // Badge Notifications
  List<_NotificationType> get _badgeNotifications => [
        _NotificationType(
          typeName: 'badge_earned',
          destinationScreen: 'MainProfile',
          routeName: 'MainProfile',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.medal,
          iconColor: AppColors.gold,
        ),
        _NotificationType(
          typeName: 'badge_progress',
          destinationScreen: 'MainProfile',
          routeName: 'MainProfile',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.medal,
          iconColor: AppColors.gold,
        ),
      ];

  // Social Notifications
  List<_NotificationType> get _socialNotifications => [
        _NotificationType(
          typeName: 'friend_request_received',
          destinationScreen: 'Tab_Friends (requests)',
          routeName: 'Tab_Friends',
          routeType: _RouteType.friendsRequests,
          icon: PhosphorIconsRegular.userPlus,
          iconColor: AppColors.green,
        ),
        _NotificationType(
          typeName: 'friend_request_accepted',
          destinationScreen: 'Tab_Friends (friends)',
          routeName: 'Tab_Friends',
          routeType: _RouteType.friendsFriends,
          icon: PhosphorIconsRegular.users,
          iconColor: AppColors.green,
        ),
      ];

  // Dispute Notifications
  List<_NotificationType> get _disputeNotifications => [
        _NotificationType(
          typeName: 'attendance_dispute',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.info,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'dispute_resolved_cleared',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.checkCircle,
          iconColor: AppColors.success,
        ),
        _NotificationType(
          typeName: 'dispute_resolved_upheld',
          destinationScreen: 'YourStanding',
          routeName: 'YourStanding',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.warning,
          iconColor: AppColors.error,
        ),
      ];

  // Join Request Notifications
  List<_NotificationType> get _joinRequestNotifications => [
        _NotificationType(
          typeName: 'join_request_new',
          destinationScreen: 'GameJoinedDetailed (host view)',
          routeName: 'GameJoinedDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'join_request_approved',
          destinationScreen: 'GameJoinedDetailed (now participant)',
          routeName: 'GameJoinedDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.success,
        ),
        _NotificationType(
          typeName: 'join_request_declined',
          destinationScreen: 'JoinGameDetailed (shows declined)',
          routeName: 'JoinGameDetailed',
          routeType: _RouteType.gameRef,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.error,
        ),
        _NotificationType(
          typeName: 'join_request_round_filled',
          destinationScreen: 'GamesList',
          routeName: 'GamesList',
          routeType: _RouteType.gamesList,
          icon: AppPhosphorIcons.games,
          iconColor: AppColors.info,
        ),
      ];

  // Streak Notifications
  List<_NotificationType> get _streakNotifications => [
        _NotificationType(
          typeName: 'streak_weekend_nudge',
          destinationScreen: 'GamesList',
          routeName: 'GamesList',
          routeType: _RouteType.gamesList,
          icon: PhosphorIconsRegular.flame,
          iconColor: AppColors.info,
        ),
        _NotificationType(
          typeName: 'streak_freeze_unlocked',
          destinationScreen: 'MainProfile',
          routeName: 'MainProfile',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.snowflake,
          iconColor: AppColors.gold,
        ),
        _NotificationType(
          typeName: 'streak_freeze_prompt',
          destinationScreen: 'MainProfile',
          routeName: 'MainProfile',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.snowflake,
          iconColor: AppColors.warning,
        ),
        _NotificationType(
          typeName: 'streak_milestone_reached',
          destinationScreen: 'MainProfile',
          routeName: 'MainProfile',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.trophy,
          iconColor: AppColors.gold,
        ),
        _NotificationType(
          typeName: 'streak_broken',
          destinationScreen: 'MainProfile',
          routeName: 'MainProfile',
          routeType: _RouteType.noParams,
          icon: PhosphorIconsRegular.heartBreak,
          iconColor: AppColors.error,
        ),
      ];
}

enum _RouteType {
  gameRef,
  chatId,
  friendsRequests,
  friendsFriends,
  noParams,
  gamesList,
}

class _NotificationType {
  final String typeName;
  final String destinationScreen;
  final String routeName;
  final _RouteType routeType;
  final PhosphorIconData icon;
  final Color iconColor;

  const _NotificationType({
    required this.typeName,
    required this.destinationScreen,
    required this.routeName,
    required this.routeType,
    required this.icon,
    required this.iconColor,
  });
}
