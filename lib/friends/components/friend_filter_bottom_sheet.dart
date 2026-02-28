import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_matcher.dart';

/// Filter bottom sheet for friends search
class FriendFilterBottomSheet extends StatefulWidget {
  final FriendFilters currentFilters;
  final double topPadding;

  const FriendFilterBottomSheet({
    super.key,
    required this.currentFilters,
    this.topPadding = 0,
  });

  @override
  State<FriendFilterBottomSheet> createState() =>
      _FriendFilterBottomSheetState();
}

class _FriendFilterBottomSheetState extends State<FriendFilterBottomSheet> {
  late FriendFilters _filters;
  late TextEditingController _homeCourseController;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters.copy();
    _homeCourseController = TextEditingController(text: _filters.homeCourse ?? '');
  }

  @override
  void dispose() {
    _homeCourseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: SafeArea(
        top: false, // Handle top padding explicitly for safe area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(
                top: widget.topPadding + AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(AppPhosphorIcons.close),
                        color: AppColors.pure,
                        iconSize: AppIconSize.md,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Filter Golfers',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pure,
                        ),
                      ),
                    ],
                  ),
                  AppButtonEnhanced(
                    text: 'Clear All',
                    variant: AppButtonVariant.ghostDark,
                    size: AppButtonSize.small,
                    enabled: _filters.hasActiveFilters,
                    onPressed: () {
                      setState(() {
                        _filters = FriendFilters();
                        _homeCourseController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Filter options
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handicap range
                    _buildSectionHeader('Handicap Range'),
                    SizedBox(height: AppSpacing.sm),
                    _buildHandicapRange(),

                    SizedBox(height: AppSpacing.xl),

                    // Vibe score
                    _buildSectionHeader('Vibe score'),
                    SizedBox(height: AppSpacing.sm),
                    _buildVibeRange(),

                    SizedBox(height: AppSpacing.xl),

                    // Home Course
                    _buildSectionHeader('Home Course'),
                    SizedBox(height: AppSpacing.sm),
                    _buildCourseFilter(),

                    SizedBox(height: AppSpacing.xl),

                    // Additional filters
                    _buildSectionHeader('Additional Filters'),
                    SizedBox(height: AppSpacing.sm),
                    _buildAdditionalFilters(),

                    SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Apply button
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                border: Border(
                  top: BorderSide(
                    color: AppColors.navyLight,
                    width: 1,
                  ),
                ),
              ),
              child: AppButtonEnhanced(
                onPressed: () {
                  Navigator.of(context).pop(_filters);
                },
                text: 'Apply Filters',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.pure,
      ),
    );
  }

  Widget _buildHandicapRange() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHandicapChip('Any', null),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildHandicapChip('0-10', HandicapRange.low),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildHandicapChip('11-20', HandicapRange.mid),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildHandicapChip('21+', HandicapRange.high),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHandicapChip(String label, HandicapRange? range) {
    final isSelected = _filters.handicapRange == range;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filters.handicapRange = range;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha:0.15)
              : AppColors.navy.withValues(alpha:0.3),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.navyLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVibeRange() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildVibeChip('Any', null),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildVibeChip('50-70', VibeRange.low),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildVibeChip('71-80', VibeRange.mid),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildVibeChip('81-100', VibeRange.high),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVibeChip(String label, VibeRange? range) {
    final isSelected = _filters.vibeRange == range;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filters.vibeRange = range;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha:0.15)
              : AppColors.navy.withValues(alpha:0.3),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.navyLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseFilter() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          Icon(AppPhosphorIcons.golfCourse, color: AppColors.textSecondary, size: AppIconSize.button),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _filters.homeCourse = value.trim().isEmpty ? null : value;
                });
              },
              controller: _homeCourseController,
              decoration: InputDecoration(
                hintText: 'Enter course name...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.pure,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFilters() {
    return Column(
      children: [
        _buildFilterToggle(
          'Has Golf Canada number',
          _filters.hasGolfCanadaNumber,
          AppPhosphorIcons.badge,
          (value) {
            setState(() {
              _filters.hasGolfCanadaNumber = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterToggle(
    String label,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: value ? AppColors.green.withValues(alpha:0.15) : AppColors.navy.withValues(alpha:0.3),
          border: Border.all(
            color: value ? AppColors.green : AppColors.navyLight,
            width: value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xs - 2),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.green.withValues(alpha:0.2)
                    : AppColors.navy,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(
                icon,
                size: AppIconSize.button,
                color: value ? AppColors.green : AppColors.textSecondary,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: value ? AppColors.pure : AppColors.textSecondary,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (value)
              Icon(
                AppPhosphorIcons.success,
                color: AppColors.green,
                size: AppIconSize.button,
              ),
          ],
        ),
      ),
    );
  }
}

/// Friend filter options
class FriendFilters {
  HandicapRange? handicapRange;
  VibeRange? vibeRange;
  String? homeCourse;
  bool hasGolfCanadaNumber;

  FriendFilters({
    this.handicapRange,
    this.vibeRange,
    this.homeCourse,
    this.hasGolfCanadaNumber = false,
  });

  FriendFilters copy() {
    return FriendFilters(
      handicapRange: handicapRange,
      vibeRange: vibeRange,
      homeCourse: homeCourse,
      hasGolfCanadaNumber: hasGolfCanadaNumber,
    );
  }

  bool get hasActiveFilters {
    return handicapRange != null ||
        vibeRange != null ||
        homeCourse != null ||
        hasGolfCanadaNumber;
  }

  bool matchesUser(dynamic user) {
    // Handicap filter
    if (handicapRange != null) {
      final handicap = user.handicap ?? 0;
      switch (handicapRange!) {
        case HandicapRange.low:
          if (handicap < 0 || handicap > 10) return false;
          break;
        case HandicapRange.mid:
          if (handicap < 11 || handicap > 20) return false;
          break;
        case HandicapRange.high:
          if (handicap < 21) return false;
          break;
      }
    }

    // Vibe score filter (match against current user)
    if (vibeRange != null) {
      final currentUser = currentUserDocument;
      final myVibes = currentUser?.vibeProfile ?? const <String, dynamic>{};
      final theirVibes = user.vibeProfile ?? const <String, dynamic>{};
      if (currentUser == null || myVibes.isEmpty || theirVibes.isEmpty) {
        return false;
      }

      final myProfile = VibeProfile.fromFirestore(myVibes);
      final theirProfile = VibeProfile.fromFirestore(theirVibes);
      final result = VibeMatcher.score(myProfile, theirProfile);
      final score = result.finalScorePercent.round();

      switch (vibeRange!) {
        case VibeRange.low:
          if (score < 50 || score > 70) return false;
          break;
        case VibeRange.mid:
          if (score < 71 || score > 80) return false;
          break;
        case VibeRange.high:
          if (score < 81 || score > 100) return false;
          break;
      }
    }

    // Home course filter
    if (homeCourse != null && homeCourse!.isNotEmpty) {
      final userCourse = (user.homeCourse ?? '').toLowerCase();
      if (!userCourse.contains(homeCourse!.toLowerCase())) {
        return false;
      }
    }

    // Golf Canada number filter
    if (hasGolfCanadaNumber) {
      final gcn = user.golfCanadaNumber ?? '';
      if (gcn.isEmpty) return false;
    }

    return true;
  }
}

enum HandicapRange {
  low, // 0-10
  mid, // 11-20
  high, // 21+
}

enum VibeRange {
  low, // 50-70
  mid, // 71-80
  high, // 81-100
}
