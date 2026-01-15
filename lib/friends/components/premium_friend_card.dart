import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon_button.dart';

/// Premium friend card with social proof, status indicators, and quick actions
/// Displays rich user context including handicap, mutual friends, and activity
class PremiumFriendCard extends StatefulWidget {
  final UsersRecord user;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onAction; // Accept, Add, Remove depending on context
  final String actionLabel;
  final IconData actionIcon;
  final Color actionColor;
  final bool showActionButton;
  final bool isLoading;
  final int? mutualFriendsCount;
  final int? gamesPlayedTogether;
  final bool isOnline;
  final String? lastActive;

  const PremiumFriendCard({
    super.key,
    required this.user,
    this.onViewProfile,
    this.onMessage,
    this.onAction,
    this.actionLabel = 'Add',
    this.actionIcon = Icons.person_add_rounded,
    this.actionColor = AppColors.fairway,
    this.showActionButton = true,
    this.isLoading = false,
    this.mutualFriendsCount,
    this.gamesPlayedTogether,
    this.isOnline = false,
    this.lastActive,
  });

  @override
  State<PremiumFriendCard> createState() => _PremiumFriendCardState();
}

class _PremiumFriendCardState extends State<PremiumFriendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
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
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.sand.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: _isPressed
                  ? AppColors.fairway.withOpacity(0.4)
                  : AppColors.cloud.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sunsetGold.withOpacity(_isPressed ? 0.15 : 0.08),
                blurRadius: _isPressed ? 12 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.95),
            ),
            child: Column(
              children: [
                // Main content row
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Avatar with status indicator
                      _buildAvatar(),
                      SizedBox(width: AppSpacing.md),

                      // User info section
                      Expanded(
                        child: _buildUserInfo(),
                      ),

                      SizedBox(width: AppSpacing.sm),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),

                // Divider
                if (_shouldShowBottomSection())
                  Container(
                    height: 1,
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.cloud.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                // Bottom stats section
                if (_shouldShowBottomSection())
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: _buildBottomStats(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowBottomSection() {
    return (widget.mutualFriendsCount != null && widget.mutualFriendsCount! > 0) ||
        (widget.gamesPlayedTogether != null && widget.gamesPlayedTogether! > 0);
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        // Outer glow
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: widget.isOnline
                  ? [
                      AppColors.sunsetGold.withOpacity(0.3),
                      AppColors.sunsetPeach.withOpacity(0.1),
                      Colors.transparent,
                    ]
                  : [
                      AppColors.cloud.withOpacity(0.2),
                      Colors.transparent,
                    ],
            ),
          ),
        ),

        // Avatar with gradient border
        Positioned(
          left: 5,
          top: 5,
          child: Container(
            width: 60,
            height: 60,
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.isOnline
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.sunsetGold,
                        AppColors.sunsetPeach,
                        AppColors.sunsetRose,
                      ],
                    )
                  : null,
              color: widget.isOnline ? null : AppColors.cloud.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: widget.isOnline
                      ? AppColors.sunsetGold.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: widget.user.photoUrl.isNotEmpty
                    ? Image.network(
                        widget.user.photoUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildAvatarFallback(),
                      )
                    : _buildAvatarFallback(),
              ),
            ),
          ),
        ),

        // Online status indicator with pulse effect
        if (widget.isOnline)
          Positioned(
            right: 3,
            bottom: 3,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.fairway,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fairway.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
      color: AppColors.sand,
      child: Icon(
        Icons.person_rounded,
        size: 28,
        color: AppColors.stone,
      ),
    );
  }

  Widget _buildUserInfo() {
    final displayName = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : 'Golfer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onyx,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        SizedBox(height: 2),

        // Handicap badge and home course
        Row(
          children: [
            if (widget.user.handicap != null && widget.user.handicap! > 0) ...[
              _buildHandicapBadge(widget.user.handicap!),
              SizedBox(width: 8),
            ],
            if (widget.user.homeCourse != null && widget.user.homeCourse!.isNotEmpty)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.golf_course_rounded,
                      size: 13,
                      color: AppColors.fairway.withOpacity(0.7),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.user.homeCourse!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.stone,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHandicapBadge(int handicap) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sunsetGold,
            AppColors.sunsetPeach,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetGold.withOpacity(0.35),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 11,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            '$handicap',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomStats() {
    final statItems = <Widget>[];

    if (widget.mutualFriendsCount != null && widget.mutualFriendsCount! > 0) {
      statItems.add(
        _buildBottomStatChip(
          icon: Icons.people_rounded,
          label: '${widget.mutualFriendsCount} mutual friends',
          color: AppColors.sunsetPeach,
        ),
      );
    }

    if (widget.gamesPlayedTogether != null && widget.gamesPlayedTogether! > 0) {
      statItems.add(
        _buildBottomStatChip(
          icon: Icons.emoji_events_rounded,
          label: '${widget.gamesPlayedTogether} games together',
          color: AppColors.sunsetGold,
        ),
      );
    }

    if (statItems.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: statItems,
    );
  }

  Widget _buildBottomStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onyx,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message button
        if (widget.onMessage != null)
          _buildPremiumIconButton(
            icon: FontAwesomeIcons.commentDots,
            onPressed: widget.onMessage!,
            color: AppColors.fairway,
            isPrimary: true,
          ),

        if (widget.onMessage != null && widget.showActionButton)
          SizedBox(height: AppSpacing.xs),

        // Action button (Add/Accept/Remove)
        if (widget.showActionButton)
          _buildPremiumIconButton(
            icon: widget.actionIcon,
            onPressed: widget.onAction,
            color: widget.actionColor,
            isLoading: widget.isLoading,
            isPrimary: false,
          ),
      ],
    );
  }

  Widget _buildPremiumIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? Colors.transparent : color.withOpacity(0.2),
          width: isPrimary ? 0 : 1.5,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimary ? Colors.white : color,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: isPrimary ? Colors.white : color,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
