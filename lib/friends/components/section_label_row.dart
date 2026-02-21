import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';

/// Section label row showing context (e.g., "RECOMMENDED FOR YOU") and item count.
class SectionLabelRow extends StatelessWidget {
  final String label;
  final int count;
  final String countLabel;

  const SectionLabelRow({
    super.key,
    required this.label,
    required this.count,
    this.countLabel = 'golfers',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.sunsetGold.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '$count $countLabel',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
