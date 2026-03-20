import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/animation_helpers.dart';
import '/providers/user_provider.dart';
import '../models/create_game_form_data.dart';
import 'card_grid.dart';
import 'create_game_form_sections.dart';
import 'create_game_help_dialog.dart';
import 'section_header.dart';
import 'segmented_control.dart';

class CreateGameAccessSection extends StatelessWidget {
  const CreateGameAccessSection({
    super.key,
    required this.formData,
    required this.hasAnimated,
    required this.updateFormState,
    required this.saveDraft,
    required this.getFilteredEligibilityOptions,
  });

  final CreateGameFormData formData;
  final bool hasAnimated;
  final FormStateUpdater updateFormState;
  final VoidCallback saveDraft;
  final EligibilityOptionsResolver getFilteredEligibilityOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAnimatedSection(
          sectionIndex: 2,
          hasAnimated: hasAnimated,
          child: SectionHeader(
            phosphorIcon: AppPhosphorIcons.publicVisibility,
            title: 'Visibility',
            helpText:
                'Choose whether your game is visible to friends only or everyone in your area.',
            onHelpTap: () => showCreateGameHelpDialog(
              context,
              title: 'Visibility',
              message:
                  'Choose whether your game is visible to friends only or everyone in your area.',
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: Semantics(
            label: 'Visibility: ${formData.friendsValue}',
            child: SegmentedControl(
              options: [
                {
                  'value': 'Friends',
                  'label': 'Friends',
                  'phosphorIcon': AppPhosphorIcons.people,
                },
                {
                  'value': 'Public',
                  'label': 'Public',
                  'phosphorIcon': AppPhosphorIcons.publicVisibility,
                },
              ],
              selectedValue: formData.friendsValue,
              onChanged: (val) {
                updateFormState(() {
                  formData.friendsValue = val;
                });
                saveDraft();
              },
            ),
          ),
        ),
        buildAnimatedSection(
          sectionIndex: 3,
          hasAnimated: hasAnimated,
          child: SectionHeader(
            phosphorIcon: AppPhosphorIcons.openToAll,
            title: 'Who Can Join',
            helpText: 'Choose who can join your game based on gender.',
            onHelpTap: () => showCreateGameHelpDialog(
              context,
              title: 'Who Can Join',
              message:
                  'Choose who can join your game. \'Women Only\' and \'Men Only\' restrict joining based on the gender in each player\'s profile.',
            ),
          ),
        ),
        Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final filteredOptions = getFilteredEligibilityOptions(
              userProvider.currentUser?.gender,
            );
            return Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxs),
              child: CardGrid(
                options: filteredOptions,
                selectedValue: formData.playerEligibility,
                onChanged: (val) {
                  updateFormState(() {
                    formData.playerEligibility = val;
                  });
                  saveDraft();
                },
                crossAxisCount: filteredOptions.length,
                childAspectRatio: 1.2,
              ),
            );
          },
        ),
      ],
    );
  }
}
