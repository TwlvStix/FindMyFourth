import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditVibesImportanceCard extends StatelessWidget {
  const EditVibesImportanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pushEditVibeImportance();
      },
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        opacity: 0.25,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColorsDark.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppPhosphorIcons.star,
                  color: AppColorsDark.gold,
                  size: AppIconSize.button,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Improve your match accuracy',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColorsDark.textPrimary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Fine-tune your preferences for better pairings',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColorsDark.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColorsDark.textMuted,
              size: AppIconSize.xs,
            ),
          ],
        ),
      ),
    );
  }
}
