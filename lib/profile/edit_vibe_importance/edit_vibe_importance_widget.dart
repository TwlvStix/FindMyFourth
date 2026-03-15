import 'package:flutter/material.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/app_log.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_labels.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_repository.dart';

class EditVibeImportanceWidget extends StatefulWidget {
  const EditVibeImportanceWidget({super.key});

  static String routeName = 'EditVibeImportance';
  static String routePath = '/editVibeImportance';

  @override
  State<EditVibeImportanceWidget> createState() =>
      _EditVibeImportanceWidgetState();
}

class _EditVibeImportanceWidgetState extends State<EditVibeImportanceWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _repository = VibeRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  VibeProfile _profile = VibeProfile.defaults();
  Map<VibeCategory, VibeImportance> _importance = {
    for (final category in VibeCategory.values) category: VibeImportance.normal,
  };

  /// Order for the priority selection grid — heaviest weights first
  /// so users see the most impactful categories at the top.
  static const List<VibeCategory> _priorityGridOrder = [
    VibeCategory.pace,
    VibeCategory.competitive,
    VibeCategory.drinking,
    VibeCategory.chat,
    VibeCategory.money,
    VibeCategory.music,
  ];

  static const List<VibeCategory> _categories = [
    VibeCategory.chat,
    VibeCategory.music,
    VibeCategory.drinking,
    VibeCategory.pace,
    VibeCategory.money,
    VibeCategory.competitive,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.getMyVibesCached(forceRefresh: true);
      if (!mounted) {
        return;
      }
      updateState(this, () {
        _profile = profile;
        _importance =
            Map<VibeCategory, VibeImportance>.from(profile.importance);
        _isLoading = false;
      });
      // Auto-infer priorities if user hasn't set 2 yet
      if (_topCount < 2) {
        _initializePrioritiesFromDealbreakers();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      updateState(this, () {
        _isLoading = false;
      });
    }
  }

  int get _topCount =>
      _importance.values.where((value) => value == VibeImportance.top).length;

  /// Pre-selects categories with dealbreakers as top priorities.
  /// Respects the max of 2 top priorities — if more than 2 dealbreakers
  /// exist, only the first 2 (by grid order) are pre-selected.
  void _initializePrioritiesFromDealbreakers() {
    final updated = Map<VibeCategory, VibeImportance>.from(_importance);
    var topCount = updated.values.where((v) => v == VibeImportance.top).length;

    for (final category in _priorityGridOrder) {
      if (topCount >= 2) break;
      final pref = _profile.preferenceFor(category);
      if (pref.dealbreaker && updated[category] != VibeImportance.top) {
        updated[category] = VibeImportance.top;
        topCount++;
      }
    }

    // If still < 2, infer from slider distance
    if (topCount < 2) {
      _autoInferImportance();
      return;
    }

    if (updated != _importance) {
      updateState(this, () {
        _importance = updated;
      });
    }
  }

  /// Auto-infer top 2 priorities from dealbreakers first, then slider positions.
  /// Dealbreaker categories always take priority over distance-from-center.
  void _autoInferImportance() {
    final center = (VibePreference.minValue + VibePreference.maxValue) / 2;
    final distances = <VibeCategory, double>{};
    final dealbreakers = <VibeCategory>[];

    for (final category in _categories) {
      final pref = _profile.preferenceFor(category);
      distances[category] = (pref.value - center).abs();
      if (pref.dealbreaker) {
        dealbreakers.add(category);
      }
    }

    // Sort dealbreakers by their position in the grid order
    dealbreakers.sort((a, b) =>
        _priorityGridOrder.indexOf(a).compareTo(_priorityGridOrder.indexOf(b)));

    // Sort non-dealbreaker categories by distance descending
    final nonDealbreakers = _categories
        .where((c) => !dealbreakers.contains(c))
        .toList()
      ..sort((a, b) => (distances[b] ?? 0).compareTo(distances[a] ?? 0));

    // Build priority list: dealbreakers first (by grid order), then by distance
    final priorityOrder = [...dealbreakers, ...nonDealbreakers];

    final inferred = Map<VibeCategory, VibeImportance>.from(_importance);
    for (final category in _categories) {
      inferred[category] = VibeImportance.normal;
    }

    // Assign top 2
    for (var i = 0; i < 2 && i < priorityOrder.length; i++) {
      inferred[priorityOrder[i]] = VibeImportance.top;
    }

    updateState(this, () {
      _importance = inferred;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setImportance(VibeCategory category) {
    final current = _importance[category] ?? VibeImportance.normal;

    if (current == VibeImportance.top) {
      // Tapping a selected card deselects it
      updateState(this, () {
        _importance = Map<VibeCategory, VibeImportance>.from(_importance)
          ..[category] = VibeImportance.normal;
      });
      HapticFeedback.selectionClick();
      return;
    }

    // If already have 2 top, deselect the oldest one to make room
    if (_topCount >= 2) {
      final firstTop = _categories.firstWhere(
        (c) => c != category && _importance[c] == VibeImportance.top,
        orElse: () => category,
      );
      updateState(this, () {
        final updated = Map<VibeCategory, VibeImportance>.from(_importance);
        if (firstTop != category) {
          updated[firstTop] = VibeImportance.normal;
        }
        updated[category] = VibeImportance.top;
        _importance = updated;
      });
    } else {
      updateState(this, () {
        _importance = Map<VibeCategory, VibeImportance>.from(_importance)
          ..[category] = VibeImportance.top;
      });
    }
    HapticFeedback.selectionClick();
  }

  void _clearImportance() {
    if (_isSaving) {
      return;
    }
    updateState(this, () {
      _importance = {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
      };
    });
  }

  Future<void> _saveImportance() async {
    if (_isSaving) {
      return;
    }
    if (_topCount != 2) {
      _showSnack('Pick exactly 2 top priorities.');
      return;
    }
    if (currentUserUid.isEmpty) {
      _showSnack('Please sign in to save priorities.');
      return;
    }
    updateState(this, () {
      _isSaving = true;
    });
    try {
      await _repository.updateImportance(_importance);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on FirebaseException catch (error, stackTrace) {
      AppLog.d('Failed to save vibe priorities: ${error.code}');
      AppLog.d('Stack trace: $stackTrace');
      if (!mounted) {
        return;
      }
      final message = error.code == 'permission-denied'
          ? 'Unable to save priorities. Permission denied.'
          : 'Unable to save priorities. Please try again.';
      _showSnack(message);
      updateState(this, () {
        _isSaving = false;
      });
    } catch (error, stackTrace) {
      AppLog.d('Failed to save vibe priorities: $error');
      AppLog.d('Stack trace: $stackTrace');
      if (!mounted) {
        return;
      }
      _showSnack('Unable to save priorities. Please try again.');
      updateState(this, () {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: const PremiumBackButton(),
        title: AppText.sectionHeader(
          'Vibe Priorities',
          color: AppColors.pure,
        ),
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: false,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.pure,
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      MediaQuery.of(context).padding.top + 56 + AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What matters most to your round?',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.pure,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Pick the 2 that you care about most. We'll weigh them heavier when matching you.",
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.sand,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildCountPill(
                          label: 'Selected',
                          count: _topCount,
                          max: 2,
                          color: AppColors.green,
                          background:
                              AppColors.green.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPriorityGrid(),
                        const SizedBox(height: AppSpacing.md),
                        if (_topCount < 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              "Can't decide? No worries — we'll figure it out from your preferences.",
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.stone,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButtonEnhanced(
                                text: 'Clear',
                                variant: AppButtonVariant.secondary,
                                size: AppButtonSize.large,
                                fullWidth: true,
                                enabled: !_isSaving,
                                onPressed: _clearImportance,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButtonEnhanced(
                                text: 'Save priorities',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.large,
                                fullWidth: true,
                                isLoading: _isSaving,
                                onPressed: _saveImportance,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCountPill({
    required String label,
    required int count,
    required int max,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.pure,
              letterSpacing: AppTypography.letterSpacingNormal,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count/$max',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.sand,
              letterSpacing: AppTypography.letterSpacingNormal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityGrid() {
    // Build pairs for 2-column layout using priority order
    final List<Widget> rows = [];
    for (var i = 0; i < _priorityGridOrder.length; i += 2) {
      final first = _priorityGridOrder[i];
      final second =
          i + 1 < _priorityGridOrder.length ? _priorityGridOrder[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: _buildPriorityCard(first),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (second != null)
                Expanded(
                  child: _buildPriorityCard(second),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildPriorityCard(VibeCategory category) {
    final isSelected = _importance[category] == VibeImportance.top;
    final isDealbreaker = _profile.preferenceFor(category).dealbreaker;
    final title = _categoryTitles[category] ?? VibeLabels.titleFor(category);
    final value = _profile.preferenceFor(category).value;
    final valueLabel = _shortValueLabel(category, value);

    return GestureDetector(
      onTap: () => _setImportance(category),
      child: AnimatedContainer(
        duration: MotionTokens.contentReveal,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.green.withValues(alpha: 0.15)
              : AppColors.navyLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.pure
                          : AppColors.sand,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
                if (isSelected)
                  AppIcon(
                    icon: AppPhosphorIcons.success,
                    color: AppColors.green,
                    size: AppIconSize.sm,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.green.withValues(alpha: 0.1)
                    : AppColors.navyLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Text(
                valueLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.pure
                      : AppColors.stone,
                  letterSpacing: AppTypography.letterSpacingNormal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Dealbreaker badge — shown when user set a dealbreaker
            if (isDealbreaker) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.blocked,
                    color: AppColors.gold,
                    size: AppIconSize.xs,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dealbreaker',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Short label summarizing the user's chosen value for display on priority cards.
  /// Uses the short endpoint-style labels, not the full sentence descriptions.
  String _shortValueLabel(VibeCategory category, int value) {
    // Map to short descriptors
    const labels = <VibeCategory, Map<int, String>>{
      VibeCategory.pace: {
        0: 'Very relaxed',
        1: 'Easygoing',
        2: 'Reasonable',
        3: 'Steady',
        4: 'Fast',
        5: 'Very fast',
      },
      VibeCategory.competitive: {
        0: 'Very casual',
        1: 'Light',
        2: 'Friendly',
        3: 'Structured',
        4: 'Highly competitive',
        5: 'Tournament intensity',
      },
      VibeCategory.drinking: {
        0: 'None',
        1: 'Very limited',
        2: 'Occasional',
        3: 'A couple is fine',
        4: 'Regular',
        5: 'Love it',
      },
      VibeCategory.chat: {
        0: 'Very quiet',
        1: 'Mostly quiet',
        2: 'Light chat',
        3: 'Balanced',
        4: 'Very social',
        5: 'Constant',
      },
      VibeCategory.money: {
        0: 'None',
        1: 'Very low stakes',
        2: 'Occasional',
        3: 'Casual games',
        4: 'Regular action',
        5: 'Love gambling',
      },
      VibeCategory.music: {
        0: 'Silence',
        1: 'Rare, low volume',
        2: 'Occasional',
        3: 'Usually fine',
        4: 'Most of the round',
        5: 'Always on',
      },
    };

    return labels[category]?[value] ?? 'Set';
  }

  static const Map<VibeCategory, String> _categoryTitles = {
    VibeCategory.pace: 'Pace of play',
    VibeCategory.competitive: 'Competition vibe',
    VibeCategory.chat: 'Chat level',
    VibeCategory.music: 'Music',
    VibeCategory.drinking: 'Drinking',
    VibeCategory.money: 'Money / stakes',
  };
}
