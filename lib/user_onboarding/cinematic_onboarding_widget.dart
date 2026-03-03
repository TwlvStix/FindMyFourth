import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/utils/app_util.dart';
import '/services/profile_setup_service.dart';
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import 'components/cinematic_onboarding_slide.dart';
import 'components/cinematic_notification_banner.dart';
import 'components/cinematic_foursome_toast.dart';

class CinematicOnboardingWidget extends StatefulWidget {
  const CinematicOnboardingWidget({super.key});

  static const String routeName = 'UserOnboarding';
  static const String routePath = '/onboarding';

  @override
  State<CinematicOnboardingWidget> createState() =>
      _CinematicOnboardingWidgetState();
}

class _CinematicOnboardingWidgetState extends State<CinematicOnboardingWidget>
    with TickerProviderStateMixin {
  final _profileSetupService = ProfileSetupService();
  late PageController _pageController;
  late List<AnimationController> _slideControllers;
  late FocusNode _keyboardFocusNode;
  int _currentPage = 0;

  // Slide configuration data
  static const _slideConfigs = [
    (
      image: 'assets/images/Slide #1 - GameDetailed.png',
      title: 'Find the Game You Actually Want to Play',
      subtitle: 'Choose your format, stakes, and vibe - before you show up.',
      buttonText: 'Next',
      buttonVariant: AppButtonVariant.secondary,
      animationType: CinematicAnimationType.slideUp,
      hasNotificationOverlay: false,
      hasToastOverlay: false,
    ),
    (
      image: 'assets/images/Slide #2 - Vibe Match.png',
      title: 'Golf Is Better When the Group Is Right',
      subtitle: 'Match with players who value the same kind of round you do.',
      buttonText: 'Next',
      buttonVariant: AppButtonVariant.secondary,
      animationType: CinematicAnimationType.fadeOnly,
      hasNotificationOverlay: false,
      hasToastOverlay: false,
    ),
    (
      image: 'assets/images/Slide #3 -Notification.png',
      title: 'The Right Game Finds You',
      subtitle:
          'Set your format, stakes, and vibe. When your game drops, you\'ll be the first to know — not the last to see it already full.',
      buttonText: 'Next',
      buttonVariant: AppButtonVariant.secondary,
      animationType: CinematicAnimationType.fadeOnly,
      hasNotificationOverlay: true,
      hasToastOverlay: false,
    ),
    (
      image: 'assets/images/Slide #4 - GameList.png',
      title: 'Buddy Bailed? You are Covered.',
      subtitle:
          'Post your open spot and fill it fast with someone who actually fits your game.',
      buttonText: 'Build Your Profile',
      buttonVariant: AppButtonVariant.primary,
      animationType: CinematicAnimationType.fadeOnly,
      hasNotificationOverlay: false,
      hasToastOverlay: true,
    ),
  ];

  int get _totalPages => _slideConfigs.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _keyboardFocusNode = FocusNode();
    _ensureUserRecord();
    _createSlideControllers();

    // Start first slide animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideControllers[0].forward();
    });
  }

  void _createSlideControllers() {
    _slideControllers = List.generate(
      _totalPages,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    for (final controller in _slideControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _slideControllers[page].reset();
    _slideControllers[page].forward();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleFinish() async {
    if (!mounted) return;

    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    final nextAfterProfile = nextRoute == null ||
            nextRoute.isEmpty ||
            nextRoute == AppRouteNames.createProfile
        ? AppRouteNames.gamesList
        : nextRoute;

    final recordReady = await _ensureUserRecord();
    if (!recordReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Finishing setup. Please wait a moment before continuing.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      context.goCreateProfile(next: nextAfterProfile);
    }
  }

  Future<bool> _ensureUserRecord() async {
    final user = await _profileSetupService.currentUserOrWait(
      timeout: const Duration(seconds: 1),
    );
    if (user == null) return false;
    try {
      await ensureUserDocReady(user);
      return true;
    } catch (error, stackTrace) {
      AppLog.d('❌ ONBOARDING: unable to ensure user doc exists: $error');
      AppLog.d('❌ ONBOARDING: Stack trace: $stackTrace');
      return false;
    }
  }

  Widget? _buildOverlay(int index, AnimationController controller) {
    final config = _slideConfigs[index];

    if (config.hasNotificationOverlay) {
      return _buildNotificationOverlay(controller);
    }
    if (config.hasToastOverlay) {
      return _buildToastOverlay(controller);
    }
    return null;
  }

  Widget _buildNotificationOverlay(AnimationController controller) {
    final slideAnimation = Tween<double>(begin: -120, end: 20).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    return Positioned(
      top: slideAnimation.value,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: fadeAnimation.value,
        child: const CinematicNotificationBanner(),
      ),
    );
  }

  Widget _buildToastOverlay(AnimationController controller) {
    final translateAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );
    final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );

    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Transform.translate(
        offset: Offset(0, translateAnimation.value),
        child: Transform.scale(
          scale: scaleAnimation.value,
          child: Opacity(
            opacity: fadeAnimation.value,
            child: const CinematicFoursomeToast(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextPage();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              _currentPage > 0) {
            _goToPage(_currentPage - 1);
          }
        }
      },
      child: Scaffold(
        body: FairwayBackground(
          variant: FairwayBackgroundVariant.clubhouse,
          showOrganic: true,
          child: SafeArea(
            top: true,
            bottom: true,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                final config = _slideConfigs[index];
                return CinematicOnboardingSlide(
                  controller: _slideControllers[index],
                  imagePath: config.image,
                  title: config.title,
                  subtitle: config.subtitle,
                  buttonText: config.buttonText,
                  buttonVariant: config.buttonVariant,
                  animationType: config.animationType,
                  overlayBuilder: (config.hasNotificationOverlay ||
                          config.hasToastOverlay)
                      ? (controller) => _buildOverlay(index, controller)!
                      : null,
                  onButtonPressed:
                      index == _totalPages - 1 ? _handleFinish : _nextPage,
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onDotTapped: _goToPage,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
