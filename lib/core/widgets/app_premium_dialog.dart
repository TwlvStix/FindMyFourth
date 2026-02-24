import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';

/// Premium dialog variant types
enum PremiumDialogVariant {
  /// Red-toned destructive action (remove, delete, cancel)
  destructive,

  /// Green-toned confirmation action (join, add, confirm)
  confirmation,

  /// Blue-gray informational (single "Got It" button)
  informational,
}

/// Design tokens for the premium dialog system
class _DialogTokens {
  // Colors
  static const Color overlay = Color(0x8C000000); // rgba(0, 0, 0, 0.55)
  static const Color modalBackground = Color(0xFF0F1B24);
  static const Color titleColor = Color(0xFFF2F5F7);
  static const Color bodyColor = Color(0xFFA8B3BC);
  static const Color cancelColor = Color(0xFF8FA3AD);

  // Destructive variant
  static const Color destructiveColor = Color(0xFFD96B6B);
  static const Color destructiveBadgeBg = Color(0x1FD96B6B); // 12% opacity

  // Confirmation variant
  static const Color confirmationColor = Color(0xFF3A9B6A);
  static const Color confirmationBadgeBg = Color(0x241F6F4A); // 14% opacity

  // Informational variant
  static const Color informationalColor = Color(0xFF7A9BB5);
  static const Color informationalBadgeBg = Color(0x1F7A9BB5); // 12% opacity

  // Dimensions
  static const double maxWidth = 420;
  static const double mobileWidthFactor = 0.80;
  static const double borderRadius = 20;
  static const double buttonBorderRadius = 11;
  static const double iconBadgeSize = 40;
  static const double iconBadgeBorderRadius = 10;
  static const double iconSize = 22;

  // Spacing
  static const double horizontalPadding = 24;
  static const double topPadding = 22;
  static const double bottomPadding = 24;
  static const double titleToBodyGap = 18;
  static const double buttonGap = 14;
  static const double iconBadgeBottomMargin = 16;

  // Typography
  static const double titleSize = 18;
  static const double titleLetterSpacing = -0.2;
  static const FontWeight titleWeight = FontWeight.w600;
  static const double bodySize = 15;
  static const double bodyLineHeight = 1.55;
  static const FontWeight bodyWeight = FontWeight.w400;
  static const FontWeight cancelWeight = FontWeight.w500;
  static const FontWeight actionWeight = FontWeight.w600;

  // Animation
  static const Duration enterDuration = Duration(milliseconds: 200);
  // Exit animation is 150ms (handled by reverseCurve)
  static const double scaleStart = 0.96;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  // Shadow
  static const List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Color(0x66000000), // rgba(0, 0, 0, 0.4)
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];
}

/// A premium alert dialog with three variants: destructive, confirmation, and informational.
///
/// Usage:
/// ```dart
/// // Destructive dialog (e.g., remove player)
/// final result = await showPremiumDialog(
///   context: context,
///   variant: PremiumDialogVariant.destructive,
///   icon: PhosphorIconsRegular.userMinus,
///   title: 'Remove Player',
///   body: 'This will remove Guest 1 from the game.',
///   actionLabel: 'Remove',
/// );
///
/// // Confirmation dialog (e.g., join game)
/// final result = await showPremiumDialog(
///   context: context,
///   variant: PremiumDialogVariant.confirmation,
///   icon: PhosphorIconsRegular.userPlus,
///   title: 'Join Game',
///   body: "You'll be added to Sunset Bay as Player 4.",
///   actionLabel: 'Join',
/// );
///
/// // Informational dialog (single button)
/// await showPremiumDialog(
///   context: context,
///   variant: PremiumDialogVariant.informational,
///   icon: PhosphorIconsRegular.info,
///   title: 'Round Complete',
///   body: 'Scores have been saved. You can review the scorecard anytime from the game menu.',
///   actionLabel: 'Got It',
/// );
/// ```
Future<bool?> showPremiumDialog({
  required BuildContext context,
  required PremiumDialogVariant variant,
  required IconData icon,
  required String title,
  required String body,
  required String actionLabel,
  String cancelLabel = 'Cancel',
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: _DialogTokens.overlay,
    transitionDuration: _DialogTokens.enterDuration,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: _DialogTokens.enterCurve,
        reverseCurve: _DialogTokens.exitCurve,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: _DialogTokens.scaleStart,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PremiumDialogContent(
        variant: variant,
        icon: icon,
        title: title,
        body: body,
        actionLabel: actionLabel,
        cancelLabel: cancelLabel,
      );
    },
  );
}

