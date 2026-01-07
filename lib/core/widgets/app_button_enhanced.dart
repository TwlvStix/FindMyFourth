import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens/colors.dart';
import '../design_tokens/typography.dart';

/// Button variant types for different visual styles
enum AppButtonVariant {
  /// Filled button with primary brand color - use for main actions
  primary,

  /// Outlined button with brand color border - use for secondary actions
  secondary,

  /// Minimal text-only button - use for tertiary actions
  ghost,

  /// Gradient-filled button with sunset colors - use for special CTAs
  gradient,
}

/// Button size presets with proper touch targets
enum AppButtonSize {
  /// Small button (36px height) - compact UI elements
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
/// - 4 visual variants (primary, secondary, ghost, gradient)
/// - 4 size presets (small, medium, large, xlarge)
/// - Tactile micro-interactions (scale on press, hover states)
/// - Loading states that maintain size
/// - Icon support (leading/trailing)
/// - Haptic feedback
/// - Accessibility (focus states, touch targets)
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

  /// Optional icon before text
  final IconData? leadingIcon;

  /// Optional icon after text
  final IconData? trailingIcon;

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
      duration: const Duration(milliseconds: 150),
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
        return 36.0;
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
        return 8.0;
      case AppButtonSize.medium:
        return 10.0;
      case AppButtonSize.large:
        return 12.0;
      case AppButtonSize.xlarge:
        return 14.0;
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
        : AppTypography.button;

    return baseStyle.copyWith(
      color: _getTextColor(),
    );
  }

  Color _getBackgroundColor() {
    if (!_isEnabled) {
      return AppColors.cloud;
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _isPressed
            ? AppColors.fairwayDark
            : _isHovered
                ? AppColors.fairway
                : AppColors.fairwayDark;

      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.fairwayLight.withOpacity(0.1)
            : _isHovered
                ? AppColors.fairwayLight.withOpacity(0.05)
                : Colors.transparent;

      case AppButtonVariant.ghost:
        return _isPressed
            ? AppColors.cloud
            : _isHovered
                ? AppColors.sand
                : Colors.transparent;

      case AppButtonVariant.gradient:
        // Gradient handled separately
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (!_isEnabled) {
      return AppColors.stone;
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.gradient:
        return AppColors.pure;

      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.fairwayDark
            : _isHovered
                ? AppColors.fairway
                : AppColors.fairwayDark;

      case AppButtonVariant.ghost:
        return _isPressed
            ? AppColors.fairway
            : _isHovered
                ? AppColors.fairwayDark
                : AppColors.fairway;
    }
  }

  Color _getBorderColor() {
    if (!_isEnabled) {
      return AppColors.cloud;
    }

    switch (widget.variant) {
      case AppButtonVariant.secondary:
        return _isPressed
            ? AppColors.fairwayDark
            : _isHovered
                ? AppColors.fairway
                : AppColors.fairway;

      default:
        return Colors.transparent;
    }
  }

  List<BoxShadow> _getShadows() {
    if (!_isEnabled || widget.variant == AppButtonVariant.ghost) {
      return [];
    }

    if (widget.variant == AppButtonVariant.secondary) {
      return [];
    }

    if (_isPressed) {
      return [
        BoxShadow(
          color: AppColors.fairwayDark.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return [
      BoxShadow(
        color: AppColors.fairwayDark.withOpacity(0.2),
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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: widget.fullWidth ? double.infinity : null,
              height: _height,
              decoration: BoxDecoration(
                gradient: widget.variant == AppButtonVariant.gradient && _isEnabled
                    ? AppColors.sunsetGradient
                    : null,
                color: widget.variant != AppButtonVariant.gradient
                    ? _getBackgroundColor()
                    : null,
                borderRadius: BorderRadius.circular(_borderRadius),
                border: Border.all(
                  color: _getBorderColor(),
                  width: widget.variant == AppButtonVariant.secondary ? 2.0 : 0.0,
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
        if (widget.leadingIcon != null) ...[
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
        if (widget.trailingIcon != null) ...[
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
