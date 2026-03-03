import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';

class CinematicProgressDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onDotTapped;

  const CinematicProgressDots({
    super.key,
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
            margin: AppSpacing.symmetric(horizontal: AppSpacing.xxs),
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
