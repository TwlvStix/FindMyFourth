import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/providers/vibe_provider.dart';
import '/user_onboarding/components/vibe_onboarding_header.dart';
import '/user_onboarding/components/vibe_onboarding_step.dart';
import '/utils/app_util.dart';
import '/utils/vibe_archetypes.dart';

/// Vibe onboarding flow for new users to set their play style preferences.
///
/// Uses [VibeProvider] for state management (route-scoped, provided by router).
/// Delegates all business logic to the provider, keeping this widget thin.
class VibeOnboardingWidget extends StatefulWidget {
  const VibeOnboardingWidget({super.key});

  static String routeName = 'VibeOnboarding';
  static String routePath = '/vibeOnboarding';

  @override
  State<VibeOnboardingWidget> createState() => _VibeOnboardingWidgetState();
}

class _VibeOnboardingWidgetState extends State<VibeOnboardingWidget> {
  final PageController _pageController = PageController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<VibeCategory> _categories = [
    VibeCategory.chat,
    VibeCategory.music,
    VibeCategory.drinking,
    VibeCategory.pace,
    VibeCategory.money,
    VibeCategory.competitive,
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load profile after first frame to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VibeProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _completeOnboarding() async {
    final provider = context.read<VibeProvider>();
    final error = await provider.completeOnboarding();

    if (!mounted) return;

    if (error != null) {
      showSnackbar(context, error);
      return;
    }

    _navigateToArchetypeReveal();
  }

  void _navigateToArchetypeReveal() {
    final provider = context.read<VibeProvider>();
    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    final archetypeMatch = VibeArchetypes.classifyProfile(provider.profile);

    context.pushVibeArchetypeReveal(
      match: archetypeMatch,
      next: nextRoute,
    );
  }

  void _handleValueChanged(VibeCategory category, int value) {
    context.read<VibeProvider>().updateLocalPreference(category, value);
  }

  Future<void> _handleValueCommitted(VibeCategory category, int value) async {
    final provider = context.read<VibeProvider>();
    final error = await provider.commitValueChanged(category, value);

    if (!mounted) return;
    if (error != null) {
      showSnackbar(context, error);
    }
  }

  Future<void> _handleDealbreakerChanged(
    VibeCategory category,
    bool value,
  ) async {
    final provider = context.read<VibeProvider>();
    final error = await provider.toggleDealbreaker(category, value);

    if (!mounted) return;
    if (error != null) {
      showSnackbar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VibeProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.navyDark,
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              // Header
              VibeOnboardingHeader(
                currentIndex: _currentIndex,
                totalSteps: _categories.length,
              ),

              // Page content
              Expanded(
                child: provider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColorsDark.green,
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
                          return VibeOnboardingStep(
                            category: category,
                            pref: provider.profile.preferenceFor(category),
                            onValueChanged: (value) =>
                                _handleValueChanged(category, value),
                            onValueCommitted: (value) =>
                                _handleValueCommitted(category, value),
                            onDealbreakerChanged: (value) =>
                                _handleDealbreakerChanged(category, value),
                          );
                        },
                      ),
              ),

              // Navigation buttons
              _NavigationButtons(
                currentIndex: _currentIndex,
                totalSteps: _categories.length,
                isCompleting: provider.isCompleting,
                onPrevious: _previousStep,
                onNext: _nextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation buttons for the vibe onboarding flow.
class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.currentIndex,
    required this.totalSteps,
    required this.isCompleting,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentIndex;
  final int totalSteps;
  final bool isCompleting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  bool get _isLastStep => currentIndex == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              enabled: currentIndex > 0 && !isCompleting,
              onPressed: onPrevious,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButtonEnhanced(
              text: _isLastStep ? 'Finish' : 'Next',
              leadingIcon: _isLastStep
                  ? AppPhosphorIcons.success
                  : AppPhosphorIcons.arrowRight,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              isLoading: isCompleting,
              enabled: !isCompleting,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
