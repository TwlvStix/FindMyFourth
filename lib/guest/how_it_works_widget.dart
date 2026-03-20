import 'package:flutter/material.dart';

import '/user_onboarding/cinematic_onboarding_widget.dart';

class HowItWorksWidget extends StatelessWidget {
  const HowItWorksWidget({super.key});

  static const String routeName = 'HowItWorks';
  static const String routePath = '/how-it-works';

  @override
  Widget build(BuildContext context) {
    return CinematicOnboardingWidget(
      onComplete: () => Navigator.of(context).pop(),
    );
  }
}
