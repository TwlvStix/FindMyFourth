import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/profile/profile_user/components/overlapping_avatars.dart';

class MutualFriendsActionCard extends StatelessWidget {
  const MutualFriendsActionCard({
    super.key,
    required this.friends,
    required this.loaded,
    this.onTap,
  });

  final List<UsersRecord> friends;
  final bool loaded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatars = loaded && friends.isNotEmpty;
    final label = !loaded
        ? 'Mutual Friends'
        : friends.isEmpty
            ? 'Mutual Friends'
            : '${friends.length} Mutual';

    return GestureDetector(
      onTap: hasAvatars ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Column(
          children: [
            if (hasAvatars)
              OverlappingAvatars(friends: friends.take(3).toList())
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navyLight, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  boxShadow: [AppElevation.md],
                ),
                child: Icon(
                  AppPhosphorIcons.people,
                  color: AppColors.pure,
                  size: AppIconSize.button,
                ),
              ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
