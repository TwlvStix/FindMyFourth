import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';

/// Standardized section header with title, optional subtitle, and optional action button
///
/// Purpose: Replaces 20+ inline section header patterns with consistent spacing and typography.
///
/// Features:
/// - Title with optional subtitle
/// - Optional leading icon
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
///   leadingIcon: Icons.golf_course,
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
  });

  /// Section title (required)
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Optional action text (e.g., "See All", "View More")
  final String? actionText;

  /// Callback when action is tapped
  final VoidCallback? onActionTap;

  /// Optional leading icon
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color: AppColors.fairway,
              size: 20,
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
                  color: AppColors.fairway,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
