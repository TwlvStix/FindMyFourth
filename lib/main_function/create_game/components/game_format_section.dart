import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '../create_game_constants.dart';
import 'card_grid.dart';
import 'section_header.dart';
import 'toggle_switch.dart';
import 'games_multi_select.dart';

/// Data for game format configuration.
class GameFormatData {
  final String? rulesSetValue;
  final String? styleGameValue;
  final String? gameTypeValue;
  final String? scoringValue;
  final bool is2v2;
  final String? teamStyle;
  final Set<String> selectedGames;

  const GameFormatData({
    this.rulesSetValue,
    this.styleGameValue,
    this.gameTypeValue,
    this.scoringValue,
    this.is2v2 = false,
    this.teamStyle,
    this.selectedGames = const {},
  });
}

/// Callback types for format changes.
typedef FormatValueChanged = void Function(String? value);
typedef FormatBoolChanged = void Function(bool value);

/// Section for game format configuration (vibe, stakes, format, handicap, games).
class GameFormatSection extends StatelessWidget {
  final GameFormatData data;
  final FormatValueChanged onVibeChanged;
  final FormatValueChanged onStakesChanged;
  final FormatValueChanged onFormatChanged;
  final FormatValueChanged onHandicapChanged;
  final FormatBoolChanged onIs2v2Changed;
  final FormatValueChanged onTeamStyleChanged;
  final void Function(String game) onGameToggled;
  final TextEditingController otherGameController;
  final void Function(String value) onOtherGameChanged;
  final void Function(String title, String body)? onShowHelp;

  const GameFormatSection({
    super.key,
    required this.data,
    required this.onVibeChanged,
    required this.onStakesChanged,
    required this.onFormatChanged,
    required this.onHandicapChanged,
    required this.onIs2v2Changed,
    required this.onTeamStyleChanged,
    required this.onGameToggled,
    required this.otherGameController,
    required this.onOtherGameChanged,
    this.onShowHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game Vibe
        SectionHeader(
          phosphorIcon: AppPhosphorIcons.competitive,
          title: 'Game Vibe',
          helpText:
              'Set the tone for your round. Competitive focuses on rules and pace, while Casual keeps it relaxed and friendly.',
          onHelpTap: onShowHelp != null
              ? () => onShowHelp!(
                    'Game Vibe',
                    'Set the tone for your round. Competitive focuses on rules and pace, while Casual keeps it relaxed and friendly.',
                  )
              : null,
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: CardGrid(
            options: kCreateGameVibeOptions,
            selectedValue: data.rulesSetValue,
            onChanged: onVibeChanged,
            crossAxisCount: 2,
            childAspectRatio: 1.2,
          ),
        ),

        // Stakes
        SectionHeader(
          phosphorIcon: AppPhosphorIcons.betting,
          title: 'Stakes',
          helpText:
              'Playing for money or keeping it friendly? Choose your comfort level.',
          onHelpTap: onShowHelp != null
              ? () => onShowHelp!(
                    'Stakes',
                    'Playing for money or keeping it friendly? Choose your comfort level.',
                  )
              : null,
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: CardGrid(
            options: kCreateGameStakesOptions,
            selectedValue: data.styleGameValue,
            onChanged: onStakesChanged,
            crossAxisCount: 3,
            childAspectRatio: 0.95,
          ),
        ),

        // Primary Format
        SectionHeader(
          phosphorIcon: AppPhosphorIcons.gameType,
          title: 'Primary Format',
          helpText:
              'Choose your core scoring format: Match Play (hole-by-hole), Stroke Play (total strokes), Stableford (points).',
          onHelpTap: onShowHelp != null
              ? () => onShowHelp!(
                    'Primary Format',
                    'Choose your core scoring format: Match Play (hole-by-hole), Stroke Play (total strokes), Stableford (points).',
                  )
              : null,
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: CardGrid(
            options: kCreateGamePrimaryFormatOptions,
            selectedValue: data.gameTypeValue,
            onChanged: onFormatChanged,
            crossAxisCount: 3,
            childAspectRatio: 0.95,
          ),
        ),

        SizedBox(height: AppSpacing.md),

        // 2v2 Toggle
        ToggleSwitch(
          label: '2v2 (Teams)',
          description: 'Enable team play mode',
          value: data.is2v2,
          onChanged: onIs2v2Changed,
        ),

        // Team Style (conditional)
        if (data.is2v2) ...[
          SizedBox(height: AppSpacing.sm),
          SectionHeader(
            phosphorIcon: AppPhosphorIcons.teams,
            title: 'Team Style',
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxs),
            child: CardGrid(
              options: const [
                {
                  'value': 'Best Ball',
                  'label': 'Best Ball',
                  'phosphorIcon': AppPhosphorIcons.bestBall
                },
                {
                  'value': 'Scramble',
                  'label': 'Scramble',
                  'phosphorIcon': AppPhosphorIcons.groups
                },
              ],
              selectedValue: data.teamStyle,
              onChanged: onTeamStyleChanged,
              crossAxisCount: 2,
              childAspectRatio: 1.2,
            ),
          ),
        ],

        // Handicap Use
        SectionHeader(
          phosphorIcon: AppPhosphorIcons.handicap,
          title: 'Handicap Use',
          helpText:
              'Gross is total strokes. Net adjusts for handicap. Gross + Net tracks both scores.',
          onHelpTap: onShowHelp != null
              ? () => onShowHelp!(
                    'Handicap Use',
                    'Gross is total strokes. Net adjusts for handicap. Gross + Net tracks both scores.',
                  )
              : null,
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: CardGrid(
            options: kCreateGameHandicapOptions,
            selectedValue: data.scoringValue,
            onChanged: onHandicapChanged,
            crossAxisCount: 3,
            childAspectRatio: 0.95,
          ),
        ),

        // Games (Optional)
        SectionHeader(
          phosphorIcon: AppPhosphorIcons.dots,
          title: 'Games (Optional)',
          helpText:
              'Add up to 3 side games to your round. These are played alongside your primary format.',
          onHelpTap: onShowHelp != null
              ? () => onShowHelp!(
                    'Games',
                    'Add up to 3 side games to your round. These are played alongside your primary format.',
                  )
              : null,
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: GamesMultiSelect(
            selectedGames: data.selectedGames,
            onGameToggled: onGameToggled,
            otherGameController: otherGameController,
            onOtherGameChanged: onOtherGameChanged,
          ),
        ),
      ],
    );
  }
}
