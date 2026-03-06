import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/animated_vibe_ring.dart';

/// Avatar wrapped with an animated vibe ring.
///
/// Shows a circular avatar inside an animated ring that fills
/// based on the vibe match score. Falls back to initials or
/// a placeholder icon if no photo URL is provided.
class VibeRingAvatar extends StatelessWidget {
  const VibeRingAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.vibeScore,
    this.size = 56,
    this.animationDelay = Duration.zero,
  });

  final String photoUrl;
  final String displayName;
  final double? vibeScore;
  final double size;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();

    // If no vibe score, show avatar without ring
    if (vibeScore == null || vibeScore! <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: avatar,
      );
    }

    return AnimatedVibeRing(
      vibeScore: vibeScore!,
      size: size,
      strokeWidth: 2.5,
      animationDelay: animationDelay,
      child: avatar,
    );
  }

  Widget _buildAvatar() {
    final innerSize = vibeScore != null && vibeScore! > 0
        ? size - 9  // Account for ring stroke + padding
        : size;

    return Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navy,
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: innerSize,
                height: innerSize,
                cacheWidth: (innerSize * 3).toInt(),
                cacheHeight: (innerSize * 3).toInt(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(innerSize),
              )
            : _buildFallback(innerSize),
      ),
    );
  }

  Widget _buildFallback(double innerSize) {
    final initials = _getInitials(displayName);
    final fontSize = innerSize * 0.35;

    return Container(
      width: innerSize,
      height: innerSize,
      color: AppColors.navy,
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize.clamp(12, 20),
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
