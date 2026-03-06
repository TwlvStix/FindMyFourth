import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Callout banner showing the mutual friend connection.
///
/// Displays "You both know [Name]" or "You both know [Name] and X others"
/// with an amber-tinted styling to indicate the connection.
class MutualFriendCallout extends StatelessWidget {
  const MutualFriendCallout({
    super.key,
    required this.mutualFriendName,
    this.additionalCount = 0,
  });

  /// The display name of the first mutual friend
  final String mutualFriendName;

  /// Number of additional mutual friends (if any)
  final int additionalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.mutualCalloutBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.mutualCalloutBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wave emoji
          Text(
            '\u{1F44B}',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(width: AppSpacing.xs),
          // Connection text
          Flexible(
            child: Text.rich(
              TextSpan(
                text: 'You both know ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mutualAccent.withValues(alpha: 0.85),
                ),
                children: [
                  TextSpan(
                    text: mutualFriendName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.mutualAccent.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (additionalCount > 0)
                    TextSpan(
                      text: ' and $additionalCount other${additionalCount == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.mutualAccent.withValues(alpha: 0.85),
                      ),
                    ),
                ],
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
