import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon_button.dart';
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';

/// Redesigned premium friend card with high contrast, clear hierarchy, and compact horizontal actions
/// Optimized for readability and efficient space usage
class PremiumFriendCard extends StatefulWidget {
  final UsersRecord user;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onAction;
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
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? AppColors.fairway.withValues(alpha: 0.3)
                  : AppColors.cloud.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              // Far ambient shadow
              BoxShadow(
                color: AppColors.fairwayDark.withValues(alpha: _isPressed ? 0.12 : 0.18),
                blurRadius: _isPressed ? 16 : 24,
                offset: Offset(0, _isPressed ? 6 : 12),
                spreadRadius: 0,
              ),
              // Mid accent shadow
              BoxShadow(
                color: AppColors.sunsetGold.withValues(alpha: _isPressed ? 0.06 : 0.1),
                blurRadius: _isPressed ? 8 : 12,
                offset: Offset(0, _isPressed ? 3 : 6),
                spreadRadius: 0,
              ),
              // Near edge shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Top accent stripe
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.sunsetGold.withValues(alpha: 0.6),
                      AppColors.sunsetPeach.withValues(alpha: 0.6),
                      AppColors.sunsetGold.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Avatar
                    _buildAvatar(),

                    SizedBox(width: AppSpacing.md),

                    // User info
                    Expanded(
                      child: _buildUserInfo(),
                    ),

                    SizedBox(width: AppSpacing.sm),

                    // Actions (horizontal layout)
                    _buildHorizontalActions(),
                  ],
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
        // Name with inline VIBE badge
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.onyx,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_vibeMatch != null) ...[
              SizedBox(width: 8),
              _buildVibeBadge(),
            ],
          ],
        ),

        SizedBox(height: 6),

        // Secondary info row: handicap + location
        Row(
          children: [
            if (widget.user.handicap != null && widget.user.handicap! > 0) ...[
              _buildHandicapBadge(widget.user.handicap!),
              SizedBox(width: 8),
            ],
            if (widget.user.homeCourse != null && widget.user.homeCourse!.isNotEmpty)
              Flexible(
                child: _buildLocationChip(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVibeBadge() {
    if (_vibeMatch == null) return SizedBox.shrink();

    final score = (_vibeMatch!.cappedScore ?? _vibeMatch!.totalScore).round();

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
            '$handicap',
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

  Widget _buildLocationChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: 12,
          color: AppColors.stone,
        ),
        SizedBox(width: 3),
        Flexible(
          child: Text(
            widget.user.homeCourse!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.stone,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalActions() {
    final actions = <Widget>[];

    // Message button (primary)
    if (widget.onMessage != null) {
      actions.add(_buildActionButton(
        label: 'Chat',
        icon: Icons.message_rounded,
        onPressed: widget.onMessage!,
        isPrimary: true,
        color: AppColors.fairway,
      ));
    }

    // Action button (secondary)
    if (widget.showActionButton) {
      actions.add(_buildActionButton(
        label: widget.actionLabel,
        icon: widget.actionIcon,
        onPressed: widget.onAction,
        isPrimary: false,
        color: widget.actionColor,
        isLoading: widget.isLoading,
      ));
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
        color: isPrimary ? null : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: isPrimary
            ? null
            : Border.all(
                color: color.withValues(alpha: 0.3),
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
            : null,
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
                        isPrimary ? Colors.white : color,
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 16,
                    color: isPrimary ? Colors.white : color,
                  ),
                SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isPrimary ? Colors.white : color,
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
}
