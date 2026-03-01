import '/core/design_tokens/border_radius.dart';
import '/core/utils/state_update.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
import 'package:flutter/services.dart';
import '/models/vibe_profile.dart';
import '/profile/edit_vibes/vibe_category_slider.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';
import '/utils/vibe_archetypes.dart';
import 'package:flutter/material.dart';

class VibeOnboardingWidget extends StatefulWidget {
  const VibeOnboardingWidget({super.key});

  static String routeName = 'VibeOnboarding';
  static String routePath = '/vibeOnboarding';

  @override
  State<VibeOnboardingWidget> createState() => _VibeOnboardingWidgetState();
}

class _VibeOnboardingWidgetState extends State<VibeOnboardingWidget> {
  final PageController _pageController = PageController();
  final VibeRepository _repository = VibeRepository();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final List<VibeCategory> _categories = const [
    VibeCategory.chat,
    VibeCategory.music,
    VibeCategory.drinking,
    VibeCategory.pace,
    VibeCategory.money,
    VibeCategory.competitive,
  ];

  /// Order for the priority selection grid — heaviest weights first
  /// so users see the most impactful categories at the top.
  final List<VibeCategory> _priorityGridOrder = const [
    VibeCategory.pace,
    VibeCategory.competitive,
    VibeCategory.drinking,
    VibeCategory.chat,
    VibeCategory.money,
    VibeCategory.music,
  ];

  VibeProfile _profile = VibeProfile.defaults();
  Map<VibeCategory, VibeImportance> _importance = {
    for (final category in VibeCategory.values) category: VibeImportance.normal,
  };
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isCompleting = false;
  bool _archetypeExpanded = false;

