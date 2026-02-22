import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// A premium selection card widget for grid-based selections.
///
/// Features:
/// - Animated selection state with gradient background
/// - Green border and shadow when selected (primary accent)
/// - Supports both icon and emoji display
/// - Haptic feedback on tap
/// - Consistent styling with design tokens
///
/// Used for: Game type selection, course type, scoring method, etc.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
    this.svgPath,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;
  /// Optional SVG asset path (use AppIcons constants). Takes priority over emoji.
  final String? svgPath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.navy.withValues(alpha: 0.5),
                    AppColors.navyDark.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.navy.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.green
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [AppElevation.glowGreen] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.green, AppColors.greenLight],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: svgPath != null
                  ? Center(
                      child: AppIcon(
                        assetPath: svgPath!,
                        size: AppIconSize.button,
                        color: AppColors.pure,
                      ),
                    )
                  : emoji != null
                      ? Center(
                          child: Text(emoji!, style: AppTypography.bodyLarge.copyWith(fontSize: 18)),
                        )
                      : Icon(icon, color: AppColors.pure, size: AppIconSize.button),
            ),
            SizedBox(height: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