class _PremiumDialogContent extends StatelessWidget {
  const _PremiumDialogContent({
    required this.variant,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.cancelLabel,
  });

  final PremiumDialogVariant variant;
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final String cancelLabel;

  Color get _actionColor {
    switch (variant) {
      case PremiumDialogVariant.destructive:
        return _DialogTokens.destructiveColor;
      case PremiumDialogVariant.confirmation:
        return _DialogTokens.confirmationColor;
      case PremiumDialogVariant.informational:
        return _DialogTokens.informationalColor;
    }
  }

  Color get _badgeBackground {
    switch (variant) {
      case PremiumDialogVariant.destructive:
        return _DialogTokens.destructiveBadgeBg;
      case PremiumDialogVariant.confirmation:
        return _DialogTokens.confirmationBadgeBg;
      case PremiumDialogVariant.informational:
        return _DialogTokens.informationalBadgeBg;
    }
  }

  bool get _showCancelButton => variant != PremiumDialogVariant.informational;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * _DialogTokens.mobileWidthFactor)
        .clamp(0.0, _DialogTokens.maxWidth);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: _DialogTokens.modalBackground,
            borderRadius: BorderRadius.circular(_DialogTokens.borderRadius),
            boxShadow: _DialogTokens.modalShadow,
          ),
          padding: const EdgeInsets.only(
            left: _DialogTokens.horizontalPadding,
            right: _DialogTokens.horizontalPadding,
            top: _DialogTokens.topPadding,
            bottom: _DialogTokens.bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: _DialogTokens.iconBadgeSize,
                height: _DialogTokens.iconBadgeSize,
                decoration: BoxDecoration(
                  color: _badgeBackground,
                  borderRadius:
                      BorderRadius.circular(_DialogTokens.iconBadgeBorderRadius),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: _DialogTokens.iconSize,
                    color: _actionColor,
                  ),
                ),
              ),
              const SizedBox(height: _DialogTokens.iconBadgeBottomMargin),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: _DialogTokens.titleSize,
                  fontWeight: _DialogTokens.titleWeight,
                  color: _DialogTokens.titleColor,
                  letterSpacing: _DialogTokens.titleLetterSpacing,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: _DialogTokens.titleToBodyGap),

              // Body
              Text(
                body,
                style: const TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: _DialogTokens.bodySize,
                  fontWeight: _DialogTokens.bodyWeight,
                  color: _DialogTokens.bodyColor,
                  height: _DialogTokens.bodyLineHeight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),

              // Buttons
              Row(
                children: [
                  if (_showCancelButton) ...[
                    Expanded(
                      child: _DialogButton(
                        label: cancelLabel,
                        textColor: _DialogTokens.cancelColor,
                        backgroundColor: Colors.transparent,
                        fontWeight: _DialogTokens.cancelWeight,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    SizedBox(width: _DialogTokens.buttonGap),
                  ],
                  Expanded(
                    child: _DialogButton(
                      label: actionLabel,
                      textColor: _actionColor,
                      backgroundColor: _badgeBackground,
                      fontWeight: _DialogTokens.actionWeight,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.fontWeight,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.7 : 1.0,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius:
                BorderRadius.circular(_DialogTokens.buttonBorderRadius),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 15,
                fontWeight: widget.fontWeight,
                color: widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
