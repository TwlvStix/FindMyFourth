import 'package:flutter/material.dart';

import '/core/utils/state_update.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/player_list/components/player_search_results.dart';
import '/main_function/player_list/controller/player_list_controller.dart';
import '/models/player_eligibility.dart';
import '/models/user_profile.dart';

typedef SelectPlayerCallback = AddPlayerAttemptResult Function({
  required int slotIndex,
  required bool isGuest,
  UserProfile? profile,
});

class AddPlayerModal extends StatefulWidget {
  const AddPlayerModal({
    super.key,
    required this.slotIndex,
    required this.joinedPlayerIds,
    required this.eligibility,
    required this.controller,
    required this.onSelectPlayer,
  });

  final int slotIndex;
  final Set<String> joinedPlayerIds;
  final PlayerEligibility eligibility;
  final PlayerListController controller;
  final SelectPlayerCallback onSelectPlayer;

  @override
  State<AddPlayerModal> createState() => _AddPlayerModalState();
}

class _AddPlayerModalState extends State<AddPlayerModal> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    widget.controller.resetSearchState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.controller.resetSearchState();
    super.dispose();
  }

  void _refreshState() {
    updateState(this, () {});
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onSearchChanged(String value) {
    widget.controller.onSearchChanged(
      value,
      onStateChanged: _refreshState,
      onError: _showError,
    );
  }

  Future<void> _loadMore() async {
    await widget.controller.loadMore(
      onStateChanged: _refreshState,
      onError: _showError,
    );
  }

  void _onGuestSelected() {
    final result = widget.onSelectPlayer(
      slotIndex: widget.slotIndex,
      isGuest: true,
    );

    if (!mounted) {
      return;
    }

    if (result.added) {
      Navigator.pop(context);
      return;
    }

    _showError(result.errorMessage ?? 'Unable to add this player.');
  }

  void _onProfileSelected(UserProfile profile) {
    final result = widget.onSelectPlayer(
      slotIndex: widget.slotIndex,
      isGuest: false,
      profile: profile,
    );

    if (!mounted) {
      return;
    }

    if (result.added) {
      Navigator.pop(context);
      return;
    }

    _showError(result.errorMessage ?? 'Unable to add this player.');
  }

  @override
  Widget build(BuildContext context) {
    final searchState = widget.controller.searchState;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppBorderRadius.xl),
              topRight: Radius.circular(AppBorderRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Player',
                      style: AppTypography.sectionHeader.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: AppIcon(
                        icon: AppPhosphorIcons.close,
                        color: AppColors.textMuted,
                        size: AppIconSize.md,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1.0,
                color: AppColors.navyLight,
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search members or add Guest',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: AppIcon(
                        icon: AppPhosphorIcons.search,
                        size: AppIconSize.button,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      borderSide: BorderSide(
                        color: AppColors.inputBorderIdle,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      borderSide: BorderSide(
                        color: AppColors.inputBorderIdle,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      borderSide: BorderSide(
                        color: AppColors.inputBorderFocused,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tap a player to add them to this slot',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 13,
                      color: AppColors.stone,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Expanded(
                child: PlayerSearchResults(
                  scrollController: scrollController,
                  minSearchChars: PlayerListController.minSearchChars,
                  activeQuery: searchState.activeQuery,
                  isSearching: searchState.isSearching,
                  searchResults: searchState.results,
                  hasMoreResults: searchState.hasMoreResults,
                  resolveDecision: (profile) {
                    return widget.controller.evaluateCandidate(
                      profile: profile,
                      joinedPlayerIds: widget.joinedPlayerIds,
                      eligibility: widget.eligibility,
                    );
                  },
                  onGuestSelected: _onGuestSelected,
                  onProfileSelected: _onProfileSelected,
                  onLoadMore: _loadMore,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
