import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';

class ChatScrollFab extends StatelessWidget {
  const ChatScrollFab({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scroll to bottom',
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.navyDark,
                AppColors.navyDark.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            boxShadow: const [AppElevation.md],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: AppIcon(
                icon: AppPhosphorIcons.arrowDown,
                color: AppColors.textPrimary,
                size: AppIconSize.md,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
