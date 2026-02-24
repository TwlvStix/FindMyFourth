import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_card.dart';
import '/core/widgets/vibe_toggle.dart';
import '/core/widgets/vibe_slider_theme.dart';
import '/models/vibe_profile.dart';

/// Clean, scannable vibe category slider used exclusively on Edit Vibes page
///
/// Design principles:
/// - One-line unique description per category (no repeated copy)
/// - Clean slider with clear endpoint labels
/// - Live selection badge shows current choice
/// - Minimal dealbreaker toggle (no verbose helper text)
class VibeCategorySlider extends StatefulWidget {
  const VibeCategorySlider({
    super.key,
    required this.category,
    required this.pref,
    required this.onValueChanged,
    required this.onDealbreakerChanged,
    this.onValueCommitted,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.margin,
  });

  final VibeCategory category;
  final VibePreference pref;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<bool> onDealbreakerChanged;
  final ValueChanged<int>? onValueCommitted;
  final Duration debounceDuration;
  final EdgeInsetsGeometry? margin;

  @override
  State<VibeCategorySlider> createState() => _VibeCategorySliderState();
}

class _VibeCategorySliderState extends State<VibeCategorySlider> {
  Timer? _debounceTimer;
  int? _pendingCommitValue;
  int _currentValue = VibePreference.defaultValue;
  bool _currentDealbreaker = false;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _syncFromPref();
  }

  @override
  void didUpdateWidget(VibeCategorySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pref.value != widget.pref.value ||
        oldWidget.pref.dealbreaker != widget.pref.dealbreaker) {
      _syncFromPref();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _syncFromPref() {
    _currentValue = widget.pref.value;
    _currentDealbreaker = widget.pref.dealbreaker;
  }

  void _scheduleValueUpdate(int value) {
    if (widget.onValueCommitted == null) {
      return;
    }
    _pendingCommitValue = value;
    _debounceTimer?.cancel();
    if (widget.debounceDuration == Duration.zero) {
      final pending = _pendingCommitValue;
      _pendingCommitValue = null;
      if (pending != null) {
        widget.onValueCommitted?.call(pending);
      }
      return;
    }
    _debounceTimer = Timer(widget.debounceDuration, () {
      final pending = _pendingCommitValue;
      _pendingCommitValue = null;
      _debounceTimer = null;
      if (pending != null) {
        widget.onValueCommitted?.call(pending);
      }
    });
  }

  void _flushValueUpdate(int value) {
    if (widget.onValueCommitted == null) {
      return;
    }
    if (_pendingCommitValue == null && _debounceTimer == null) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingCommitValue = null;
    widget.onValueCommitted?.call(value);
  }

  void _handleValueChanged(double raw) {
    final updatedValue = raw.round();
    if (updatedValue == _currentValue) {
      return;
    }
    _didChange = true;
    setState(() {
      _currentValue = updatedValue;
    });
    widget.onValueChanged(updatedValue);
    _scheduleValueUpdate(updatedValue);
  }

  void _handleValueChangeEnd(double raw) {
    final updatedValue = raw.round();
    if (!_didChange && widget.pref.isDefault) {
      widget.onValueChanged(updatedValue);
      widget.onValueCommitted?.call(updatedValue);
    } else {
      _flushValueUpdate(updatedValue);
    }
    _didChange = false;
  }

  void _handleDealbreakerChanged(bool value) {
    setState(() {
      _currentDealbreaker = value;
    });
    widget.onDealbreakerChanged(value);
  }

  void _showDealbreakerInfo(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDark.navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Row(
          children: [
            AppIcon(
              icon: AppPhosphorIcons.blocked,
              color: AppColorsDark.gold,
              size: AppIconSize.md,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Dealbreakers',
              style: AppTypography.titleMedium.copyWith(
                color: AppColorsDark.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "When you mark something as a dealbreaker, we'll warn you before you join a group with players who have very different preferences.",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColorsDark.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Use this for preferences that truly matter to your experience. It helps ensure you're matched with compatible groups.",
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsDark.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColorsDark.green,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = VibeLabels.titleFor(widget.category);
    final minLabel = _VibeCategoryConfig.minLabelFor(widget.category);
    final maxLabel = _VibeCategoryConfig.maxLabelFor(widget.category);
    final currentLabel = VibeLabels.labelFor(widget.category, _currentValue) ??
        _currentValue.toString();

    return AppCard(
      variant: AppCardVariant.darkSurface,
      margin: widget.margin,
      backgroundColor: AppColorsDark.navy.withValues(alpha: 0.4),
      borderColor: AppColorsDark.glassBorder,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (no description - cleaner)
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColorsDark.textPrimary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Animated current selection badge
          AnimatedSwitcher(
            duration: MotionTokens.microInteraction,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Container(
              key: ValueKey(currentLabel),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColorsDark.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                border: Border.all(
                  color: AppColorsDark.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                currentLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColorsDark.textPrimary,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Enhanced slider with custom theme (no divisions)
          SliderTheme(
            data: VibeSliderTheme.darkTheme,
            child: Slider(
              value: _currentValue.toDouble(),
              min: VibePreference.minValue.toDouble(),
              max: VibePreference.maxValue.toDouble(),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _handleValueChanged(value);
              },
              onChangeEnd: _handleValueChangeEnd,
            ),
          ),

          // Endpoint labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColorsDark.textMuted,
                  ),
                ),
                Text(
                  maxLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColorsDark.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Compact dealbreaker row with highlight when active
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _currentDealbreaker
                  ? AppColorsDark.gold.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              border: _currentDealbreaker
                  ? Border.all(
                      color: AppColorsDark.gold.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Dealbreaker',
                      style: AppTypography.labelLarge.copyWith(
                        color: _currentDealbreaker
                            ? AppColorsDark.gold
                            : AppColorsDark.textSecondary,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => _showDealbreakerInfo(context),
                      child: AppIcon(
                        icon: AppPhosphorIcons.info,
                        size: AppIconSize.sm,
                        color: AppColorsDark.textMuted,
                      ),
                    ),
                  ],
                ),
                VibeToggle(
                  value: _currentDealbreaker,
                  onChanged: _handleDealbreakerChanged,
                  activeColor: AppColorsDark.gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Configuration for category-specific copy
class _VibeCategoryConfig {
  /// Left endpoint label (prefer less/none)
  static String minLabelFor(VibeCategory category) {
    switch (category) {
      case VibeCategory.chat:
        return 'Quiet';
      case VibeCategory.music:
        return 'No music';
      case VibeCategory.drinking:
        return 'None';
      case VibeCategory.pace:
        return 'Relaxed';
      case VibeCategory.money:
        return 'None';
      case VibeCategory.competitive:
        return 'Casual';
    }
  }

  /// Right endpoint label (prefer more/love it)
  static String maxLabelFor(VibeCategory category) {
    switch (category) {
      case VibeCategory.chat:
        return 'Very social';
      case VibeCategory.music:
        return 'Always on';
      case VibeCategory.drinking:
        return 'Welcome';
      case VibeCategory.pace:
        return 'Fast';
      case VibeCategory.money:
        return 'Love it';
      case VibeCategory.competitive:
        return 'Intense';
    }
  }
}
