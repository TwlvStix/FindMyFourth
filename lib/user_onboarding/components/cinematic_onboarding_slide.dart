import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import 'cinematic_screenshot_card.dart';
import 'cinematic_progress_dots.dart';

enum CinematicAnimationType { slideUp, fadeOnly }

class CinematicOnboardingSlide extends StatelessWidget {
  final AnimationController controller;
  final String imagePath;
  final String title;
  final String subtitle;
  final String buttonText;
  final AppButtonVariant buttonVariant;
  final VoidCallback onButtonPressed;
  final int currentPage;
  final int totalPages;
  final Function(int) onDotTapped;
  final CinematicAnimationType animationType;
  final Widget Function(AnimationController)? overlayBuilder;

  const CinematicOnboardingSlide({
    super.key,
    required this.controller,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonVariant,
    required this.onButtonPressed,
    required this.currentPage,
    required this.totalPages,
    required this.onDotTapped,
    this.animationType = CinematicAnimationType.fadeOnly,
    this.overlayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          // Image Area
          Expanded(
            child: Center(
              child: Padding(
                padding: AppSpacing.allLg,
                child: _buildAnimatedImageArea(),
              ),
            ),
          ),
          // Footer
          SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          CinematicProgressDots(
            currentPage: currentPage,
            totalPages: totalPages,
            onDotTapped: onDotTapped,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButtonEnhanced(
            text: buttonText,
            onPressed: onButtonPressed,
            variant: buttonVariant,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildAnimatedImageArea() {
    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    if (animationType == CinematicAnimationType.slideUp) {
      final slideAnimation = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ),
      );

      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, slideAnimation.value),
            child: Opacity(
              opacity: fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: CinematicScreenshotCard(imagePath: imagePath),
      );
    }

    // fadeOnly animation (with optional overlay)
    if (overlayBuilder != null) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: fadeAnimation.value,
                child: CinematicScreenshotCard(imagePath: imagePath),
              ),
              overlayBuilder!(controller),
            ],
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: child,
        );
      },
      child: CinematicScreenshotCard(imagePath: imagePath),
    );
  }
}
