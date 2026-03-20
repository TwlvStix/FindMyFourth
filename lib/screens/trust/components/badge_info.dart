import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';

typedef BadgeInfoRecord = ({
  String label,
  String description,
  PhosphorIconData icon,
  Color gradientStart,
  Color gradientEnd,
});

BadgeInfoRecord badgeInfo(String badgeLevel) {
  switch (badgeLevel) {
    case 'anchor':
      return (
        label: 'Anchor',
        description: 'Cornerstone of the community',
        icon: AppPhosphorIcons.anchor,
        gradientStart: AppColors.navyDark,
        gradientEnd: AppColors.navy,
      );
    case 'starter':
      return (
        label: 'Starter',
        description: 'Trusted regular golfer',
        icon: AppPhosphorIcons.games,
        gradientStart: AppColors.navy,
        gradientEnd: AppColors.navyLight,
      );
    case 'regular':
      return (
        label: 'Regular',
        description: 'Established member',
        icon: AppPhosphorIcons.golf,
        gradientStart: AppColors.navyLight,
        gradientEnd: AppColors.green,
      );
    case 'confirmed':
      return (
        label: 'Confirmed',
        description: 'Verified by the community',
        icon: AppPhosphorIcons.verified,
        gradientStart: AppColors.green,
        gradientEnd: AppColors.greenLight,
      );
    case 'new':
    default:
      return (
        label: 'First Tee',
        description: 'Your story begins here',
        icon: AppPhosphorIcons.golfCourse,
        gradientStart: AppColors.greenLight,
        gradientEnd: AppColors.green,
      );
  }
}
