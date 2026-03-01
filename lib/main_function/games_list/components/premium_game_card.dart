import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_expandable_text.dart';
import '/core/widgets/app_icon.dart';
import '/utils/app_util.dart';
import '/main_function/games_list/components/flexible_availability_summary.dart';
import '/main_function/games_list/games_list_widget.dart'
    show CancelledGameHandling;
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/providers/profile_provider.dart';

/// Premium-styled game card for the games list with entrance animation
class PremiumGameCard extends StatefulWidget {
  const PremiumGameCard({
    super.key,
    required this.game,
    required this.currentUserReference,
    this.isLocked = false,
    this.hasPendingFriendRequest = false,
    this.getCancelledHandling,
    this.onCancelledGameTap,
    this.onFriendsOnlyTap,
    this.onAddFriend,
    this.animationIndex = 0,
    this.staggerDelay = Duration.zero,
  });

  final Game game;
  final DocumentReference? currentUserReference;
  final bool isLocked;
  final bool hasPendingFriendRequest;
  final CancelledGameHandling? Function(Game game)? getCancelledHandling;
  final Future<void> Function(Game game)? onCancelledGameTap;
  final Future<void> Function()? onFriendsOnlyTap;
  final Future<void> Function()? onAddFriend;
  final int animationIndex;
  final Duration staggerDelay;

  @override
  State<PremiumGameCard> createState() => _PremiumGameCardState();
}

