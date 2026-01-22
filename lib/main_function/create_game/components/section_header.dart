import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';

/// Consistent section header with emoji icon and title
///
/// Used throughout forms to mark distinct sections.
/// Supports optional help text with info icon that shows dialog on tap.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.helpText,
    this.onHelpTap,
  });

  final String emoji;
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
                colors: [AppColors.fairwayLight, AppColors.fairway],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTheme.of(context).labelMedium.override(
                  font: GoogleFonts.outfit(
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
                  color: AppColors.sunsetGold.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.sunsetGold,
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
