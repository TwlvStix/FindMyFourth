import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import 'selection_card.dart';

/// A responsive grid layout widget for displaying SelectionCard widgets.
///
/// Features:
/// - Configurable column count (default: 2)
/// - Configurable aspect ratio (default: 1.4)
/// - Consistent spacing using AppSpacing
/// - Automatic integration with SelectionCard
/// - Non-scrollable (embedded in parent scroll view)
///
/// Used for: Game type grids, scoring method grids, etc.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.4,
  });

  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final Function(String) onChanged;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: childAspectRatio,
      padding: EdgeInsets.zero,
      children: options.map((option) {
        final isSelected = selectedValue == option['value'];
        return SelectionCard(
          icon: option['icon'] as IconData,
          label: option['label'] as String,
          emoji: option['emoji'] as String?,
          svgPath: option['svgPath'] as String?,
          isSelected: isSelected,
          onTap: () => onChanged(option['value'] as String),
        );
      }).toList(),
    );
  }
}
