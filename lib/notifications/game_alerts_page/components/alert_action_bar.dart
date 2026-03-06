import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// Sticky bottom action bar with Reset and Save buttons.
///
/// Positioned at the bottom of the Game Alerts page with gradient fade.
class AlertActionBar extends StatelessWidget {
  const AlertActionBar({
    super.key,
    required this.isSaving,
    required this.hasChanges,
    required this.onReset,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasChanges;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.transparent,
              AppColors.navyDark.withValues(alpha: 0.95),
              AppColors.navyDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: _ResetButton(
                  isDisabled: isSaving,
                  onPressed: onReset,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: _SaveButton(
                  isSaving: isSaving,
                  isDisabled: isSaving || !hasChanges,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.isDisabled,
    required this.onPressed,
  });

  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: isDisabled
                  ? AppColors.stone.withValues(alpha: 0.3)
                  : AppColors.pure.withValues(alpha: 0.4),
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              'Reset',
              style: AppTypography.buttonLarge.copyWith(
                color: isDisabled ? AppColors.stone : AppColors.pure,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool isSaving;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.stone.withValues(alpha: 0.3)
                : AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: isDisabled
                  ? AppColors.transparent
                  : AppColors.pure.withValues(alpha: 0.3),
              width: 2.0,
            ),
            boxShadow: isDisabled ? [] : [AppElevation.lg],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.pure),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                ] else ...[
                  AppIcon(
                    icon: AppPhosphorIcons.check,
                    size: AppIconSize.button,
                    color: AppColors.pure,
                  ),
                  SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  isSaving ? 'Saving...' : 'Save Settings',
                  style: AppTypography.buttonLarge.copyWith(
                    color: AppColors.pure,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
