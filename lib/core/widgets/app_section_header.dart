import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/icon_size.dart';
import 'app_icon.dart';

/// Standardized section header with title, optional subtitle, and optional action button
///
/// Purpose: Replaces 20+ inline section header patterns with consistent spacing and typography.
///
/// Features:
/// - Title with optional subtitle
/// - Optional leading icon (IconData or SVG path)
/// - Optional action button (e.g., "See All")
/// - Design token integration
/// - Consistent spacing and typography
///
/// Example:
/// ```dart
/// AppSectionHeader(
///   title: 'Recent Games',
///   subtitle: 'Last 30 days',
///   actionText: 'See All',
///   onActionTap: () => navigateToAllGames(),
///   leadingPhosphorIcon: AppPhosphorIcons.games,
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.leadingIcon,
    this.leadingPhosphorIcon,
  });

  /// Section title (required)
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Optional action text (e.g., "See All", "View More")
  final String? actionText;

  /// Callback when action is tapped
  final VoidCallback? onActionTap;

  /// Optional leading icon (IconData)
  final IconData? leadingIcon;

  /// Optional leading Phosphor icon (takes precedence over leadingIcon)
  final PhosphorIconData? leadingPhosphorIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (leadingPhosphorIcon != null) ...[
            AppIcon(
              icon: leadingPhosphorIcon!,
              color: AppColors.navy,
              size: AppIconSize.button,
            ),
            SizedBox(width: AppSpacing.xs),
          ] else if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color: AppColors.navy,
              size: AppIconSize.button,
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.onyx,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.navy,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
