import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/animated_scale_tap.dart';
import '/backend/backend.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';
import '/utils/vibe_archetypes.dart';
import 'friend_card_action_button.dart';
import 'premium_friend_card/friend_card_background.dart';
import 'premium_friend_card/vibe_ring_avatar.dart';
import 'premium_friend_card/friend_card_footer.dart';
import 'premium_friend_card/friend_card_user_info.dart';

// Re-export for backwards compatibility
export 'friend_card_action_button.dart' show ActionButtonVariant;

/// Redesigned premium friend card with:
/// - Animated vibe ring around avatar
/// - Large gold HCP display
/// - Archetype label above name
/// - Stats strip with vibe match percentage
/// - Footer with Message + Action buttons
class PremiumFriendCard extends StatefulWidget {
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

  /// Card index in list for stagger animation (0-based)
  final int cardIndex;

  const PremiumFriendCard({
    super.key,
    required this.user,
    this.onViewProfile,
    this.onMessage,
    this.onAction,
    this.messageLabel = 'Message',
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
    this.cardIndex = 0,
  });

  @override
  State<PremiumFriendCard> createState() => _PremiumFriendCardState();
}

class _PremiumFriendCardState extends State<PremiumFriendCard> {
  VibeMatchResult? _vibeMatch;

  // Stagger animation delay per card (24ms base, capped at 8 cards)
  Duration get _staggerDelay {
    final index = widget.cardIndex.clamp(0, 7);
    return Duration(milliseconds: index * 24);
  }

  @override
  void initState() {
    super.initState();
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

  String? _getArchetypeName() {
    // 1. Check denormalized field first (fast)
    if (widget.user.archetype.isNotEmpty) {
      return widget.user.archetype.replaceFirst('The ', '');
    }
    // 2. Compute from vibe profile (fallback)
    if (widget.user.vibeProfile.isNotEmpty) {
      try {
        final profile = VibeProfile.fromFirestore(widget.user.vibeProfile);
        final match = VibeArchetypes.classifyProfile(profile);
        return match.name.replaceFirst('The ', '');
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleTap(
      onTap: widget.onViewProfile,
      onTapDown: (_) => HapticFeedback.lightImpact(),
      scaleFactor: MotionTokens.pressScaleSubtle,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: FriendCardBackground(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMainContent(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with vibe ring
          VibeRingAvatar(
            photoUrl: widget.user.photoUrl,
            displayName: widget.user.displayName,
            vibeScore: _vibeMatch?.myFitPercent,
            size: 56,
            animationDelay: _staggerDelay,
          ),
          SizedBox(width: AppSpacing.md),
          // User info
          Expanded(
            child: FriendCardUserInfo(
              displayName: widget.user.displayName.isNotEmpty
                  ? widget.user.displayName
                  : 'Golfer',
              archetype: _getArchetypeName(),
              dateOfBirth: widget.user.dateOfBirth,
              gender: widget.user.gender,
              hometownName: widget.user.hometownName,
              vibeMatchPercent: _vibeMatch?.myFitPercent.round(),
            ),
          ),
          // HCP display
          if (widget.user.hasHandicap()) _buildHandicapDisplay(),
        ],
      ),
    );
  }

  Widget _buildHandicapDisplay() {
    final handicap = widget.user.handicap;
    final handicapText = handicap < 0 ? '+${handicap.abs()}' : '$handicap';

    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HCP label
          Text(
            'HCP',
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          // Handicap value
          Text(
            handicapText,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    // Determine button visibility based on callbacks
    final showMessage = widget.onMessage != null;
    final showAction = widget.showActionButton;

    if (!showMessage && !showAction && !widget.showOverflowMenu) {
      return const SizedBox.shrink();
    }

    return FriendCardFooter(
      onMessage: widget.onMessage,
      onAction: widget.onAction,
      messageLabel: widget.messageLabel,
      messageIcon: widget.messageIcon,
      actionLabel: widget.actionLabel,
      actionIcon: widget.actionIcon,
      actionIsPrimary: widget.actionVariant == ActionButtonVariant.primary,
      isLoading: widget.isLoading,
      showMessageButton: showMessage,
      showActionButton: showAction,
    );
  }
}
