import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/utils/app_util.dart';
import '/services/profile_setup_service.dart';
import '../core/design_tokens/colors.dart';
import '../core/design_tokens/spacing.dart';
import '../core/design_tokens/border_radius.dart';
import '../core/design_tokens/typography.dart';
import '../core/design_tokens/icon_size.dart';
import '../core/widgets/app_button_enhanced.dart';
import '../core/widgets/fairway_background.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

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
  int _currentPage = 0;
  final int _totalPages = 4;

  // Animation controllers for each slide
  late AnimationController _slide1Controller;
  late AnimationController _slide2Controller;
  late AnimationController _slide3Controller;
  late AnimationController _slide4Controller;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _ensureUserRecord();

    // Initialize animation controllers for each slide
    _slide1Controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slide2Controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slide3Controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slide4Controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start first slide animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slide1Controller.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slide1Controller.dispose();
    _slide2Controller.dispose();
    _slide3Controller.dispose();
    _slide4Controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Reset and play animation for current page
    switch (page) {
      case 0:
        _slide1Controller.reset();
        _slide1Controller.forward();
        break;
      case 1:
        _slide2Controller.reset();
        _slide2Controller.forward();
        break;
      case 2:
        _slide3Controller.reset();
        _slide3Controller.forward();
        break;
      case 3:
        _slide4Controller.reset();
        _slide4Controller.forward();
        break;
    }
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
      context.goCreateProfile(
        next: nextAfterProfile,
      );
    }
  }

  Future<bool> _ensureUserRecord() async {
    final user = await _profileSetupService.currentUserOrWait(
      timeout: const Duration(seconds: 1),
    );
    if (user == null) {
      return false;
    }
    try {
      await ensureUserDocReady(user);
      return true;
    } catch (error, stackTrace) {
      AppLog.d('❌ ONBOARDING: unable to ensure user doc exists: $error');
      AppLog.d('❌ ONBOARDING: Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
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
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _Slide1FindYourGame(
                  controller: _slide1Controller,
                  currentPage: _currentPage,
                  onNextPage: _nextPage,
                  onDotTapped: _goToPage,
                  totalPages: _totalPages,
                ),
                _Slide2RightGroup(
                  controller: _slide2Controller,
                  currentPage: _currentPage,
                  onNextPage: _nextPage,
                  onDotTapped: _goToPage,
                  totalPages: _totalPages,
                ),
                _Slide3GetAlerted(
                  controller: _slide3Controller,
                  currentPage: _currentPage,
                  onNextPage: _nextPage,
                  onDotTapped: _goToPage,
                  totalPages: _totalPages,
                ),
                _Slide4FillFoursome(
                  controller: _slide4Controller,
                  currentPage: _currentPage,
                  onFinish: _handleFinish,
                  onDotTapped: _goToPage,
                  totalPages: _totalPages,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SLIDE 1: Find Your Game
// ============================================================================

class _Slide1FindYourGame extends StatelessWidget {
  final AnimationController controller;
  final int currentPage;
  final VoidCallback onNextPage;
  final Function(int) onDotTapped;
  final int totalPages;

  const _Slide1FindYourGame({
    required this.controller,
    required this.currentPage,
    required this.onNextPage,
    required this.onDotTapped,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final cardAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          // Image Area - flex: 1
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, cardAnimation.value),
                      child: Opacity(
                        opacity: fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.8,
                          maxHeight: constraints.maxHeight,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xl),
                          child: Image.asset(
                            'assets/images/Slide #1 - GameDetailed.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Footer - fixed height
          SizedBox(height: AppSpacing.xl),
          Text(
            'Find the Game You Actually Want to Play',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Choose your format, stakes, and vibe - before you show up.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          _ProgressDots(
            currentPage: currentPage,
            totalPages: totalPages,
            onDotTapped: onDotTapped,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButtonEnhanced(
            text: 'Next',
            onPressed: onNextPage,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ============================================================================
// SLIDE 2: Right Group
// ============================================================================

class _Slide2RightGroup extends StatelessWidget {
  final AnimationController controller;
  final int currentPage;
  final VoidCallback onNextPage;
  final Function(int) onDotTapped;
  final int totalPages;

  const _Slide2RightGroup({
    required this.controller,
    required this.currentPage,
    required this.onNextPage,
    required this.onDotTapped,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          // Image Area - flex: 1
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.8,
                          maxHeight: constraints.maxHeight,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xl),
                          child: Image.asset(
                            'assets/images/Slide #2 - Vibe Match.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Footer - fixed height
          SizedBox(height: AppSpacing.xl),
          Text(
            'Golf Is Better When the Group Is Right',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Match with players who value the same kind of round you do.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          _ProgressDots(
            currentPage: currentPage,
            totalPages: totalPages,
            onDotTapped: onDotTapped,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButtonEnhanced(
            text: 'Next',
            onPressed: onNextPage,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ============================================================================
// SLIDE 3: Get Alerted
// ============================================================================

class _Slide3GetAlerted extends StatelessWidget {
  final AnimationController controller;
  final int currentPage;
  final VoidCallback onNextPage;
  final Function(int) onDotTapped;
  final int totalPages;

  const _Slide3GetAlerted({
    required this.controller,
    required this.currentPage,
    required this.onNextPage,
    required this.onDotTapped,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Notification slides down from top
    final notificationSlide = Tween<double>(begin: -120, end: 20).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    final notificationFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          // Image Area - flex: 1
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Screenshot image
                        Opacity(
                          opacity: fadeAnimation.value,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.8,
                                  maxHeight: constraints.maxHeight,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.xl),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 40,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.xl),
                                  child: Image.asset(
                                    'assets/images/Slide #3 -Notification.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Animated notification banner overlay
                        Positioned(
                          top: notificationSlide.value,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: notificationFade.value,
                            child: const _AppNotificationBanner(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Footer - fixed height
          SizedBox(height: AppSpacing.xl),
          Text(
            'The Right Game Finds You',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Set your format, stakes, and vibe. When your game drops, you\'ll be the first to know — not the last to see it already full.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          _ProgressDots(
            currentPage: currentPage,
            totalPages: totalPages,
            onDotTapped: onDotTapped,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButtonEnhanced(
            text: 'Next',
            onPressed: onNextPage,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ============================================================================
// SLIDE 4: Fill Your Foursome
// ============================================================================

class _Slide4FillFoursome extends StatelessWidget {
  final AnimationController controller;
  final int currentPage;
  final VoidCallback onFinish;
  final Function(int) onDotTapped;
  final int totalPages;

  const _Slide4FillFoursome({
    required this.controller,
    required this.currentPage,
    required this.onFinish,
    required this.onDotTapped,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Toast appears with bounce
    final toastAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );

    final toastFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );

    final toastScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          // Image Area - flex: 1
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Screenshot image
                        Opacity(
                          opacity: fadeAnimation.value,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.8,
                                  maxHeight: constraints.maxHeight,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.xl),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 40,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.xl),
                                  child: Image.asset(
                                    'assets/images/Slide #4 - GameList.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Animated "Foursome Complete" toast overlay
                        Positioned(
                          bottom: 40,
                          left: 0,
                          right: 0,
                          child: Transform.translate(
                            offset: Offset(0, toastAnimation.value),
                            child: Transform.scale(
                              scale: toastScale.value,
                              child: Opacity(
                                opacity: toastFade.value,
                                child: const _FoursomeCompleteToast(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Footer - fixed height
          SizedBox(height: AppSpacing.xl),
          Text(
            'Buddy Bailed? You are Covered.',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Post your open spot and fill it fast with someone who actually fits your game.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          _ProgressDots(
            currentPage: currentPage,
            totalPages: totalPages,
            onDotTapped: onDotTapped,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButtonEnhanced(
            text: 'Build Your Profile',
            onPressed: onFinish,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED OVERLAYS
// ============================================================================

class _AppNotificationBanner extends StatelessWidget {
  const _AppNotificationBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayDark,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // App icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.navyDark, AppColors.green],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Center(
                child: Icon(
                  AppPhosphorIcons.golfCourse,
                  color: AppColors.pure,
                  size: AppIconSize.button,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FIND MY FOURTH',
                    style: AppTypography.overline.copyWith(
                      fontSize: 10,
                      color: AppColors.slate,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'New Game Match',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 13,
                      color: AppColors.onyx,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Match Play · Meadow Creek · Saturday 8:40 AM',
                    style: AppTypography.timestamp.copyWith(
                      fontSize: 11,
                      color: AppColors.slate,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoursomeCompleteToast extends StatelessWidget {
  const _FoursomeCompleteToast();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark icon
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppPhosphorIcons.check,
                size: AppIconSize.button,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 10),
            // Text column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Foursome Complete!',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Ryan\'s group is ready to go',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.glassTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROGRESS DOTS
// ============================================================================

class _ProgressDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onDotTapped;

  const _ProgressDots({
    required this.currentPage,
    required this.totalPages,
    required this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return GestureDetector(
          onTap: () => onDotTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.navyDark : AppColors.cloud,
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
            ),
          ),
        );
      }),
    );
  }
}
