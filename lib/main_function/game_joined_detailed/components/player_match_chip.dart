import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/services/vibe_group_matcher.dart';

/// Individual player vibe compatibility chip showing name and match percentage
class PlayerMatchChip extends StatelessWidget {
  const PlayerMatchChip({
    super.key,
    required this.name,
    required this.memberMatch,
    this.onTap,
  });

  final String name;
  final GroupVibeMemberResult? memberMatch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scoreLabel = memberMatch == null
        ? '--%'
        : '${memberMatch!.displayScore.round()}%';
    final label = '$name $scoreLabel';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.navy.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: AppTypography.letterSpacingNormal,
            ),
          ),
        ),
      ),
    );
  }
}
