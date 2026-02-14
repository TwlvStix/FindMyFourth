import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/design_tokens/colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: EdgeInsets.all(4),
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
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.sunsetGold,
                            AppColors.sunsetPeach,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.sunsetGold.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      option['label'] as String,
                      style: TextStyle(fontFamily: 'Outfit',
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
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
  }
}
