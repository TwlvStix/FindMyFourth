import 'package:flutter/material.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_badge.dart';

class FlexibleBadge extends StatelessWidget {
  const FlexibleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: 'Flexible',
      variant: AppBadgeVariant.warning,
      size: AppBadgeSize.small,
      icon: AppPhosphorIcons.calendarNote,
    );
  }
}
