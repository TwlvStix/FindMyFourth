import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

/// Header section for the fallback confirmation form showing course name
/// and the "Did you play today?" prompt.
class FallbackHeader extends StatelessWidget {
  const FallbackHeader({super.key, required this.courseName});

  final String courseName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.only(
        top: AppSpacing.xxl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: Column(
        children: [
          PhosphorIcon(
            AppPhosphorIcons.golfCourse,
            color: AppColors.textSecondary,
            size: AppIconSize.xxl,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            courseName,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Did you play today?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
