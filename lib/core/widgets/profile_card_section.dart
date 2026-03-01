import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Premium white card section for profile content.
///
/// Creates an elevated white card with:
/// - Clean white background
/// - Layered subtle shadows
/// - Section title
/// - Custom child content
/// - Consistent padding and styling
class ProfileCardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets? padding;

  const ProfileCardSection({
    super.key,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: padding ??
          EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.pure,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [AppElevation.md, AppElevation.lg],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.navyDark,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Content
          child,
        ],
      ),
    );
  }
}

/// Icon-based preference item for golf stats display.
///
/// Shows a preference with:
/// - Icon in colored circle
/// - Label
/// - Value/counter
class ProfilePreferenceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget valueWidget;
  final Color iconColor;

  const ProfilePreferenceItem({
    super.key,
    required this.icon,
    required this.label,
    required this.valueWidget,
    this.iconColor = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon circle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withValues(alpha: 0.12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: AppIconSize.lg,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        // Label
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.stone,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        // Value
        valueWidget,
      ],
    );
  }
}
