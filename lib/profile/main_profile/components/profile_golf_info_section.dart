import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/utils/app_util.dart';

/// Golf info section of the main profile page.
///
/// Contains Golf Canada #, Email, and Phone info rows.
/// Self-contained with [AuthUserStreamWidget] for reactive user data.
class ProfileGolfInfoSection extends StatelessWidget {
  const ProfileGolfInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Golf Info',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Golf Canada Number
          AuthUserStreamWidget(
            builder: (context) => _buildInfoRow(
              phosphorIcon: AppPhosphorIcons.verified,
              label: 'Golf Canada #',
              value: valueOrDefault(
                  currentUserDocument?.golfCanadaNumber, 'Not set'),
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Email
          _buildInfoRow(
            phosphorIcon: AppPhosphorIcons.email,
            label: 'Email',
            value: currentUserEmail,
          ),

          SizedBox(height: AppSpacing.md),

          // Phone
          AuthUserStreamWidget(
            builder: (context) => _buildInfoRow(
              phosphorIcon: AppPhosphorIcons.phone,
              label: 'Phone',
              value: currentPhoneNumber.isNotEmpty
                  ? currentPhoneNumber
                  : 'Not set',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required PhosphorIconData phosphorIcon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          // Just icon, no container background
          AppIcon(
            icon: phosphorIcon,
            color: AppColors.textMuted,
            size: AppIconSize.md,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
