import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';

/// Expanded content for the Social Alerts notification category card.
///
/// Simple informational text explaining what social notifications cover.
/// No sub-options since it's a single toggle for friend request notifications.
class SocialAlertsContent extends StatelessWidget {
  const SocialAlertsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        'Get notified when someone sends you a friend request or accepts yours.',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
