import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';

/// Redesigned premium friend card with high contrast, clear hierarchy, and compact horizontal actions
/// Optimized for readability and efficient space usage
class PremiumFriendCard extends StatefulWidget {
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
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            // Dark green tinted background - matches "My Games" cards
            color: AppColors.fairway.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: widget.isOnline
                ? [
                    // Subtle glow for online users
                    BoxShadow(
                      color: AppColors.sunsetGold.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [

              // Main content with responsive layout
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
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
    return Stack(
      children: [
        // Outer glow for online users
        if (widget.isOnline)
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.fairway.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

        // Avatar ring
        Container(
          width: 68,
          height: 68,
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isOnline
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.fairway,
                      AppColors.fairwayLight,
                    ],
                  )
                : null,
            color: widget.isOnline ? null : AppColors.cloud.withValues(alpha: 0.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: widget.user.photoUrl.isNotEmpty
                  ? Image.network(
                      widget.user.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
        ),

        // Online indicator
        if (widget.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fairway.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.fairway,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.fairwayLight, AppColors.fairway],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 24,
        color: Colors.white,
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
        // NAME - Hero element (LARGEST, highest contrast, NO truncation)
        Text(
          displayName,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.visible, // NO ellipsis - name always visible
        ),

        SizedBox(height: 6),

        // Secondary badges row: vibe % + handicap (minimal, compact)
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (_vibeMatch != null) _buildVibeBadge(),
            if (widget.user.handicap > 0)
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.fairway,
            AppColors.fairwayLight,
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.fairway.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 10,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            '$score%',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandicapBadge(int handicap) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sunsetGold,
            AppColors.sunsetPeach,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetGold.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 10,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            handicap < 0 ? '+${handicap.abs()}' : '$handicap',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveActions(double availableWidth) {
    // Determine if we have space for full buttons or need icon-only
    // Account for: avatar (68) + spacing (16) + min name space (120) + spacing (12)
    final usedSpace = 68 + 16 + 120 + 12;
    final remainingSpace = availableWidth - usedSpace;
    final useIconOnly = remainingSpace < 140; // Need ~140px for two full buttons

    final actions = <Widget>[];

    // Message button (primary)
    if (widget.onMessage != null) {
      actions.add(
        useIconOnly
            ? _buildIconOnlyButton(
                icon: widget.messageIcon,
                onPressed: widget.onMessage!,
                isPrimary: true,
                color: AppColors.fairway,
                tooltip: widget.messageLabel,
              )
            : _buildActionButton(
                label: widget.messageLabel,
                icon: widget.messageIcon,
                onPressed: widget.onMessage!,
                isPrimary: true,
                color: AppColors.fairway,
              ),
      );
    }

    // Action button (secondary)
    if (widget.showActionButton) {
      actions.add(
        useIconOnly
            ? _buildIconOnlyButton(
                icon: widget.actionIcon,
                onPressed: widget.onAction,
                isPrimary: false,
                color: widget.actionColor,
                isLoading: widget.isLoading,
                tooltip: widget.actionLabel,
              )
            : _buildActionButton(
                label: widget.actionLabel,
                icon: widget.actionIcon,
                onPressed: widget.onAction,
                isPrimary: false,
                color: widget.actionColor,
                isLoading: widget.isLoading,
              ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .expand((widget) => [widget, SizedBox(width: AppSpacing.xs)])
          .toList()
        ..removeLast(), // Remove last spacer
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.85)],
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: isPrimary
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 16,
                    color: Colors.white,
                  ),
                SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required Color color,
    bool isLoading = false,
    String? tooltip,
  }) {
    final button = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.85)],
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
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
                        Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
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
