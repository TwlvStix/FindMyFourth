import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/app_phosphor_icons.dart';
import 'package:find_my_fourth/core/design_tokens/colors.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';
import 'package:find_my_fourth/core/design_tokens/icon_size.dart';
import 'package:find_my_fourth/core/widgets/app_icon.dart';
import 'package:find_my_fourth/utils/vibe_archetypes.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/styles/premium_vibe_page_styles.dart';

/// Side-by-side archetype comparison showing "You" vs "Them".
///
/// Displays vibe style archetypes in a compact, understated format.
/// The identity pairing gives context without over-explaining.
class ArchetypePairingCard extends StatelessWidget {
  const ArchetypePairingCard({
    super.key,
    required this.myArchetype,
    required this.theirArchetype,
  });

  /// Current user's archetype classification
  final VibeArchetypeMatch myArchetype;

  /// Matched user's archetype classification
  final VibeArchetypeMatch theirArchetype;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PremiumVibePageStyles.sectionPaddingMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vibe styles',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "You" archetype card
              Expanded(
                child: _buildArchetypeCard(
                  label: 'You',
                  archetype: myArchetype,
                  decoration: PremiumVibePageStyles.archetypeCardPrimary,
                  nameColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // "Them" archetype card
              Expanded(
                child: _buildArchetypeCard(
                  label: 'Them',
                  archetype: theirArchetype,
                  decoration: PremiumVibePageStyles.archetypeCardSecondary,
                  nameColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchetypeCard({
    required String label,
    required VibeArchetypeMatch archetype,
    required BoxDecoration decoration,
    required Color nameColor,
  }) {
    return _ExpandableArchetypeCard(
      label: label,
      archetype: archetype,
      decoration: decoration,
      nameColor: nameColor,
    );
  }
}

/// Individual archetype card with tap-to-expand functionality.
///
/// Cards have a min-height and show a fade gradient when content overflows.
/// Tapping expands the card to show full content. Each card expands independently.
class _ExpandableArchetypeCard extends StatefulWidget {
  const _ExpandableArchetypeCard({
    required this.label,
    required this.archetype,
    required this.decoration,
    required this.nameColor,
  });

  final String label;
  final VibeArchetypeMatch archetype;
  final BoxDecoration decoration;
  final Color nameColor;

  @override
  State<_ExpandableArchetypeCard> createState() =>
      _ExpandableArchetypeCardState();
}

class _ExpandableArchetypeCardState extends State<_ExpandableArchetypeCard> {
  static const double _minHeight = 190.0;
  static const double _fadeHeight = 25.0;
  static const double _cardPadding = 12.0; // AppSpacing.sm

  bool _isExpanded = false;
  bool _hasOverflow = false;
  double _lastKnownWidth = 0;

  @override
  void didUpdateWidget(_ExpandableArchetypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.archetype.description != widget.archetype.description) {
      // Re-measure after next frame when archetype changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastKnownWidth > 0) {
          _measureOverflow(_lastKnownWidth);
        }
      });
    }
  }

  /// Measures whether the description text overflows the available space.
  void _measureOverflow(double availableWidth) {
    final textScaleFactor = MediaQuery.textScalerOf(context);

    // Text styles matching what's used in build()
    final labelStyle = AppTypography.labelSmall.copyWith(
      color: AppColors.textMuted,
      letterSpacing: AppTypography.letterSpacingNormal,
    );
    final nameStyle = AppTypography.bodyMedium.copyWith(
      color: widget.nameColor,
      fontWeight: AppTypography.semiBold,
    );
    final descriptionStyle = AppTypography.labelSmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.4,
    );

    // Measure header elements
    final labelPainter = TextPainter(
      text: TextSpan(text: widget.label, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaleFactor,
    )..layout(maxWidth: availableWidth);

    final namePainter = TextPainter(
      text: TextSpan(text: widget.archetype.name, style: nameStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaleFactor,
    )..layout(maxWidth: availableWidth);

    // Calculate header height (label + spacing + name + optional base + spacing)
    double headerHeight = labelPainter.height + 4.0 + namePainter.height;

    // Add base archetype line if applicable
    if (widget.archetype.isWarden && widget.archetype.baseArchetype != null) {
      final baseStyle = AppTypography.labelSmall.copyWith(
        color: widget.nameColor.withValues(alpha: 0.6),
        fontWeight: AppTypography.semiBold,
      );
      final basePainter = TextPainter(
        text: TextSpan(
            text: '(${widget.archetype.baseArchetype!.name})', style: baseStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaleFactor,
      )..layout(maxWidth: availableWidth);
      headerHeight += basePainter.height;
    }

    headerHeight += 4.0; // spacing before description

    // Available height for description = minHeight - padding - header - fadeHeight
    final availableHeight =
        _minHeight - (2 * _cardPadding) - headerHeight - _fadeHeight;

    // Measure description
    final descriptionPainter = TextPainter(
      text: TextSpan(text: widget.archetype.description, style: descriptionStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaleFactor,
    )..layout(maxWidth: availableWidth);

    final hasOverflow = descriptionPainter.height > availableHeight;

    if (hasOverflow != _hasOverflow) {
      setState(() => _hasOverflow = hasOverflow);
    }
  }

  void _handleTap() {
    if (_hasOverflow) {
      setState(() => _isExpanded = !_isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: widget.decoration,
        padding: PremiumVibePageStyles.archetypeCardPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Measure overflow on layout
            if (constraints.maxWidth != _lastKnownWidth) {
              _lastKnownWidth = constraints.maxWidth;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _measureOverflow(constraints.maxWidth);
              });
            }

            return AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: _minHeight,
                  maxHeight: _isExpanded ? double.infinity : _minHeight,
                ),
                child: Stack(
                  children: [
                    // Main card content
                    SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Label (You/Them)
                          Text(
                            widget.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              letterSpacing: AppTypography.letterSpacingNormal,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),

                          // Archetype name
                          Text(
                            widget.archetype.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: widget.nameColor,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          if (widget.archetype.isWarden &&
                              widget.archetype.baseArchetype != null)
                            Text(
                              '(${widget.archetype.baseArchetype!.name})',
                              style: AppTypography.labelSmall.copyWith(
                                color: widget.nameColor.withValues(alpha: 0.6),
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xxs),

                          // Archetype description
                          Text(
                            widget.archetype.description,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fade gradient overlay with expand indicator (only if overflows)
                    if (_hasOverflow && !_isExpanded)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _fadeHeight,
                        child: IgnorePointer(
                          child: Stack(
                            children: [
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _getBackgroundColor().withValues(alpha: 0.0),
                                      _getBackgroundColor(),
                                    ],
                                  ),
                                ),
                              ),
                              // Subtle expand indicator
                              Positioned(
                                right: 4,
                                bottom: 2,
                                child: AppIcon(
                                  icon: AppPhosphorIcons.expandMore,
                                  size: AppIconSize.xs,
                                  color: AppColors.stone.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Collapse indicator (only if overflows and expanded)
                    if (_hasOverflow && _isExpanded)
                      Positioned(
                        right: 4,
                        bottom: 2,
                        child: IgnorePointer(
                          child: AppIcon(
                            icon: AppPhosphorIcons.expandLess,
                            size: AppIconSize.xs,
                            color: AppColors.stone.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Extracts background color from decoration for gradient overlay
  Color _getBackgroundColor() {
    if (widget.decoration.color != null) {
      return widget.decoration.color!;
    }
    // Fallback to navy if no color specified (dark theme)
    return AppColors.navy;
  }
}
