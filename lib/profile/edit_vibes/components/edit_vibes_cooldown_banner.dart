import '/core/content/app_copy.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

class EditVibesCooldownBanner extends StatelessWidget {
  const EditVibesCooldownBanner({
    super.key,
    required this.cooldownDateText,
  });

  final String cooldownDateText;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      opacity: 0.20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColorsDark.navyLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColorsDark.glassBorder,
              ),
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.clock,
                size: AppIconSize.button,
                color: AppColorsDark.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppVibeEditCopy.cooldownBannerMessage(cooldownDateText),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColorsDark.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppVibeEditCopy.cooldownBannerSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColorsDark.textSecondary,
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
