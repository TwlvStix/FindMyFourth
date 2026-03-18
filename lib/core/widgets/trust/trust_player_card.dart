import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/schema/trust_profile.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_avatar.dart';
import '/core/widgets/trust/cancellation_warning_icon.dart';
import '/core/widgets/trust/trust_badge_chip.dart';

/// Compact player card for game lobbies and browse screens.
///
/// Shows avatar, name, trust badge, verified round count, unique co-players,
/// and (if active) a cancellation warning icon.
///
/// Usage: replace raw player list rows in game lobby with this widget.
class TrustPlayerCard extends StatelessWidget {
  const TrustPlayerCard({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.tier,
    required this.verifiedRounds,
    required this.uniqueCoPlayers,
    this.cancellationWarningActive = false,
    this.cancellationWarningDetail = '',
    this.onTap,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final BadgeTier tier;
  final int verifiedRounds;
  final int uniqueCoPlayers;
  final bool cancellationWarningActive;
  final String cancellationWarningDetail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Avatar
            AppAvatar(
              imageUrl: avatarUrl,
              initials: _initials(name),
              size: AppAvatarSize.small,
            ),
            SizedBox(width: AppSpacing.md),

            // Name + badge + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name row with badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onyx,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      TrustBadgeChip(
                        tier: tier,
                        mode: TrustBadgeChipMode.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxs),

                  // Stats row
                  Row(
                    children: [
                      Text(
                        '$verifiedRounds',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                      Text(
                        ' rounds',
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.slate),
                      ),
                      Text(
                        ' · ',
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.stone),
                      ),
                      Text(
                        '$uniqueCoPlayers',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                      Text(
                        ' players',
                        style: AppTypography.labelSmall.copyWith(
                            color: AppColors.slate),
                      ),
                      if (cancellationWarningActive) ...[
                        SizedBox(width: AppSpacing.xs),
                        CancellationWarningIcon(
                          warningCount: 0,
                          detail: cancellationWarningDetail,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            if (onTap != null)
              PhosphorIcon(
                AppPhosphorIcons.chevronRight,
                color: AppColors.stone,
                size: AppIconSize.button,
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
