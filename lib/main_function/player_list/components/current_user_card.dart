import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/models/user_profile.dart';

class CurrentUserCard extends StatelessWidget {
  const CurrentUserCard({
    super.key,
    required this.currentUserRef,
  });

  final DocumentReference? currentUserRef;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: currentUserRef?.snapshots(),
      builder: (context, userSnapshot) {
        final profile = userSnapshot.hasData
            ? UserProfile.fromDoc(userSnapshot.data!)
            : null;

        return Container(
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                  child: profile?.photoUrl.isNotEmpty ?? false
                      ? CachedNetworkImage(
                          imageUrl: profile!.photoUrl,
                          width: 48.0,
                          height: 48.0,
                          fit: BoxFit.cover,
                          memCacheWidth: 96,
                          memCacheHeight: 96,
                          fadeInDuration: Duration.zero,
                          errorWidget: (_, __, ___) => AppIcon(
                            icon: AppPhosphorIcons.profile,
                            color: AppColors.textMuted,
                            size: AppIconSize.md,
                          ),
                        )
                      : AppIcon(
                          icon: AppPhosphorIcons.profile,
                          color: AppColors.textMuted,
                          size: AppIconSize.md,
                        ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName.isNotEmpty ?? false
                          ? profile!.displayName
                          : 'You',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Game Creator',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: Text(
                  'You',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
