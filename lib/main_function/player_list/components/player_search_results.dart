import 'package:flutter/material.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/main_function/player_list/components/player_option_card.dart';
import '/main_function/player_list/controller/player_list_controller.dart';
import '/models/user_profile.dart';

class PlayerSearchResults extends StatelessWidget {
  const PlayerSearchResults({
    super.key,
    required this.scrollController,
    required this.minSearchChars,
    required this.activeQuery,
    required this.isSearching,
    required this.searchResults,
    required this.hasMoreResults,
    required this.resolveDecision,
    required this.onGuestSelected,
    required this.onProfileSelected,
    required this.onLoadMore,
  });

  final ScrollController scrollController;
  final int minSearchChars;
  final String activeQuery;
  final bool isSearching;
  final List<UserProfile> searchResults;
  final bool hasMoreResults;
  final AddPlayerDecision Function(UserProfile profile) resolveDecision;
  final VoidCallback onGuestSelected;
  final void Function(UserProfile profile) onProfileSelected;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) {
        return _buildListItem(index);
      },
    );
  }

  int _calculateItemCount() {
    int count = 1; // Guest option is always shown.

    if (activeQuery.length < minSearchChars) {
      count += 1;
    } else if (isSearching) {
      count += 1;
    } else if (searchResults.isEmpty) {
      count += 1;
    } else {
      count += searchResults.length;
      if (hasMoreResults) {
        count += 1;
      }
    }

    return count;
  }

  Widget _buildListItem(int index) {
    if (index == 0) {
      return Column(
        children: [
          PlayerOptionCard(
            name: 'Guest',
            subtitle: 'Add a guest player',
            photoUrl: null,
            isGuest: true,
            onTap: onGuestSelected,
          ),
          SizedBox(height: AppSpacing.sm),
        ],
      );
    }

    final contentIndex = index - 1;

    if (activeQuery.length < minSearchChars) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'Type at least $minSearchChars characters to search members.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.stone,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (isSearching) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(
            color: AppColors.navyDark,
          ),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'No members found.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.stone,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (contentIndex < searchResults.length) {
      final profile = searchResults[contentIndex];
      final decision = resolveDecision(profile);

      return PlayerOptionCard(
        name: profile.displayName.isNotEmpty ? profile.displayName : 'Player',
        subtitle: decision.subtitle,
        photoUrl: profile.photoUrl,
        isGuest: false,
        onTap: decision.canAdd ? () => onProfileSelected(profile) : null,
      );
    }

    if (hasMoreResults) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: AppButtonEnhanced(
            text: 'Load more',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: () async {
              await onLoadMore();
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
