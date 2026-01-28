import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';

/// Host information section showing avatar, name, and view profile button
class HostInfoSection extends StatelessWidget {
  const HostInfoSection({
    super.key,
    required this.hostUser,
  });

  final UsersRecord hostUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.fairwayLight, AppColors.fairway],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.sunsetGold,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hostUser.photoUrl.isNotEmpty
                ? Image.network(
                    hostUser.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosted by',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  hostUser.displayName.isNotEmpty
                      ? hostUser.displayName
                      : 'Golfer',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // View profile button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pushNamed(
                'ProfileUser',
                extra: <String, dynamic>{
                  'userRef': hostUser.reference,
                },
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
