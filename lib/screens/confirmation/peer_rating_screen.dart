import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_tokens.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_avatar.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/services/trust_flow_service.dart';

/// PeerRatingScreen
///
/// Allows app users to rate each other with a segmented toggle
/// ('would you play again') after the host has confirmed attendance.
/// Opened via push notification ~30 min after host confirms.
///
/// Guests are excluded from rating and being rated.
///
/// Route name: 'PeerRating'
/// Parameters: gameRef (DocumentReference)
class PeerRatingScreen extends StatefulWidget {
  const PeerRatingScreen({super.key, required this.gameRef});

  final DocumentReference gameRef;

  static const String routeName = 'PeerRating';
  static const String routePath = '/peerRating';

  @override
  State<PeerRatingScreen> createState() => _PeerRatingScreenState();
}

class _PeerRatingScreenState extends State<PeerRatingScreen>
    with TickerProviderStateMixin {
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;
  bool _alreadyCompleted = false;
  bool _windowClosed = false;

  String _courseName = '';

  // Present app users to rate (excluding current user)
  final List<_RateeEntry> _ratees = [];

  // Ratings map: uid → wouldPlayAgain (bool)
  final Map<String, bool?> _ratings = {};

  // Staggered entrance animation
  late AnimationController _staggerController;
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadRatees();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _buildStaggerAnimations() {
    _fadeAnimations.clear();
    _slideAnimations.clear();

    final itemCount =
        _ratees.length.clamp(0, MotionTokens.staggerMaxItems);
    if (itemCount == 0) return;

    for (int i = 0; i < _ratees.length; i++) {
      final staggerIndex = i.clamp(0, MotionTokens.staggerMaxItems - 1);
      final startFraction = (staggerIndex * 24) / 600;
      final endFraction = (startFraction + 0.4).clamp(0.0, 1.0);

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(startFraction, endFraction,
                curve: MotionTokens.curveEnter),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(startFraction, endFraction,
                curve: MotionTokens.curveEnter),
          ),
        ),
      );
    }
  }

  Future<void> _loadRatees() async {
    try {
      // Check if already submitted or window closed before loading the form.
      final status = await _trustFlowService.checkPeerRatingStatus(
        gameRef: widget.gameRef,
      );
      if (!mounted) return;
      if (status == ConfirmationStatus.completed) {
        updateState(this, () {
          _alreadyCompleted = true;
          _loading = false;
        });
        return;
      }
      if (status == ConfirmationStatus.windowClosed) {
        updateState(this, () {
          _windowClosed = true;
          _loading = false;
        });
        return;
      }

      final data =
          await _trustFlowService.loadPeerRatees(gameRef: widget.gameRef);

      if (mounted) {
        updateState(this, () {
          _courseName = data.courseName;
          _ratees.addAll(
            data.ratees.map(
              (ratee) => _RateeEntry(
                uid: ratee.uid,
                displayName: ratee.displayName,
                photoUrl: ratee.photoUrl,
              ),
            ),
          );
          _ratings.addAll(data.initialRatings);
          _loading = false;
        });
        _buildStaggerAnimations();
        _staggerController.forward();
      }
    } on StateError catch (e) {
      final code = e.message;
      if (mounted) {
        updateState(this, () {
          _error = code == 'not_signed_in'
              ? 'Not signed in.'
              : code == 'game_not_found'
                  ? 'Game not found.'
                  : 'Failed to load players. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      AppLog.d('PeerRatingScreen load error: $e');
      if (mounted) {
        updateState(this, () {
          _error = 'Failed to load players. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    // Build ratings map — include only rated entries (non-null)
    final ratedMap = <String, bool>{};
    for (final entry in _ratings.entries) {
      if (entry.value != null) {
        ratedMap[entry.key] = entry.value!;
      }
    }

    if (ratedMap.isEmpty) {
      updateState(this, () {
        _error = 'Please rate at least one player before submitting.';
      });
      return;
    }

    updateState(this, () {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await makeCloudCall('submitPeerRatings', {
        'gameId': widget.gameRef.id,
        'ratings': ratedMap,
      });

      if (result['success'] == true) {
        if (mounted) {
          updateState(this, () {
            _submitting = false;
            _submitted = true;
          });
        }
      } else {
        if (mounted) {
          updateState(this, () {
            _submitting = false;
            _error = 'Submission failed. Please try again.';
          });
        }
      }
    } catch (e) {
      AppLog.d('PeerRatingScreen submit error: $e');
      if (mounted) {
        updateState(this, () {
          _submitting = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.green,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_alreadyCompleted) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(AppPhosphorIcons.thumbsUp,
                      color: AppColors.green, size: AppIconSize.hero),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ratings already submitted.',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your feedback helps build better groups.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Done',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_windowClosed) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(AppPhosphorIcons.clock,
                      color: AppColors.textMuted, size: AppIconSize.hero),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'This confirmation window has closed.',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Done',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_submitted) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(AppPhosphorIcons.thumbsUp,
                      color: AppColors.green, size: AppIconSize.hero),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ratings submitted!',
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your feedback helps build better groups.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  AppButtonEnhanced(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Done',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_ratees.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
          elevation: 0,
          title: Text('Rate Your Group', style: AppTypography.titleMedium),
          centerTitle: true,
          leading: IconButton(
            icon: PhosphorIcon(AppPhosphorIcons.back,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error != null
                        ? _error!
                        : 'No players to rate for this round.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _error != null
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    SizedBox(height: AppSpacing.lg),
                    AppButtonEnhanced(
                      onPressed: () {
                        updateState(this, () {
                          _loading = true;
                          _error = null;
                        });
                        _loadRatees();
                      },
                      text: 'Try Again',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        title: Text('Rate Your Group', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon:
              PhosphorIcon(AppPhosphorIcons.back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Header
                      _buildHeader(),

                      SizedBox(height: AppSpacing.xxxl),

                      // Card list (non-scrollable column)
                      Padding(
                        padding: AppSpacing.symmetric(
                            horizontal: AppSpacing.screenPadding),
                        child: Column(
                          children: [
                            for (int i = 0; i < _ratees.length; i++) ...[
                              if (i > 0) SizedBox(height: AppSpacing.xxs),
                              _buildRateeRow(i),
                            ],
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Error message
                      if (_error != null)
                        Padding(
                          padding: AppSpacing.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.sm),
                          child: Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Submit button
                      Padding(
                        padding: AppSpacing.only(
                            left: AppSpacing.xl,
                            right: AppSpacing.xl,
                            bottom: AppSpacing.xxl,
                            top: AppSpacing.lg),
                        child: AppButtonEnhanced(
                          onPressed: _submitting ? null : _submit,
                          text: _submitting ? 'Submitting...' : 'Submit Ratings',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.large,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRateeRow(int i) {
    final ratee = _ratees[i];
    Widget row = _RateeRow(
      ratee: ratee,
      rating: _ratings[ratee.uid],
      onRate: (val) {
        updateState(this, () {
          _ratings[ratee.uid] = val;
        });
      },
    );

    // Stagger animation
    if (i < _fadeAnimations.length) {
      row = AnimatedBuilder(
        animation: _staggerController,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimations[i].value,
          child: SlideTransition(
            position: _slideAnimations[i],
            child: child,
          ),
        ),
        child: row,
      );
    }

    return row;
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.only(
        top: AppSpacing.xxl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: Column(
        children: [
          PhosphorIcon(
            AppPhosphorIcons.thumbsUp,
            color: AppColors.textSecondary,
            size: AppIconSize.xxl,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            _courseName,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Would you play again?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                AppPhosphorIcons.lock,
                size: AppIconSize.xs,
                color: AppColors.textMuted,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                'Responses are always private',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateeEntry {
  const _RateeEntry({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
}

class _RateeRow extends StatelessWidget {
  const _RateeRow({
    required this.ratee,
    required this.rating,
    required this.onRate,
  });

  final _RateeEntry ratee;
  final bool? rating; // null = not yet rated
  final ValueChanged<bool> onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: rating == null
              ? AppColors.navyLight
              : (rating!
                  ? AppColors.green.withValues(alpha: 0.4)
                  : AppColors.error.withValues(alpha: 0.4)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar with border
          _buildAvatar(),
          SizedBox(width: AppSpacing.sm),
          // Name
          Expanded(
            child: Text(
              ratee.displayName,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Rating toggle
          _RatingToggle(
            rating: rating,
            onRate: onRate,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = ratee.displayName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .take(2)
        .join();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: AppAvatar(
        imageUrl: ratee.photoUrl.isNotEmpty ? ratee.photoUrl : null,
        initials: initials.isEmpty ? '?' : initials,
        size: AppAvatarSize.small,
        backgroundColor: AppColors.navyDark,
      ),
    );
  }
}

/// Segmented toggle pair for peer rating: [Play again | No]
/// Supports tri-state: null (unselected), true (play again), false (no).
class _RatingToggle extends StatelessWidget {
  const _RatingToggle({required this.rating, required this.onRate});

  final bool? rating;
  final ValueChanged<bool> onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RatingSegment(
              label: 'Play again',
              selected: rating == true,
              selectedColor: AppColors.green,
              onTap: () => onRate(true),
            ),
            _RatingSegment(
              label: 'No',
              selected: rating == false,
              selectedColor: AppColors.error,
              onTap: () => onRate(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual segment within the rating toggle.
class _RatingSegment extends StatelessWidget {
  const _RatingSegment({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.navyLight,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
