import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// A row displaying a feature with an icon, title, and description.
///
/// Used on the onboarding welcome step to highlight app features.
class OnboardingFeatureRow extends StatelessWidget {
  const OnboardingFeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  /// Phosphor icon to display in the circular container.
  final PhosphorIconData icon;

  /// Feature title.
  final String title;

  /// Feature description.
  final String description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      child: Padding(
        padding: AppSpacing.only(bottom: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container - intentional fixed 48x48 size for visual consistency
            ExcludeSemantics(
              child: Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: AppColors.navyDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  icon: icon,
                  size: AppIconSize.md,
                  color: AppColors.navyDark,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppSpacing.only(left: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: AppSpacing.only(top: AppSpacing.xxs),
                      child: Text(
                        description,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
