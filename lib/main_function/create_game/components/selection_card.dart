import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
/// - Supports Phosphor icons, SVG, emoji, and Material icons
/// - Haptic feedback on tap
/// - Consistent styling with design tokens
///
/// Icon priority: phosphorIcon > emoji > icon (Material)
///
/// Used for: Game type selection, course type, scoring method, etc.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
    this.phosphorIcon,
  });

  /// Material icon (fallback only). Use phosphorIcon instead for new code.
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;
  /// Phosphor icon (preferred). Takes priority over all other icon types.
  final PhosphorIconData? phosphorIcon;

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
                : AppColors.glassSurface,
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
                color: isSelected ? null : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: phosphorIcon != null
                  ? Center(
                      child: AppIcon(
                        icon: phosphorIcon!,
                        size: AppIconSize.button,
                        color: AppColors.pure,
                      ),
                    )
                  : emoji != null
                      ? Center(
                          child: Text(emoji!, style: AppTypography.bodyLarge.copyWith(fontSize: 18)),
                        )
                      : icon != null
                          ? Icon(icon, color: AppColors.pure, size: AppIconSize.button)
                          : const SizedBox.shrink(),
            ),
            SizedBox(height: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.pure,
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
