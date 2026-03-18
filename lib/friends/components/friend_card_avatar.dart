import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Rounded-square avatar for friend cards.
class FriendCardAvatar extends StatelessWidget {
  const FriendCardAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.size = 52,
  });

  final String photoUrl;
  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg - 1),
        child: photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                width: size,
                height: size,
                memCacheWidth: (size * 3).toInt(),
                memCacheHeight: (size * 3).toInt(),
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                errorWidget: (_, __, ___) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    final initials = _getInitials(displayName);

    return Container(
      color: AppColors.navy,
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              )
            : AppIcon(
                icon: AppPhosphorIcons.profile,
                color: AppColors.textMuted,
                size: AppIconSize.md,
              ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }
}
