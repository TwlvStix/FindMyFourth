import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_icon.dart';

/// A premium selection card widget for grid-based selections.
///
/// Features:
/// - Animated selection state with gradient background
/// - Gold border and shadow when selected
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
                    AppColors.fairway.withValues(alpha: 0.5),
                    AppColors.fairwayDark.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.fairway.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.sunsetGold
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sunsetGold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
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
                        colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: svgPath != null
                  ? Center(
                      child: AppIcon(
                        assetPath: svgPath!,
                        size: 20,
                        color: Colors.white,
                      ),
                    )
                  : emoji != null
                      ? Center(
                          child: Text(emoji!, style: TextStyle(fontSize: 18)),
                        )
                      : Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(height: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 12,
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
