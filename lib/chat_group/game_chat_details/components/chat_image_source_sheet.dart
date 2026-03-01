import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

class ChatImageSourceSheet extends StatelessWidget {
  const ChatImageSourceSheet({
    super.key,
    required this.onGallerySelected,
    required this.onCameraSelected,
  });

  final VoidCallback onGallerySelected;
  final VoidCallback onCameraSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon(
                icon: AppPhosphorIcons.imageGallery,
                color: AppColors.textPrimary,
                size: AppIconSize.md,
              ),
              title: Text(
                'Photo Library',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
              onTap: onGallerySelected,
            ),
            ListTile(
              leading: const AppIcon(
                icon: AppPhosphorIcons.camera,
                color: AppColors.textPrimary,
                size: AppIconSize.md,
              ),
              title: Text(
                'Take Photo',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
              onTap: onCameraSelected,
            ),
          ],
        ),
      ),
    );
  }
}
