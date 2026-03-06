import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/game.dart';

/// Detail pills showing game attributes with icons.
///
/// Fun games: Show only "Fun only" pill.
/// Regular games: Up to 2 pills - Primary Format, Stakes.
class GameCardDetailPills extends StatelessWidget {
  const GameCardDetailPills({
    super.key,
    required this.game,
  });

  final Game game;

  @override
  Widget build(BuildContext context) {
    final pills = _buildPills();
    if (pills.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: pills
          .map((pill) => _DetailPill(icon: pill.icon, label: pill.label))
          .toList(),
    );
  }

  List<_PillData> _buildPills() {
    // Fun game = only show "Fun only" pill
    if (game.isFunGame) {
      return [_PillData(AppPhosphorIcons.funGame, 'Fun only')];
    }

    // Regular game = up to 2 pills
    final pills = <_PillData>[];

    // 1. Primary Format
    if (game.gameType.isNotEmpty) {
      final icon = _getFormatIcon(game.gameType);
      pills.add(_PillData(icon, game.gameType));
    }

    // 2. Stakes
    if (game.styleGame.isNotEmpty && game.styleGame != 'No Money') {
      final icon = game.styleGame == 'High Stakes'
          ? AppPhosphorIcons.highStakes
          : AppPhosphorIcons.lowStakes;
      pills.add(_PillData(icon, game.styleGame));
    }

    return pills;
  }

  PhosphorIconData _getFormatIcon(String gameType) {
    switch (gameType) {
      case 'Match Play':
        return AppPhosphorIcons.matchPlay;
      case 'Stableford':
        return AppPhosphorIcons.stableford;
      default:
        return AppPhosphorIcons.strokePlay;
    }
  }
}

/// Data class holding icon and label for a pill.
class _PillData {
  final PhosphorIconData icon;
  final String label;
  const _PillData(this.icon, this.label);
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final PhosphorIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppBorderRadius.chip),
        border: Border.all(
          color: AppColors.navyLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            icon,
            size: AppIconSize.xs,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
