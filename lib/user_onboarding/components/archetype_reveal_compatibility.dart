import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Displays compatibility teaser information for an archetype.
///
/// Shows which archetypes pair well together and which to watch out for.
class ArchetypeRevealCompatibility extends StatelessWidget {
  const ArchetypeRevealCompatibility({
    super.key,
    required this.bestWith,
    required this.watchOutFor,
    required this.animationValue,
  });

  /// The two archetypes that pair best with this one.
  final List<String> bestWith;

  /// The archetype to watch out for (potential friction).
  final String watchOutFor;

  /// Animation value (0.0-1.0) for fade and slide.
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final offset = Offset(0, 12 * (1 - animationValue));

    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: animationValue,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              children: [
                // Best with row
                _buildCompatibilityRow(
                  label: 'Plays well with',
                  values: bestWith,
                  valueColor: AppColorsDark.success,
                ),
                SizedBox(height: AppSpacing.sm),
                // Watch out for row
                _buildCompatibilityRow(
                  label: 'Watch out for',
                  values: [watchOutFor],
                  valueColor: AppColorsDark.warning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilityRow({
    required String label,
    required List<String> values,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: AppTypography.labelSmall.copyWith(
            color: AppColorsDark.textMuted,
          ),
        ),
        Text(
          values.join(' & '),
          style: AppTypography.labelSmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
