import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';

/// Multi-select chip component for filter options in expanded filter cards.
///
/// Used for Game Vibe, Stakes, Primary Format, and Handicap Use selections.
/// Chips toggle on tap with green fill when selected.
class AlertFilterChips extends StatelessWidget {
  const AlertFilterChips({
    super.key,
    required this.selectedValues,
    required this.options,
    required this.onChanged,
  });

  /// Currently selected values
  final List<String> selectedValues;

  /// Available options with 'value' and 'label' keys
  final List<Map<String, dynamic>> options;

  /// Callback when selection changes
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((option) {
          final value = option['value'] as String;
          final label = option['label'] as String;
          final isSelected = selectedValues.contains(value);

          return GestureDetector(
            onTap: () {
              final newValues = List<String>.from(selectedValues);
              if (isSelected) {
                newValues.remove(value);
              } else {
                newValues.add(value);
              }
              onChanged(newValues);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.green
                    : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? AppColors.green
                      : AppColors.glassBorder,
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.pure
                      : AppColors.whiteStrong,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
