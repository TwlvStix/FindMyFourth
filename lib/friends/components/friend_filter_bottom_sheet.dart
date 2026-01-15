import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Filter bottom sheet for friends search
class FriendFilterBottomSheet extends StatefulWidget {
  final FriendFilters currentFilters;

  const FriendFilterBottomSheet({
    super.key,
    required this.currentFilters,
  });

  @override
  State<FriendFilterBottomSheet> createState() =>
      _FriendFilterBottomSheetState();
}

class _FriendFilterBottomSheetState extends State<FriendFilterBottomSheet> {
  late FriendFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters.copy();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cloud,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Golfers',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = FriendFilters();
                      });
                    },
                    child: Text(
                      'Clear All',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.fairway,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
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
        color: AppColors.onyx,
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
              ? AppColors.fairway.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.fairway : AppColors.cloud,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.fairway : AppColors.stone,
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
        color: AppColors.sand.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Row(
        children: [
          Icon(Icons.golf_course_rounded, color: AppColors.fairway, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _filters.homeCourse = value.trim().isEmpty ? null : value;
                });
              },
              controller: TextEditingController(text: _filters.homeCourse ?? ''),
              decoration: InputDecoration(
                hintText: 'Enter course name...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTypography.bodyMedium,
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
          'Friends only',
          _filters.friendsOnly,
          Icons.people_rounded,
          (value) {
            setState(() {
              _filters.friendsOnly = value;
            });
          },
        ),
        SizedBox(height: AppSpacing.sm),
        _buildFilterToggle(
          'Has Golf Canada number',
          _filters.hasGolfCanadaNumber,
          Icons.badge_rounded,
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
          color: value ? AppColors.fairway.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: value ? AppColors.fairway : AppColors.cloud,
            width: value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.fairway.withOpacity(0.2)
                    : AppColors.cloud.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: value ? AppColors.fairway : AppColors.stone,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: value ? AppColors.onyx : AppColors.stone,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (value)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.fairway,
                size: 20,
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
  String? homeCourse;
  bool friendsOnly;
  bool hasGolfCanadaNumber;

  FriendFilters({
    this.handicapRange,
    this.homeCourse,
    this.friendsOnly = false,
    this.hasGolfCanadaNumber = false,
  });

  FriendFilters copy() {
    return FriendFilters(
      handicapRange: handicapRange,
      homeCourse: homeCourse,
      friendsOnly: friendsOnly,
      hasGolfCanadaNumber: hasGolfCanadaNumber,
    );
  }

  bool get hasActiveFilters {
    return handicapRange != null ||
        homeCourse != null ||
        friendsOnly ||
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
