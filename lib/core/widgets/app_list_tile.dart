import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/spacing.dart';
import 'app_avatar.dart';
import 'app_icon.dart';

enum AppListTileVariant {
  /// Standard list tile with divider
  standard,

  /// Compact tile for dense lists
  compact,

  /// Card-style tile with background
  card,

  /// Highlighted tile for selected/active state
  highlighted,
}

class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? leadingWidget;
  final Widget? trailingWidget;
  final String? avatarUrl;
  final String? avatarInitials;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final PhosphorIconData? leadingPhosphorIcon;
  final PhosphorIconData? trailingPhosphorIcon;
  final AppListTileVariant variant;
  final VoidCallback? onTap;
  final bool showDivider;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leadingWidget,
    this.trailingWidget,
    this.avatarUrl,
    this.avatarInitials,
    this.leadingIcon,
    this.trailingIcon,
    this.leadingPhosphorIcon,
    this.trailingPhosphorIcon,
    this.variant = AppListTileVariant.standard,
    this.onTap,
    this.showDivider = true,
    this.semanticLabel,
  });

  final String? semanticLabel;

  Widget _wrapWithSemantics(Widget child) {
    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    switch (variant) {
      case AppListTileVariant.standard:
        return Column(
          children: [
            _wrapWithSemantics(
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: content,
                ),
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.cloud,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        );

      case AppListTileVariant.compact:
        return Column(
          children: [
            _wrapWithSemantics(
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.cloud,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        );

      case AppListTileVariant.card:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Material(
            color: AppColors.pure,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            elevation: 0,
            child: _wrapWithSemantics(
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cloud),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: content,
                ),
              ),
            ),
          ),
        );

      case AppListTileVariant.highlighted:
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Material(
            color: AppColors.navyLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            child: _wrapWithSemantics(
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.navy.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: content,
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildContent() {
    return Row(
      children: [
        if (leadingWidget != null)
          leadingWidget!
        else if (avatarUrl != null || avatarInitials != null)
          AppAvatar(
            imageUrl: avatarUrl,
            initials: avatarInitials,
            size: variant == AppListTileVariant.compact
                ? AppAvatarSize.small
                : AppAvatarSize.medium,
          )
        else if (leadingPhosphorIcon != null)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: AppIcon(
                icon: leadingPhosphorIcon!,
                color: AppColors.slate,
                size: AppIconSize.button,
              ),
            ),
          )
        else if (leadingIcon != null)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(
              leadingIcon,
              color: AppColors.slate,
              size: AppIconSize.button,
            ),
          ),
        if (leadingWidget != null ||
            avatarUrl != null ||
            avatarInitials != null ||
            leadingPhosphorIcon != null ||
            leadingIcon != null)
          SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: variant == AppListTileVariant.compact
                    ? AppTypography.bodyMedium
                    : AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.stone,
                  ),
                  maxLines: variant == AppListTileVariant.compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null || trailingWidget != null || trailingPhosphorIcon != null || trailingIcon != null)
          SizedBox(width: AppSpacing.sm),
        if (trailingWidget != null)
          trailingWidget!
        else if (trailing != null)
          Text(
            trailing!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.stone,
            ),
          )
        else if (trailingPhosphorIcon != null)
          AppIcon(
            icon: trailingPhosphorIcon!,
            color: AppColors.slate,
            size: AppIconSize.button,
          )
        else if (trailingIcon != null)
          Icon(
            trailingIcon,
            color: AppColors.slate,
            size: AppIconSize.button,
          ),
      ],
    );
  }
}
