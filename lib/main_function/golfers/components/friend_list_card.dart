import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/providers/user_provider.dart';
import '/utils/app_util.dart';

/// Friend list card component for displaying current friends with actions
class FriendListCard extends StatelessWidget {
  final UsersRecord user;
  final Future<void> Function(BuildContext, UsersRecord) onOpenDirectChat;

  const FriendListCard({
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
          // Premium Avatar
          _buildPremiumAvatar(user.photoUrl, 52),
          SizedBox(width: AppSpacing.md),
          // Name and course
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(user.displayName, 'Friend'),
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
          // Action buttons
          Row(
            children: [
              // View profile
              GestureDetector(
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
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.fairwayLight, AppColors.fairway],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'View',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Chat
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await onOpenDirectChat(context, user);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sunsetGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                ),
              ),
              SizedBox(width: 8),
              // Remove friend
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  try {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (alertDialogContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Remove Friend?',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onyx,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            'This will remove you from each other\'s friends list.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.slate,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(alertDialogContext, false),
                              child: Text(
                                'Cancel',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.stone,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(alertDialogContext, true),
                              child: Text(
                                'Remove',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ) ?? false;
                    if (!confirm) return;
                    await context.read<UserProvider>().removeFriend(user.reference);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Friend removed.',
                          style: AppTypography.bodySmall.copyWith(color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    showSnackbar(context, 'Unable to remove friend. Please try again.');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_remove_rounded, color: AppColors.error, size: 18),
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
