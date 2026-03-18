import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';

enum AppAvatarSize {
  /// Extra small (24x24) - list items in compact mode
  xs,

  /// Small (32x32) - compact lists, inline mentions
  small,

  /// Medium (40x40) - standard list items
  medium,

  /// Large (56x56) - profile headers, featured users
  large,

  /// Extra large (72x72) - profile pages
  xl,

  /// Extra extra large (96x96) - profile hero sections
  xxl,
}

enum AppAvatarShape {
  /// Circular avatar (default)
  circle,

  /// Rounded square
  rounded,

  /// Square avatar
  square,
}

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AppAvatarSize size;
  final AppAvatarShape shape;
  final Color? backgroundColor;
  final String? semanticLabel;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppAvatarSize.medium,
    this.shape = AppAvatarShape.circle,
    this.backgroundColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = _getDimension();
    final borderRadius = _getBorderRadius();
    final bgColor = backgroundColor ?? AppColors.navy;

    final hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    final container = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: hasValidImage ? null : bgColor,
        borderRadius: borderRadius,
        image: hasValidImage
            ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasValidImage && initials != null
          ? Center(
              child: Text(
                initials!,
                style: _getTextStyle().copyWith(
                  color: AppColors.pure,
                ),
              ),
            )
          : null,
    );

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        image: true,
        child: container,
      );
    }

    return ExcludeSemantics(child: container);
  }

  double _getDimension() {
    switch (size) {
      case AppAvatarSize.xs:
        return 24;
      case AppAvatarSize.small:
        return 32;
      case AppAvatarSize.medium:
        return 40;
      case AppAvatarSize.large:
        return 56;
      case AppAvatarSize.xl:
        return 72;
      case AppAvatarSize.xxl:
        return 96;
    }
  }

  BorderRadius? _getBorderRadius() {
    switch (shape) {
      case AppAvatarShape.circle:
        return BorderRadius.circular(AppBorderRadius.full); // Full circle
      case AppAvatarShape.rounded:
        return BorderRadius.circular(AppBorderRadius.md);
      case AppAvatarShape.square:
        return null;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppAvatarSize.xs:
        return AppTypography.labelSmall;
      case AppAvatarSize.small:
        return AppTypography.labelMedium;
      case AppAvatarSize.medium:
        return AppTypography.titleMedium;
      case AppAvatarSize.large:
        return AppTypography.titleLarge;
      case AppAvatarSize.xl:
        return AppTypography.headlineSmall;
      case AppAvatarSize.xxl:
        return AppTypography.headlineMedium;
    }
  }
}
