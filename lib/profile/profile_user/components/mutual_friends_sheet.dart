import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

class MutualFriendsSheet extends StatelessWidget {
  const MutualFriendsSheet({
    super.key,
    required this.mutualFriends,
    required this.onFriendTap,
  });

  final List<UsersRecord> mutualFriends;
  final void Function(UsersRecord friend) onFriendTap;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.xxl),
          topRight: Radius.circular(AppBorderRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Mutual Friends',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.pure,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  ),
                  child: Text(
                    mutualFriends.length > 3 ? '3+' : '${mutualFriends.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xxxl,
              ),
              shrinkWrap: true,
              itemCount: mutualFriends.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.navyLight,
              ),
              itemBuilder: (context, index) {
                final friend = mutualFriends[index];
                final handicapStr = friend.handicap < 0
                    ? '+${friend.handicap.abs()}'
                    : friend.handicap.toString();
                final displayName = friend.displayName.isNotEmpty
                    ? friend.displayName
                    : 'Golfer';
                final fullName = [friend.firstName, friend.lastName]
                    .where((n) => n.trim().isNotEmpty)
                    .join(' ')
                    .trim();
                final title = fullName.isNotEmpty ? fullName : displayName;

                return GestureDetector(
                  onTap: () => onFriendTap(friend),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.navy,
                          ),
                          child: ClipOval(
                            child: friend.photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: friend.photoUrl,
                                    fit: BoxFit.cover,
                                    fadeInDuration: Duration.zero,
                                    errorWidget: (_, __, ___) => Icon(
                                      AppPhosphorIcons.profile,
                                      color: AppColors.textSecondary,
                                      size: AppIconSize.md,
                                    ),
                                  )
                                : Icon(
                                    AppPhosphorIcons.profile,
                                    color: AppColors.textSecondary,
                                    size: AppIconSize.md,
                                  ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.pure,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (displayName.isNotEmpty)
                                Text(
                                  '@$displayName',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Text(
                            handicapStr,
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Icon(
                          AppPhosphorIcons.chevronRight,
                          color: AppColors.textSecondary,
                          size: AppIconSize.button,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
