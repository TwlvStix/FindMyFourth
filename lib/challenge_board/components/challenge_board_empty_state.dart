import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_empty_state_premium.dart';

/// Empty state for the Challenge Board when user has no progress.
class ChallengeBoardEmptyState extends StatelessWidget {
  const ChallengeBoardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyStatePremium(
      icon: AppPhosphorIcons.trophy,
      title: 'No challenges started yet',
      message: 'Play your first round to begin tracking progress.',
    );
  }
}
