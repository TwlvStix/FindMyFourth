import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '../models/create_game_form_data.dart';
import 'create_game_form_sections.dart';
import 'create_game_help_dialog.dart';
import 'game_format_section.dart';

class CreateGameFormatWrapperSection extends StatelessWidget {
  const CreateGameFormatWrapperSection({
    super.key,
    required this.formData,
    required this.updateFormState,
    required this.saveDraft,
    required this.otherGameController,
  });

  final CreateGameFormData formData;
  final FormStateUpdater updateFormState;
  final VoidCallback saveDraft;
  final TextEditingController otherGameController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameFormatSection(
          data: GameFormatData(
            rulesSetValue: formData.rulesSetValue,
            styleGameValue: formData.styleGameValue,
            gameTypeValue: formData.gameTypeValue,
            scoringValue: formData.scoringValue,
            is2v2: formData.is2v2,
            teamStyle: formData.teamStyle,
            selectedGames: formData.selectedGames,
          ),
          onVibeChanged: (val) {
            updateFormState(() {
              formData.rulesSetValue = val;
            });
            saveDraft();
          },
          onStakesChanged: (val) {
            updateFormState(() {
              formData.styleGameValue = val;
            });
            saveDraft();
          },
          onFormatChanged: (val) {
            updateFormState(() {
              formData.gameTypeValue = val;
            });
            saveDraft();
          },
          onHandicapChanged: (val) {
            updateFormState(() {
              formData.scoringValue = val;
            });
            saveDraft();
          },
          onIs2v2Changed: (val) {
            updateFormState(() {
              formData.is2v2 = val;
              if (!val) {
                formData.teamStyle = null;
              }
            });
            saveDraft();
          },
          onTeamStyleChanged: (val) {
            updateFormState(() {
              formData.teamStyle = val;
            });
            saveDraft();
          },
          onGameToggled: (game) {
            updateFormState(() {
              if (formData.selectedGames.contains(game)) {
                formData.selectedGames.remove(game);
                if (game == 'Other') {
                  formData.otherGameText = null;
                  otherGameController.clear();
                }
              } else {
                formData.selectedGames.add(game);
              }
            });
            saveDraft();
          },
          otherGameController: otherGameController,
          onOtherGameChanged: (text) {
            updateFormState(() {
              final trimmed = text.trim();
              formData.otherGameText = trimmed.isEmpty ? null : trimmed;
            });
            saveDraft();
          },
          onShowHelp: (title, body) => showCreateGameHelpDialog(
            context,
            title: title,
            message: body,
          ),
        ),
        if (formData.gameTypeValue != null &&
            formData.scoringValue != null &&
            formData.styleGameValue != null &&
            formData.rulesSetValue != null) ...[
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.navy.withValues(alpha: 0.3),
                    AppColors.navyDark.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Summary',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.glassTextSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    formData.buildGameSummary(),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
