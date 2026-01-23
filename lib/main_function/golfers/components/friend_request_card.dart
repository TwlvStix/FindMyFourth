import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/providers/user_provider.dart';
import '/utils/app_util.dart';

/// Friend request card component for displaying pending friend requests
class FriendRequestCard extends StatelessWidget {
  final UsersRecord user;
  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;

  const FriendRequestCard({
    super.key,
    required this.user,
    this.onAccepted,
    this.onRejected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sunsetPeach.withOpacity(0.15),
            AppColors.sunsetGold.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.sunsetGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Premium Avatar
          _buildPremiumAvatar(user.photoUrl, 52),
          SizedBox(width: AppSpacing.md),
          // Name and course
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Friend Request',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.sunsetGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  valueOrDefault<String>(user.displayName, 'Golfer'),
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.homeCourse.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      user.homeCourse,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Accept/Reject buttons
          Row(
            children: [
              // Accept button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    await context
                        .read<UserProvider>()
                        .acceptFriendRequest(user.reference);
                    onAccepted?.call();
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Friend request accepted!',
                          style:
                              AppTypography.bodySmall.copyWith(color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to accept request.',
                          style:
                              AppTypography.bodySmall.copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.fairwayLight, AppColors.fairway],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.fairway.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 22),
                ),
              ),
              SizedBox(width: 8),
              // Reject button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    await context
                        .read<UserProvider>()
                        .rejectFriendRequest(user.reference);
                    onRejected?.call();
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to reject request.',
                          style:
                              AppTypography.bodySmall.copyWith(color: Colors.white),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.close_rounded, color: AppColors.error, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAvatar(String? photoUrl, double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gradient ring
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                AppColors.sunsetGold,
                AppColors.sunsetPeach,
                AppColors.sunsetRose,
                AppColors.fairwayLight,
                AppColors.sunsetGold,
              ],
            ),
          ),
        ),
        // White border
        Container(
          width: size + 4,
          height: size + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pure,
          ),
        ),
        // Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            valueOrDefault<String>(
              photoUrl,
              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
            ),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              color: AppColors.sand,
              child: Icon(Icons.person_rounded, size: size * 0.5, color: AppColors.stone),
            ),
          ),
        ),
      ],
    );
  }
}
