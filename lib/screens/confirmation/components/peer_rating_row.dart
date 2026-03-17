import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_avatar.dart';

/// Data class for a player who can be rated.
class RateeEntry {
  const RateeEntry({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
}

/// A single row showing a ratee's avatar, name, and a rating toggle.
class RateeRow extends StatelessWidget {
  const RateeRow({
    super.key,
    required this.ratee,
    required this.rating,
    required this.onRate,
  });

  final RateeEntry ratee;
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
          _buildAvatar(),
          SizedBox(width: AppSpacing.sm),
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
