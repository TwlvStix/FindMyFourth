import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';

/// Redesigned premium friend card matching LuxuryPlayerCard design language:
/// - Dark fairway surface (AppColors.fairway @ 30% alpha)
/// - Rounded-square avatars (52×52, radius 14)
/// - Manrope typography with cream/gold color tokens
/// - 20px border radius, consistent padding (20h × 18v)
class PremiumFriendCard extends StatefulWidget {
  // LuxuryPlayerCard design tokens
  static const Color textPrimary = Color(0xFFF0ECE4);
  static const Color textMuted = Color(0x80F0ECE4);
  static const Color goldAccent = Color(0xFFD4A843);
  final UsersRecord user;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onAction;
  final String messageLabel;
  final IconData messageIcon;
  final String actionLabel;
  final IconData actionIcon;
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
    this.messageIcon = Icons.message_rounded,
    this.actionLabel = 'Add',
    this.actionIcon = Icons.person_add_rounded,
    this.actionColor = AppColors.fairway,
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

    // Calculate vibe match if both profiles exist
    if (widget.currentUser != null &&
        widget.currentUser!.vibeProfile.isNotEmpty &&
        widget.user.vibeProfile.isNotEmpty) {
      try {
        final myProfile =
            VibeProfile.fromFirestore(widget.currentUser!.vibeProfile);
        final theirProfile = VibeProfile.fromFirestore(widget.user.vibeProfile);
        _vibeMatch = VibeMatcher.score(myProfile, theirProfile);
      } catch (e) {
        // Vibe calculation failed, leave as null
        _vibeMatch = null;
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
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
            color: AppColors.fairway.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? AppColors.fairwayLight.withValues(alpha: 0.4)
                  : AppColors.fairwayLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [

              // Main content with responsive layout
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
        color: AppColors.fairwayLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
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
    return Container(
      color: Colors.white.withValues(alpha: 0.04),
      child: const Icon(
        Icons.person_rounded,
        color: PremiumFriendCard.textMuted,
        size: 26,
      ),
    );
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
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: PremiumFriendCard.textPrimary,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 3),

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

    final score = _vibeMatch!.finalScorePercent.round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PremiumFriendCard.goldAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: PremiumFriendCard.goldAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 10,
            color: PremiumFriendCard.goldAccent,
          ),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PremiumFriendCard.goldAccent,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandicapBadge(int handicap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sunsetGold,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        handicap < 0 ? '+${handicap.abs()}' : '$handicap',
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A2B1A),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildResponsiveActions(double availableWidth) {
    // Always use icon-only buttons for compact design
    final actions = <Widget>[];

    // Message button (primary)
    if (widget.onMessage != null) {
      actions.add(
        _buildIconOnlyButton(
          icon: widget.messageIcon,
          onPressed: widget.onMessage!,
          isPrimary: true,
          tooltip: widget.messageLabel,
        ),
      );
    }

    // Action button (secondary)
    if (widget.showActionButton) {
      actions.add(
        _buildIconOnlyButton(
          icon: widget.actionIcon,
          onPressed: widget.onAction,
          isPrimary: false,
          isLoading: widget.isLoading,
          tooltip: widget.actionLabel,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .expand((widget) => [widget, const SizedBox(width: 8)])
          .toList()
        ..removeLast(), // Remove last spacer
    );
  }

  Widget _buildIconOnlyButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isLoading = false,
    String? tooltip,
  }) {
    final button = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.fairwayDark
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? AppColors.fairwayLight.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        PremiumFriendCard.textPrimary,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: PremiumFriendCard.textPrimary,
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
