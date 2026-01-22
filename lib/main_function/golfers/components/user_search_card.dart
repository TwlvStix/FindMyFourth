import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/providers/user_provider.dart';
import '/providers/chat_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/app_util.dart';

/// User search card component for displaying search results with add friend functionality
class UserSearchCard extends StatelessWidget {
  final UsersRecord user;
  final Future<void> Function(BuildContext, UsersRecord) onOpenDirectChat;

  const UserSearchCard({
    super.key,
    required this.user,
    required this.onOpenDirectChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.fairway.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.fairwayLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Premium Avatar with gradient ring
          _buildPremiumAvatar(user.photoUrl, 56),
          SizedBox(width: AppSpacing.md),
          // Name, course, and handicap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(user.displayName, 'Golfer'),
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                if (user.homeCourse.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.sunsetGold,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
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
                if (user.handicap != null && user.handicap > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'HC ${user.handicap}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.sunsetGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          // Action buttons
          AuthUserStreamWidget(
            builder: (context) {
              final isFriend =
                  (currentUserDocument?.friends.toList() ?? [])
                      .contains(user.reference);
              final hasPending = user.friendRequests.contains(
                      currentUserReference) ||
                  (currentUserDocument?.friendRequests.toList() ?? [])
                      .contains(user.reference);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary action button (state-based)
                  if (isFriend)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.fairwayLight, AppColors.fairway],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Friends',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hasPending)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.7), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Pending',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await context.read<UserProvider>().sendFriendRequest(user.reference);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Friend request sent!', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                              duration: Duration(milliseconds: 1500),
                              backgroundColor: AppColors.fairwayDark,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unable to send request.', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunsetGold.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Add',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  // View profile
                  _buildGlassIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pushNamed(
                        'ProfileUser',
                        extra: <String, dynamic>{
                          'userRef': user.reference,
                          kTransitionInfoKey: TransitionStandards.detailTransition,
                        },
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  // Chat
                  _buildGlassIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await onOpenDirectChat(context, user);
                    },
                  ),
                ],
              );
            },
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

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
