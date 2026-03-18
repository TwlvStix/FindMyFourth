import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

class ChatImageViewer extends StatelessWidget {
  const ChatImageViewer({
    super.key,
    required this.imageUrl,
    required this.onClose,
  });

  final String imageUrl;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                fadeInDuration: Duration.zero,
                progressIndicatorBuilder: (context, url, progress) {
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
                      color: AppColors.pure,
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          icon: AppPhosphorIcons.error,
                          color: AppColors.textPrimary,
                          size: AppIconSize.xxl,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: AppIcon(
                icon: AppPhosphorIcons.close,
                color: AppColors.textPrimary,
                size: AppIconSize.md,
              ),
              tooltip: 'Close image',
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
