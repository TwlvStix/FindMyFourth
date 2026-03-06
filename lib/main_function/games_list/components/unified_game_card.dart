import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/main_function/games_list/components/game_card_avatar_stack.dart';
import '/main_function/games_list/components/game_card_detail_pills.dart';
import '/main_function/games_list/components/game_card_spots_badge.dart';
import '/main_function/games_list/components/game_card_vibe_ring.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/utils/app_util.dart';

/// Unified game card with vibe ring, detail pills, avatar stack, and spots badge.
///
/// This card design merges both flexible and scheduled games into a single
/// unified layout. Flexible games are distinguished by a green accent bar
/// and "FLEXIBLE" badge.
class UnifiedGameCard extends StatefulWidget {
  const UnifiedGameCard({
    super.key,
    required this.game,
    required this.currentUserReference,
    this.vibeScore,
    this.isLocked = false,
    this.showStatusBadge = false,
    this.animationIndex = 0,
    this.onTap,
  });

  final Game game;
  final DocumentReference? currentUserReference;

  /// Vibe match score (0-100). If null, vibe ring is hidden.
  final double? vibeScore;

  /// Whether this is a friends-only locked game
  final bool isLocked;

  /// Whether to show status badge (Owner/Joined/Cancelled/Played).
  /// Used on My Games page to indicate user's relationship to the game.
  final bool showStatusBadge;

  /// Index for staggered entrance animation
  final int animationIndex;

  /// Custom tap handler (defaults to navigation)
  final VoidCallback? onTap;

  @override
  State<UnifiedGameCard> createState() => _UnifiedGameCardState();
}

class _UnifiedGameCardState extends State<UnifiedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Cap stagger at max items
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

    // Start animation after stagger delay
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
    final currentUserReference = widget.currentUserReference;
    final isFlexible = game.isFlexible;
    final isCancelled = game.status == 'cancelled';
    final isExpired = game.date != null &&
        game.date!.isBefore(getCurrentTimestamp) &&
        !isCancelled;
    final isOwner =
        currentUserUid.isNotEmpty && game.userRef?.id == currentUserUid;
    final spotsLeft = game.maxPlayers - game.playerCount;
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
          return;
        }
        // Default navigation
        if (isUserGame) {
          context.pushGameJoinedDetailed(gameRef: game.reference);
        } else {
          context.pushJoinGameDetailed(gameRef: game.reference);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: _isPressed
            ? (Matrix4.identity()..setEntry(0, 0, 0.982)..setEntry(1, 1, 0.982))
            : Matrix4.identity(),
        child: Opacity(
          opacity: isCancelled ? 0.65 : 1.0,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
              border: Border.all(
                color: AppColors.navyLight,
                width: 1.0,
              ),
              boxShadow: [AppElevation.card],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green accent bar for flexible games
                if (isFlexible)
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.green, AppColors.greenLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                // Main content
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with vibe ring and optional status badge
                      _buildHeaderRow(
                        isFlexible: isFlexible,
                        isCancelled: isCancelled,
                        isExpired: isExpired,
                        isOwner: isOwner,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      // Detail pills
                      GameCardDetailPills(game: game),
                      SizedBox(height: AppSpacing.sm),
                      // Footer row with avatars and spots
                      _buildFooterRow(spotsLeft: spotsLeft),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required bool isFlexible,
    required bool isCancelled,
    required bool isExpired,
    required bool isOwner,
  }) {
    final game = widget.game;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: course info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flexible badge
              if (isFlexible)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                      border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '\u26A1 FLEXIBLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                ),
              // Course name (only if set)
              if (game.coursePlay.isNotEmpty) ...[
                Text(
                  game.coursePlay,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.pure,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
              ],
              // Date/time/distance row
              _buildDateTimeRow(),
            ],
          ),
        ),
        // Right side: status badge and/or vibe ring
        if (widget.showStatusBadge)
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: _buildStatusBadge(
              isCancelled: isCancelled,
              isExpired: isExpired,
              isOwner: isOwner,
            ),
          ),
        if (widget.vibeScore != null)
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm),
            child: GameCardVibeRing(
              vibeScore: widget.vibeScore!,
              animationDelay: MotionTokens.staggerDelay * widget.animationIndex,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required bool isCancelled,
    required bool isExpired,
    required bool isOwner,
  }) {
    if (isCancelled) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'Cancelled',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isExpired) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Text(
          'Played',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isOwner) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.owner,
              color: AppColors.pure,
              size: AppIconSize.xs,
            ),
            SizedBox(width: 4),
            Text(
              'Owner',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.pure,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Default: Joined
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.stone.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.joined,
            color: AppColors.pure,
            size: AppIconSize.xs,
          ),
          SizedBox(width: 4),
          Text(
            'Joined',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow() {
    final game = widget.game;

    // Build date/time string
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

    // Determine trailing icon (Member Rate takes priority, then Gender)
    final trailingIcon = _getTrailingIcon();

    return Row(
      children: [
        AppIcon(
          icon: AppPhosphorIcons.calendar,
          size: 12,
          color: AppColors.textMuted,
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            dateTimeStr,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          SizedBox(width: AppSpacing.xs),
          AppIcon(
            icon: trailingIcon,
            size: AppIconSize.sm,
            color: AppColors.textSecondary,
          ),
        ],
      ],
    );
  }

  /// Returns icon for Member Rate or Gender restriction (icon only, no text).
  /// Member Rate takes priority over Gender.
  PhosphorIconData? _getTrailingIcon() {
    final game = widget.game;

    // 1. Member Rate (priority)
    if (game.memberDiscount == 'Yes') {
      return AppPhosphorIcons.memberDiscount;
    }

    // 2. Gender restriction
    if (game.playerEligibility == PlayerEligibility.womenOnly) {
      return AppPhosphorIcons.womenOnly;
    }
    if (game.playerEligibility == PlayerEligibility.menOnly) {
      return AppPhosphorIcons.menOnly;
    }

    return null;
  }

  Widget _buildFooterRow({required int spotsLeft}) {
    final game = widget.game;

    return Row(
      children: [
        // Avatar stack with host name
        Expanded(
          child: GameCardAvatarStack(
            playerRefs: game.joinedPlayers,
            hostRef: game.userRef,
          ),
        ),
        // Spots badge
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
