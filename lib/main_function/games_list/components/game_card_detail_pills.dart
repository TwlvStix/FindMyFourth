import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/models/game.dart';

/// Detail pills showing game format, pace, and stakes.
///
/// Displays up to 3 pills with game metadata:
/// - Format: game type (e.g., "18 Holes", "Stroke Play")
/// - Pace: style of play (Fast, Relaxed, etc.)
/// - Stakes: money game indicator or "Fun only"
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
      children: pills.map((pill) => _DetailPill(label: pill)).toList(),
    );
  }

  List<String> _buildPills() {
    final pills = <String>[];

    // Format pill (game type)
    if (game.gameType.isNotEmpty) {
      pills.add(game.gameType);
    }

    // Pace pill (style of game) - skip if it's "Just for Fun" as that's handled by stakes
    if (game.styleGame.isNotEmpty && game.styleGame != 'Just for Fun') {
      // Simplify pace labels
      final pace = _simplifyPace(game.styleGame);
      if (pace != null) {
        pills.add(pace);
      }
    }

    // Stakes pill
    pills.add(_getStakesLabel());

    return pills;
  }

  String? _simplifyPace(String styleGame) {
    switch (styleGame) {
      case 'Money Game':
        return null; // Handled by stakes
      case 'Casual':
        return '\u{1F407} Relaxed'; // rabbit emoji
      case 'Competitive':
        return '\u{1F407} Fast'; // rabbit emoji
      default:
        return styleGame;
    }
  }

  String _getStakesLabel() {
    if (game.isFunGame) {
      return '\u{1F91D} Fun only'; // handshake emoji
    }

    if (game.styleGame == 'Money Game') {
      // Show stakes level based on rules setting
      final rules = game.rulesSetting.toLowerCase();
      if (rules.contains('skins')) {
        return '\u{1F4B0} Skins'; // money bag
      } else if (rules.contains('nassau')) {
        return '\u{1F4B0} Nassau'; // money bag
      } else if (rules.isNotEmpty && rules != 'none') {
        return '\u{1F4B0} ${game.rulesSetting}'; // money bag
      }
      return '\u{1F4B0} Stakes'; // money bag
    }

    return '\u{1F91D} Fun only'; // handshake emoji
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label});

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
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
