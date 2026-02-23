import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/app_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/utils/app_util.dart';
import '/main_function/game_joined_detailed/game_joined_detailed_widget.dart';
import '/main_function/join_game_detailed/join_game_detailed_widget.dart';
import '/main_function/games_list/components/flexible_time_display.dart';
import '/main_function/games_list/games_list_widget.dart' show CancelledGameHandling;
import '/models/game.dart';
import '/providers/profile_provider.dart';
import '/backend/backend.dart';
import '/friends/tab_friends/tab_friends_widget.dart';

/// Premium-styled game card for the games list with entrance animation
class PremiumGameCard extends StatefulWidget {
  const PremiumGameCard({
    super.key,
    required this.game,
    required this.currentUserReference,
    this.isLocked = false,
    this.getCancelledHandling,
    this.onCancelledGameTap,
    this.onFriendsOnlyTap,
    this.animationIndex = 0,
    this.staggerDelay = Duration.zero,
  });

  final Game game;
  final DocumentReference? currentUserReference;
  final bool isLocked;
  final CancelledGameHandling? Function(Game game)? getCancelledHandling;
  final Future<void> Function(Game game)? onCancelledGameTap;
  final Future<void> Function()? onFriendsOnlyTap;
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
    final effectiveIndex = widget.animationIndex.clamp(0, MotionTokens.staggerMaxItems - 1);
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
    final isOwner = currentUserReference != null &&
        game.userRef == currentUserReference;
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
        if (isCancelled) {
          if (widget.getCancelledHandling?.call(game) == null) {
            await widget.onCancelledGameTap?.call(game);
          }
        } else if (isLocked) {
          await widget.onFriendsOnlyTap?.call();
        } else if (isUserGame) {
          context.pushNamed(
            GameJoinedDetailedWidget.routeName,
            extra: <String, dynamic>{
              'gameRef': game.reference,
              kTransitionInfoKey: TransitionStandards.detailTransition,
            },
          );
        } else {
          context.pushNamed(
            JoinGameDetailedWidget.routeName,
            extra: <String, dynamic>{
              'gameRef': game.reference,
              kTransitionInfoKey: TransitionStandards.detailTransition,
            },
          );
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isUserGame
              ? AppColors.navy.withValues(alpha: 0.15)
              : AppColors.navy.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: isUserGame
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
          boxShadow: null,
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
            // Bottom action bar
            if (!isCancelled && !isExpired)
              _buildBottomActionBar(
                context: context,
                isLocked: isLocked,
                isUserGame: isUserGame,
                isFull: isFull,
              ),
          ],
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
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.lock,
                    size: AppIconSize.xs,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Friends Only',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
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
                gradient: LinearGradient(
                  colors: [AppColors.navyLight, AppColors.navy],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                boxShadow: [AppElevation.md],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    assetPath: AppIcons.games,
                    color: AppColors.pure,
                    size: AppIconSize.xs,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Just for Fun',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        // Game Type Badge with gradient
        else if (widget.game.gameType.isNotEmpty)
          Opacity(
            opacity: isUserGame ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.game.styleGame == 'Money Game'
                      ? [AppColors.gold, AppColors.goldLight]
                      : [AppColors.navyLight, AppColors.navy],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: (widget.game.styleGame == 'Money Game'
                            ? AppColors.gold
                            : AppColors.navy)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.game.gameType,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
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
        Spacer(),
        // Status badges
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
                color: Colors.white,
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
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
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
              gradient: LinearGradient(
                colors: [AppColors.navyLight, AppColors.navy],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.course,
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
                Text(
                  widget.game.coursePlay.isEmpty ? 'Course TBD' : widget.game.coursePlay,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        widget.game.coursePlay.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  valueOrDefault<String>(widget.game.nameGame, 'Game Name'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gold,
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
                color: AppColors.goldLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppPhosphorIcons.calendarCheck,
                  color: AppColors.goldLight,
                  size: AppIconSize.xs,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            if (widget.game.isFlexible) ...[
              Expanded(
                child: FlexibleTimeDisplay(
                  game: widget.game,
                  showWeekLabel: true,
                  compact: true,
                ),
              ),
            ] else ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dateTimeFormat("EEEE", widget.game.date)}, ${dateTimeFormat("MMM d", widget.game.date)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
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
            ],
            // Player count indicator
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isFull
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.navyLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                border: Border.all(
                  color: isFull
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.glassSurface,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.golfers,
                    color: isFull ? AppColors.error : AppColors.pure,
                    size: AppIconSize.xs,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${widget.game.joinedPlayers.length + widget.game.guestPlayers.length}/${widget.game.maxPlayers}',
                    style: AppTypography.labelSmall.copyWith(
                      color: isFull ? AppColors.error : Colors.white,
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

  Widget _buildBottomActionBar({
    required BuildContext context,
    required bool isLocked,
    required bool isUserGame,
    required bool isFull,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.xl),
          bottomRight: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: Row(
        children: [
          // Member discount badge
          if (widget.game.memberDiscount == 'Yes')
            Opacity(
              opacity: isUserGame ? 0.65 : 1.0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon: AppPhosphorIcons.memberDiscount,
                      color: AppColors.navyLight,
                      size: AppIconSize.xs,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Discount',
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.pure,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Spacer(),
          // Action button
          _buildActionButton(
            context: context,
            isLocked: isLocked,
            isUserGame: isUserGame,
            isFull: isFull,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isLocked,
    required bool isUserGame,
    required bool isFull,
  }) {
    if (isLocked) {
      return InkWell(
        onTap: () {
          context.pushNamed(TabFriendsWidget.routeName);
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.goldLight],
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            boxShadow: [AppElevation.md],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: AppPhosphorIcons.addPlayer,
                color: AppColors.pure,
                size: AppIconSize.xs,
              ),
              SizedBox(width: 6),
              Text(
                'Add Friend',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: isUserGame
            ? null
            : LinearGradient(colors: [AppColors.gold, AppColors.goldLight]),
        border: isUserGame
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              )
            : null,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: isUserGame
            ? null
            : [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUserGame)
            AppIcon(
              icon: AppPhosphorIcons.eye,
              color: AppColors.pure,
              size: AppIconSize.xs,
            )
          else if (isFull)
            AppIcon(
              icon: AppPhosphorIcons.pending,
              color: AppColors.pure,
              size: AppIconSize.xs,
            )
          else
            AppIcon(
              icon: AppPhosphorIcons.add,
              color: AppColors.pure,
              size: AppIconSize.xs,
            ),
          SizedBox(width: 6),
          Text(
            isUserGame ? 'View Details' : (isFull ? 'Full' : 'Join Game'),
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
