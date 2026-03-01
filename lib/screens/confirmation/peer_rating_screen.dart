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
import '/core/utils/app_log.dart';
import '/core/widgets/app_avatar.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/services/trust_flow_service.dart';

/// PeerRatingScreen
///
/// Allows app users to rate each other with a thumbs up / thumbs down
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

class _PeerRatingScreenState extends State<PeerRatingScreen> {
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  String _courseName = '';

  // Present app users to rate (excluding current user)
  final List<_RateeEntry> _ratees = [];

  // Ratings map: uid → wouldPlayAgain (bool)
  final Map<String, bool?> _ratings = {};

  @override
  void initState() {
    super.initState();
    _loadRatees();
  }

  Future<void> _loadRatees() async {
    try {
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
        body: const Center(child: CircularProgressIndicator()),
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
              child: Text(
                'No players to rate for this round.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
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
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.only(
                  top: AppSpacing.md,
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.sm),
              child: Text(
                'Would you play again with these players from $_courseName?',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            // Privacy notice
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppColors.navyLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhosphorIcon(
                      AppPhosphorIcons.lock,
                      size: AppIconSize.xs,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Your responses are completely private. '
                        "They're never shown to other players.",
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null)
              Padding(
                padding: AppSpacing.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: AppSpacing.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: _ratees.length,
                itemBuilder: (context, i) {
                  final ratee = _ratees[i];
                  return _RateeRow(
                    ratee: ratee,
                    rating: _ratings[ratee.uid],
                    onRate: (val) {
                      updateState(this, () {
                        _ratings[ratee.uid] = val;
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: AppSpacing.only(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xxl,
                  top: AppSpacing.md),
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
      margin: AppSpacing.only(bottom: AppSpacing.sm),
      padding: AppSpacing.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
          // Avatar
          _buildAvatar(),
          SizedBox(width: AppSpacing.md),
          // Name
          Expanded(
            child: Text(ratee.displayName, style: AppTypography.bodyLarge),
          ),
          // Thumbs up / down
          _ThumbsRating(
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
    return AppAvatar(
      imageUrl: ratee.photoUrl.isNotEmpty ? ratee.photoUrl : null,
      initials: initials.isEmpty ? '?' : initials,
      size: AppAvatarSize.medium,
    );
  }
}

class _ThumbsRating extends StatelessWidget {
  const _ThumbsRating({required this.rating, required this.onRate});

  final bool? rating;
  final ValueChanged<bool> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThumbButton(
          icon: AppPhosphorIcons.thumbsUp,
          selected: rating == true,
          activeColor: AppColors.green,
          onTap: () => onRate(true),
        ),
        SizedBox(width: AppSpacing.sm),
        _ThumbButton(
          icon: AppPhosphorIcons.thumbsDown,
          selected: rating == false,
          activeColor: AppColors.error,
          onTap: () => onRate(false),
        ),
      ],
    );
  }
}

class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? activeColor
                : AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: PhosphorIcon(
          icon,
          size: AppIconSize.md,
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
