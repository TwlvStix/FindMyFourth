import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

/// Header section for the peer rating form.
///
/// Shows a thumbs-up icon, the course name, the prompt question,
/// and a privacy notice.
class PeerRatingHeader extends StatelessWidget {
  const PeerRatingHeader({super.key, required this.courseName});

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
            AppPhosphorIcons.thumbsUp,
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
            'Would you play again?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                AppPhosphorIcons.lock,
                size: AppIconSize.xs,
                color: AppColors.textMuted,
              ),
              SizedBox(width: AppSpacing.xxs),
              Text(
                'Responses are always private',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
