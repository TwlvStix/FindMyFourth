import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/utils/vibe_archetypes.dart';

/// Name section of the archetype reveal: label, archetype name, optional
/// Warden subtitle, and tagline — each with independent fade + slide-up.
class ArchetypeRevealName extends StatelessWidget {
  const ArchetypeRevealName({
    super.key,
    required this.match,
    required this.tagline,
    required this.accentColor,
    required this.labelValue,
    required this.nameValue,
    required this.taglineValue,
  });

  final VibeArchetypeMatch match;
  final String tagline;
  final Color accentColor;
  final double labelValue;
  final double nameValue;
  final double taglineValue;

  @override
  Widget build(BuildContext context) {
    final labelOffset = Offset(0, 12 * (1 - labelValue));
    final nameOffset = Offset(0, 12 * (1 - nameValue));
    final taglineOffset = Offset(0, 8 * (1 - taglineValue));

    return Column(
      children: [
        // "Your vibe style" label
        Transform.translate(
          offset: labelOffset,
          child: Opacity(
            opacity: labelValue,
            child: Text(
              'Your vibe style',
              style: AppTypography.labelSmall.copyWith(
                color: AppColorsDark.textMuted,
                letterSpacing: AppTypography.letterSpacingWide,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        // Archetype name
        Transform.translate(
          offset: nameOffset,
          child: Opacity(
            opacity: nameValue,
            child: Semantics(
              header: true,
              child: Text(
                match.name,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColorsDark.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // Warden base archetype subtitle
        if (match.isWarden && match.baseLabel != null) ...[
          SizedBox(height: AppSpacing.xxs),
          Transform.translate(
            offset: nameOffset,
            child: Opacity(
              opacity: nameValue,
              child: Text(
                match.baseLabel!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsDark.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.sm),
        // Tagline
        Transform.translate(
          offset: taglineOffset,
          child: Opacity(
            opacity: taglineValue,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                tagline,
                style: AppTypography.titleSmall.copyWith(
                  color: accentColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
