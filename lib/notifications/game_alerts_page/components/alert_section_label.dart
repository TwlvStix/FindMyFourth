import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';

/// Section label for Game Alerts page groupings (FILTERS, SPECIAL, COURSES).
///
/// Matches the notification settings page section label pattern:
/// - Uppercase text
/// - Small, muted styling
/// - Consistent spacing
class AlertSectionLabel extends StatelessWidget {
  const AlertSectionLabel({
    super.key,
    required this.text,
    this.isFirst = false,
  });

  /// Label text (will be uppercased automatically)
  final String text;

  /// Whether this is the first section (no top margin needed)
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : AppSpacing.xl, // 24px between sections
        bottom: AppSpacing.sm, // 12px before first card
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelMicro.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
