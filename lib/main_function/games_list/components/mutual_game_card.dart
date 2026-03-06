import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/components/game_card_avatar_stack.dart';
import '/main_function/games_list/components/game_card_detail_pills.dart';
import '/main_function/games_list/components/game_card_spots_badge.dart';
import '/main_function/games_list/components/mutual_card_actions.dart';
import '/main_function/games_list/components/mutual_friend_callout.dart';
import '/models/game.dart';

/// Amber/gold styled card for friends-only games visible via mutual friend.
///
/// This card has a distinct amber header with lock icon, muted content,
/// mutual friend callout banner, and action buttons for chat/friend request.
class MutualGameCard extends StatefulWidget {
  const MutualGameCard({
    super.key,
    required this.game,
    required this.mutualFriendName,
    required this.onAskToChat,
    required this.onAddFriend,
    this.additionalMutualCount = 0,
    this.chatState = MutualActionState.idle,
    this.friendState = MutualActionState.idle,
    this.animationIndex = 0,
  });

  final Game game;

  /// Name of the first mutual friend to display
  final String mutualFriendName;

  /// Number of additional mutual friends
  final int additionalMutualCount;

  /// Callback when "Ask to Chat" is tapped
  final VoidCallback onAskToChat;

  /// Callback when "Add Friend" is tapped
  final VoidCallback onAddFriend;

  /// Current state of the chat action
  final MutualActionState chatState;

  /// Current state of the friend request action
  final MutualActionState friendState;

  /// Index for staggered entrance animation
  final int animationIndex;

  @override
  State<MutualGameCard> createState() => _MutualGameCardState();
}

class _MutualGameCardState extends State<MutualGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final effectiveIndex =
        widget.animationIndex.clamp(0, MotionTokens.staggerMaxItems - 1);
    final staggerDelay = MotionTokens.staggerDelay * effectiveIndex;

    _controller = AnimationController(
      duration: MotionTokens.contentReveal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionTokens.curveEnter),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionTokens.curveEnter),
    );

    Future.delayed(staggerDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final game = widget.game;
    final spotsLeft = game.maxPlayers - game.playerCount;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.mutualCardGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.mutualBorder,
          width: 1.0,
        ),
        boxShadow: [AppElevation.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber header bar with lock icon
          _buildHeader(),
          // Main content (muted)
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row (no vibe ring for mutual cards)
                _buildCourseInfo(game),
                SizedBox(height: AppSpacing.sm),
                // Detail pills (muted)
                Opacity(
                  opacity: 0.65,
                  child: GameCardDetailPills(game: game),
                ),
                SizedBox(height: AppSpacing.sm),
                // Footer row with avatars and spots (muted)
                Opacity(
                  opacity: 0.65,
                  child: _buildFooterRow(game, spotsLeft),
                ),
                SizedBox(height: AppSpacing.md),
                // Mutual friend callout
                MutualFriendCallout(
                  mutualFriendName: widget.mutualFriendName,
                  additionalCount: widget.additionalMutualCount,
                ),
                SizedBox(height: AppSpacing.md),
                // Action buttons
                MutualCardActions(
                  onAskToChat: widget.onAskToChat,
                  onAddFriend: widget.onAddFriend,
                  chatState: widget.chatState,
                  friendState: widget.friendState,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.mutualHeaderGradient,
      ),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.lock,
            size: 12,
            color: AppColors.mutualAccent.withValues(alpha: 0.85),
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            'FRIENDS ONLY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.mutualAccent.withValues(alpha: 0.85),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            '\u{00B7}', // middle dot
            style: TextStyle(
              fontSize: 10,
              color: AppColors.mutualAccent.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'private game',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.mutualAccent.withValues(alpha: 0.5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfo(Game game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course name (slightly muted)
        Opacity(
          opacity: 0.85,
          child: Text(
            game.coursePlay,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.pure,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 4),
        // Date/time row (muted)
        Opacity(
          opacity: 0.65,
          child: _buildDateTimeRow(game),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(Game game) {
    String dateTimeStr;
    if (game.isFlexible) {
      dateTimeStr = game.flexibleSummary;
    } else {
      final date = game.date;
      if (date != null) {
        final dayOfWeek = _getDayOfWeek(date.weekday);
        final month = _getMonth(date.month);
        final timeStr = _formatTime(date);
        dateTimeStr = '$dayOfWeek, $month ${date.day} \u00B7 $timeStr';
      } else {
        dateTimeStr = 'Date TBD';
      }
    }

    return Row(
      children: [
        AppIcon(
          icon: AppPhosphorIcons.calendar,
          size: 12,
          color: AppColors.textMuted,
        ),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            dateTimeStr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow(Game game, int spotsLeft) {
    return Row(
      children: [
        // Avatar stack with host name (muted via parent opacity)
        Expanded(
          child: Opacity(
            opacity: 0.5,
            child: GameCardAvatarStack(
              playerRefs: game.joinedPlayers,
              hostRef: game.userRef,
            ),
          ),
        ),
        // Spots badge (muted via parent opacity)
        GameCardSpotsBadge(spotsLeft: spotsLeft),
      ],
    );
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
}
