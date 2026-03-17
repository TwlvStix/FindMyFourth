import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/streak/streak_profile_section.dart';
import '/models/streak_profile.dart';
import '/providers/provider_extensions.dart';

/// Streak section wrapper for the main profile screen.
///
/// Fetches and displays the current user's streak profile
/// using the StreakProvider.
class ProfileStreakSection extends StatefulWidget {
  const ProfileStreakSection({super.key});

  @override
  State<ProfileStreakSection> createState() => _ProfileStreakSectionState();
}

class _ProfileStreakSectionState extends State<ProfileStreakSection> {
  StreakProfile? _profile;
  bool _loading = true;
  StreamSubscription<StreakProfile?>? _subscription;

  @override
  void initState() {
    super.initState();
    _initSubscription();
  }

  void _initSubscription() {
    _subscription = context.streakProvider.watchMyStreak().listen(
      (profile) {
        if (!mounted) return;
        setState(() {
          _profile = profile;
          _loading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show while loading
    if (_loading) {
      return const SizedBox.shrink();
    }

    // Don't show if no streak data
    if (_profile == null) {
      return const SizedBox.shrink();
    }

    // Dormant state for low-history users (no active streak, longestWeeks 0-2)
    if (!_profile!.hasActiveStreak &&
        _profile!.longestWeeks <= 2 &&
        !_profile!.hasPreviousStreak) {
      return _buildDormantState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: StreakProfileSection(
        profile: _profile!,
        showFreezeStatus: true,
        variant: StreakSectionVariant.dark,
      ),
    );
  }

  /// Compact dormant state for users with no active streak and low history.
  Widget _buildDormantState() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Container(
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
            if (_profile!.longestWeeks > 0) ...[
              Text(
                ' · ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'Longest: ${_profile!.longestWeeks}w',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
