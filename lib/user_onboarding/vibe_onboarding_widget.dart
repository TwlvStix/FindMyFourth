import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/profile/edit_vibes/vibe_category_slider.dart';
import '/profile/main_profile/main_profile_widget.dart';
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

  VibeProfile _profile = VibeProfile.defaults();
  Map<VibeCategory, VibeImportance> _importance = {
    for (final category in VibeCategory.values)
      category: VibeImportance.normal,
  };
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isCompleting = false;

  int get _topCount =>
      _importance.values.where((value) => value == VibeImportance.top).length;

  int get _bottomCount => _importance.values
      .where((value) => value == VibeImportance.bottom)
      .length;

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
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _repository.getMyVibesCached(forceRefresh: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _importance = Map<VibeCategory, VibeImportance>.from(profile.importance);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateLocalPreference(
    VibeCategory category,
    VibePreference preference,
  ) {
    final updatedPrefs = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updatedPrefs[category] = preference;
    setState(() {
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

  void _setImportance(VibeCategory category, VibeImportance next) {
    final current = _importance[category] ?? VibeImportance.normal;
    if (current == next) {
      setState(() {
        _importance = Map<VibeCategory, VibeImportance>.from(_importance)
          ..[category] = VibeImportance.normal;
      });
      return;
    }
    setState(() {
      final updated = Map<VibeCategory, VibeImportance>.from(_importance);
      if (next == VibeImportance.top && _topCount >= 2) {
        // Auto-clear another top to allow this selection
        final otherTop = _categories.firstWhere(
          (entry) => entry != category && updated[entry] == VibeImportance.top,
          orElse: () => category,
        );
        if (otherTop != category) {
          updated[otherTop] = VibeImportance.normal;
        }
      }
      if (next == VibeImportance.bottom && _bottomCount >= 1) {
        // Auto-clear the existing bottom to allow this selection
        final otherBottom = _categories.firstWhere(
          (entry) =>
              entry != category && updated[entry] == VibeImportance.bottom,
          orElse: () => category,
        );
        if (otherBottom != category) {
          updated[otherBottom] = VibeImportance.normal;
        }
      }
      updated[category] = next;
      _importance = updated;
    });
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

  Future<void> _skipOnboarding() async {
    setState(() {
      _isCompleting = true;
    });
    try {
      // Set defaults for both vibes and importance
      await _repository.setDefaults();
      // Set default importance (all normal)
      final defaultImportance = {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
      };
      await _repository.updateImportance(defaultImportance);
      _goToNext();
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to skip. Please try again.');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompleting = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }

    // Validate priorities
    if (_topCount != 2) {
      showSnackbar(context, 'Please pick exactly 2 top priorities.');
      return;
    }

    setState(() {
      _isCompleting = true;
    });
    try {
      // Save importance first
      await _repository.updateImportance(_importance);
      // Then confirm vibes
      await _repository.confirmVibes(profile: _profile);
      _goToNext();
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to finish setup. Please try again.');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompleting = false;
      });
    }
  }

  void _goToNext() {
    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    if (nextRoute != null && nextRoute.isNotEmpty) {
      context.goNamed(
        nextRoute,
        extra: <String, dynamic>{
          kTransitionInfoKey: TransitionStandards.modalTransition,
        },
      );
    } else {
      context.goNamed(
        MainProfileWidget.routeName,
        extra: <String, dynamic>{
          kTransitionInfoKey: TransitionStandards.modalTransition,
        },
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
          // Vibe Archetype Display
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha:0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 20,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Your vibe style',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.sand,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  archetypeMatch.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.pure,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  archetypeMatch.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.sand,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Header
          Text(
            'What makes or breaks your round?',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.pure,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick the 2 things that matter most. Optional: pick 1 that matters least.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.sand,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Count pills
          Row(
            children: [
              _buildCountPill(
                label: 'Top',
                count: _topCount,
                max: 2,
                color: AppColors.navy,
                background: AppColors.navyLight.withValues(alpha:0.15),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildCountPill(
                label: 'Bottom',
                count: _bottomCount,
                max: 1,
                color: AppColors.gold,
                background: AppColors.gold.withValues(alpha:0.15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Category cards
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildImportanceCard(category),
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
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha:0.3)),
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

  Widget _buildImportanceCard(VibeCategory category) {
    final importance = _importance[category] ?? VibeImportance.normal;
    final title = _categoryTitles[category] ?? VibeLabels.titleFor(category);

    final isTop = importance == VibeImportance.top;
    final isBottom = importance == VibeImportance.bottom;
    final background = isTop
        ? AppColors.navyDark.withValues(alpha:0.3)
        : isBottom
            ? AppColors.gold.withValues(alpha:0.2)
            : AppColors.slate.withValues(alpha:0.15);
    final borderColor = isTop
        ? AppColors.navy
        : isBottom
            ? AppColors.gold
            : AppColors.cloud;
    final label = isTop
        ? 'Top priority'
        : isBottom
            ? 'Least important'
            : 'Normal';
    final titleColor = isTop || isBottom ? AppColors.pure : AppColors.sand;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha:0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: titleColor,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isTop || isBottom ? AppColors.sand : AppColors.stone,
                        letterSpacing: AppTypography.letterSpacingNormal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isTop
                    ? Icons.arrow_upward_rounded
                    : isBottom
                        ? Icons.arrow_downward_rounded
                        : Icons.radio_button_unchecked_rounded,
                color: isTop || isBottom ? AppColors.pure : AppColors.stone,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _buildSelectorChip(
                label: 'Matters most',
                selected: isTop,
                color: AppColors.navy,
                onTap: () => _setImportance(category, VibeImportance.top),
              ),
              _buildSelectorChip(
                label: 'Does not matter',
                selected: isBottom,
                color: AppColors.gold,
                onTap: () => _setImportance(category, VibeImportance.bottom),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textColor = selected ? AppColors.pure : AppColors.onyx;
    final bgColor = selected ? color : AppColors.sand.withValues(alpha:0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : AppColors.cloud,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: textColor,
            letterSpacing: AppTypography.letterSpacingNormal,
            fontWeight:
                selected ? AppTypography.semiBold : AppTypography.regular,
          ),
        ),
      ),
    );
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
      backgroundColor: AppTheme.of(context).primaryBackground,
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
                              color: AppColors.pure,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Step ${_currentIndex + 1} of ${_categories.length + 1}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.stone,
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
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / (_categories.length + 1),
                    backgroundColor: AppColors.slate.withValues(alpha:0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
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
                          color: AppColors.navy,
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _categories.length + 1, // 7 categories + 1 priorities
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
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
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.navyLight.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.navy.withValues(alpha:0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 20,
                                        color: AppColors.navy,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'We\'ll match you with golfers on the same wavelength.',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.sand,
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
                                      _handleDealbreakerChanged(category, value),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Help text
                                Text(
                                  'You can adjust this anytime in your profile settings.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.stone,
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
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
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
