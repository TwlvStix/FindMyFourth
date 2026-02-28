import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/widgets/app_avatar.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/vibe_gap_indicator.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';

/// Visual state of the join request card
enum _CardState {
  /// Default state with active approve/decline buttons
  pending,

  /// Request was approved - shows confirmation then collapses
  approved,

  /// Request was declined - shows confirmation then collapses
  declined,
}

/// Card displayed to game owners showing a pending join request.
///
/// Shows the requesting player's info, vibe gap indicator from the owner's
/// perspective, and approve/decline action buttons.
///
/// After the owner responds, the card transitions to a confirmation state
/// (approved or declined) with a brief hold, then collapses and removes itself.
class VibeJoinRequestCard extends StatefulWidget {
  const VibeJoinRequestCard({
    super.key,
    required this.request,
    required this.requesterProfile,
    required this.ownerVibeProfile,
    required this.requesterVibeProfile,
    required this.matchResult,
    required this.onApprove,
    required this.onDecline,
    this.onRemoved,
  });

  /// The join request data
  final JoinRequest request;

  /// The requesting player's user profile
  final UsersRecord requesterProfile;

  /// The game owner's vibe profile (for perspective display)
  final VibeProfile ownerVibeProfile;

  /// The requesting player's vibe profile
  final VibeProfile requesterVibeProfile;

  /// The vibe match result between owner and requester
  final VibeMatchResult matchResult;

  /// Called when the owner taps "Approve"
  final VoidCallback onApprove;

  /// Called when the owner taps "Decline"
  final VoidCallback onDecline;

  /// Called after the collapse animation completes (for removal from list)
  final VoidCallback? onRemoved;

  @override
  State<VibeJoinRequestCard> createState() => _VibeJoinRequestCardState();
}

class _VibeJoinRequestCardState extends State<VibeJoinRequestCard>
    with SingleTickerProviderStateMixin {
  _CardState _state = _CardState.pending;
  bool _isProcessing = false;

  // Animation for collapse
  late AnimationController _collapseController;
  late Animation<double> _heightFactor;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      duration: ReducedMotionService.adjust(
        const Duration(milliseconds: 200),
      ),
      vsync: this,
    );

    _heightFactor = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: MotionTokens.curveExit,
      ),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _collapseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onRemoved?.call();
      }
    });
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    widget.onApprove();

    setState(() => _state = _CardState.approved);

    // Hold for 1.5 seconds to show confirmation, then collapse
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _collapseController.forward();
    }
  }

  Future<void> _handleDecline() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    widget.onDecline();

    setState(() => _state = _CardState.declined);

    // Hold for 1.5 seconds to show confirmation, then collapse
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _collapseController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _collapseController,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: Opacity(
              opacity: _opacity.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: _state == _CardState.pending
                ? AppColors.gold.withValues(alpha: 0.3)
                : AppColors.navyLight,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header label
            Text(
              'JOIN REQUEST',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.04 * 12, // 0.04em
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // Player info row
            _buildPlayerInfoRow(),
            SizedBox(height: AppSpacing.md),

            // Vibe comparison section (only in pending state)
            if (_state == _CardState.pending) ...[
              Text(
                'How your styles compare',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              VibeGapIndicator(
                matchResult: widget.matchResult,
                ownerProfile: widget.ownerVibeProfile,
                playerProfile: widget.requesterVibeProfile,
                perspective: VibeGapPerspective.owner,
                maxDimensions: 3,
              ),
              SizedBox(height: AppSpacing.md),
            ],

            // Action row or status message
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfoRow() {
    final rawName = widget.requesterProfile.displayName;
    final displayName = rawName.isNotEmpty ? rawName : 'Unknown Player';
    final photoUrl = widget.requesterProfile.photoUrl;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Row(
      children: [
        AppAvatar(
          imageUrl: photoUrl,
          initials: initials,
          size: AppAvatarSize.medium,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Wants to join this round',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    if (_state == _CardState.approved) {
      final rawName = widget.requesterProfile.displayName;
      final displayName = rawName.isNotEmpty ? rawName : 'Player';
      return AnimatedOpacity(
        opacity: 1.0,
        duration: MotionTokens.contentReveal,
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.green,
              size: 20,
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Approved — $displayName has been notified',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_state == _CardState.declined) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: MotionTokens.contentReveal,
        child: Text(
          'Declined',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    // Pending state - show buttons
    return Row(
      children: [
        Expanded(
          child: AppButtonEnhanced(
            text: 'Decline',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            onPressed: _isProcessing ? null : _handleDecline,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButtonEnhanced(
            text: 'Approve',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.medium,
            onPressed: _isProcessing ? null : _handleApprove,
          ),
        ),
      ],
    );
  }
}
