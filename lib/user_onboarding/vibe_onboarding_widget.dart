import '/core/design_tokens/border_radius.dart';
import '/core/utils/state_update.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
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


  void _nextStep() {
    // Last category is at index _categories.length - 1
    if (_currentIndex < _categories.length - 1) {
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
    // Navigate to the archetype reveal page
    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    final archetypeMatch = VibeArchetypes.classifyProfile(_profile);

    context.pushVibeArchetypeReveal(
      match: archetypeMatch,
      next: nextRoute,
    );
  }


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
                            'Step ${_currentIndex + 1} of ${_categories.length}',
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
                    value: (_currentIndex + 1) / _categories.length,
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
                        itemCount: _categories.length,
                        onPageChanged: (index) {
                          updateState(this, () {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
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
                        text: _currentIndex == _categories.length - 1
                            ? 'Finish'
                            : 'Next',
                        leadingIcon: _currentIndex == _categories.length - 1
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
