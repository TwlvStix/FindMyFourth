import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/backend.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_icon.dart';
import '/models/game.dart';
import 'game_details_card.dart';
import 'host_info_section.dart';

/// Hero card showing game details and host info.
///
/// Handles loading/error states for host data internally.
class HostHeroCard extends StatelessWidget {
  final Game game;
  final bool hasAnimated;

  const HostHeroCard({
    super.key,
    required this.game,
    required this.hasAnimated,
  });

  @override
  Widget build(BuildContext context) {
    final hostRef = game.userRef;

    // Null host reference fallback
    if (hostRef == null) {
      return _buildHostUnavailable();
    }

    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(hostRef),
      builder: (context, hostSnapshot) {
        // Handle error state
        if (hostSnapshot.hasError) {
          AppLog.d('HostHeroCard: Host data error: ${hostSnapshot.error}');
          return _buildHostError();
        }

        // Show loading while waiting for data
        if (!hostSnapshot.hasData) {
          return _buildHostLoading();
        }

        // Render full hero card with host data
        return _buildHeroContent(hostSnapshot.data!);
      },
    );
  }

  Widget _buildHostUnavailable() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
      ),
      child: Center(
        child: Text(
          'Host information unavailable',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.glassTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHostError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.profile,
              color: AppColors.glassTextTertiary,
              size: AppIconSize.xl,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Host information unavailable',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.glassTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostLoading() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
      ),
      child: Center(
        child: SpinKitWanderingCubes(
          color: AppColors.gold,
          size: 30.0,
        ),
      ),
    );
  }

  Widget _buildHeroContent(UsersRecord hostUser) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.4),
            AppColors.navyDark.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [AppElevation.xl],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameDetailsCard(game: game),
          SizedBox(height: AppSpacing.lg),
          HostInfoSection(hostUser: hostUser),
        ],
      ),
    );
  }
}
