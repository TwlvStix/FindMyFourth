import 'package:flutter/material.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_icon.dart';

/// Consistent section header with icon and title
///
/// Used throughout forms to mark distinct sections.
/// Supports optional help text with info icon that shows dialog on tap.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.emoji,
    this.svgPath,
    required this.title,
    this.helpText,
    this.onHelpTap,
  });

  final String? emoji;
  final String? svgPath;
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: svgPath != null
                  ? AppIcon(
                      assetPath: svgPath!,
                      size: 18,
                      color: Colors.white,
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
            style: AppTheme.of(context).labelMedium.override(
                  font: TextStyle(fontFamily: 'Manrope',
                    fontWeight: AppTheme.of(context).labelMedium.fontWeight,
                    fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: AppTheme.of(context).labelMedium.fontStyle,
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
                child: Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.gold,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
