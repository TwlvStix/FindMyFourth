import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';

/// Visual variants for AppStatCard
enum AppStatCardVariant {
  /// Outlined horizontal card with light background
  /// Layout: [icon] [label] ............ [value]
  /// Used for: settings rows, profile stats on light backgrounds
  standard,

  /// Glass-morphic vertical card for dark backgrounds
  /// Layout: [icon]
  ///         [value]
  ///         [label]
  /// Used for: hero metrics on dark/gradient backgrounds
  glass,

  /// Minimal compact version for tight layouts
  /// Layout: [value]
  ///         [label]
  /// Used for: inline stats, compact displays, data grids
  compact,
}

/// Unified stat card component for displaying metrics
///
/// Replaces the duplicate StatCard implementations in app_card.dart and
/// premium_ui_patterns.dart with a single configurable component.
///
/// Example:
/// ```dart
/// // Standard horizontal stat (light background)
/// AppStatCard(
///   value: '24',
///   label: 'Games Played',
///   icon: AppPhosphorIcons.games,
///   variant: AppStatCardVariant.standard,
/// )
///
/// // Glass vertical stat (dark background)
/// AppStatCard(
///   value: '8.2',
///   label: 'Handicap',
///   icon: AppPhosphorIcons.golf,
///   variant: AppStatCardVariant.glass,
///   accentGlow: true,
/// )
///
/// // Compact inline stat
/// AppStatCard(
///   value: '156',
///   label: 'Friends',
///   variant: AppStatCardVariant.compact,
/// )
/// ```
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.variant = AppStatCardVariant.standard,
    this.valueStyle,
    this.accentGlow = false,
    this.onTap,
    this.iconGradient,
    this.isTextValue = false,
  });

  /// The primary stat value to display (e.g., "24", "8.2", "Gold")
  final String value;

  /// Label describing the stat (e.g., "Games Played", "Handicap")
  final String label;

  /// Optional icon to display with the stat
  final PhosphorIconData? icon;

  /// Visual variant controlling layout and styling
  final AppStatCardVariant variant;

  /// Optional override for value text style
  final TextStyle? valueStyle;

  /// Whether to add a subtle accent glow (glass variant only)
  final bool accentGlow;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Custom gradient for icon box (glass variant only)
  /// Defaults to green gradient if not specified
  final List<Color>? iconGradient;

  /// Use text styling instead of mono for the value (glass variant only)
  /// Set to true for text values like "Home Course" instead of numeric values
  final bool isTextValue;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppStatCardVariant.standard => _buildStandardVariant(),
      AppStatCardVariant.glass => _buildGlassVariant(),
      AppStatCardVariant.compact => _buildCompactVariant(),
    };
  }

  /// Outlined horizontal card with light background
  Widget _buildStandardVariant() {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: AppColors.mist,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    AppIcon(
                      icon: icon,
                      color: AppColors.navy,
                      size: AppIconSize.button,
                    ),
                    AppSpacing.horizontalSmBox,
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.withColor(AppColors.slate),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalSmBox,
            Text(
              value,
              style: valueStyle ??
                  AppTypography.monoLarge.withColor(AppColors.navyDark),
            ),
          ],
        ),
      ),
    );
  }

  /// Glass-morphic vertical card for dark backgrounds
  Widget _buildGlassVariant() {
    final effectiveValueStyle = valueStyle ??
        (isTextValue
            ? AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
              )
            : AppTypography.monoLarge.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
              ));

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.navyLight.withValues(alpha: 0.2),
          ),
          boxShadow: accentGlow ? [AppElevation.glowGold] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              _GlassIconBox(icon: icon!, gradient: iconGradient),
              SizedBox(height: AppSpacing.xs),
            ],
            Text(
              value,
              style: effectiveValueStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.60),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Minimal compact version for tight layouts
  Widget _buildCompactVariant() {
    final effectiveValueStyle = valueStyle ??
        AppTypography.monoLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: effectiveValueStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Internal gradient icon box for glass variant
/// Matches the GradientIconBox style from premium_ui_patterns.dart
class _GlassIconBox extends StatelessWidget {
  const _GlassIconBox({
    required this.icon,
    this.gradient,
  });

  final PhosphorIconData icon;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? [AppColors.green, AppColors.greenLight];
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: effectiveGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: AppIcon(
          icon: icon,
          size: 14,
          color: AppColors.pure,
        ),
      ),
    );
  }
}
