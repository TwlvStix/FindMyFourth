import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Description section of the archetype reveal: animated divider that grows
/// in width, followed by a fade + slide-up description paragraph.
class ArchetypeRevealDescription extends StatelessWidget {
  const ArchetypeRevealDescription({
    super.key,
    required this.description,
    required this.accentColor,
    required this.dividerValue,
    required this.descriptionValue,
  });

  final String description;
  final Color accentColor;
  final double dividerValue;
  final double descriptionValue;

  @override
  Widget build(BuildContext context) {
    final descOffset = Offset(0, 12 * (1 - descriptionValue));
    final dividerWidth = 200.0 * dividerValue;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          // Animated divider
          Opacity(
            opacity: dividerValue,
            child: Container(
              width: dividerWidth,
              height: 1,
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // Description text
          Transform.translate(
            offset: descOffset,
            child: Opacity(
              opacity: descriptionValue,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColorsDark.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
