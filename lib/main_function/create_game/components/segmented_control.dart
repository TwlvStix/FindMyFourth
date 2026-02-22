import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';

/// A generic segmented control widget for binary or multi-option selections.
///
/// Features:
/// - Animated selection state with gradient background
/// - Gold gradient on selected segment
/// - Supports icons and labels for each option
/// - Haptic feedback on tap
/// - Flexible option count (2+ options)
///
/// Used for: Public/Private visibility, skill level selection, etc.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available width
        final width = constraints.maxWidth;
        final isCompact = width < 360; // Small phones
        final iconSize = isCompact ? 18.0 : 20.0;
        final fontSize = isCompact ? 13.0 : 15.0;
        final spacing = isCompact ? 4.0 : 8.0;
        final verticalPadding = isCompact ? 12.0 : 14.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          padding: AppSpacing.allXxs,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedValue == option['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(option['value']);
                  },
                  child: AnimatedContainer(
                    duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppColors.gold,
                                AppColors.goldLight,
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      boxShadow: isSelected ? [AppElevation.md] : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                          size: iconSize,
                        ),
                        SizedBox(width: spacing),
                        Flexible(
                          child: Text(
                            option['label'] as String,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontSize: fontSize,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
