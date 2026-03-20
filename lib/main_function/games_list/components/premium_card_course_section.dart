import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_expandable_text.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';
import '/providers/profile_provider.dart';
import '/utils/app_util.dart';

/// Course name section of a [PremiumGameCard]: icon box + course name + game name
/// + optional host label for locked games.
class PremiumCardCourseSection extends StatelessWidget {
  const PremiumCardCourseSection({
    super.key,
    required this.game,
    required this.isUserGame,
    required this.isLocked,
    required this.ownerRef,
  });

  final Game game;
  final bool isUserGame;
  final bool isLocked;
  final DocumentReference? ownerRef;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: AppIcon(
                icon: AppPhosphorIcons.course,
                color: AppColors.textSecondary,
                size: AppIconSize.button,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppExpandableText(
                  text: game.coursePlay.isEmpty
                      ? 'Course TBD'
                      : game.coursePlay,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontStyle: game.coursePlay.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 1,
                ),
                Text(
                  valueOrDefault<String>(game.nameGame, 'Game Name'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isLocked) _LockedGameHostLabel(ownerRef: ownerRef),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display the host label for locked games.
class _LockedGameHostLabel extends StatelessWidget {
  const _LockedGameHostLabel({required this.ownerRef});

  final DocumentReference? ownerRef;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.glassTextSecondary,
      fontWeight: FontWeight.w500,
    );

    if (ownerRef == null) {
      return Text('Host: Unknown', style: style);
    }

    return Selector<ProfileProvider, String?>(
      selector: (context, profileProvider) =>
          profileProvider.getCachedProfile(ownerRef!.id)?.displayName,
      builder: (context, hostName, _) {
        final label = hostName != null && hostName.trim().isNotEmpty
            ? hostName.trim()
            : 'Unknown';
        return Text('Host: $label', style: style);
      },
    );
  }
}
