import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/motion/animation_helpers.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_text_field.dart';
import '/models/course.dart';
import '/providers/trust_provider.dart';
import '/providers/user_provider.dart';
import '/services/course_service.dart';
import '/utils/app_util.dart';
import '../models/create_game_form_data.dart';
import 'card_grid.dart';
import 'create_game_help_dialog.dart';
import 'flexible_time_section.dart';
import 'game_format_section.dart';
import 'premium_date_picker.dart';
import 'section_header.dart';
import 'segmented_control.dart';
import 'tee_time_picker.dart';
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
    required this.updateFormState,
    required this.saveDraft,
    required this.submitGame,
    required this.onWeekChanged,
    required this.getFilteredEligibilityOptions,
  });

  final GlobalKey<FormState> formKey;
  final CreateGameFormData formData;
  final TextEditingController gameNameController;
  final TextEditingController otherGameController;
  final FormFieldController<String> courseValueController;
  final CourseService courseService;
  final bool hasAnimated;
  final FormStateUpdater updateFormState;
  final VoidCallback saveDraft;
  final VoidCallback submitGame;
  final void Function(String weekValue) onWeekChanged;
  final EligibilityOptionsResolver getFilteredEligibilityOptions;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.always,
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
                InkWell(
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
            buildAnimatedSection(
              sectionIndex: 4,
              hasAnimated: hasAnimated,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
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
            buildAnimatedSection(
              sectionIndex: 5,
              hasAnimated: hasAnimated,
              child: SectionHeader(
                phosphorIcon: AppPhosphorIcons.course,
                title: 'Course',
              ),
            ),
            Align(
              alignment: AlignmentDirectional(-1.0, 0.0),
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs),
                child: StreamBuilder<List<Course>>(
                  stream: courseService.streamAllCourses(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: SizedBox(
                          width: 50.0,
                          height: 50.0,
                          child: SpinKitWanderingCubes(
                            color: AppColors.gold,
                            size: 50.0,
                          ),
                        ),
                      );
                    }
                    final courses = snapshot.data!;
                    if (courses.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                          border: Border.all(
                            color: AppColors.navyLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            AppIcon(
                              icon: AppPhosphorIcons.golfCourse,
                              size: AppIconSize.xl,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'No courses available',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.glassTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    formData.hydrateSelectedCourse(courses);
                    if (courseValueController.value != formData.courseValue) {
                      courseValueController.value = formData.courseValue;
                    }

                    return AppDropDown<String>(
                      controller: courseValueController,
                      options: courses.map((e) => e.name).toList(),
                      onChanged: (val) {
                        updateFormState(() {
                          formData.courseValue = val;
                        });
                        formData.setSelectedCourse(
                          courses
                              .firstWhereOrNull((course) => course.name == val),
                        );
                        saveDraft();
                      },
                      width: 300.0,
                      height: 50.0,
                      searchHintTextStyle: AppTypography.labelMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      searchTextStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      searchCursorColor: AppColors.green,
                      textStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      hintText: 'Where are you playing?',
                      searchHintText: 'Find your course',
                      icon: AppIcon(
                        icon: AppPhosphorIcons.chevronDown,
                        color: AppColors.textSecondary,
                        size: AppIconSize.md,
                      ),
                      fillColor: AppColors.inputBackground,
                      elevation: 2.0,
                      borderColor: AppColors.inputBorderIdle,
                      borderWidth: 1.0,
                      borderRadius: 10.0,
                      margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
                      hidesUnderline: true,
                      isOverButton: true,
                      isSearchable: true,
                      isMultiSelect: false,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            ToggleSwitch(
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
            ToggleSwitch(
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
            if (!formData.isJustForFun) ...[
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
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: Consumer<TrustProvider>(
                builder: (context, trust, _) {
                  final isRestricted =
                      trust.myStanding?.currentRestriction != null;
                  return AppButtonEnhanced(
                    text: 'Submit Game',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    onPressed: isRestricted ? null : submitGame,
                    enabled: !isRestricted,
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
