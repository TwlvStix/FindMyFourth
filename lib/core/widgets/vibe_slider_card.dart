import 'dart:async';

import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_card.dart';
import '/models/vibe_profile.dart';

class VibeSliderCard extends StatefulWidget {
  const VibeSliderCard({
    super.key,
    required this.category,
    required this.pref,
    required this.onValueChanged,
    required this.onDealbreakerChanged,
    this.onValueCommitted,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.margin,
    this.showAlternateHelper,
  });

  final VibeCategory category;
  final VibePreference pref;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<bool> onDealbreakerChanged;
  final ValueChanged<int>? onValueCommitted;
  final Duration debounceDuration;
  final EdgeInsetsGeometry? margin;
  final bool? showAlternateHelper;

  @override
  State<VibeSliderCard> createState() => _VibeSliderCardState();
}

class _VibeSliderCardState extends State<VibeSliderCard> {
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
  void didUpdateWidget(VibeSliderCard oldWidget) {
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
      // Mark as answered even if user kept the default value.
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

  @override
  Widget build(BuildContext context) {
    final title = VibeLabels.titleFor(widget.category);
    final meaning = VibeLabels.labelFor(widget.category, _currentValue) ??
        _currentValue.toString();
    final showAltHelper = widget.showAlternateHelper ??
        MediaQuery.sizeOf(context).width >= 380;

    return AppCard(
      variant: AppCardVariant.outlined,
      margin: widget.margin,
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onyx,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            VibeLabels.helperFor(widget.category),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.stone,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            meaning,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.navyDark,
              letterSpacing: AppTypography.letterSpacingNormal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.navy,
              inactiveTrackColor: AppColors.cloud,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
              trackHeight: 4,
              showValueIndicator: ShowValueIndicator.never,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
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
          _AnchorRow(category: widget.category),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dealbreaker for me',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onyx,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      "If someone's far from you here, we'll warn you (or block).",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.stone,
                      ),
                    ),
                    if (showAltHelper) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        "I won't join a group if we clash on this.",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                value: _currentDealbreaker,
                onChanged: _handleDealbreakerChanged,
                activeColor: AppColors.navy,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  const _AnchorRow({
    required this.category,
  });

  final VibeCategory category;

  @override
  Widget build(BuildContext context) {
    final anchors = <int, String>{
      0: VibeLabels.labelFor(category, 0) ?? '0',
      2: VibeLabels.labelFor(category, 2) ?? '2',
      3: VibeLabels.labelFor(category, 3) ?? '3',
      5: VibeLabels.labelFor(category, 5) ?? '5',
    };

    return Row(
      children: [
        _AnchorLabel(
          text: anchors[0] ?? '',
          alignment: Alignment.centerLeft,
          flex: 2,
        ),
        _AnchorLabel(
          text: anchors[2] ?? '',
          alignment: Alignment.center,
          flex: 1,
        ),
        _AnchorLabel(
          text: anchors[3] ?? '',
          alignment: Alignment.center,
          flex: 1,
        ),
        _AnchorLabel(
          text: anchors[5] ?? '',
          alignment: Alignment.centerRight,
          flex: 2,
        ),
      ],
    );
  }
}

class _AnchorLabel extends StatelessWidget {
  const _AnchorLabel({
    required this.text,
    required this.alignment,
    required this.flex,
  });

  final String text;
  final Alignment alignment;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.stone,
            letterSpacing: AppTypography.letterSpacingNormal,
          ),
        ),
      ),
    );
  }
}
