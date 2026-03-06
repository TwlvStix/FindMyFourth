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
import '/services/vibe_matcher.dart';
import '/models/vibe_profile.dart';
import '/utils/vibe_archetypes.dart';
import 'friend_card_action_button.dart';
import 'premium_friend_card/friend_card_background.dart';
import 'premium_friend_card/vibe_ring_avatar.dart';
import 'premium_friend_card/friend_card_footer.dart';

// Re-export for backwards compatibility
export 'friend_card_action_button.dart' show ActionButtonVariant;

/// Redesigned premium friend card with:
/// - Animated vibe ring around avatar
/// - Large gold HCP display
/// - Archetype label above name
/// - Stats strip with vibe match percentage
/// - Footer with Message + Action buttons
class PremiumFriendCard extends StatefulWidget {
  static final Color textPrimary = AppColors.sand;
  static final Color textMuted = AppColors.glassTextTertiary;

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

class _PremiumFriendCardState extends State<PremiumFriendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  VibeMatchResult? _vibeMatch;

  // Stagger animation delay per card (24ms base, capped at 8 cards)
  Duration get _staggerDelay {
    final index = widget.cardIndex.clamp(0, 7);
    return Duration(milliseconds: index * 24);
  }

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
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
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

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
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
          child: FriendCardBackground(
            isPressed: _isPressed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMainContent(),
                _buildFooter(),
              ],
            ),
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
          Expanded(child: _buildUserInfo()),
          // HCP display
          if (widget.user.hasHandicap()) _buildHandicapDisplay(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final displayName = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : 'Golfer';
    final archetype = _getArchetypeName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Archetype label
        if (archetype != null) ...[
          Text(
            archetype.toUpperCase(),
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
        ],
        // Name
        Text(
          displayName,
          style: AppTypography.titleMedium.copyWith(
            color: PremiumFriendCard.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Age + Hometown
        _buildSecondaryInfo(),
      ],
    );
  }

  Widget _buildSecondaryInfo() {
    final age = _calculateAge(widget.user.dateOfBirth);
    final hometown = widget.user.hometownName;
    final vibePercent = _vibeMatch?.myFitPercent.round();

    // Get gender letter: M for Male, F for Female
    String? genderLetter;
    final gender = widget.user.gender;
    if (gender == 'Male') {
      genderLetter = 'M';
    } else if (gender == 'Female') {
      genderLetter = 'F';
    }

    final locationParts = <String>[
      if (age != null) '$age${genderLetter ?? ''}',
      if (hometown.isNotEmpty) hometown
    ];

    if (locationParts.isEmpty && vibePercent == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          // Age · Town
          if (locationParts.isNotEmpty)
            Text(
              locationParts.join(' · '),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          // Vibe match chip
          if (vibePercent != null) ...[
            if (locationParts.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '·',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            Icon(
              AppPhosphorIcons.heartFill,
              size: 12,
              color: AppColors.green,
            ),
            SizedBox(width: 4),
            Text(
              '$vibePercent% match',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          // Handicap value
          Text(
            handicapText,
            style: AppTypography.monoMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 32,
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
