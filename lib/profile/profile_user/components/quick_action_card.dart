import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
    this.isDisabled = false,
    this.labelColor,
    this.richLabel,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final bool isDisabled;
  final Color? labelColor;
  final Widget? richLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient =
        isDisabled ? [AppColors.navyLight, AppColors.navyLight] : gradient;
    final effectiveLabelColor = isDisabled
        ? AppColors.textMuted
        : (labelColor ?? AppColors.textSecondary);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.navyLight),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: effectiveGradient),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: effectiveGradient[0].withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: isDisabled ? AppColors.textMuted : AppColors.pure,
                size: AppIconSize.button,
              ),
            ),
            SizedBox(height: 4),
            if (richLabel != null)
              richLabel!
            else
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: effectiveLabelColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
