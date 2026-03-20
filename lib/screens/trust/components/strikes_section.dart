import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import 'standing_section_card.dart';

class StrikesSection extends StatelessWidget {
  const StrikesSection({super.key, required this.standing});

  final Map<String, dynamic> standing;

  @override
  Widget build(BuildContext context) {
    final strikes = (standing['strikes'] as List<dynamic>?) ?? [];
    final activeCount =
        (standing['activeStrikeCount'] as num?)?.toInt() ?? 0;
    final nextThresholdMap =
        standing['nextThreshold'] as Map<String, dynamic>?;
    final strikesNeeded =
        (nextThresholdMap?['strikesNeeded'] as num?)?.toInt();
    final restrictionLabel =
        nextThresholdMap?['restriction'] as String?;

    return StandingSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                icon: AppPhosphorIcons.lightning,
                color:
                    activeCount > 0 ? AppColors.warning : AppColors.success,
                size: AppIconSize.button,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Active Strikes',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: Text(
                  '$activeCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: activeCount > 0
                        ? AppColors.warning
                        : AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (strikesNeeded != null &&
              strikesNeeded > 0 &&
              restrictionLabel != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              '$strikesNeeded more strike${strikesNeeded == 1 ? "" : "s"} until: $restrictionLabel',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
          if (strikes.isEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              'No active strikes.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          ] else ...[
            SizedBox(height: AppSpacing.md),
            ...strikes.map((strike) {
              final map = strike as Map<String, dynamic>;
              return _StrikeRow(strike: map);
            }),
          ],
        ],
      ),
    );
  }
}

class _StrikeRow extends StatelessWidget {
  const _StrikeRow({required this.strike});

  final Map<String, dynamic> strike;

  @override
  Widget build(BuildContext context) {
    final reason = strike['reason'] as String? ?? '';
    final expiresAtMs = (strike['expiresAt'] as num?)?.toInt();

    final label = _reasonLabel(reason);
    final expiryText = expiresAtMs != null
        ? _formatExpiry(
            DateTime.fromMillisecondsSinceEpoch(expiresAtMs))
        : '';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppIcon(
              icon: AppPhosphorIcons.lightning,
              color: AppColors.warning,
              size: AppIconSize.xs,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (expiryText.isNotEmpty)
                  Text(
                    'Expires $expiryText',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'day_of_cancel':
        return 'Same-day cancellation';
      case 'late_cancel_pattern':
        return 'Late cancellation pattern (3 in 90 days)';
      case 'ghost_no_show':
        return 'No-show (ghost)';
      default:
        return reason;
    }
  }

  String _formatExpiry(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays > 0) {
      return 'in ${diff.inDays} day${diff.inDays == 1 ? "" : "s"}';
    } else if (diff.inHours > 0) {
      return 'in ${diff.inHours} hour${diff.inHours == 1 ? "" : "s"}';
    } else {
      return 'soon';
    }
  }
}
