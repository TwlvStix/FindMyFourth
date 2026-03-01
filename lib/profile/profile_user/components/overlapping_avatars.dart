import 'package:flutter/material.dart';

import '/backend/schema/users_record.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';

class OverlappingAvatars extends StatelessWidget {
  const OverlappingAvatars({
    super.key,
    required this.friends,
  });

  final List<UsersRecord> friends;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 36.0;
    const overlap = 12.0;
    final count = friends.length.clamp(1, 3);
    final totalWidth = avatarSize + (count - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(count, (i) {
          final friend = friends[i];
          return Positioned(
            left: i * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navy, width: 2),
                color: AppColors.navyLight,
                boxShadow: [AppElevation.sm],
              ),
              child: ClipOval(
                child: friend.photoUrl.isNotEmpty
                    ? Image.network(
                        friend.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          AppPhosphorIcons.profile,
                          size: AppIconSize.button,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        AppPhosphorIcons.profile,
                        size: AppIconSize.button,
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
