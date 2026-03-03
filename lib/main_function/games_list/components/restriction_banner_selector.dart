import 'package:flutter/material.dart';

import '/core/design_tokens/spacing.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/providers/provider_extensions.dart';

/// A selector wrapper for RestrictionBanner in the games list.
///
/// Uses fine-grained selector to only rebuild when the user's current
/// restriction changes. This prevents rebuilds on unrelated TrustProvider
/// state changes.
class RestrictionBannerSelector extends StatelessWidget {
  const RestrictionBannerSelector({
    super.key,
    required this.onNavigateToStanding,
  });

  final VoidCallback onNavigateToStanding;

  @override
  Widget build(BuildContext context) {
    // Select only the restriction from TrustProvider
    final restriction = context.selectTrust(
      (trust) => trust.myStanding?.currentRestriction,
    );

    if (restriction == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: RestrictionBanner(
        restriction: restriction,
        onViewStanding: onNavigateToStanding,
      ),
    );
  }
}
