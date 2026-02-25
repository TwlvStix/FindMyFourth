import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

/// Navigation row card for Courses selection.
///
/// Features:
/// - 40x40 icon container with map pin icon
/// - Title and subtitle with green status dot
/// - Static chevron (doesn't rotate) indicating navigation
/// - Entire card is tappable to open course picker
class AlertNavigationCard extends StatelessWidget {
  const AlertNavigationCard({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  /// Card title (e.g., "Courses")
  final String title;

  /// Icon for the card
  final PhosphorIconData icon;

  /// Subtitle showing current state (e.g., "All courses", "3 courses")
  final String subtitle;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Whether courses are selected (for dot color)
  bool get _hasSelection => !subtitle.toLowerCase().contains('all');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: AppColors.navyLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon container (40x40)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AppIcon(
                    icon: icon,
                    size: AppIconSize.md,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              SizedBox(width: AppSpacing.sm),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        // Status dot
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _hasSelection
                                ? AppColors.green
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        // Subtitle text
                        Expanded(
                          child: Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: AppSpacing.sm),

              // Static chevron (navigation indicator)
              AppIcon(
                icon: AppPhosphorIcons.chevronRight,
                size: AppIconSize.sm,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
