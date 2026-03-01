import 'dart:async';
import '/core/utils/state_update.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/motion/motion_tokens.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_card.dart';
import '/core/widgets/vibe_slider_theme.dart';
import '/models/vibe_profile.dart';

/// Clean, scannable vibe category slider used on Edit Vibes and Onboarding
///
/// Design principles:
/// - One-line unique description per category (no repeated copy)
/// - Clean slider with clear endpoint labels
/// - Live selection badge shows current choice
/// - Smart dealbreaker prompt only at extreme values (0 or 5)
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
  Timer? _dealbreakerPromptTimer;
  int? _pendingCommitValue;
  int _currentValue = VibePreference.defaultValue;
  bool _currentDealbreaker = false;
  bool _didChange = false;
  bool _showDealbreakerPrompt = false;
  bool _dealbreakerConfirmed = false;

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
    _dealbreakerPromptTimer?.cancel();
    super.dispose();
  }

  void _syncFromPref() {
    _currentValue = widget.pref.value;
    _currentDealbreaker = widget.pref.dealbreaker;
    // If loading a profile that already has a dealbreaker at an extreme,
    // mark it as confirmed so we don't re-prompt
    _dealbreakerConfirmed = widget.pref.dealbreaker &&
        (_currentValue == VibePreference.minValue ||
            _currentValue == VibePreference.maxValue);
  }

  /// Check if the current value is an extreme (0 or 5)
  bool get _isExtremeValue =>
      _currentValue == VibePreference.minValue ||
      _currentValue == VibePreference.maxValue;

  /// Called after slider value changes. Starts or cancels the prompt timer.
  void _evaluateDealbreakerPrompt() {
    _dealbreakerPromptTimer?.cancel();

    if (_isExtremeValue) {
      // If already confirmed as dealbreaker at this extreme, don't re-prompt
      if (_dealbreakerConfirmed && _currentDealbreaker) return;

      // Wait 400ms before showing prompt (user might still be sliding)
      _dealbreakerPromptTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted && _isExtremeValue) {
          updateState(this, () {
            _showDealbreakerPrompt = true;
          });
        }
      });
    } else {
      // Moved away from extreme — hide prompt and clear dealbreaker
      if (_showDealbreakerPrompt || _currentDealbreaker) {
        updateState(this, () {
          _showDealbreakerPrompt = false;
          _dealbreakerConfirmed = false;
        });
        if (_currentDealbreaker) {
          _currentDealbreaker = false;
          widget.onDealbreakerChanged(false);
        }
      }
    }
  }

  /// User tapped "Yes, it's a must"
  void _confirmDealbreaker() {
    HapticFeedback.mediumImpact();
    updateState(this, () {
      _currentDealbreaker = true;
      _dealbreakerConfirmed = true;
      _showDealbreakerPrompt = false;
    });
    widget.onDealbreakerChanged(true);
  }

  /// User tapped "No, just a preference"
  void _declineDealbreaker() {
    updateState(this, () {
      _showDealbreakerPrompt = false;
      _dealbreakerConfirmed = false;
      _currentDealbreaker = false;
    });
    widget.onDealbreakerChanged(false);
  }

  /// Inline prompt asking if this extreme preference is a dealbreaker
  Widget _buildDealbreakerPrompt() {
    final category = widget.category;
    final isMin = _currentValue == VibePreference.minValue;
    final promptText = _dealbreakerPromptText(category, isMin);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColorsDark.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: AppColorsDark.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promptText,
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsDark.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButtonEnhanced(
                  text: "Yes, it's a must",
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                  onPressed: _confirmDealbreaker,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppButtonEnhanced(
                  text: 'No, just a preference',
                  variant: AppButtonVariant.ghostDark,
                  size: AppButtonSize.small,
                  onPressed: _declineDealbreaker,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Compact badge shown after user confirms a dealbreaker
  Widget _buildDealbreakerBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColorsDark.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: AppColorsDark.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.blocked,
              color: AppColorsDark.gold,
              size: AppIconSize.sm,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Dealbreaker set',
              style: AppTypography.labelMedium.copyWith(
                color: AppColorsDark.gold,
                fontWeight: AppTypography.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Context-aware prompt text based on category and slider position
  String _dealbreakerPromptText(VibeCategory category, bool isMin) {
    switch (category) {
      case VibeCategory.drinking:
        return isMin
            ? 'You strongly prefer no drinking around you. Is this a dealbreaker?'
            : 'You love a group that drinks. Is this a dealbreaker?';
      case VibeCategory.music:
        return isMin
            ? 'You prefer no music on the course. Is this a dealbreaker?'
            : 'Music is a big part of your round. Is this a dealbreaker?';
      case VibeCategory.chat:
        return isMin
            ? 'You prefer a very quiet round. Is this a dealbreaker?'
            : 'You love a talkative group. Is this a dealbreaker?';
      case VibeCategory.pace:
        return isMin
            ? 'You prefer a very relaxed pace. Is this a dealbreaker?'
            : 'You need a fast-paced round. Is this a dealbreaker?';
      case VibeCategory.money:
        return isMin
            ? 'You prefer no gambling or side games. Is this a dealbreaker?'
            : 'You love having money on the line. Is this a dealbreaker?';
      case VibeCategory.competitive:
        return isMin
            ? 'You prefer zero competitive pressure. Is this a dealbreaker?'
            : 'You play at tournament-level intensity. Is this a dealbreaker?';
    }
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
    updateState(this, () {
      _currentValue = updatedValue;
    });
    widget.onValueChanged(updatedValue);
    _scheduleValueUpdate(updatedValue);
    _evaluateDealbreakerPrompt();
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
    _evaluateDealbreakerPrompt();
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
          // Smart dealbreaker prompt — only appears at extreme values (0 or 5)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showDealbreakerPrompt
                ? _buildDealbreakerPrompt()
                : _dealbreakerConfirmed && _currentDealbreaker
                    ? _buildDealbreakerBadge()
                    : const SizedBox.shrink(),
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
