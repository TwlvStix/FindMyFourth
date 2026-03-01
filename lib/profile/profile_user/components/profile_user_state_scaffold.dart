import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/premium_back_button.dart';

class ProfileUserStateScaffold extends StatelessWidget {
  const ProfileUserStateScaffold({
    super.key,
    required this.body,
    this.scaffoldKey,
  });

  final Widget body;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PremiumBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
