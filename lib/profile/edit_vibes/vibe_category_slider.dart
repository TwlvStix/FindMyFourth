import 'dart:async';

import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_card.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.sand,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.block_rounded,
              color: AppColors.fairway,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Dealbreakers',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onyx,
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
                color: AppColors.onyx,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Use this for preferences that truly matter to your experience. It helps ensure you're matched with compatible groups.",
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.stone,
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
                color: AppColors.fairway,
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
    final description = _VibeCategoryConfig.descriptionFor(widget.category);
    final minLabel = _VibeCategoryConfig.minLabelFor(widget.category);
    final maxLabel = _VibeCategoryConfig.maxLabelFor(widget.category);
    final currentLabel = VibeLabels.labelFor(widget.category, _currentValue) ??
        _currentValue.toString();

    return AppCard(
      variant: AppCardVariant.outlined,
      margin: widget.margin,
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onyx,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // One-line description (unique per category)
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.stone,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Current selection badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.fairwayLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.fairway.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              currentLabel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.fairwayDark,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.fairway,
              inactiveTrackColor: AppColors.cloud,
              thumbColor: AppColors.sunsetGold,
              overlayColor: AppColors.sunsetGold.withValues(alpha: 0.2),
              trackHeight: 5,
              showValueIndicator: ShowValueIndicator.never,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10,
              ),
            ),
            child: Slider(
              value: _currentValue.toDouble(),
              min: VibePreference.minValue.toDouble(),
              max: VibePreference.maxValue.toDouble(),
              divisions: VibePreference.maxValue - VibePreference.minValue,
              onChanged: _handleValueChanged,
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
                    color: AppColors.stone,
                  ),
                ),
                Text(
                  maxLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.stone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Dealbreaker toggle with info icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Dealbreaker for me',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onyx,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => _showDealbreakerInfo(context),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.stone,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _currentDealbreaker,
                onChanged: _handleDealbreakerChanged,
                activeColor: AppColors.fairway,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Configuration for category-specific copy
class _VibeCategoryConfig {
  /// Unique one-line description per category
  static String descriptionFor(VibeCategory category) {
    switch (category) {
      case VibeCategory.chat:
        return 'Set your preferred conversation level';
      case VibeCategory.music:
        return 'Set your music preference';
      case VibeCategory.drinking:
        return 'Set your alcohol comfort level';
      case VibeCategory.weed:
        return 'Set your cannabis comfort level';
      case VibeCategory.pace:
        return 'Set your preferred pace';
      case VibeCategory.money:
        return 'Set your gambling preference';
      case VibeCategory.competitive:
        return 'Set your competitive intensity';
    }
  }

  /// Left endpoint label (prefer less/none)
  static String minLabelFor(VibeCategory category) {
    switch (category) {
      case VibeCategory.chat:
        return 'Quiet';
      case VibeCategory.music:
        return 'No music';
      case VibeCategory.drinking:
        return 'None';
      case VibeCategory.weed:
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
      case VibeCategory.weed:
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
