import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// Consistent section header with icon and title
///
/// Used throughout forms to mark distinct sections.
/// Supports optional help text with info icon that shows dialog on tap.
///
/// Icon priority: phosphorIcon > svgPath > emoji
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.emoji,
    this.svgPath,
    this.phosphorIcon,
    required this.title,
    this.helpText,
    this.onHelpTap,
  });

  final String? emoji;
  final String? svgPath;
  final PhosphorIconData? phosphorIcon;
  final String title;
  final String? helpText;
  final VoidCallback? onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navyLight, AppColors.navy],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: phosphorIcon != null
                  ? AppIcon(
                      icon: phosphorIcon,
                      size: AppIconSize.button,
                      color: AppColors.pure,
                    )
                  : svgPath != null
                      ? AppIcon(
                          assetPath: svgPath!,
                          size: AppIconSize.button,
                          color: AppColors.pure,
                        )
                      : Text(
                          emoji ?? '',
                          style: TextStyle(fontSize: 18),
                        ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helpText != null && onHelpTap != null) ...[
            SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onHelpTap,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.help,
                  color: AppColors.gold,
                  size: AppIconSize.xs,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
