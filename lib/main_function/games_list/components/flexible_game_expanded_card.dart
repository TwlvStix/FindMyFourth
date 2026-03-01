import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_expandable_text.dart';
import '/models/player_eligibility.dart';
import '/main_function/games_list/components/flexible_availability_summary.dart';
import '/models/game.dart';
import '/utils/app_util.dart';

/// Full-width expanded card for flexible games in the bottom sheet.
/// Matches PremiumGameCard's compact 3-row layout.
class FlexibleGameExpandedCard extends StatelessWidget {
  const FlexibleGameExpandedCard({
    super.key,
    required this.game,
    required this.currentUserReference,
  });

  final Game game;
  final DocumentReference? currentUserReference;

  @override
  Widget build(BuildContext context) {
    final isOwner =
        currentUserReference != null && game.userRef == currentUserReference;
    final isUserGame = currentUserReference != null &&
        (game.userRef == currentUserReference ||
            game.joinedPlayers.contains(currentUserReference));
    final isCancelled = game.status == 'cancelled';
    final isExpired = game.status == 'expired';

    return GestureDetector(
      onTap: () => _navigateToGame(context, isUserGame),
      child: Opacity(
        opacity: isCancelled ? 0.65 : 1.0,
        child: Container(
          width: double.infinity,
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
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Badges + Status
                _buildTopRow(
                  isOwner: isOwner,
                  isUserGame: isUserGame,
                  isCancelled: isCancelled,
                  isExpired: isExpired,
                ),
                SizedBox(height: AppSpacing.md),
                // Row 2: Course icon + Course name + Game name
                _buildCourseSection(isUserGame: isUserGame),
                SizedBox(height: AppSpacing.md),
                // Row 3: Flexible availability summary
                _buildDateTimeSection(
                  isUserGame: isUserGame,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Row 1: Badge pills + Status badge
  Widget _buildTopRow({
    required bool isOwner,
    required bool isUserGame,
    required bool isCancelled,
    required bool isExpired,
  }) {
    return Row(
      children: [
        // Wrap badges in Flexible to prevent overflow
        Flexible(
          child: Row(
            children: [
              // Game type badge (Just for Fun or gameType)
              if (game.isFunGame)
                Opacity(
                  opacity: isUserGame ? 0.65 : 1.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                      border: Border.all(
                        color: AppColors.navyLight,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'Just for Fun',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else if (game.gameType.isNotEmpty)
                Opacity(
                  opacity: isUserGame ? 0.65 : 1.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                      border: Border.all(
                        color: AppColors.navyLight,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      _formatGameType(game.gameType),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Money Game badge
              if (game.styleGame == 'Money Game') ...[
                SizedBox(width: AppSpacing.xs),
                Opacity(
                  opacity: isUserGame ? 0.65 : 1.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Text(
                      '\$\$\$',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              // Player eligibility badge
              if (game.playerEligibility == PlayerEligibility.womenOnly) ...[
                SizedBox(width: AppSpacing.xs),
                Opacity(
                  opacity: isUserGame ? 0.65 : 1.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Text(
                      'Women Only',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (game.playerEligibility ==
                  PlayerEligibility.menOnly) ...[
                SizedBox(width: AppSpacing.xs),
                Opacity(
                  opacity: isUserGame ? 0.65 : 1.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Text(
                      'Men Only',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              // Member discount badge
              if (game.memberDiscount == 'Yes') ...[
                SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Opacity(
                    opacity: isUserGame ? 0.65 : 1.0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            icon: AppPhosphorIcons.memberDiscount,
                            color: AppColors.green,
                            size: AppIconSize.xs,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Discount',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        // Status badges (always visible, outside Flexible)
        _buildStatusBadge(
          isCancelled: isCancelled,
          isExpired: isExpired,
          isOwner: isOwner,
          isUserGame: isUserGame,
        ),
      ],
    );
  }

  /// Status badge (Owner/Joined/Cancelled/Expired)
  Widget _buildStatusBadge({
    required bool isCancelled,
    required bool isExpired,
    required bool isOwner,
    required bool isUserGame,
  }) {
    if (isCancelled) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'Cancelled',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (isExpired) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Text(
          'Expired',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (isOwner) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.owner,
              color: AppColors.pure,
              size: AppIconSize.xs,
            ),
            SizedBox(width: 4),
            Text(
              'Owner',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (isUserGame) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.stone.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.joined,
              color: AppColors.pure,
              size: AppIconSize.xs,
            ),
            SizedBox(width: 4),
            Text(
              'Joined',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  /// Row 2: Course icon + Course name + Game name
  Widget _buildCourseSection({required bool isUserGame}) {
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
                  text:
                      game.coursePlay.isEmpty ? 'Course TBD' : game.coursePlay,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Row 3: Flexible availability summary
  Widget _buildDateTimeSection({
    required bool isUserGame,
  }) {
    return Opacity(
      opacity: isUserGame ? 0.65 : 1.0,
      child: FlexibleAvailabilitySummary(game: game),
    );
  }

  void _navigateToGame(BuildContext context, bool isUserGame) {
    // Close the bottom sheet first
    Navigator.of(context).pop();

    if (isUserGame) {
      context.pushGameJoinedDetailed(
        gameRef: game.reference,
      );
    } else {
      context.pushJoinGameDetailed(
        gameRef: game.reference,
      );
    }
  }

  String _formatGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'stroke':
        return 'Stroke Play';
      case 'match_play':
        return 'Match Play';
      case 'stableford':
        return 'Stableford';
      case 'scramble':
        return 'Scramble';
      case 'best_ball':
        return 'Best Ball';
      case 'skins':
        return 'Skins';
      default:
        return gameType;
    }
  }
}
