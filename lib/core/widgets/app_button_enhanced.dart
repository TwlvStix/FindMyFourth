import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '../design_tokens/border_radius.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';
import 'app_icon.dart';

/// Button variant types for different visual styles
enum AppButtonVariant {
  /// Filled button with GREEN (primary accent) - use for main CTAs
  primary,

  /// Outlined button with navy border - use for secondary actions
  secondary,

  /// Minimal text-only button - use for tertiary actions (light backgrounds)
  ghost,

  /// Minimal text-only button for dark backgrounds - use for tertiary actions in app bars, dark surfaces
  ghostDark,

  /// Gold gradient button - RESTRICTED USE ONLY
  /// Only for: onboarding completion, premium upsell
  /// DO NOT use for standard CTAs (use primary instead)
  premium,

  /// Filled destructive button with error color - use for FINAL confirmations only
  /// For secondary destructive actions, use destructiveOutlined instead
  destructive,

  /// Outlined destructive button with error border - use for secondary destructive actions
  /// Examples: "Leave Game", "Cancel Game", "Delete Account"
  /// Use filled `destructive` only for final confirmation in modals
  destructiveOutlined,

  /// Filled button with NAVY (structural) - use for secondary prominent actions
  navyFilled,

  /// Google sign-in button - transparent with border and multicolor G logo
  google,
}

/// Button size presets with proper touch targets
enum AppButtonSize {
  /// Small button (44px height) - compact UI, meets accessibility minimum
  small,

  /// Medium button (48px height) - standard size, meets accessibility
  medium,

  /// Large button (56px height) - prominent CTAs
  large,

  /// Extra large button (64px height) - hero actions
  xlarge,
}

/// Enhanced button component with variants, animations, and polish
///
/// Features:
/// - 9 visual variants (primary, secondary, ghost, ghostDark, premium, destructive, destructiveOutlined, navyFilled, google)
/// - 4 size presets (small, medium, large, xlarge)
/// - Tactile micro-interactions (scale on press, hover states)
/// - Loading states that maintain size
/// - Icon support (leading/trailing)
/// - Haptic feedback
/// - Accessibility (focus states, touch targets)
///
/// Variant Usage:
/// - primary: Main CTA per screen (green filled)
/// - secondary: Secondary actions (navy outlined)
/// - ghost: Tertiary/dismiss actions on light backgrounds (transparent, dark text)
/// - ghostDark: Tertiary/dismiss actions on dark backgrounds (transparent, light text)
/// - premium: ONLY for onboarding completion or premium upsell (gold gradient)
/// - destructive: Final confirmation in modals (red filled)
/// - destructiveOutlined: Secondary destructive actions like "Leave Game" (red outlined)
/// - navyFilled: Secondary prominent actions in auth flows
/// - google: Google sign-in button
///
/// Example:
/// ```dart
/// AppButtonEnhanced(
///   text: 'Join Game',
///   variant: AppButtonVariant.primary,
///   size: AppButtonSize.large,
///   onPressed: () => handleJoin(),
///   leadingIcon: Icons.add,
/// )
/// ```
class AppButtonEnhanced extends StatefulWidget {
  const AppButtonEnhanced({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.leadingPhosphorIcon,
    this.trailingPhosphorIcon,
    this.leadingWidget,
    this.isLoading = false,
    this.enabled = true,
    this.fullWidth = false,
    this.hapticFeedback = true,
    this.focusNode,
  });

  /// Button label text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Visual style variant
  final AppButtonVariant variant;

  /// Size preset
  final AppButtonSize size;

  /// Optional icon before text (IconData)
  final IconData? leadingIcon;

  /// Optional icon after text (IconData)
  final IconData? trailingIcon;

  /// Optional Phosphor icon before text (takes precedence over leadingIcon)
  final PhosphorIconData? leadingPhosphorIcon;

  /// Optional Phosphor icon after text (takes precedence over trailingIcon)
  final PhosphorIconData? trailingPhosphorIcon;

  /// Optional custom widget before text (takes precedence over leadingPhosphorIcon and leadingIcon)
  final Widget? leadingWidget;

  /// Show loading indicator and disable interaction
  final bool isLoading;

  /// Enable/disable button
  final bool enabled;

  /// Expand button to full width
  final bool fullWidth;

  /// Enable haptic feedback on press
  final bool hapticFeedback;

  /// Optional focus node for keyboard navigation
  final FocusNode? focusNode;

  @override
  State<AppButtonEnhanced> createState() => _AppButtonEnhancedState();
}

