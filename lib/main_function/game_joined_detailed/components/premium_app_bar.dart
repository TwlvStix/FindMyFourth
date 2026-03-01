import 'package:flutter/material.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/widgets/premium_back_button.dart';

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
      leading: PremiumBackButton(
        onTap: () {
          context.goGamesList();
        },
      ),
      title: Text(
        title,
        style: AppTypography.headlineMediumSans.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      elevation: 0.0,
    );
  }
}
