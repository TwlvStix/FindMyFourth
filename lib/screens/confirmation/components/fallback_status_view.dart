import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';

/// Shared status screen used for loading, already-completed, window-closed,
/// and post-submit states in the fallback confirmation flow.
class FallbackStatusView extends StatelessWidget {
  const FallbackStatusView({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.onDone,
  });

  final PhosphorIconData icon;
  final Color iconColor;
  final String message;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(icon: icon, color: iconColor, size: AppIconSize.hero),
                SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: AppTypography.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppButtonEnhanced(
                  onPressed: onDone,
                  text: 'Done',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
