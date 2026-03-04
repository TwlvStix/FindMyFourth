import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/streak/streak_chip.dart';
import '/core/widgets/streak/streak_profile_section.dart';
import '/models/streak_profile.dart';

/// Debug screen for previewing streak UI components with mock data.
///
/// Allows manipulation of all StreakProfile fields via sliders and toggles
/// to see how the UI responds without touching Firestore.
class StreakDebugScreen extends StatefulWidget {
  const StreakDebugScreen({super.key});

  static const routeName = 'StreakDebug';
  static const routePath = '/debug/streak';

  @override
  State<StreakDebugScreen> createState() => _StreakDebugScreenState();
}

class _StreakDebugScreenState extends State<StreakDebugScreen> {
  // Control values
  int _currentWeeks = 8;
  bool _hasPreviousWeeks = false;
  int _previousWeeks = 4;
  int _longestWeeks = 12;
  bool _freezeEarned = true;
  bool _freezeUsed = false;
  bool _hasPendingWeeks = false;
  int _milestoneLevel = 8;

  StreakProfile get _mockProfile => StreakProfile(
        currentWeeks: _currentWeeks,
        previousWeeks: _hasPreviousWeeks ? _previousWeeks : null,
        longestWeeks: _longestWeeks,
        seasonId: '2026',
        weeksPlayed: List.generate(_currentWeeks, (i) => '2026-0${5 + i ~/ 4}-0${1 + (i % 4) * 7}'),
        weeksPending: _hasPendingWeeks ? ['2026-03-03'] : [],
        lastCompletedWeekKey: _currentWeeks > 0 ? '2026-02-24' : null,
        freezeEarned: _freezeEarned,
        freezeUsed: _freezeUsed,
        freezeUsedWeekKey: _freezeUsed ? '2026-02-17' : null,
        milestoneLevel: _milestoneLevel,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        title: Text(
          'Streak UI Preview',
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          _buildControlsCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildPreviewSection(),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Current Weeks
          _buildSliderControl(
            label: 'Current Weeks',
            value: _currentWeeks,
            min: 0,
            max: 30,
            tierLabel: _mockProfile.visualTier.label,
            onChanged: (v) => setState(() => _currentWeeks = v.round()),
          ),

          // Previous Weeks (with toggle)
          _buildToggleSliderControl(
            label: 'Previous Weeks',
            enabled: _hasPreviousWeeks,
            value: _previousWeeks,
            min: 1,
            max: 30,
            onToggle: (v) => setState(() => _hasPreviousWeeks = v),
            onChanged: (v) => setState(() => _previousWeeks = v.round()),
          ),

          // Longest Weeks
          _buildSliderControl(
            label: 'Longest Weeks',
            value: _longestWeeks,
            min: 0,
            max: 30,
            onChanged: (v) => setState(() => _longestWeeks = v.round()),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Freeze toggles
          Row(
            children: [
              Expanded(
                child: _buildToggle(
                  label: 'Freeze Earned',
                  value: _freezeEarned,
                  onChanged: (v) => setState(() => _freezeEarned = v),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildToggle(
                  label: 'Freeze Used',
                  value: _freezeUsed,
                  onChanged: (v) => setState(() => _freezeUsed = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Pending weeks toggle
          _buildToggle(
            label: 'Has Pending Weeks',
            value: _hasPendingWeeks,
            onChanged: (v) => setState(() => _hasPendingWeeks = v),
          ),

          const SizedBox(height: AppSpacing.md),

          // Milestone segmented control
          _buildMilestoneSelector(),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required int value,
    required int min,
    required int max,
    String? tierLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: AppTypography.monoMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (tierLabel != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '($tierLabel)',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.green,
                  ),
                ),
              ],
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.green,
              inactiveTrackColor: AppColors.navyLight,
              thumbColor: AppColors.green,
              overlayColor: AppColors.green.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSliderControl({
    required String label,
    required bool enabled,
    required int value,
    required int min,
    required int max,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: enabled ? AppColors.textSecondary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeTrackColor: AppColors.green,
                activeThumbColor: AppColors.pure,
              ),
              const Spacer(),
              if (enabled)
                Text(
                  '$value',
                  style: AppTypography.monoMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          if (enabled)
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.green,
                inactiveTrackColor: AppColors.navyLight,
                thumbColor: AppColors.green,
                overlayColor: AppColors.green.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: value
              ? AppColors.green.withValues(alpha: 0.1)
              : AppColors.navyLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: value ? AppColors.green : AppColors.navyLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value
                  ? PhosphorIconsRegular.checkSquare
                  : PhosphorIconsRegular.square,
              color: value ? AppColors.green : AppColors.textMuted,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: value ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneSelector() {
    const milestones = [0, 4, 8, 13, 26];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Milestone Level',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: milestones.map((m) {
            final selected = _milestoneLevel == m;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _milestoneLevel = m),
                child: Container(
                  margin: EdgeInsets.only(
                    right: m != 26 ? AppSpacing.xxs : 0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.green.withValues(alpha: 0.15)
                        : AppColors.navyLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    border: Border.all(
                      color: selected ? AppColors.green : AppColors.navyLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$m',
                      style: AppTypography.labelMedium.copyWith(
                        color: selected ? AppColors.green : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final profile = _mockProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Preview'),
        const SizedBox(height: AppSpacing.md),

        // Chips row
        _buildSubsectionLabel('Chips (small / medium / large)'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(color: AppColors.navyLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StreakChip(profile: profile, size: StreakChipSize.small),
              StreakChip(profile: profile, size: StreakChipSize.medium),
              StreakChip(profile: profile, size: StreakChipSize.large),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Extended chip
        _buildSubsectionLabel('Extended Chip'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(color: AppColors.navyLight),
          ),
          child: Center(
            child: StreakChipExtended(profile: profile, size: StreakChipSize.medium),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Profile Section
        _buildSubsectionLabel('Profile Section'),
        const SizedBox(height: AppSpacing.xs),
        StreakProfileSection(
          profile: profile,
          seasonLabel: '2026 Season',
          onFreezeTap: () {},
          variant: StreakSectionVariant.dark,
        ),
        const SizedBox(height: AppSpacing.md),

        // Dormant State (when currentWeeks=0, longestWeeks<=2, no previous)
        _buildSubsectionLabel('Dormant State (longestWeeks: $_longestWeeks)'),
        const SizedBox(height: AppSpacing.xs),
        _buildDormantStatePreview(),
        const SizedBox(height: AppSpacing.md),

        // Compact Display
        _buildSubsectionLabel('Compact Display'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(color: AppColors.navyLight),
          ),
          child: Center(
            child: StreakCompactDisplay(profile: profile),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Debug info
        _buildDebugInfo(profile),
      ],
    );
  }

  /// Preview of the dormant state widget (matches ProfileStreakSection).
  Widget _buildDormantStatePreview() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          AppIcon(
            icon: PhosphorIconsRegular.flame,
            color: AppColors.textMuted,
            size: 16,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'No active streak',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_longestWeeks > 0 && _longestWeeks <= 2) ...[
            Text(
              ' · ',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            Text(
              'Longest: ${_longestWeeks}w',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubsectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildDebugInfo(StreakProfile profile) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.navyLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tier: ${profile.visualTier.label} (min ${profile.visualTier.minWeeks}w)\n'
            'hasActiveStreak: ${profile.hasActiveStreak}\n'
            'hasPreviousStreak: ${profile.hasPreviousStreak}\n'
            'canUseFreeze: ${profile.canUseFreeze}\n'
            'hasPendingWeeks: ${profile.hasPendingWeeks}\n'
            'milestone: ${profile.milestone.weeks}',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
