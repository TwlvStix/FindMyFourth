import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/navigation/transition_standards.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import 'components/progressive_basic_info_step.dart';
import 'components/progressive_golf_info_step.dart';
import 'components/progressive_navigation_buttons.dart';
import 'components/progressive_preferences_step.dart';
import 'components/progressive_progress_indicator.dart';
import 'components/progressive_welcome_step.dart';
import 'controllers/progressive_onboarding_controller.dart';
import 'controllers/progressive_onboarding_result.dart';

class ProgressiveOnboardingWidget extends StatefulWidget {
  const ProgressiveOnboardingWidget({super.key});

  static String routeName = 'ProgressiveOnboarding';
  static String routePath = '/progressiveOnboarding';

  @override
  State<ProgressiveOnboardingWidget> createState() =>
      _ProgressiveOnboardingWidgetState();
}

class _ProgressiveOnboardingWidgetState
    extends State<ProgressiveOnboardingWidget> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 4;

  // Controller
  final _controller = ProgressiveOnboardingController();

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  // Golf info state
  String? _homeCourseValue;
  late FormFieldController<String> _homeCourseController;
  int _handicapValue = 18;

  // Preferences state
  int _drinksValue = 2;
  int _musicValue = 2;
  int _playMoneyValue = 2;
  int _paceValue = 2;

  bool _isLoading = false;

  // Cached courses future to avoid refetch on rebuild
  late Future<List<CourseRecord>> _coursesFuture;
  List<CourseRecord>? _loadedCourses;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _homeCourseController = FormFieldController<String>(null);
    _coursesFuture = queryCourseRecordOnce();
    _coursesFuture.then((courses) {
      if (mounted) {
        updateState(this, () => _loadedCourses = courses);
      }
    });
    _controller.ensureUserRecordOnInit();
    _emailController.text = currentUserEmail;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final userRef = currentUserReference;
    if (userRef == null) {
      _showErrorSnackbar('User not authenticated');
      return;
    }

    updateState(this, () => _isLoading = true);

    try {
      final result = await _controller.submitOnboarding(
        userRef: userRef,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        currentEmail: currentUserEmail,
        desiredEmail: _emailController.text,
        homeCourse: _homeCourseValue,
        handicap: _handicapValue,
        drinks: _drinksValue,
        music: _musicValue,
        playMoney: _playMoneyValue,
        pace: _paceValue,
      );

      if (!mounted) return;

      switch (result) {
        case OnboardingSuccess():
          context.goVibeOnboarding(
            next: AppRouteNames.mainProfile,
            transition: TransitionStandards.modalTransition,
          );
        case OnboardingFailure(:final type, :final message):
          if (type == OnboardingFailureType.requiresReauth) {
            await _showReauthDialog();
          } else {
            _showErrorSnackbar(message);
          }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error completing onboarding: $e');
      }
    } finally {
      if (mounted) {
        updateState(this, () => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _showReauthDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.navy,
          title: Text(
            'Re-authentication required',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'To update your email, please sign in again and retry.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            AppButtonEnhanced(
              text: 'Cancel',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            AppButtonEnhanced(
              text: 'Sign In',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.small,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.goSignIn(
                  transition: TransitionStandards.modalTransition,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.navyDark,
      body: FairwayBackgroundClubhouse(
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              ProgressiveProgressIndicator(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    updateState(this, () => _currentStep = index);
                  },
                  children: [
                    const ProgressiveWelcomeStep(),
                    ProgressiveBasicInfoStep(
                      formKey: _formKey,
                      data: BasicInfoFormData(
                        firstName: _firstNameController,
                        lastName: _lastNameController,
                        username: _usernameController,
                        phone: _phoneController,
                        email: _emailController,
                        firstNameFocus: _firstNameFocus,
                        lastNameFocus: _lastNameFocus,
                        usernameFocus: _usernameFocus,
                        phoneFocus: _phoneFocus,
                        emailFocus: _emailFocus,
                        validateUsername: _controller.validateUsername,
                        validateEmail: _controller.validateEmail,
                      ),
                    ),
                    ProgressiveGolfInfoStep(
                      data: GolfInfoStepData(
                        courses: _loadedCourses,
                        isLoadingCourses: _loadedCourses == null,
                        homeCourseValue: _homeCourseValue,
                        handicapValue: _handicapValue,
                        onHomeCourseChanged: (val) {
                          updateState(this, () => _homeCourseValue = val);
                        },
                        onHandicapChanged: (val) {
                          updateState(this, () => _handicapValue = val);
                        },
                        homeCourseController: _homeCourseController,
                      ),
                    ),
                    ProgressivePreferencesStep(
                      data: PreferencesStepData(
                        musicValue: _musicValue,
                        drinksValue: _drinksValue,
                        playMoneyValue: _playMoneyValue,
                        paceValue: _paceValue,
                        onMusicChanged: (val) {
                          updateState(this, () => _musicValue = val);
                        },
                        onDrinksChanged: (val) {
                          updateState(this, () => _drinksValue = val);
                        },
                        onPlayMoneyChanged: (val) {
                          updateState(this, () => _playMoneyValue = val);
                        },
                        onPaceChanged: (val) {
                          updateState(this, () => _paceValue = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ProgressiveNavigationButtons(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                isLoading: _isLoading,
                onNext: _nextStep,
                onPrevious: _previousStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
