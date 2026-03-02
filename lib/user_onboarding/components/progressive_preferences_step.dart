import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import 'preference_control.dart';

/// Data contract for PreferencesStep props.
class PreferencesStepData {
  const PreferencesStepData({
    required this.musicValue,
    required this.drinksValue,
    required this.playMoneyValue,
    required this.paceValue,
    required this.onMusicChanged,
    required this.onDrinksChanged,
    required this.onPlayMoneyChanged,
    required this.onPaceChanged,
  });

  final int musicValue;
  final int drinksValue;
  final int playMoneyValue;
  final int paceValue;
  final ValueChanged<int> onMusicChanged;
  final ValueChanged<int> onDrinksChanged;
  final ValueChanged<int> onPlayMoneyChanged;
  final ValueChanged<int> onPaceChanged;
}

/// Preferences step of progressive onboarding.
///
/// Collects play style preferences (music, drinks, betting, pace).
class ProgressivePreferencesStep extends StatelessWidget {
  const ProgressivePreferencesStep({
    super.key,
    required this.data,
  });

  final PreferencesStepData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your play style',
            style: AppTypography.headlineMediumSans.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.0,
            ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.xs),
            child: Text(
              'Rate your preferences from 0 (not at all) to 5 (very much).',
              style: AppTypography.bodyMedium,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          PreferenceControl(
            title: 'Music on the course',
            icon: AppPhosphorIcons.music,
            value: data.musicValue,
            onUpdate: data.onMusicChanged,
          ),
          SizedBox(height: AppSpacing.lg),
          PreferenceControl(
            title: 'Drinks while playing',
            icon: AppPhosphorIcons.drinks,
            value: data.drinksValue,
            onUpdate: data.onDrinksChanged,
          ),
          SizedBox(height: AppSpacing.lg),
          PreferenceControl(
            title: 'Play for money',
            icon: AppPhosphorIcons.betting,
            value: data.playMoneyValue,
            onUpdate: data.onPlayMoneyChanged,
          ),
          SizedBox(height: AppSpacing.lg),
          PreferenceControl(
            title: 'Pace of play',
            icon: AppPhosphorIcons.pace,
            value: data.paceValue,
            onUpdate: data.onPaceChanged,
          ),
        ],
      ),
    );
  }
}