class _PremiumGameCardState extends State<PremiumGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    final isLocked = widget.isLocked;
    final isOwner =
        currentUserReference != null && game.userRef == currentUserReference;
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
    final isCancelled = game.status == 'cancelled';
    final isExpired = game.status == 'expired';
    final spotsLeft = game.maxPlayers -
        (game.joinedPlayers.length + game.guestPlayers.length);
    final isFull = spotsLeft <= 0;
    final ownerRef = game.userRef;

    return GestureDetector(
      onTap: () async {
        if (isLocked && !isCancelled) {
          await widget.onFriendsOnlyTap?.call();
        } else if (isUserGame) {
          // Navigate to joined game detail (includes cancelled games user joined)
          context.pushGameJoinedDetailed(
            gameRef: game.reference,
          );
        } else {
          // Navigate to join game detail (includes cancelled games - will show banner)
          context.pushJoinGameDetailed(
            gameRef: game.reference,
          );
        }
      },
      child: Opacity(
        opacity: isCancelled ? 0.65 : 1.0,
        child: Container(
          clipBehavior: Clip.antiAlias,
          width: double.infinity,
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
            children: [
              // Main content
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Game Type Badge + Status + Spots indicator
                    _buildTopRow(
                      isLocked: isLocked,
                      isUserGame: isUserGame,
                      isCancelled: isCancelled,
                      isExpired: isExpired,
                      isOwner: isOwner,
                    ),
                    SizedBox(height: AppSpacing.md),
                    // Course Name - Hero Element with icon
                    _buildCourseSection(
                      isUserGame: isUserGame,
                      isLocked: isLocked,
                      ownerRef: ownerRef,
                    ),
                    SizedBox(height: AppSpacing.md),
                    // Date & Time with premium styling
                    _buildDateTimeSection(
                      isUserGame: isUserGame,
                      isFull: isFull,
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

  Widget _buildTopRow({
    required bool isLocked,
    required bool isUserGame,
    required bool isCancelled,
    required bool isExpired,
    required bool isOwner,
  }) {
    return Row(
      children: [
        if (isLocked)
          Tooltip(
            message: 'Friends-only game',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.lock,
                    size: AppIconSize.xs,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Friends Only',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isLocked) SizedBox(width: AppSpacing.xs),
        // Just for Fun pill
        if (widget.game.isFunGame)
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                border: Border.all(
                  color: AppColors.navyLight,
                  width: 1.0,
                ),
              ),
              child: Text(
                'Just for Fun',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        // Game Type Badge
        else if (widget.game.gameType.isNotEmpty)
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                border: Border.all(
                  color: AppColors.navyLight,
                  width: 1.0,
                ),
              ),
              child: Text(
                widget.game.gameType,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (widget.game.styleGame == 'Money Game') ...[
          SizedBox(width: AppSpacing.xs),
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Text(
                '\$\$\$',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        // Player eligibility badge
        if (widget.game.playerEligibility == PlayerEligibility.womenOnly) ...[
          SizedBox(width: AppSpacing.xs),
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Text(
                'Women Only',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else if (widget.game.playerEligibility ==
            PlayerEligibility.menOnly) ...[
          SizedBox(width: AppSpacing.xs),
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Text(
                'Men Only',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        // Member discount badge
        if (widget.game.memberDiscount == 'Yes') ...[
          SizedBox(width: AppSpacing.xs),
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.memberDiscount,
                color: AppColors.green,
                size: AppIconSize.xs,
              ),
            ),
          ),
        ],
        Spacer(),
        // Add Friend button for locked games (top right)
        if (isLocked && widget.onAddFriend != null) _buildAddFriendButton(),
        // Status badges for non-locked games
        if (!isLocked)
          _buildStatusBadge(
            isCancelled: isCancelled,
            isExpired: isExpired,
            isOwner: isOwner,
            isUserGame: isUserGame,
          ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required bool isCancelled,
    required bool isExpired,
    required bool isOwner,
    required bool isUserGame,
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
    } else if (isExpired) {
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
          'Expired',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (isOwner) {
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
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (isUserGame) {
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
    return SizedBox.shrink();
  }

  /// Builds the Add Friend button for locked games
  Widget _buildAddFriendButton() {
    if (widget.hasPendingFriendRequest) {
      // Show "Pending" state
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Text(
          'Pending',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Show "+ Add Friend" button
    return GestureDetector(
      onTap: widget.onAddFriend,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.addPlayer,
              size: AppIconSize.xs,
              color: AppColors.green,
            ),
            SizedBox(width: 4),
            Text(
              'Add Friend',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSection({
    required bool isUserGame,
    required bool isLocked,
    required DocumentReference? ownerRef,
  }) {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.course,
                color: AppColors.textSecondary,
                size: AppIconSize.button,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppExpandableText(
                  text: widget.game.coursePlay.isEmpty
                      ? 'Course TBD'
                      : widget.game.coursePlay,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontStyle: widget.game.coursePlay.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 1,
                ),
                Text(
                  valueOrDefault<String>(widget.game.nameGame, 'Game Name'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isLocked) _LockedGameHostLabel(ownerRef: ownerRef),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection({
    required bool isUserGame,
    required bool isFull,
  }) {
    // Flexible games use the unified summary with built-in icon and spots
    if (widget.game.isFlexible) {
      return Opacity(
        opacity: isUserGame ? 0.65 : 1.0,
        child: FlexibleAvailabilitySummary(game: widget.game),
      );
    }

    // Fixed-time games use the glass container with date/time and player count
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppPhosphorIcons.calendarCheck,
                  color: AppColors.textSecondary,
                  size: AppIconSize.xs,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dateTimeFormat("EEEE", widget.game.date)}, ${dateTimeFormat("MMM d", widget.game.date)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateTimeFormat("jm", widget.game.date),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.glassTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Player count indicator
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isFull
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.navy,
                borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                border: Border.all(
                  color: isFull
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.navyLight,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.golfers,
                    color: isFull ? AppColors.error : AppColors.textSecondary,
                    size: AppIconSize.xs,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${widget.game.joinedPlayers.length + widget.game.guestPlayers.length}/${widget.game.maxPlayers}',
                    style: AppTypography.labelMicro.copyWith(
                      color: isFull ? AppColors.error : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display the host label for locked games
class _LockedGameHostLabel extends StatelessWidget {
  const _LockedGameHostLabel({required this.ownerRef});

  final DocumentReference? ownerRef;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.glassTextSecondary,
      fontWeight: FontWeight.w500,
    );

    if (ownerRef == null) {
      return Text('Host: Unknown', style: style);
    }

    return Selector<ProfileProvider, String?>(
      selector: (context, profileProvider) =>
          profileProvider.getCachedProfile(ownerRef!.id)?.displayName,
      builder: (context, hostName, _) {
        final label = hostName != null && hostName.trim().isNotEmpty
            ? hostName.trim()
            : 'Unknown';
        return Text('Host: $label', style: style);
      },
    );
  }
}
