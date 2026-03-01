import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/providers/user_provider.dart';

class ProfileAvatarFriendFab extends StatelessWidget {
  const ProfileAvatarFriendFab({
    super.key,
    required this.userRef,
    required this.friendRequests,
  });

  final DocumentReference userRef;
  final List<dynamic> friendRequests;

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) {
        final userProvider = context.watch<UserProvider>();
        final currentUserRef = currentUserReference;
        final currentFriends = currentUserDocument?.friends.toList() ?? [];
        final currentRequests =
            currentUserDocument?.friendRequests.toList() ?? [];

        final isFriend = currentFriends.contains(userRef);
        final hasPending = currentRequests.contains(userRef) ||
            (currentUserRef != null &&
                friendRequests.contains(currentUserRef)) ||
            userProvider.hasPendingOutgoingRequest(userRef.id);

        IconData icon;
        List<Color> gradientColors;
        VoidCallback? onTap;

        if (isFriend) {
          icon = AppPhosphorIcons.check;
          gradientColors = [AppColors.navyDark, AppColors.navy];
        } else if (hasPending) {
          icon = AppPhosphorIcons.pending;
          gradientColors = [AppColors.gold, AppColors.goldLight];
        } else {
          icon = AppPhosphorIcons.addPlayer;
          gradientColors = [AppColors.gold, AppColors.goldLight];
          onTap = () async {
            HapticFeedback.lightImpact();
            try {
              await context.read<UserProvider>().sendFriendRequest(userRef);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Friend request sent!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  duration: Duration(milliseconds: 1500),
                  backgroundColor: AppColors.navyDark,
                ),
              );
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unable to send request.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          };
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.navyDark,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.pure,
              size: AppIconSize.button,
            ),
          ),
        );
      },
    );
  }
}
