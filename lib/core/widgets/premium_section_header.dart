import 'package:flutter/material.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/border_radius.dart';

/// Premium section header with gradient accent line for dark backgrounds
///
/// Designed for use on dark/navy backgrounds with the premium "Clubhouse" aesthetic.
/// Features a vertical gradient accent bar, title, optional subtitle, and optional
/// trailing widget (e.g., badges, counts, action buttons).
///
/// Example:
/// ```dart
/// PremiumSectionHeader(
///   title: 'Game Details',
/// )
///
/// PremiumSectionHeader(
///   title: 'Players',
///   trailing: Container(
///     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
///     decoration: BoxDecoration(
///       color: AppColors.gold.withValues(alpha: 0.2),
///       borderRadius: BorderRadius.circular(12),
///     ),
///     child: Text('3/4', style: TextStyle(color: AppColors.gold)),
///   ),
/// )
/// ```
class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.gradientColors,
    this.accentHeight = 24.0,
    this.accentWidth = 4.0,
  });

  /// Section title (required)
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Optional trailing widget (badges, counts, action buttons)
  final Widget? trailing;

  /// Custom gradient colors for the accent line (defaults to gold gradient)
  final List<Color>? gradientColors;

  /// Height of the accent line (default: 24)
  final double accentHeight;

  /// Width of the accent line (default: 4)
  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [AppColors.gold, AppColors.goldLight];

    return Row(
      children: [
        // Gradient accent line
        Container(
          width: accentWidth,
          height: accentHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
          ),
        ),
        SizedBox(width: AppSpacing.sm),

        // Title and optional subtitle
        Expanded(
          child: subtitle != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),

        // Optional trailing widget
        if (trailing != null) ...[
          SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
