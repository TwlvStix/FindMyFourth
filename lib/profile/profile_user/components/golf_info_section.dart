import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

class GolfInfoSection extends StatelessWidget {
  const GolfInfoSection({
    super.key,
    required this.golfCanadaNumber,
    this.email,
    this.phone,
    this.hometown,
  });

  final String golfCanadaNumber;
  final String? email;
  final String? phone;
  final String? hometown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
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
          if (hometown != null && hometown!.isNotEmpty) ...[
            _InfoRow(
              icon: AppPhosphorIcons.course,
              label: 'Hometown',
              value: hometown!,
            ),
            SizedBox(height: AppSpacing.lg),
          ],
          _InfoRow(
            icon: AppPhosphorIcons.verified,
            label: 'Golf Canada #',
            value: golfCanadaNumber,
          ),
          if (email != null) ...[
            SizedBox(height: AppSpacing.lg),
            _InfoRow(
              icon: AppPhosphorIcons.email,
              label: 'Email',
              value: email!,
            ),
          ],
          if (phone != null) ...[
            SizedBox(height: AppSpacing.lg),
            _InfoRow(
              icon: AppPhosphorIcons.phone,
              label: 'Phone',
              value: phone!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: AppIconSize.md),
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
                SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
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
