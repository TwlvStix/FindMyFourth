import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/vibe_slider_card.dart';
import '/models/vibe_profile.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    VibeCategory.weed,
    VibeCategory.pace,
    VibeCategory.money,
    VibeCategory.competitive,
  ];

  VibeProfile _profile = VibeProfile.defaults();
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isCompleting = false;

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

  void _nextStep() {
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

  Future<void> _skipOnboarding() async {
    setState(() {
      _isCompleting = true;
    });
    try {
      await _repository.setDefaults();
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
    setState(() {
      _isCompleting = true;
    });
    try {
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
      context.goNamed(nextRoute);
    } else {
      context.goNamed(MainProfileWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: FairwayBackgroundSunset(
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_currentIndex + 1} of ${_categories.length}',
                        style: AppTheme.of(context).bodySmall.override(
                              font: GoogleFonts.outfit(
                                fontWeight: AppTheme.of(context)
                                    .bodySmall
                                    .fontWeight,
                                fontStyle: AppTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                              color: AppTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isCompleting ? null : _skipOnboarding,
                      child: Text(
                        'Skip for now',
                        style: AppTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.outfit(
                                fontWeight: AppTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: AppTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: AppTheme.of(context).primary,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.of(context).primary,
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _categories.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return SingleChildScrollView(
                            padding: AppSpacing.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your ${VibeLabels.titleFor(category)} vibe',
                                  style: AppTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight: AppTheme.of(context)
                                              .headlineMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .headlineMedium
                                              .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                      ),
                                ),
                                SizedBox(height: AppSpacing.lg),
                                VibeSliderCard(
                                  category: category,
                                  pref: _profile.preferenceFor(category),
                                  onValueChanged: (value) =>
                                      _handleValueChanged(category, value),
                                  onValueCommitted: (value) =>
                                      _commitValueChanged(category, value),
                                  onDealbreakerChanged: (value) =>
                                      _handleDealbreakerChanged(category, value),
                                  showAlternateHelper: false,
                                ),
                                SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Want to adjust this later? You can edit vibes anytime.',
                                  style: AppTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight: AppTheme.of(context)
                                              .bodySmall
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodySmall
                                              .fontStyle,
                                        ),
                                        color:
                                            AppTheme.of(context).secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: AppSpacing.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButtonEnhanced(
                        text: 'Back',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.medium,
                        enabled: _currentIndex > 0 && !_isCompleting,
                        onPressed: _previousStep,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButtonEnhanced(
                        text: _currentIndex == _categories.length - 1
                            ? 'Finish'
                            : 'Next',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.medium,
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
