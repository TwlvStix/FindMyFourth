import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';
import 'friend_card_action_button.dart';
import 'friend_card_avatar.dart';
import 'friend_card_badges.dart';

// Re-export for backwards compatibility
export 'friend_card_action_button.dart' show ActionButtonVariant;

/// Redesigned premium friend card matching LuxuryPlayerCard design language:
/// - Dark fairway surface (AppColors.navy @ 30% alpha)
/// - Rounded-square avatars (52x52, radius 14)
/// - Manrope typography with cream/gold color tokens
/// - 20px border radius, consistent padding (20h x 18v)
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
  final bool messageIsPrimary;
  final String actionLabel;
  final PhosphorIconData? actionIcon;
  final Color actionColor;
  final ActionButtonVariant actionVariant;
  final bool showActionButton;
  final bool showOverflowMenu;
  final VoidCallback? onOverflowAction;
  final bool isLoading;
  final int? mutualFriendsCount;
  final int? gamesPlayedTogether;
  final bool isOnline;
  final String? lastActive;
  final UsersRecord? currentUser;

  const PremiumFriendCard({
    super.key,
    required this.user,
    this.onViewProfile,
    this.onMessage,
    this.onAction,
    this.messageLabel = 'Chat',
    this.messageIcon = AppPhosphorIcons.chat,
    this.messageIsPrimary = false,
    this.actionLabel = 'Add',
    this.actionIcon = AppPhosphorIcons.addPlayer,
    this.actionColor = AppColors.navy,
    this.actionVariant = ActionButtonVariant.primary,
    this.showActionButton = true,
    this.showOverflowMenu = false,
    this.onOverflowAction,
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

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  void _onTapDown(TapDownDetails _) { setState(() => _isPressed = true); _scaleController.forward(); HapticFeedback.lightImpact(); }
  void _onTapUp(TapUpDetails _) { setState(() => _isPressed = false); _scaleController.reverse(); }
  void _onTapCancel() { setState(() => _isPressed = false); _scaleController.reverse(); }

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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    FriendCardAvatar(
                      photoUrl: widget.user.photoUrl,
                      displayName: widget.user.displayName,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildUserInfo()),
                    SizedBox(width: AppSpacing.sm),
                    _buildActions(),
                  ],
                );
              },
            ),
          ),
        ),
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
        _buildSecondaryInfo(),
        AppSpacing.verticalXxs,
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (_vibeMatch != null)
              FriendCardVibeBadge(vibeMatch: _vibeMatch!),
            if (widget.user.handicap != 0)
              FriendCardHandicapBadge(handicap: widget.user.handicap),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryInfo() {
    final age = _calculateAge(widget.user.dateOfBirth);
    final hometown = widget.user.hometownName;
    final parts = <String>[if (age != null) '$age', if (hometown.isNotEmpty) hometown];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxs),
      child: Text(
        parts.join(' • '),
        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActions() {
    final actions = <Widget>[];
    if (widget.onMessage != null) {
      actions.add(FriendCardActionButton(
        icon: widget.messageIcon,
        onPressed: widget.onMessage!,
        variant: widget.messageIsPrimary ? ActionButtonVariant.primary : ActionButtonVariant.secondary,
        tooltip: widget.messageLabel,
      ));
    }
    if (widget.showActionButton) {
      actions.add(FriendCardActionButton(
        icon: widget.actionIcon,
        onPressed: widget.onAction,
        variant: widget.actionVariant,
        isLoading: widget.isLoading,
        tooltip: widget.actionLabel,
      ));
    }
    if (widget.showOverflowMenu && widget.onOverflowAction != null) {
      actions.add(FriendCardActionButton(
        icon: AppPhosphorIcons.more,
        onPressed: widget.onOverflowAction!,
        variant: ActionButtonVariant.muted,
        tooltip: 'More options',
      ));
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.expand((w) => [w, AppSpacing.horizontalXsBox]).toList()..removeLast(),
    );
  }
}