class _AppButtonEnhancedState extends State<AppButtonEnhanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;
  late FocusNode _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();

    _animationController = AnimationController(
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    if (!_isEnabled) return;

    // Haptic feedback
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    widget.onPressed?.call();
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (!_isEnabled) return;
    setState(() => _isHovered = true);
  }

  void _handleHoverExit(PointerExitEvent event) {
    if (!_isEnabled) return;
    setState(() => _isHovered = false);
  }

  bool get _isEnabled => widget.enabled && !widget.isLoading;

  // ========================================================================
  // STYLE GETTERS
  // ========================================================================

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return 44.0;
      case AppButtonSize.medium:
        return 48.0;
      case AppButtonSize.large:
        return 56.0;
      case AppButtonSize.xlarge:
        return 64.0;
    }
  }

  double get _borderRadius {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppBorderRadius.sm; // 8px
      case AppButtonSize.medium:
        return AppBorderRadius.sm; // 8px - aligned to design token grid
      case AppButtonSize.large:
        return AppBorderRadius.md; // 12px
      case AppButtonSize.xlarge:
        return AppBorderRadius.lg; // 16px - aligned to design token grid
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0);
      case AppButtonSize.xlarge:
        return const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0);
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 18.0;
      case AppButtonSize.large:
        return 20.0;
      case AppButtonSize.xlarge:
        return 24.0;
    }
  }

  TextStyle get _textStyle {
    final baseStyle = widget.size == AppButtonSize.large ||
            widget.size == AppButtonSize.xlarge
        ? AppTypography.buttonLarge
        : AppTypography.labelLarge;

    return baseStyle.copyWith(
      color: _getTextColor(),
    );
  }

  Color _getBackgroundColor() {
    if (!_isEnabled) {
      // Ghost variants stay transparent when disabled
      if (widget.variant == AppButtonVariant.ghost ||
          widget.variant == AppButtonVariant.ghostDark) {
        return AppColors.transparent;
      }
      // Dark theme: use navy surface instead of light cloud
      return AppColors.navyLight;
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _isPressed
            ? AppColors.greenPressed
            : _isHovered
                ? AppColors.greenHovered
                : AppColors.green;

      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.navyLight.withValues(alpha:0.1)
            : _isHovered
                ? AppColors.navyLight.withValues(alpha:0.05)
                : AppColors.transparent;

      case AppButtonVariant.ghost:
        return _isPressed
            ? AppColors.cloud
            : _isHovered
                ? AppColors.sand
                : AppColors.transparent;

      case AppButtonVariant.ghostDark:
        // For dark surfaces - subtle glass effect on interaction
        return _isPressed
            ? AppColors.glassSurface
            : _isHovered
                ? AppColors.glassSurface
                : AppColors.transparent;

      case AppButtonVariant.premium:
        // Gradient handled separately in build
        return AppColors.transparent;

      case AppButtonVariant.destructive:
        return _isPressed
            ? AppColors.errorPressed // Darker error red when pressed
            : _isHovered
                ? AppColors.errorHovered // Lighter error red on hover
                : AppColors.error;

      case AppButtonVariant.destructiveOutlined:
        // Transparent with subtle error tint on hover/press
        return _isPressed
            ? AppColors.error.withValues(alpha: 0.12)
            : _isHovered
                ? AppColors.error.withValues(alpha: 0.06)
                : AppColors.transparent;

      case AppButtonVariant.navyFilled:
        return _isPressed
            ? AppColors.navyPressed
            : _isHovered
                ? AppColors.navyHovered
                : AppColors.navy;

      case AppButtonVariant.google:
        return _isPressed
            ? AppColors.navyLight.withValues(alpha: 0.15)
            : _isHovered
                ? AppColors.navyLight.withValues(alpha: 0.08)
                : AppColors.transparent;
    }
  }

  Color _getTextColor() {
    if (!_isEnabled) {
      // Dark theme: use muted text for all disabled buttons
      return AppColors.textMuted;
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.premium:
      case AppButtonVariant.destructive:
      case AppButtonVariant.navyFilled:
        return AppColors.pure;

      case AppButtonVariant.google:
        return AppColors.textPrimary;

      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.textSecondary.withValues(alpha: 0.7)
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.85)
                : AppColors.textSecondary;

      case AppButtonVariant.ghost:
        return _isPressed
            ? AppColors.navy
            : _isHovered
                ? AppColors.navyDark
                : AppColors.navy;

      case AppButtonVariant.ghostDark:
        // For dark surfaces - light text that brightens on interaction
        return _isPressed
            ? AppColors.textPrimary
            : _isHovered
                ? AppColors.textPrimary
                : AppColors.textSecondary;

      case AppButtonVariant.destructiveOutlined:
        // Error color - slightly muted for the outlined variant
        return _isPressed
            ? AppColors.errorPressed
            : _isHovered
                ? AppColors.errorHovered
                : AppColors.error.withValues(alpha: 0.85);
    }
  }

  Color _getBorderColor() {
    if (!_isEnabled) {
      // Dark theme: use subtle border for outlined variants, transparent for filled
      if (widget.variant == AppButtonVariant.secondary ||
          widget.variant == AppButtonVariant.destructiveOutlined ||
          widget.variant == AppButtonVariant.google) {
        return AppColors.inputBorderIdle;
      }
      return AppColors.transparent;
    }

    switch (widget.variant) {
      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.textSecondary.withValues(alpha: 0.5)
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppColors.textSecondary.withValues(alpha: 0.3);

      case AppButtonVariant.destructiveOutlined:
        // Error-colored border at 35% alpha for subtlety
        return _isPressed
            ? AppColors.error.withValues(alpha: 0.5)
            : _isHovered
                ? AppColors.error.withValues(alpha: 0.45)
                : AppColors.error.withValues(alpha: 0.35);

      case AppButtonVariant.google:
        return _isPressed
            ? AppColors.inputBorderFocused
            : _isHovered
                ? AppColors.textMuted
                : AppColors.inputBorderIdle;

      default:
        return AppColors.transparent;
    }
  }

  List<BoxShadow> _getShadows() {
    if (!_isEnabled ||
        widget.variant == AppButtonVariant.ghost ||
        widget.variant == AppButtonVariant.ghostDark) {
      return [];
    }

    // Outlined variants get no shadow
    if (widget.variant == AppButtonVariant.secondary ||
        widget.variant == AppButtonVariant.destructiveOutlined ||
        widget.variant == AppButtonVariant.google) {
      return [];
    }

    // Destructive (filled) variant gets error-colored shadow
    if (widget.variant == AppButtonVariant.destructive) {
      if (_isPressed) {
        return [
          BoxShadow(
            color: AppColors.error.withValues(alpha:0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      }
      return [
        BoxShadow(
          color: AppColors.error.withValues(alpha:0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // Primary button gets green shadow
    if (widget.variant == AppButtonVariant.primary) {
      if (_isPressed) {
        return [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      }
      return [
        BoxShadow(
          color: AppColors.green.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // Navy filled button gets navy shadow
    if (widget.variant == AppButtonVariant.navyFilled) {
      if (_isPressed) {
        return [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      }
      return [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // Premium variant gets gold shadow
    if (_isPressed) {
      return [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return [
      BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.25),
        blurRadius: 12,
        offset: const Offset(0, 4),
        ),
    ];
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          child: Focus(
            focusNode: _focusNode,
            child: AnimatedContainer(
              duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
              curve: MotionTokens.curveEnter,
              width: widget.fullWidth ? double.infinity : null,
              height: _height,
              decoration: BoxDecoration(
                gradient: widget.variant == AppButtonVariant.premium && _isEnabled
                    ? AppColors.goldGradient
                    : null,
                color: widget.variant != AppButtonVariant.premium
                    ? _getBackgroundColor()
                    : null,
                borderRadius: BorderRadius.circular(_borderRadius),
                border: Border.all(
                  color: _getBorderColor(),
                  width: widget.variant == AppButtonVariant.secondary
                      ? 2.0
                      : widget.variant == AppButtonVariant.destructiveOutlined
                          ? 2.0
                          : widget.variant == AppButtonVariant.google
                              ? 1.5
                              : 0.0,
                ),
                boxShadow: _getShadows(),
              ),
              child: Padding(
                padding: _padding,
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: _iconSize,
          height: _iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingWidget != null) ...[
          widget.leadingWidget!,
          SizedBox(width: widget.size == AppButtonSize.small ? 6.0 : 8.0),
        ] else if (widget.leadingPhosphorIcon != null) ...[
          AppIcon(
            icon: widget.leadingPhosphorIcon!,
            size: _iconSize,
            color: _getTextColor(),
          ),
          SizedBox(width: widget.size == AppButtonSize.small ? 6.0 : 8.0),
        ] else if (widget.leadingIcon != null) ...[
          Icon(
            widget.leadingIcon,
            size: _iconSize,
            color: _getTextColor(),
          ),
          SizedBox(width: widget.size == AppButtonSize.small ? 6.0 : 8.0),
        ],
        Flexible(
          fit: widget.fullWidth ? FlexFit.tight : FlexFit.loose,
          child: Text(
            widget.text,
            style: _textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (widget.trailingPhosphorIcon != null) ...[
          SizedBox(width: widget.size == AppButtonSize.small ? 6.0 : 8.0),
          AppIcon(
            icon: widget.trailingPhosphorIcon!,
            size: _iconSize,
            color: _getTextColor(),
          ),
        ] else if (widget.trailingIcon != null) ...[
          SizedBox(width: widget.size == AppButtonSize.small ? 6.0 : 8.0),
          Icon(
            widget.trailingIcon,
            size: _iconSize,
            color: _getTextColor(),
          ),
        ],
      ],
    );
  }
}
