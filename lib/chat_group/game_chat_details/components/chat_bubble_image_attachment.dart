import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Image attachment sub-widget for [ChatMessageBubble].
///
/// Displays a cached network image with an aspect-ratio-aware loading
/// skeleton and an error fallback.
class ChatBubbleImageAttachment extends StatelessWidget {
  final String imageUrl;
  final double? imageWidth;
  final double? imageHeight;
  final String messageText;
  final bool isSentByCurrentUser;
  final Color textColor;
  final VoidCallback? onImageTap;

  const ChatBubbleImageAttachment({
    super.key,
    required this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    required this.messageText,
    required this.isSentByCurrentUser,
    required this.textColor,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: messageText.isNotEmpty ? AppSpacing.xs : 0),
      child: GestureDetector(
        onTap: onImageTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                // Use stored dimensions for correct aspect-ratio skeleton
                final double w = (imageWidth != null &&
                        imageHeight != null &&
                        imageWidth! > 0)
                    ? 220.0
                    : 200.0;
                final double h = (imageWidth != null &&
                        imageHeight != null &&
                        imageWidth! > 0)
                    ? (220.0 * imageHeight! / imageWidth!)
                        .clamp(80.0, 300.0)
                    : 200.0;
                return Container(
                  width: w,
                  height: h,
                  color: AppColors.stone.withValues(alpha: 0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: isSentByCurrentUser
                          ? AppColors.pure
                              .withValues(alpha: 0.8)
                          : AppColors.navyDark,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  height: 150,
                  width: 200,
                  color: AppColors.stone.withValues(alpha: 0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        icon: AppPhosphorIcons.imageBroken,
                        color: textColor.withValues(alpha: 0.6),
                        size: AppIconSize.xl,
                      ),
                      AppSpacing.verticalXsBox,
                      Text(
                        'Failed to load',
                        style: AppTypography.labelMicro.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
