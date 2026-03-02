import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/providers/group_vibe_provider.dart';
import '/services/vibe_group_matcher.dart';
import 'group_vibe_summary.dart';

/// Wrapper that selects GroupVibeMatch from provider and passes to GroupVibeSummary.
/// Isolates rebuilds - only this subtree rebuilds when match data changes.
class GroupVibeSummarySelector extends StatelessWidget {
  const GroupVibeSummarySelector({
    super.key,
    required this.groupVibeCacheKey,
    required this.onViewBreakdown,
  });

  final String? groupVibeCacheKey;
  final void Function(GroupVibeMatchResult result) onViewBreakdown;

  @override
  Widget build(BuildContext context) {
    final groupVibeMatch =
        context.select<GroupVibeProvider, GroupVibeMatchResult?>(
      (provider) => groupVibeCacheKey == null
          ? null
          : provider.getMatch(groupVibeCacheKey!),
    );

    return GroupVibeSummary(
      groupVibeMatch: groupVibeMatch,
      onViewBreakdown: groupVibeMatch == null
          ? () {}
          : () => onViewBreakdown(groupVibeMatch),
    );
  }
}
