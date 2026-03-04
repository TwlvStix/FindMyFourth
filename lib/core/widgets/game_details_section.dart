import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/models/game.dart';
import '/models/player_eligibility.dart';
import '../design_tokens/app_phosphor_icons.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/icon_size.dart';
import '../design_tokens/spacing.dart';
import '../design_tokens/typography.dart';
import 'app_detail_row.dart';

/// A shared widget for displaying game details in both joined and join game screens.
///
/// Renders two different layouts based on whether the game is "Just for Fun" or competitive:
/// - Just for Fun: Hero row + visibility + optional eligibility + hint
/// - Competitive: All detail rows (betting, rules, game type, scoring, discount, visibility)
///   + optional eligibility row. Empty values are hidden.
class GameDetailsSection extends StatelessWidget {
  const GameDetailsSection({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  Widget build(BuildContext context) {
    if (game.isFunGame) {
      return _buildJustForFunLayout();
    } else {
      return _buildCompetitiveLayout();
    }
  }

  Widget _buildJustForFunLayout() {
    final isFriendsOnly = game.friendGame.toLowerCase() == 'yes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main card
        Container(
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.3),
            border: Border.all(color: AppColors.navyLight.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero row
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Icon container - boosted alpha for visibility
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          AppPhosphorIcons.funGame,
                          size: AppIconSize.md,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Just for Fun',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.info,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'No stakes · No stress · Just golf',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                height: 1,
                color: AppColors.navyLight.withValues(alpha: 0.3),
              ),
              // Visibility row
              AppDetailRow(
                icon: isFriendsOnly ? AppPhosphorIcons.friendsOnly : AppPhosphorIcons.visibility,
                label: 'Visibility',
                value: isFriendsOnly ? 'Friends Only' : 'Public',
                showDivider: true,
              ),
              // Eligibility row
              AppDetailRow(
                icon: AppPhosphorIcons.golfers,
                label: 'Who Can Join',
                value: switch (game.playerEligibility) {
                  PlayerEligibility.womenOnly => 'Women Only',
                  PlayerEligibility.menOnly => 'Men Only',
                  PlayerEligibility.openToAll => 'Everyone',
                },
                showDivider: false,
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        // Hint below card
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.lightbulb,
                size: AppIconSize.sm,
                color: AppColors.textMuted,
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'No betting, no formats, no scores tracked. Just a casual round — play your own game.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitiveLayout() {
    final isFriendsOnly = game.friendGame.toLowerCase() == 'yes';

    // Build list of rows, filtering out empty values
    final rows = <_DetailRowData>[];

    // Betting - only show STAKES tag when there's actual money involved
    if (game.styleGame.isNotEmpty) {
      final hasActualStakes = !game.styleGame.toLowerCase().contains('no money');
      rows.add(_DetailRowData(
        icon: AppPhosphorIcons.betting,
        label: 'Betting',
        value: game.styleGame,
        valueColor: hasActualStakes ? AppColors.gold : null,
        tag: hasActualStakes ? 'Stakes' : null,
        tagColor: hasActualStakes ? AppColors.gold : null,
        tagBgColor: hasActualStakes ? AppColors.gold.withValues(alpha: 0.12) : null,
      ));
    }

    // Rule Style
    if (game.rulesSetting.isNotEmpty) {
      rows.add(_DetailRowData(
        icon: AppPhosphorIcons.ruleStyle,
        label: 'Rule Style',
        value: game.rulesSetting,
      ));
    }

    // Game Type
    if (game.gameType.isNotEmpty) {
      rows.add(_DetailRowData(
        icon: AppPhosphorIcons.gameType,
        label: 'Game Type',
        value: game.gameType,
      ));
    }

    // Scoring
    if (game.scoring.isNotEmpty) {
      rows.add(_DetailRowData(
        icon: AppPhosphorIcons.scoring,
        label: 'Scoring',
        value: game.scoring,
      ));
    }

    // Member Discount - use brighter green for better contrast
    if (game.memberDiscount.isNotEmpty) {
      rows.add(_DetailRowData(
        icon: AppPhosphorIcons.memberDiscount,
        label: 'Member Discount',
        value: game.memberDiscount,
        valueColor: AppColors.successHovered,
        tag: 'Savings',
        tagColor: AppColors.successHovered,
        tagBgColor: AppColors.successHovered.withValues(alpha: 0.18),
      ));
    }

    // Visibility (always shown)
    rows.add(_DetailRowData(
      icon: isFriendsOnly ? AppPhosphorIcons.friendsOnly : AppPhosphorIcons.visibility,
      label: 'Visibility',
      value: isFriendsOnly ? 'Friends Only' : 'Public',
    ));

    // Eligibility
    rows.add(_DetailRowData(
      icon: AppPhosphorIcons.golfers,
      label: 'Who Can Join',
      value: switch (game.playerEligibility) {
        PlayerEligibility.womenOnly => 'Women Only',
        PlayerEligibility.menOnly => 'Men Only',
        PlayerEligibility.openToAll => 'Everyone',
      },
    ));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.3),
        border: Border.all(color: AppColors.navyLight.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < rows.length; i++)
            AppDetailRow(
              icon: rows[i].icon,
              label: rows[i].label,
              value: rows[i].value,
              valueColor: rows[i].valueColor,
              tag: rows[i].tag,
              tagColor: rows[i].tagColor,
              tagBgColor: rows[i].tagBgColor,
              showDivider: i < rows.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Internal data class for competitive row configuration.
class _DetailRowData {
  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.tag,
    this.tagColor,
    this.tagBgColor,
  });

  final PhosphorIconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? tag;
  final Color? tagColor;
  final Color? tagBgColor;
}
