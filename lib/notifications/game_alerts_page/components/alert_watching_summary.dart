import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/models/alert_subscription.dart';

/// Inline summary line showing current filter state.
///
/// Displays "Watching: ..." with filter icon at top of content.
class AlertWatchingSummary extends StatelessWidget {
  const AlertWatchingSummary({
    super.key,
    required this.subscription,
  });

  final AlertSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final summary = subscription.getSummary();
    // getSummary() already returns "Watching: ..." so just truncate if needed
    final displaySummary =
        summary.length > 50 ? '${summary.substring(0, 47)}...' : summary;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.filter,
            size: AppIconSize.sm,
            color: AppColors.textMuted,
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              displaySummary,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
