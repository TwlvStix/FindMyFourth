import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/form_field_controller.dart';
import '/core/motion/animation_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_text_field.dart';
import '/providers/trust_provider.dart';
import '/services/course_service.dart';
import '/utils/app_util.dart';
import '../models/create_game_form_data.dart';
import 'create_game_access_section.dart';
import 'create_game_course_section.dart';
import 'create_game_format_wrapper_section.dart';
import 'create_game_help_dialog.dart';
import 'create_game_schedule_section.dart';
import 'section_header.dart';
import 'toggle_switch.dart';

typedef FormStateUpdater = void Function(VoidCallback mutation);
typedef EligibilityOptionsResolver = List<Map<String, dynamic>> Function(
  String? userGender,
);

class CreateGameFormSections extends StatelessWidget {
  const CreateGameFormSections({
    super.key,
    required this.formKey,
    required this.formData,
    required this.gameNameController,
    required this.otherGameController,
    required this.courseValueController,
    required this.courseService,
    required this.hasAnimated,
    this.isSubmitting = false,
    required this.updateFormState,
    required this.saveDraft,
    required this.submitGame,
    required this.onWeekChanged,
    required this.getFilteredEligibilityOptions,
    this.courseStreamKey,
    this.onCourseRetry,
  });

  final GlobalKey<FormState> formKey;
  final CreateGameFormData formData;
  final TextEditingController gameNameController;
  final TextEditingController otherGameController;
  final FormFieldController<String> courseValueController;
  final CourseService courseService;
  final bool hasAnimated;
  final bool isSubmitting;
  final FormStateUpdater updateFormState;
  final VoidCallback saveDraft;
  final VoidCallback submitGame;
  final void Function(String weekValue) onWeekChanged;
  final EligibilityOptionsResolver getFilteredEligibilityOptions;
  final Key? courseStreamKey;
  final VoidCallback? onCourseRetry;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildAnimatedSection(
              sectionIndex: 0,
              hasAnimated: hasAnimated,
              child: SectionHeader(
                phosphorIcon: AppPhosphorIcons.games,
                title: 'Game Name',
                helpText:
                    'Auto-generated for you. Edit here if you want a custom name.',
                onHelpTap: () => showCreateGameHelpDialog(
                  context,
                  title: 'Game Name',
                  message:
                      'Auto-generated for you. Edit here if you want a custom name.',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxs),
              child: AppTextField(
                label: 'Game name',
                hint: 'Auto-generated',
                controller: gameNameController,
                variant: AppTextFieldVariant.filledDark,
                prefixPhosphorIcon: AppPhosphorIcons.label,
                onChanged: (_) => saveDraft(),
              ),
            ),
            CreateGameScheduleSection(
              formData: formData,
              hasAnimated: hasAnimated,
              updateFormState: updateFormState,
              saveDraft: saveDraft,
              onWeekChanged: onWeekChanged,
            ),
            CreateGameAccessSection(
              formData: formData,
              hasAnimated: hasAnimated,
              updateFormState: updateFormState,
              saveDraft: saveDraft,
              getFilteredEligibilityOptions: getFilteredEligibilityOptions,
            ),
            buildAnimatedSection(
              sectionIndex: 4,
              hasAnimated: hasAnimated,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Semantics(
                  toggled: formData.requireVibeMatch,
                  label: 'Require vibe match',
                  child: ToggleSwitch(
                    label: 'Require vibe match',
                    description:
                        'Players with a different play style will need your approval',
                    value: formData.requireVibeMatch,
                    onChanged: (val) {
                      updateFormState(() {
                        formData.requireVibeMatch = val;
                      });
                      saveDraft();
                    },
                  ),
                ),
              ),
            ),
            CreateGameCourseSection(
              formData: formData,
              courseService: courseService,
              courseValueController: courseValueController,
              hasAnimated: hasAnimated,
              updateFormState: updateFormState,
              saveDraft: saveDraft,
              courseStreamKey: courseStreamKey,
              onCourseRetry: onCourseRetry,
            ),
            SizedBox(height: AppSpacing.md),
            Semantics(
              toggled: formData.memberDiscount,
              label: 'Member guest rate',
              child: ToggleSwitch(
                label: 'Member Guest Rate',
                description:
                    'This game is created by a course member who can offer guest-rate pricing.',
                value: formData.memberDiscount,
                onChanged: (val) {
                  updateFormState(() {
                    formData.memberDiscount = val;
                    formData.memberValue = val ? 'Yes' : 'No';
                  });
                  saveDraft();
                },
              ),
            ),
            Semantics(
              toggled: formData.isJustForFun,
              label: 'Just for fun',
              child: ToggleSwitch(
                label: 'Just for Fun',
                description: 'Skip all the details. Just show up and play.',
                value: formData.isJustForFun,
                onChanged: (val) {
                  updateFormState(() {
                    formData.isJustForFun = val;
                  });
                  saveDraft();
                },
              ),
            ),
            if (!formData.isJustForFun)
              CreateGameFormatWrapperSection(
                formData: formData,
                updateFormState: updateFormState,
                saveDraft: saveDraft,
                otherGameController: otherGameController,
              ),
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: Consumer<TrustProvider>(
                builder: (context, trust, _) {
                  final isRestricted =
                      trust.myStanding?.currentRestriction != null;
                  return Semantics(
                    button: true,
                    label: isSubmitting ? 'Submitting game' : 'Submit game',
                    child: AppButtonEnhanced(
                      text: 'Submit Game',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      onPressed: isRestricted || isSubmitting ? null : submitGame,
                      enabled: !isRestricted && !isSubmitting,
                      isLoading: isSubmitting,
                    ),
                  );
                },
              ),
            ),
          ]
              .divide(SizedBox(height: AppSpacing.xs))
              .addToStart(SizedBox(height: AppSpacing.xs))
              .addToEnd(SizedBox(height: AppSpacing.xs)),
        ),
      ),
    );
  }
}
