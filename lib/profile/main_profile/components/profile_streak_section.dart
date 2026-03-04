import 'dart:async';
import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
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

    // Don't show if no streak data or no active streak
    if (_profile == null) {
      return const SizedBox.shrink();
    }

    // Don't show section if user has never had a streak
    if (!_profile!.hasActiveStreak &&
        _profile!.longestWeeks == 0 &&
        !_profile!.hasPreviousStreak) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: StreakProfileSection(
        profile: _profile!,
        showFreezeStatus: true,
      ),
    );
  }
}
