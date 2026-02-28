import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_avatar.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

/// Collapsed row showing minimal join request info with tap-to-expand.
///
/// Shows: small avatar (32px) | player name | "Review" text + chevron
/// Used in accordion pattern when multiple pending requests exist.
class CollapsedJoinRequestRow extends StatelessWidget {
  const CollapsedJoinRequestRow({
    super.key,
    required this.requesterProfile,
    required this.onTap,
  });

  /// The requesting player's user profile
  final UsersRecord requesterProfile;

  /// Called when the row is tapped to expand this request
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rawName = requesterProfile.displayName;
    final displayName = rawName.isNotEmpty ? rawName : 'Unknown Player';
    final photoUrl = requesterProfile.photoUrl;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.navyLight,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Small avatar (32px)
            AppAvatar(
              imageUrl: photoUrl,
              initials: initials,
              size: AppAvatarSize.small,
            ),
            SizedBox(width: AppSpacing.sm),

            // Player name
            Expanded(
              child: Text(
                displayName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // "Review" text in green
            Text(
              'Review',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.green,
              ),
            ),
            SizedBox(width: AppSpacing.xs),

            // Chevron
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              size: AppIconSize.sm,
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }
}
