import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';

/// Button styling variants for friend card actions
enum ActionButtonVariant {
  /// Green filled, white icon - for primary positive actions
  primary,
  /// Transparent, navyLight border, textSecondary icon - for neutral secondary actions
  secondary,
  /// Transparent, stone border, textMuted icon - for de-emphasized/destructive actions
  muted,
}

/// Icon-only action button used in friend cards.
class FriendCardActionButton extends StatelessWidget {
  const FriendCardActionButton({
    super.key,
    this.icon,
    required this.onPressed,
    required this.variant,
    this.isLoading = false,
    this.tooltip,
  });

  final PhosphorIconData? icon;
  final VoidCallback? onPressed;
  final ActionButtonVariant variant;
  final bool isLoading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, borderColor, iconColor) = _getColors();

    final button = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : icon != null
                    ? AppIcon(
                        icon: icon!,
                        size: AppIconSize.button,
                        color: iconColor,
                      )
                    : SizedBox.shrink(),
          ),
        ),
      ),
    );

    return tooltip != null
        ? Tooltip(message: tooltip!, child: button)
        : button;
  }

  (Color, Color?, Color) _getColors() {
    switch (variant) {
      case ActionButtonVariant.primary:
        return (AppColors.green, null, AppColors.textPrimary);
      case ActionButtonVariant.secondary:
        return (AppColors.transparent, AppColors.navyLight, AppColors.textSecondary);
      case ActionButtonVariant.muted:
        return (AppColors.transparent, AppColors.stone, AppColors.textMuted);
    }
  }
}
