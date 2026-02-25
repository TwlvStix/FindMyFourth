import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/main_function/games_list/components/flexible_game_expanded_card.dart';
import '/models/game.dart';

/// Bottom sheet displaying all flexible games in an expanded format.
/// Opened when user taps "See all X" in the FlexibleGamesShelf.
class FlexibleGamesBottomSheet extends StatelessWidget {
  const FlexibleGamesBottomSheet({
    super.key,
    required this.games,
    required this.currentUserReference,
  });

  final List<Game> games;
  final DocumentReference? currentUserReference;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xxl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            // Header row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(AppPhosphorIcons.close, size: AppIconSize.md),
                    color: AppColors.pure,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flexible Games',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.pure,
                          ),
                        ),
                        Text(
                          '${games.length} ${games.length == 1 ? 'game' : 'games'}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            // Scrollable content
            Expanded(
              child: games.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == games.length - 1 ? 0 : AppSpacing.sm,
                          ),
                          child: FlexibleGameExpandedCard(
                            game: game,
                            currentUserReference: currentUserReference,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No flexible games available.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
