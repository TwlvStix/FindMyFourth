import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// A menu item for [AppPopupMenu].
class AppPopupMenuItem {
  const AppPopupMenuItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.textColor,
    this.isDestructive = false,
  });

  /// Display label for the menu item
  final String label;

  /// Value returned when this item is selected
  final String value;

  /// Optional Phosphor icon to display before the label
  final PhosphorIconData? icon;

  /// Custom icon color (defaults to textSecondary, or error if destructive)
  final Color? iconColor;

  /// Custom text color (defaults to textPrimary, or error if destructive)
  final Color? textColor;

  /// If true, uses error color for icon and text
  final bool isDestructive;
}

/// Premium popup menu widget that follows the Clubhouse design system.
///
/// Features:
/// - Dark navy surface with proper border radius
/// - Subtle border and elevation for depth
/// - Consistent typography and spacing
/// - Hover/press states using glass effects
/// - Support for icons and destructive items
///
/// Example:
/// ```dart
/// AppPopupMenu(
///   icon: AppPhosphorIcons.more,
///   items: [
///     AppPopupMenuItem(
///       label: 'Edit',
///       value: 'edit',
///       icon: AppPhosphorIcons.pencil,
///     ),
///     AppPopupMenuItem(
///       label: 'Delete',
///       value: 'delete',
///       icon: AppPhosphorIcons.trash,
///       isDestructive: true,
///     ),
///   ],
///   onSelected: (value) {
///     if (value == 'delete') {
///       // Handle delete
///     }
///   },
/// )
/// ```
class AppPopupMenu extends StatelessWidget {
  const AppPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon,
    this.iconColor,
    this.tooltip,
    this.enabled = true,
  });

  /// Menu items to display
  final List<AppPopupMenuItem> items;

  /// Callback when an item is selected
  final void Function(String value) onSelected;

  /// Icon to display as the menu trigger (defaults to more/ellipsis)
  final PhosphorIconData? icon;

  /// Color of the trigger icon (defaults to white)
  final Color? iconColor;

  /// Tooltip for the menu button
  final String? tooltip;

  /// Whether the menu is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: AppIcon(
        icon: icon ?? PhosphorIconsRegular.dotsThreeVertical,
        color: enabled ? (iconColor ?? AppColors.pure) : AppColors.textMuted,
        size: AppIconSize.md,
      ),
      tooltip: tooltip ?? 'More options',
      enabled: enabled,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        side: BorderSide(
          color: AppColors.inputBorderIdle,
          width: 1.0,
        ),
      ),
      color: AppColors.inputBackground,
      elevation: 0, // We use custom shadow via decoration
      shadowColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      onSelected: onSelected,
      itemBuilder: (context) => items.map((item) {
        final effectiveIconColor = item.iconColor ??
            (item.isDestructive ? AppColors.error : AppColors.textSecondary);
        final effectiveTextColor = item.textColor ??
            (item.isDestructive ? AppColors.error : AppColors.textPrimary);

        return PopupMenuItem<String>(
          value: item.value,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                AppIcon(
                  icon: item.icon!,
                  color: effectiveIconColor,
                  size: AppIconSize.button,
                ),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// A styled popup menu with custom shadow for premium appearance.
///
/// Use this when you need the popup menu with proper elevation shadow.
/// The standard [AppPopupMenu] uses Flutter's built-in popup which doesn't
/// support custom BoxShadow decorations on the menu surface.
class AppPopupMenuStyled extends StatefulWidget {
  const AppPopupMenuStyled({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon,
    this.iconColor,
    this.tooltip,
    this.enabled = true,
  });

  final List<AppPopupMenuItem> items;
  final void Function(String value) onSelected;
  final PhosphorIconData? icon;
  final Color? iconColor;
  final String? tooltip;
  final bool enabled;

  @override
  State<AppPopupMenuStyled> createState() => _AppPopupMenuStyledState();
}

class _AppPopupMenuStyledState extends State<AppPopupMenuStyled> {
  final GlobalKey _buttonKey = GlobalKey();

  void _showMenu() {
    final RenderBox button =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx,
      buttonPosition.dy + button.size.height + 8,
      overlay.size.width - buttonPosition.dx - button.size.width,
      overlay.size.height - buttonPosition.dy - button.size.height - 8,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        side: BorderSide(
          color: AppColors.inputBorderIdle,
          width: 1.0,
        ),
      ),
      color: AppColors.inputBackground,
      elevation: 8,
      shadowColor: AppColors.navyDark,
      surfaceTintColor: AppColors.transparent,
      items: widget.items.map((item) {
        final effectiveIconColor = item.iconColor ??
            (item.isDestructive ? AppColors.error : AppColors.textSecondary);
        final effectiveTextColor = item.textColor ??
            (item.isDestructive ? AppColors.error : AppColors.textPrimary);

        return PopupMenuItem<String>(
          value: item.value,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                AppIcon(
                  icon: item.icon!,
                  color: effectiveIconColor,
                  size: AppIconSize.button,
                ),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        widget.onSelected(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _buttonKey,
      icon: AppIcon(
        icon: widget.icon ?? PhosphorIconsRegular.dotsThreeVertical,
        color: widget.enabled
            ? (widget.iconColor ?? AppColors.pure)
            : AppColors.textMuted,
        size: AppIconSize.md,
      ),
      tooltip: widget.tooltip ?? 'More options',
      onPressed: widget.enabled ? _showMenu : null,
    );
  }
}
