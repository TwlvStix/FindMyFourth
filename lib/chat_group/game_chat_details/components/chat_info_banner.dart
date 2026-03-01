import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

class ChatInfoBanner extends StatelessWidget {
  const ChatInfoBanner({
    super.key,
    required this.bannerText,
    required this.isArchived,
  });

  final String bannerText;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    if (bannerText.isEmpty && !isArchived) {
      return const SizedBox.shrink();
    }

    final displayText =
        bannerText.isNotEmpty ? bannerText : 'This chat is archived.';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.navyDark.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            icon: AppPhosphorIcons.info,
            color: AppColors.textSecondary,
            size: AppIconSize.button,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: AppTypography.bodyMedium,
                ),
                if (isArchived)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Messages are disabled.',
                      style: AppTypography.labelMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
