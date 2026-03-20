import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_avatar.dart';
import 'checkin_attendance_toggle.dart';
import 'checkin_participant_entry.dart';

/// Compact roster row: [Avatar] [Name + badge] ..... [Present | No-show]
class CheckinParticipantRow extends StatelessWidget {
  const CheckinParticipantRow({
    super.key,
    required this.participant,
    required this.isPresent,
    required this.onToggle,
  });

  final CheckinParticipantEntry participant;
  final bool isPresent;
  final ValueChanged<bool> onToggle;

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
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    participant.displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (participant.role == 'host') ...[
                  SizedBox(width: AppSpacing.xs),
                  _HostBadge(),
                ] else if (participant.isGuest) ...[
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Guest',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          CheckinAttendanceToggle(
            isPresent: isPresent,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = participant.displayName
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
        imageUrl:
            participant.photoUrl.isNotEmpty ? participant.photoUrl : null,
        initials: initials.isEmpty ? '?' : initials,
        size: AppAvatarSize.small,
        backgroundColor: AppColors.navyDark,
      ),
    );
  }
}

/// Inline gold pill badge for "Host" role.
class _HostBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        'Host',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
