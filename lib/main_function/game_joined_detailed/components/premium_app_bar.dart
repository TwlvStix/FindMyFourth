import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';

/// Premium gradient app bar with title and custom back button
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final router = GoRouter.of(context);
          router.go('/gamesList');
        },
        child: Container(
          margin: EdgeInsets.only(left: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.fairway.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 28.0,
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTypography.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      elevation: 0.0,
    );
  }
}
