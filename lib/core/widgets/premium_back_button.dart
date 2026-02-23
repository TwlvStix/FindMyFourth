import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_icon.dart';

/// Premium glass-morphism style back button with haptic feedback
///
/// This button uses a semi-transparent fairway green background with white border
/// and chevron icon, providing a luxury feel consistent with the app's design language.
///
/// By default, it navigates back using context.pop(). You can override this behavior
/// by providing a custom [onTap] callback.
///
/// Example:
/// ```dart
/// PremiumBackButton() // Default: context.pop()
///
/// PremiumBackButton(
///   onTap: () => GoRouter.of(context).go('/home')
/// )
/// ```
class PremiumBackButton extends StatelessWidget {
  const PremiumBackButton({
    super.key,
    this.onTap,
    this.tooltip = 'Back',
  });

  /// Optional custom tap handler. If not provided, defaults to context.pop()
  final VoidCallback? onTap;

  /// Tooltip for accessibility
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            context.pop();
          }
        },
        child: Container(
          margin: EdgeInsets.only(left: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: AppIcon(
            icon: AppPhosphorIcons.back,
            color: Colors.white,
            size: AppIconSize.lg,
          ),
        ),
      ),
    );
  }
}
