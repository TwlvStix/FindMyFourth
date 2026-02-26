import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// Banner displayed when viewing a cancelled game's detail page.
///
/// Shows a prominent but neutral-toned message indicating the game
/// has been cancelled, with an optional reason.
class CancelledGameBanner extends StatelessWidget {
  const CancelledGameBanner({
    super.key,
    this.reason = 'Cancelled by host',
  });

  /// The cancellation reason displayed as the body text.
  /// Defaults to "Cancelled by host".
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
        boxShadow: [AppElevation.card],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent stripe (red to match cancelled badge styling)
            Container(
              width: 4,
              color: AppColors.error,
            ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      icon: AppPhosphorIcons.blocked,
                      color: AppColors.textMuted,
                      size: AppIconSize.md,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Game Cancelled',
                            style: AppTypography.titleSmall.copyWith(
                              fontFamily: AppTypography.displayFamily,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Text(
                            reason,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
