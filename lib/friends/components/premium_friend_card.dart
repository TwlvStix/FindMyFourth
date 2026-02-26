import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';

/// Redesigned premium friend card matching LuxuryPlayerCard design language:
/// - Dark fairway surface (AppColors.navy @ 30% alpha)
/// - Rounded-square avatars (52×52, radius 14)
/// - Manrope typography with cream/gold color tokens
/// - 20px border radius, consistent padding (20h × 18v)
class PremiumFriendCard extends StatefulWidget {
  // LuxuryPlayerCard design tokens — using AppColors
  static final Color textPrimary = AppColors.sand;
  static final Color textMuted = AppColors.glassTextTertiary;
  static final Color goldAccent = AppColors.goldLight;
  final UsersRecord user;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onAction;
  final String messageLabel;
  final PhosphorIconData? messageIcon;
  final String? messageSvgPath;
  final String actionLabel;
  final PhosphorIconData? actionIcon;
  final String? actionSvgPath;
  final Color actionColor;
  final bool showActionButton;
  final bool isLoading;
  final int? mutualFriendsCount;
  final int? gamesPlayedTogether;
  final bool isOnline;
  final String? lastActive;
  final UsersRecord? currentUser; // For vibe matching

  const PremiumFriendCard({
    super.key,
    required this.user,
    this.onViewProfile,
    this.onMessage,
    this.onAction,
    this.messageLabel = 'Chat',
    this.messageIcon = AppPhosphorIcons.chat,
    this.messageSvgPath,
    this.actionLabel = 'Add',
    this.actionIcon = AppPhosphorIcons.addPlayer,
    this.actionSvgPath,
    this.actionColor = AppColors.navy,
    this.showActionButton = true,
    this.isLoading = false,
    this.mutualFriendsCount,
    this.gamesPlayedTogether,
    this.isOnline = false,
    this.lastActive,
    this.currentUser,
  });

  @override
  State<PremiumFriendCard> createState() => _PremiumFriendCardState();
}

class _PremiumFriendCardState extends State<PremiumFriendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  VibeMatchResult? _vibeMatch;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: MotionTokens.curveEnter),
    );

    _calculateVibeMatch();
  }

  @override
  void didUpdateWidget(PremiumFriendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate vibe match if user data changed
    if (oldWidget.user.reference.id != widget.user.reference.id ||
        oldWidget.user.vibeProfile != widget.user.vibeProfile ||
        oldWidget.currentUser?.vibeProfile != widget.currentUser?.vibeProfile) {
      _calculateVibeMatch();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _calculateVibeMatch() {
    if (widget.currentUser != null &&
        widget.currentUser!.vibeProfile.isNotEmpty &&
        widget.user.vibeProfile.isNotEmpty) {
      try {
        final myProfile =
            VibeProfile.fromFirestore(widget.currentUser!.vibeProfile);
        final theirProfile = VibeProfile.fromFirestore(widget.user.vibeProfile);
        _vibeMatch = VibeMatcher.score(myProfile, theirProfile);
      } catch (e) {
        _vibeMatch = null;
      }
    } else {
      _vibeMatch = null;
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onViewProfile,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.navy.withValues(alpha: 0.4)
                : AppColors.navy.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          child: Column(
            children: [

              // Main content with responsive layout
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        // Avatar
                        _buildAvatar(),

                        SizedBox(width: AppSpacing.md),

                        // User info - gets priority with Expanded
                        Expanded(
                          child: _buildUserInfo(constraints.maxWidth),
                        ),

                        SizedBox(width: AppSpacing.sm),

                        // Actions (responsive - adapts to available space)
                        _buildResponsiveActions(constraints.maxWidth),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg - 1),
        child: widget.user.photoUrl.isNotEmpty
            ? Image.network(
                widget.user.photoUrl,
                width: 52,
                height: 52,
                cacheWidth: 156,
                cacheHeight: 156,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(),
              )
            : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final initials = _getInitials(widget.user.displayName);

    return Container(
      color: AppColors.navy,
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              )
            : AppIcon(
                icon: AppPhosphorIcons.profile,
                color: AppColors.textMuted,
                size: AppIconSize.md,
              ),
      ),
    );
  }

  /// Extracts up to 2 initials from a display name
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  Widget _buildUserInfo(double availableWidth) {
    final displayName = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : 'Golfer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // NAME - Hero element with cream color
        Text(
          displayName,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 15,
            color: PremiumFriendCard.textPrimary,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        AppSpacing.verticalXxs,

        // Secondary badges row: vibe % + handicap
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (_vibeMatch != null) _buildVibeBadge(),
            if (widget.user.handicap != 0)
              _buildHandicapBadge(widget.user.handicap),
          ],
        ),
      ],
    );
  }

  Widget _buildVibeBadge() {
    if (_vibeMatch == null) return SizedBox.shrink();

    final score = _vibeMatch!.myFitPercent.round();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xs),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.heartFill,
            size: 10,
            color: AppColors.textMuted,
          ),
          AppSpacing.horizontalXxs,
          Text(
            '$score%',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandicapBadge(int handicap) {
    final handicapText = handicap < 0 ? '+${handicap.abs()}' : '$handicap';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppBorderRadius.xs),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: Text(
        'HCP $handicapText',
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildResponsiveActions(double availableWidth) {
    // Always use icon-only buttons for compact design
    final actions = <Widget>[];

    // Message button (secondary - ghost style)
    if (widget.onMessage != null) {
      actions.add(
        _buildIconOnlyButton(
          icon: widget.messageIcon,
          svgPath: widget.messageSvgPath,
          onPressed: widget.onMessage!,
          isPrimary: false,
          tooltip: widget.messageLabel,
        ),
      );
    }

    // Action button (primary - Add Friend is the main CTA)
    if (widget.showActionButton) {
      actions.add(
        _buildIconOnlyButton(
          icon: widget.actionIcon,
          svgPath: widget.actionSvgPath,
          onPressed: widget.onAction,
          isPrimary: true,
          isLoading: widget.isLoading,
          tooltip: widget.actionLabel,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .expand((widget) => [widget, AppSpacing.horizontalXsBox])
          .toList()
        ..removeLast(), // Remove last spacer
    );
  }

  Widget _buildIconOnlyButton({
    PhosphorIconData? icon,
    String? svgPath,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isLoading = false,
    String? tooltip,
  }) {
    // Primary: green filled (Add Friend CTA)
    // Secondary: ghost/transparent with muted icon (Chat)
    final iconColor = isPrimary ? AppColors.textPrimary : AppColors.textSecondary;

    final button = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: isPrimary
            ? null
            : Border.all(
                color: AppColors.navyLight,
                width: 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : svgPath != null
                    ? AppIcon(
                        assetPath: svgPath,
                        size: AppIconSize.button,
                        color: iconColor,
                      )
                    : AppIcon(
                        icon: icon,
                        size: AppIconSize.button,
                        color: iconColor,
                      ),
          ),
        ),
      ),
    );

    return tooltip != null
        ? Tooltip(
            message: tooltip,
            child: button,
          )
        : button;
  }
}
