import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/utils/app_util.dart';
import '/utils/availability_text_helper.dart';
import '/utils/game_tag_helper.dart';

/// Compact card for flexible games in the horizontal carousel shelf.
/// Dimensions: ~260px width x 100px height
///
/// Layout:
/// - Row 1: Course name + Player count
/// - Row 2: Calendar icon + Availability (collapsed format)
/// - Row 3: Stakes tag (color-coded) or format fallback
class FlexibleGameCompactCard extends StatefulWidget {
  const FlexibleGameCompactCard({
    super.key,
    required this.game,
    required this.currentUserReference,
    this.animationIndex = 0,
  });

  final Game game;
  final DocumentReference? currentUserReference;
  final int animationIndex;

  @override
  State<FlexibleGameCompactCard> createState() =>
      _FlexibleGameCompactCardState();
}

class _FlexibleGameCompactCardState extends State<FlexibleGameCompactCard>
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
      begin: const Offset(0.08, 0), // Slide from right for horizontal scroll
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
    final currentUserReference = widget.currentUserReference;
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
    final isCancelled = game.status == 'cancelled';

    return GestureDetector(
      onTap: () {
        if (isUserGame) {
          context.pushGameJoinedDetailed(
            gameRef: game.reference,
          );
        } else {
          context.pushJoinGameDetailed(
            gameRef: game.reference,
          );
        }
      },
      child: Opacity(
        opacity: isCancelled ? 0.65 : 1.0,
        child: Container(
          width: 260,
          height: 100,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.navyLight,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Gold accent bar on the left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.lg - 1),
                      bottomLeft: Radius.circular(AppBorderRadius.lg - 1),
                    ),
                  ),
                ),
              ),
              // Cancelled badge (top-right)
              if (isCancelled)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Cancelled',
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Main content
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.sm + 4, // Extra padding for gold bar
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row 1: Course name + Player count
                    _buildRow1(game),
                    // Row 2: Availability with calendar icon
                    _buildRow2(game),
                    // Row 3: Stakes tag (THE HOOK)
                    _buildRow3(game),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Row 1: Course name (left) + Player count (right)
  Widget _buildRow1(Game game) {
    final playerCount = game.joinedPlayers.length + game.guestPlayers.length;

    return Row(
      children: [
        Expanded(
          child: Text(
            game.coursePlay,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        // Player count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.golfers,
              color: AppColors.textSecondary,
              size: AppIconSize.xs,
            ),
            SizedBox(width: 4),
            Text(
              '$playerCount/${game.maxPlayers}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Row 2: Calendar icon + Availability (collapsed format)
  Widget _buildRow2(Game game) {
    final availability = formatFlexibleAvailability(game);

    return Row(
      children: [
        AppIcon(
          icon: AppPhosphorIcons.calendar,
          color: AppColors.textSecondary,
          size: AppIconSize.xs,
        ),
        SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            availability,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Row 3: Stakes tag (left) + Eligibility pill (right)
  Widget _buildRow3(Game game) {
    final tags = getRow3Tags(game);
    final eligibilityLabel = _getEligibilityLabel(game);

    // If no stakes AND no eligibility, show nothing
    if (tags.isEmpty && eligibilityLabel == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Stakes/format tag on LEFT
        if (tags.isNotEmpty) _buildTag(tags.first),

        // Spacer pushes eligibility to right
        const Spacer(),

        // Eligibility pill on RIGHT (only if restricted)
        if (eligibilityLabel != null) _buildEligibilityPill(eligibilityLabel),
      ],
    );
  }

  /// Get eligibility label for restricted games
  String? _getEligibilityLabel(Game game) {
    switch (game.playerEligibility) {
      case PlayerEligibility.openToAll:
        return null;
      case PlayerEligibility.womenOnly:
        return 'WOMEN ONLY';
      case PlayerEligibility.menOnly:
        return 'MEN ONLY';
    }
  }

  /// Build eligibility pill with muted styling
  Widget _buildEligibilityPill(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTypography.labelMicro.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Build a single tag chip with appropriate color styling
  Widget _buildTag(GameTag tag) {
    final colors = _getTagColors(tag);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        tag.label,
        style: AppTypography.labelMicro.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Get foreground and background colors based on tag type
  _TagColors _getTagColors(GameTag tag) {
    if (tag.stakesLevel != null) {
      switch (tag.stakesLevel!) {
        case StakesLevel.noMoney:
          // Muted appearance - recedes
          return _TagColors(
            foreground: AppColors.textMuted,
            background: AppColors.textMuted.withValues(alpha: 0.1),
          );
        case StakesLevel.lowStakes:
          // Warm gold tone - attention
          return _TagColors(
            foreground: AppColors.gold,
            background: AppColors.gold.withValues(alpha: 0.15),
          );
        case StakesLevel.highStakes:
          // Hot red/orange - demands attention
          return _TagColors(
            foreground: AppColors.error,
            background: AppColors.error.withValues(alpha: 0.15),
          );
      }
    }

    // Format fallback - neutral gold
    return _TagColors(
      foreground: AppColors.gold,
      background: AppColors.gold.withValues(alpha: 0.1),
    );
  }
}

/// Helper class for tag color pairs
class _TagColors {
  const _TagColors({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}
