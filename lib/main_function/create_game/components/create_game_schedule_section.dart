import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/animation_helpers.dart';
import '/core/widgets/app_icon.dart';
import '/utils/app_util.dart';
import '../models/create_game_form_data.dart';
import 'create_game_form_sections.dart';
import 'create_game_help_dialog.dart';
import 'flexible_time_section.dart';
import 'premium_date_picker.dart';
import 'section_header.dart';
import 'segmented_control.dart';
import 'tee_time_picker.dart';

class CreateGameScheduleSection extends StatelessWidget {
  const CreateGameScheduleSection({
    super.key,
    required this.formData,
    required this.hasAnimated,
    required this.updateFormState,
    required this.saveDraft,
    required this.onWeekChanged,
  });

  final CreateGameFormData formData;
  final bool hasAnimated;
  final FormStateUpdater updateFormState;
  final VoidCallback saveDraft;
  final void Function(String) onWeekChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAnimatedSection(
          sectionIndex: 1,
          hasAnimated: hasAnimated,
          child: SectionHeader(
            phosphorIcon: AppPhosphorIcons.calendarCheck,
            title: 'Schedule',
            helpText:
                'Choose if you have a confirmed tee time or flexible availability.',
            onHelpTap: () => showCreateGameHelpDialog(
              context,
              title: 'Schedule',
              message:
                  'Choose if you have a confirmed tee time or flexible availability.',
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxs),
          child: Semantics(
            label: 'Schedule type: ${formData.scheduleType == 'confirmed' ? 'I have a tee time' : 'Flexible time'}',
            child: SegmentedControl(
              options: [
                {
                  'value': 'confirmed',
                  'label': 'I Have a Tee Time',
                  'phosphorIcon': AppPhosphorIcons.calendarCheck,
                },
                {
                  'value': 'flexible',
                  'label': 'Flexible Time',
                  'phosphorIcon': AppPhosphorIcons.calendarNote,
                },
              ],
              selectedValue: formData.scheduleType,
              onChanged: (val) {
                updateFormState(() {
                  formData.scheduleType = val;
                  if (val == 'flexible') {
                    formData.datePicked = null;
                  } else {
                    formData.flexibleWeek = null;
                    formData.selectedDays.clear();
                    formData.flexibleTimesOfDay = {'anytime'};
                  }
                });
                saveDraft();
              },
            ),
          ),
        ),
        if (formData.scheduleType == 'confirmed') ...[
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: PremiumDatePicker(
              selectedDate: formData.datePicked,
              onDateSelected: (date) {
                updateFormState(() {
                  formData.datePicked = date;
                });
                saveDraft();
              },
            ),
          ),
          if (formData.datePicked != null) ...[
            SizedBox(height: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Tee time: ${dateTimeFormat('jm', formData.datePicked)}, tap to change',
              child: InkWell(
                onTap: () {
                  showTeeTimePicker(
                    context: context,
                    selectedDateTime: formData.datePicked,
                    onTimeSelected: (dateTime) {
                      updateFormState(() {
                        formData.datePicked = dateTime;
                      });
                      saveDraft();
                    },
                  );
                },
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: AppColors.greenLight.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        icon: AppPhosphorIcons.teeTime,
                        color: AppColors.pure,
                        size: AppIconSize.button,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          dateTimeFormat('jm', formData.datePicked),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.pure,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppIcon(
                        icon: AppPhosphorIcons.edit,
                        color: AppColors.textSecondary,
                        size: AppIconSize.sm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (formData.datePicked != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyLight, AppColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.golfCourse,
                    color: AppColors.pure,
                    size: AppIconSize.button,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${dateTimeFormat('EEEE, MMM d', formData.datePicked)} at ${dateTimeFormat('jm', formData.datePicked)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          FlexibleTimeSection(
            data: FlexibleTimeData(
              flexibleWeek: formData.flexibleWeek ?? 'this_week',
              selectedDays: formData.selectedDays,
              flexibleTimesOfDay: formData.flexibleTimesOfDay,
            ),
            onWeekChanged: onWeekChanged,
            onDaysChanged: (days) {
              updateFormState(() {
                formData.selectedDays = days;
              });
              saveDraft();
            },
            onTimesOfDayChanged: (times) {
              updateFormState(() {
                formData.flexibleTimesOfDay = times;
              });
              saveDraft();
            },
          ),
        ],
      ],
    );
  }
}
