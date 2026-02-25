import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/components/flexible_game_compact_card.dart';
import '/models/game.dart';

/// Horizontal carousel shelf for flexible games.
/// Displays above the scheduled games list with a "See all" tap target.
/// Features a pulsing gold dot indicator to draw attention.
class FlexibleGamesShelf extends StatefulWidget {
  const FlexibleGamesShelf({
    super.key,
    required this.games,
    required this.currentUserReference,
    required this.onSeeAll,
  });

  final List<Game> games;
  final DocumentReference? currentUserReference;
  final VoidCallback onSeeAll;

  @override
  State<FlexibleGamesShelf> createState() => _FlexibleGamesShelfState();
}

class _FlexibleGamesShelfState extends State<FlexibleGamesShelf>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Label + See all
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                // Pulsing gold dot indicator
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Flexible Games',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all ${widget.games.length}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xxs),
                        AppIcon(
                          icon: AppPhosphorIcons.chevronRight,
                          size: AppIconSize.xs,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Horizontal scrolling carousel
          SizedBox(
            height: 100, // Fixed height for compact cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: widget.games.length,
              itemBuilder: (context, index) {
                final game = widget.games[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.games.length - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: FlexibleGameCompactCard(
                    game: game,
                    currentUserReference: widget.currentUserReference,
                    animationIndex: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
