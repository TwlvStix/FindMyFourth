import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';

class FirmItUpBanner extends StatelessWidget {
  final VoidCallback onPressed;

  const FirmItUpBanner({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.2),
            AppColors.goldLight.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.calendarCheck,
                  color: AppColors.gold,
                  size: AppIconSize.md,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Got Your Tee Time?',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lock in your date, time, and course',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButtonEnhanced(
              text: 'Set Tee Time & Course',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.medium,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
