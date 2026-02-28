import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';

/// Data needed for flexible time selection.
class FlexibleTimeData {
  String flexibleWeek;
  Set<int> selectedDays;
  Set<String> flexibleTimesOfDay;

  FlexibleTimeData({
    required this.flexibleWeek,
    required this.selectedDays,
    required this.flexibleTimesOfDay,
  });
}

/// Section for selecting flexible tee time preferences.
class FlexibleTimeSection extends StatelessWidget {
  final FlexibleTimeData data;
  final ValueChanged<String> onWeekChanged;
  final ValueChanged<Set<int>> onDaysChanged;
  final ValueChanged<Set<String>> onTimesOfDayChanged;

  const FlexibleTimeSection({
    super.key,
    required this.data,
    required this.onWeekChanged,
    required this.onDaysChanged,
    required this.onTimesOfDayChanged,
  });

  TextStyle _labelStyle() => AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      );

  List<int> _getAvailableDays() {
    switch (data.flexibleWeek) {
      case 'this_week':
        final today = DateTime.now().weekday % 7;
        return List.generate(7 - today, (i) => (today + i) % 7);
      case 'this_weekend':
        return [0, 6]; // Sun, Sat
      case 'next_week':
        return [0, 1, 2, 3, 4, 5, 6];
      case 'next_2_weeks':
        return [0, 1, 2, 3, 4, 5, 6];
      default:
        return [0, 1, 2, 3, 4, 5, 6];
    }
  }

  String _buildFlexibleSummary() {
    if (data.flexibleWeek.isEmpty) return 'Select your availability';

    String weekLabel;
    switch (data.flexibleWeek) {
      case 'this_week':
        weekLabel = 'This Week';
        break;
      case 'this_weekend':
        weekLabel = 'This Weekend';
        break;
      case 'next_week':
        weekLabel = 'Next Week';
        break;
      case 'next_2_weeks':
        weekLabel = 'Next 2 Weeks';
        break;
      default:
        weekLabel = data.flexibleWeek;
    }

    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selectedDaysSorted = data.selectedDays.toList()..sort();
    final daysLabel = selectedDaysSorted.isEmpty
        ? ''
        : ' • ${selectedDaysSorted.map((d) => dayNames[d]).join(', ')}';

    String timeLabel = '';
    if (data.flexibleTimesOfDay.contains('anytime')) {
      timeLabel = ' • Anytime';
    } else if (data.flexibleTimesOfDay.isNotEmpty) {
      timeLabel = ' • ${data.flexibleTimesOfDay.map((t) {
        switch (t) {
          case 'morning':
            return 'Morning';
          case 'afternoon':
            return 'Afternoon';
          case 'twilight':
            return 'Twilight';
          default:
            return t;
        }
      }).join(', ')}';
    }

    return '$weekLabel$daysLabel$timeLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.sm),
        _buildInfoBanner(),
        SizedBox(height: AppSpacing.md),
        Text('Week', style: _labelStyle()),
        SizedBox(height: AppSpacing.xs),
        _buildWeekChips(),
        SizedBox(height: AppSpacing.md),
        AnimatedCrossFade(
          duration: MotionTokens.contentReveal,
          crossFadeState: data.flexibleWeek == 'this_weekend'
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Days — tap to exclude', style: _labelStyle()),
              SizedBox(height: AppSpacing.xs),
              _buildDayChips(),
              SizedBox(height: AppSpacing.md),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
        Text('Time of Day', style: _labelStyle()),
        SizedBox(height: AppSpacing.xs),
        _buildTimeOfDayCards(),
        if (_buildFlexibleSummary().isNotEmpty &&
            _buildFlexibleSummary() != 'Select your availability') ...[
          SizedBox(height: AppSpacing.md),
          _buildSummaryBanner(),
        ],
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.info,
            color: AppColors.pure,
            size: AppIconSize.button,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No tee time yet? Pick when you\'re available — lock it in once you have your group.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChips() {
    final weeks = [
      {'value': 'this_week', 'label': 'This Week'},
      {'value': 'this_weekend', 'label': 'This Weekend'},
      {'value': 'next_week', 'label': 'Next Week'},
      {'value': 'next_2_weeks', 'label': 'Next 2 Weeks'},
    ];

    return Row(
      children: weeks.map((week) {
        final isSelected = data.flexibleWeek == week['value'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: week == weeks.last ? 0 : AppSpacing.xs,
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onWeekChanged(week['value'] as String);
              },
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDark : AppColors.navy,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.navyDark
                        : AppColors.greenLight.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  week['label'] as String,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.pure,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayChips() {
    final allDays = [
      {'value': 0, 'label': 'Sun'},
      {'value': 1, 'label': 'Mon'},
      {'value': 2, 'label': 'Tue'},
      {'value': 3, 'label': 'Wed'},
      {'value': 4, 'label': 'Thu'},
      {'value': 5, 'label': 'Fri'},
      {'value': 6, 'label': 'Sat'},
    ];

    final availableDayIndices = _getAvailableDays().toSet();
    final days =
        allDays.where((d) => availableDayIndices.contains(d['value'])).toList();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: days.map((day) {
        final dayIndex = day['value'] as int;
        final isSelected = data.selectedDays.contains(dayIndex);

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final newDays = Set<int>.from(data.selectedDays);
            if (isSelected) {
              newDays.remove(dayIndex);
            } else {
              newDays.add(dayIndex);
            }
            onDaysChanged(newDays);
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.green, AppColors.greenLight],
                    )
                  : null,
              color: isSelected ? null : AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(
                color: isSelected
                    ? AppColors.green
                    : AppColors.greenLight.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              day['label'] as String,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeOfDayCards() {
    final times = [
      {
        'value': 'anytime',
        'label': 'Anytime',
        'icon': AppPhosphorIcons.teeTime,
        'subtitle': 'Any Time'
      },
      {
        'value': 'morning',
        'label': 'Morning',
        'icon': AppPhosphorIcons.morning,
        'subtitle': 'Before 11am'
      },
      {
        'value': 'afternoon',
        'label': 'Afternoon',
        'icon': AppPhosphorIcons.afternoon,
        'subtitle': '11am-3pm'
      },
      {
        'value': 'twilight',
        'label': 'Twilight',
        'icon': AppPhosphorIcons.twilight,
        'subtitle': 'After 3pm'
      },
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.xs,
      mainAxisSpacing: AppSpacing.xs,
      childAspectRatio: 0.75,
      padding: EdgeInsets.zero,
      children: times.map((time) {
        final value = time['value'] as String;
        final isSelected = data.flexibleTimesOfDay.contains(value);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final newTimes = Set<String>.from(data.flexibleTimesOfDay);
            if (value == 'anytime') {
              newTimes.clear();
              newTimes.add('anytime');
            } else {
              if (isSelected) {
                newTimes.remove(value);
                if (newTimes.isEmpty ||
                    (newTimes.length == 1 && newTimes.contains('anytime'))) {
                  newTimes.clear();
                  newTimes.add('anytime');
                }
              } else {
                newTimes.remove('anytime');
                newTimes.add(value);
                if (newTimes.containsAll({'morning', 'afternoon', 'twilight'})) {
                  newTimes.clear();
                  newTimes.add('anytime');
                }
              }
            }
            onTimesOfDayChanged(newTimes);
          },
          child: Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.navy.withValues(alpha: 0.5),
                        AppColors.navyDark.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: isSelected ? null : AppColors.navy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.glassSurface,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  icon: time['icon'] as PhosphorIconData,
                  size: AppIconSize.md,
                  color: AppColors.pure,
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  time['label'] as String,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 1),
                Text(
                  time['subtitle'] as String,
                  style: AppTypography.labelMicro.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.glassTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyLight, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.calendarNote,
            color: AppColors.pure,
            size: AppIconSize.button,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _buildFlexibleSummary(),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
