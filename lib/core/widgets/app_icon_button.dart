import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import 'app_icon.dart';

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.buttonSize,
    this.fillColor,
    this.disabledColor,
    this.disabledIconColor,
    this.hoverColor,
    this.hoverIconColor,
    this.hoverBorderColor,
    this.tooltip,
    this.semanticLabel,
    this.onPressed,
    this.showLoadingIndicator = false,
    this.focusBorderSide,
    this.focusBorderRadius,
  });

  final Widget icon;
  final double? borderRadius;
  final double? buttonSize;
  final Color? fillColor;
  final Color? disabledColor;
  final Color? disabledIconColor;
  final Color? hoverColor;
  final Color? hoverIconColor;
  final Color? hoverBorderColor;
  final String? tooltip;
  final String? semanticLabel;
  final Color? borderColor;
  final double? borderWidth;
  final bool showLoadingIndicator;
  final Function()? onPressed;
  final BorderSide? focusBorderSide;
  final BorderRadius? focusBorderRadius;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool loading = false;
  late double? iconSize;
  late Color? iconColor;
  late Widget effectiveIcon;

  @override
  void initState() {
    super.initState();
    _updateIcon();
  }

  @override
  void didUpdateWidget(AppIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIcon();
  }

  void _updateIcon() {
    if (widget.icon is PhosphorIcon) {
      // Phosphor icon support
      PhosphorIcon icon = widget.icon as PhosphorIcon;
      if (icon.icon != null) {
        effectiveIcon = PhosphorIcon(
          icon.icon!,
          size: icon.size,
          color: icon.color,
        );
      } else {
        effectiveIcon = icon;
      }
      iconSize = icon.size;
      iconColor = icon.color;
    } else if (widget.icon is AppIcon) {
      AppIcon icon = widget.icon as AppIcon;
      effectiveIcon = AppIcon(
        icon: icon.icon,
        size: icon.size,
        color: icon.color,
      );
      iconSize = icon.size;
      iconColor = icon.color;
    } else if (widget.icon is Icon) {
      Icon icon = widget.icon as Icon;
      effectiveIcon = Icon(
        icon.icon,
        size: icon.size,
        color: icon.color,
      );
      iconSize = icon.size;
      iconColor = icon.color;
    } else {
      // Fallback for other widget types
      effectiveIcon = widget.icon;
      iconSize = null;
      iconColor = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.buttonSize == null || widget.buttonSize! >= 44,
      'AppIconButton buttonSize must be >= 44px for accessibility. Got: ${widget.buttonSize}',
    );

    final effectiveSize = widget.buttonSize ?? 48.0;

    ButtonStyle style = ButtonStyle(
      shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
              side: BorderSide(
                color: widget.hoverBorderColor ??
                    widget.borderColor ??
                    AppColors.transparent,
                width: widget.borderWidth ?? 0,
              ),
            );
          }
          if (states.contains(WidgetState.focused) &&
              widget.focusBorderSide != null) {
            return RoundedRectangleBorder(
              borderRadius:
                  widget.focusBorderRadius ?? BorderRadius.circular(AppBorderRadius.sm),
              side: widget.focusBorderSide!,
            );
          }
          return RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
            side: BorderSide(
              color: widget.borderColor ?? AppColors.transparent,
              width: widget.borderWidth ?? 0,
            ),
          );
        },
      ),
      iconColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.disabled) &&
              widget.disabledIconColor != null) {
            return widget.disabledIconColor;
          }
          if (states.contains(WidgetState.hovered) &&
              widget.hoverIconColor != null) {
            return widget.hoverIconColor;
          }
          return iconColor;
        },
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.disabled) &&
              widget.disabledColor != null) {
            return widget.disabledColor;
          }
          if (states.contains(WidgetState.hovered) &&
              widget.hoverColor != null) {
            return widget.hoverColor;
          }

          return widget.fillColor;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return null;
        }
        return widget.hoverColor == null ? null : AppColors.transparent;
      }),
    );

    final button = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Theme(
        data: ThemeData.from(
          colorScheme: Theme.of(context).colorScheme,
          useMaterial3: true,
        ),
        child: IgnorePointer(
          ignoring: (widget.showLoadingIndicator && loading),
          child: IconButton(
            icon: (widget.showLoadingIndicator && loading)
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        iconColor ?? AppColors.pure,
                      ),
                    ),
                  )
                : effectiveIcon,
            tooltip: widget.tooltip,
            onPressed: widget.onPressed == null
                ? null
                : () async {
                    if (loading) {
                      return;
                    }
                    setState(() => loading = true);
                    try {
                      await widget.onPressed!();
                    } finally {
                      if (mounted) {
                        setState(() => loading = false);
                      }
                    }
                  },
            splashRadius: effectiveSize,
            style: style,
          ),
        ),
      ),
    );

    final effectiveLabel = widget.semanticLabel ?? widget.tooltip;
    if (effectiveLabel != null) {
      return Semantics(
        label: effectiveLabel,
        button: true,
        excludeSemantics: true,
        child: button,
      );
    }

    return button;
  }
}
