import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_icon.dart';

/// A preference slider control with title, icon, and value selector.
///
/// Used on the preferences step of progressive onboarding.
class PreferenceControl extends StatelessWidget {
  const PreferenceControl({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onUpdate,
  });

  /// Control title displayed above the slider.
  final String title;

  /// Phosphor icon displayed next to the title.
  final PhosphorIconData icon;

  /// Current value (0-5).
  final int value;

  /// Callback when value changes.
  final ValueChanged<int> onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              icon: icon,
              color: AppColors.navyDark,
              size: AppIconSize.button,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: AppColors.cloud,
              width: 2.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppCountController(
              decrementIconBuilder: (enabled) => AppIcon(
                icon: AppPhosphorIcons.minus,
                color: enabled ? AppColors.navyDark : AppColors.pure,
                size: AppIconSize.button,
              ),
              incrementIconBuilder: (enabled) => AppIcon(
                icon: AppPhosphorIcons.plus,
                color: enabled ? AppColors.navyDark : AppColors.pure,
                size: AppIconSize.button,
              ),
              countBuilder: (val) => Text(
                val.toString(),
                style: AppTypography.headlineSmallSans.copyWith(
                  letterSpacing: 0.0,
                ),
              ),
              count: value,
              updateCount: onUpdate,
              stepSize: 1,
              minimum: 0,
              maximum: 5,
            ),
          ),
        ),
      ],
    );
  }
}