  int get _topCount =>
      _importance.values.where((value) => value == VibeImportance.top).length;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    updateState(this, () {
      _isLoading = true;
    });
    try {
      final profile = await _repository.getMyVibesCached(forceRefresh: true);
      if (!mounted) {
        return;
      }
      updateState(this, () {
        _profile = profile;
        _importance =
            Map<VibeCategory, VibeImportance>.from(profile.importance);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        updateState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  void _updateLocalPreference(
    VibeCategory category,
    VibePreference preference,
  ) {
    final updatedPrefs = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updatedPrefs[category] = preference;
    updateState(this, () {
      _profile = _profile.copyWith(prefs: updatedPrefs);
    });
  }

  void _handleValueChanged(
    VibeCategory category,
    int value,
  ) {
    final current = _profile.preferenceFor(category);
    _updateLocalPreference(
      category,
      current.copyWith(value: value, isDefault: false),
    );
  }

  Future<void> _commitValueChanged(
    VibeCategory category,
    int value,
  ) async {
    try {
      await _repository.updateCategory(category, value);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to update vibe. Please try again.');
    }
  }

  Future<void> _handleDealbreakerChanged(
    VibeCategory category,
    bool value,
  ) async {
    final current = _profile.preferenceFor(category);
    _updateLocalPreference(
      category,
      current.copyWith(dealbreaker: value, isDefault: false),
    );
    try {
      await _repository.toggleDealbreaker(category, value);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to update dealbreaker. Please try again.');
    }
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

  /// Pre-selects categories with dealbreakers as top priorities.
  /// Called when the priorities page first becomes visible.
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

    if (updated != _importance) {
      updateState(this, () {
        _importance = updated;
      });
    }
  }

  void _nextStep() {
    // Total pages = 7 categories + 1 priorities page
    if (_currentIndex < _categories.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }

    // If user hasn't picked 2 top priorities, auto-infer
    if (_topCount < 2) {
      _autoInferImportance();
    }

    updateState(this, () {
      _isCompleting = true;
    });
    try {
      await _repository.updateImportance(_importance);
      await _repository.confirmVibes(profile: _profile);
      _goToNext();
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to finish setup. Please try again.');
    } finally {
      if (mounted) {
        updateState(this, () {
          _isCompleting = false;
        });
      }
    }
  }

  void _goToNext() {
    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    if (nextRoute != null && nextRoute.isNotEmpty) {
      context.goWithTransition(
        nextRoute,
        transition: TransitionStandards.modalTransition,
      );
    } else {
      context.goMainProfile(
        transition: TransitionStandards.modalTransition,
      );
    }
  }

  Widget _buildPrioritiesPage() {
    final archetypeMatch = VibeArchetypes.classifyProfile(_profile);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vibe Archetype Display - tap to expand description
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              updateState(this, () => _archetypeExpanded = !_archetypeExpanded);
            },
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              opacity: 0.25,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColorsDark.navyLight,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(
                        color: AppColorsDark.glassBorder,
                      ),
                    ),
                    child: Center(
                      child: AppIcon(
                        icon: AppPhosphorIcons.trophy,
                        size: AppIconSize.md,
                        color: AppColorsDark.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your vibe style',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColorsDark.textMuted,
                            letterSpacing: AppTypography.letterSpacingWide,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          archetypeMatch.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColorsDark.textPrimary,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        if (archetypeMatch.isWarden &&
                            archetypeMatch.baseArchetype != null) ...[
                          Text(
                            '(${archetypeMatch.baseArchetype!.name})',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColorsDark.textPrimary
                                  .withValues(alpha: 0.6),
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxs),
                        AnimatedCrossFade(
                          duration: MotionTokens.microInteraction,
                          crossFadeState: _archetypeExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: Text(
                            archetypeMatch.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            archetypeMatch.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColorsDark.textSecondary,
                            ),
                          ),
                        ),
                        if (!_archetypeExpanded) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Tap to read more',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColorsDark.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header — scenario-based framing
          Text(
            'What matters most to your round?',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColorsDark.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick the 2 that you care about most. We\'ll weigh them heavier when matching you.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColorsDark.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Selection count indicator (single pill, no Row wrapper)
          _buildCountPill(
            label: 'Selected',
            count: _topCount,
            max: 2,
            color: AppColorsDark.green,
            background: AppColorsDark.green.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2-column grid of category cards
          _buildPriorityGrid(),

          const SizedBox(height: AppSpacing.md),

          // Soft nudge if they haven't picked 2 yet
          if (_topCount < 2)
            Text(
              "Can't decide? No worries — we'll figure it out from your preferences.",
              style: AppTypography.bodySmall.copyWith(
                color: AppColorsDark.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),
        ],
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
              color: AppColorsDark.textPrimary,
              letterSpacing: AppTypography.letterSpacingNormal,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count/$max',
            style: AppTypography.labelSmall.copyWith(
              color: AppColorsDark.textSecondary,
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
              ? AppColorsDark.green.withValues(alpha: 0.15)
              : AppColorsDark.navyLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected ? AppColorsDark.green : AppColorsDark.glassBorder,
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
                          ? AppColorsDark.textPrimary
                          : AppColorsDark.textSecondary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
                if (isSelected)
                  AppIcon(
                    icon: AppPhosphorIcons.success,
                    color: AppColorsDark.green,
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
                    ? AppColorsDark.green.withValues(alpha: 0.1)
                    : AppColorsDark.navyLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Text(
                valueLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColorsDark.textPrimary
                      : AppColorsDark.textMuted,
                  letterSpacing: AppTypography.letterSpacingNormal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Dealbreaker badge — shown when user set a dealbreaker on slider page
            if (isDealbreaker) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.blocked,
                    color: AppColorsDark.gold,
                    size: AppIconSize.xs,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dealbreaker',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColorsDark.gold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.navyDark,
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              // Header with progress and skip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tell us how you like to play.',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColorsDark.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Step ${_currentIndex + 1} of ${_categories.length + 1}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColorsDark.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / (_categories.length + 1),
                    backgroundColor: AppColorsDark.navyLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColorsDark.green),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Page content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColorsDark.green,
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _categories.length +
                            1, // 7 categories + 1 priorities
                        onPageChanged: (index) {
                          updateState(this, () {
                            _currentIndex = index;
                          });
                          // When user reaches the priorities page, pre-select dealbreaker categories
                          if (index == _categories.length) {
                            _initializePrioritiesFromDealbreakers();
                          }
                        },
                        itemBuilder: (context, index) {
                          // Last page is priorities
                          if (index == _categories.length) {
                            return _buildPrioritiesPage();
                          }

                          // Otherwise show category slider
                          final category = _categories[index];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Info card
                                GlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  opacity: 0.2,
                                  child: Row(
                                    children: [
                                      AppIcon(
                                        icon: AppPhosphorIcons.lightbulb,
                                        size: AppIconSize.md,
                                        color: AppColorsDark.green,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'We\'ll match you with golfers on the same wavelength.',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: AppColorsDark.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Category slider
                                VibeCategorySlider(
                                  category: category,
                                  pref: _profile.preferenceFor(category),
                                  onValueChanged: (value) =>
                                      _handleValueChanged(category, value),
                                  onValueCommitted: (value) =>
                                      _commitValueChanged(category, value),
                                  onDealbreakerChanged: (value) =>
                                      _handleDealbreakerChanged(
                                          category, value),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Help text
                                Text(
                                  'You can adjust this anytime in your profile settings.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColorsDark.textMuted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButtonEnhanced(
                        text: 'Back',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.large,
                        enabled: _currentIndex > 0 && !_isCompleting,
                        onPressed: _previousStep,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButtonEnhanced(
                        text: _currentIndex == _categories.length
                            ? 'Finish'
                            : 'Next',
                        leadingIcon: _currentIndex == _categories.length
                            ? AppPhosphorIcons.success
                            : AppPhosphorIcons.arrowRight,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        isLoading: _isCompleting,
                        enabled: !_isCompleting,
                        onPressed: _nextStep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
