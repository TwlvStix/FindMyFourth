import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';

/// A text widget that shows the full text in a premium tooltip on long-press
/// when the text is truncated.
///
/// Features:
/// - Automatically detects text truncation using TextPainter
/// - Only enables long-press tooltip when text would overflow
/// - Premium tooltip styling matching The Clubhouse design system
/// - Smooth animations using MotionTokens
/// - Respects reduced motion settings
/// - Positions above/below based on screen position
///
/// Example:
/// ```dart
/// AppExpandableText(
///   text: veryLongCourseName,
///   style: AppTypography.titleSmall,
///   maxLines: 1,
///   color: AppColors.textPrimary,
/// )
/// ```
class AppExpandableText extends StatefulWidget {
  const AppExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
    this.color,
    this.textAlign,
    this.tooltipMaxWidth = 280,
  });

  /// The text content to display
  final String text;

  /// Text style (use AppTypography tokens)
  final TextStyle style;

  /// Maximum number of lines before truncation (default: 1)
  final int maxLines;

  /// Text color (overrides style color)
  final Color? color;

  /// Text alignment
  final TextAlign? textAlign;

  /// Maximum width for the tooltip (default: 280)
  final double tooltipMaxWidth;

  @override
  State<AppExpandableText> createState() => _AppExpandableTextState();
}

class _AppExpandableTextState extends State<AppExpandableText>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ReducedMotionService.adjust(MotionTokens.microInteraction),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: MotionTokens.curveEnter,
      reverseCurve: MotionTokens.curveExit,
    );
  }

  @override
  void dispose() {
    _hideTooltip(animate: false);
    _animationController.dispose();
    super.dispose();
  }

  TextStyle get _effectiveStyle =>
      widget.color != null ? widget.style.copyWith(color: widget.color) : widget.style;

  bool _checkTextTruncation(double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: _effectiveStyle),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  void _showTooltip() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenPadding = mediaQuery.padding;

    // Calculate if tooltip should appear above or below
    final spaceAbove = position.dy - screenPadding.top;
    final spaceBelow =
        screenSize.height - position.dy - size.height - screenPadding.bottom;

    // Prefer showing above, unless there's not enough space (need at least 80px)
    final showAbove = spaceAbove > spaceBelow && spaceAbove > 80;

    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        text: widget.text,
        style: _effectiveStyle,
        targetPosition: position,
        targetSize: size,
        showAbove: showAbove,
        maxWidth: widget.tooltipMaxWidth,
        animation: _fadeAnimation,
        onDismiss: () => _hideTooltip(animate: true),
        screenSize: screenSize,
        screenPadding: screenPadding,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideTooltip({required bool animate}) {
    if (_overlayEntry == null) return;

    if (animate) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTruncated = _checkTextTruncation(constraints.maxWidth);

        return GestureDetector(
          onLongPress: isTruncated ? _showTooltip : null,
          child: Text(
            key: _textKey,
            widget.text,
            style: _effectiveStyle,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }
}

/// The tooltip overlay content
class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.text,
    required this.style,
    required this.targetPosition,
    required this.targetSize,
    required this.showAbove,
    required this.maxWidth,
    required this.animation,
    required this.onDismiss,
    required this.screenSize,
    required this.screenPadding,
  });

  final String text;
  final TextStyle style;
  final Offset targetPosition;
  final Size targetSize;
  final bool showAbove;
  final double maxWidth;
  final Animation<double> animation;
  final VoidCallback onDismiss;
  final Size screenSize;
  final EdgeInsets screenPadding;

  @override
  Widget build(BuildContext context) {
    // Calculate tooltip position
    const tooltipGap = 8.0;
    const horizontalPadding = 16.0;

    // Center the tooltip horizontally over the target, with screen edge constraints
    double left = targetPosition.dx + (targetSize.width / 2) - (maxWidth / 2);

    // Constrain to screen edges
    if (left < horizontalPadding) {
      left = horizontalPadding;
    } else if (left + maxWidth > screenSize.width - horizontalPadding) {
      left = screenSize.width - maxWidth - horizontalPadding;
    }

    // Calculate vertical position
    final top = showAbove
        ? targetPosition.dy - tooltipGap - 60 // Approximate tooltip height
        : targetPosition.dy + targetSize.height + tooltipGap;

    return Stack(
      children: [
        // Tap-outside dismiss layer
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: AppColors.transparent),
          ),
        ),
        // Tooltip content
        Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final scaleValue = ReducedMotionService.shouldScale
                  ? 0.97 + (0.03 * animation.value)
                  : 1.0;

              return Opacity(
                opacity: animation.value,
                child: Transform.scale(
                  scale: scaleValue,
                  child: child,
                ),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  border: Border.all(
                    color: AppColors.inputBorderIdle,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDark.withValues(alpha: 0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: style.copyWith(
                    color: AppColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
