import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';

/// CTA section of the archetype reveal: Share and Continue buttons in a row.
class ArchetypeRevealCTA extends StatelessWidget {
  const ArchetypeRevealCTA({
    super.key,
    required this.animationValue,
    required this.isSharing,
    required this.onShare,
    required this.onContinue,
  });

  final double animationValue;
  final bool isSharing;
  final VoidCallback onShare;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: animationValue,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: AppButtonEnhanced(
                text: isSharing ? 'Sharing...' : 'Share',
                variant: AppButtonVariant.ghostDark,
                size: AppButtonSize.large,
                leadingIcon: AppPhosphorIcons.share,
                onPressed: onShare,
                enabled: animationValue > 0.5 && !isSharing,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButtonEnhanced(
                text: 'Continue',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                leadingIcon: AppPhosphorIcons.arrowRight,
                onPressed: onContinue,
                enabled: animationValue > 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
