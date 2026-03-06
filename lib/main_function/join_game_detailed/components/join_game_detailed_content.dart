import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/animation_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/widgets/cancelled_game_banner.dart';
import '/core/widgets/game_details_section.dart';
import '/core/widgets/premium_section_header.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import '/main_function/game_joined_detailed/components/group_vibe_summary_selector.dart';
import '/main_function/game_joined_detailed/components/player_list_section_selector.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/providers/trust_provider.dart';
import '/providers/user_provider.dart';
import '/utils/app_util.dart';
import 'available_game_hero_section.dart';
import 'join_game_action_section.dart';

/// Content for the join game detailed screen.
///
/// Stateless widget that receives all data and callbacks from parent.
/// Handles layout, animations, and section composition.
class JoinGameDetailedContent extends StatelessWidget {
  const JoinGameDetailedContent({
    super.key,
    required this.game,
    required this.currentUserRef,
    required this.groupVibeCacheKey,
    required this.hasAnimated,
    required this.existingRequest,
    required this.isCheckingRequest,
    required this.isCreatorFriend,
    required this.onJoinPressed,
    required this.onPlayerTap,
  });

  final Game game;
  final DocumentReference? currentUserRef;
  final String? groupVibeCacheKey;
  final bool hasAnimated;
  final JoinRequest? existingRequest;
  final bool isCheckingRequest;
  final bool isCreatorFriend;
  final VoidCallback onJoinPressed;
  final void Function(DocumentReference userRef) onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final isCancelled = game.isCancelledStatus;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top padding for AppBar
          SizedBox(height: MediaQuery.of(context).padding.top + 22),

          // Hero Section with host info, course, and date/time
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: AvailableGameHeroSection(game: game),
          )
              .animate(target: hasAnimated ? 1 : 0)
              .fadeIn(
                duration: ReducedMotionService.adjust(
                  MotionTokens.routeEnter,
                ),
                curve: MotionTokens.curveEnter,
              )
              .scale(
                begin: ReducedMotionService.shouldScale
                    ? Offset(
                        MotionTokens.pageScaleStart,
                        MotionTokens.pageScaleStart,
                      )
                    : const Offset(1, 1),
                end: const Offset(1, 1),
                duration: ReducedMotionService.adjust(
                  MotionTokens.routeEnter,
                ),
                curve: MotionTokens.curveEnter,
              ),

          SizedBox(height: AppSpacing.md),

          // Group Vibe Summary
          buildAnimatedSection(
            sectionIndex: 0,
            hasAnimated: hasAnimated,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: GroupVibeSummarySelector(
                groupVibeCacheKey: groupVibeCacheKey,
                onViewBreakdown: (result) => GroupVibeBreakdownSheet.show(
                  context: context,
                  result: result,
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Game Details Section
          buildAnimatedSection(
            sectionIndex: 1,
            hasAnimated: hasAnimated,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumSectionHeader(title: 'Game Details'),
                  SizedBox(height: AppSpacing.sm),
                  GameDetailsSection(game: game),
                  SizedBox(height: AppSpacing.lg),
                  PremiumSectionHeader(
                    title: 'Players',
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Text(
                        '${game.playerCount}/4',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // Players list
          PlayerListSectionSelector(
            game: game,
            groupVibeCacheKey: groupVibeCacheKey,
            hasAnimated: hasAnimated,
            isOwner: false,
            onRemovePlayer: null,
            onPlayerTap: onPlayerTap,
            onMatchChipTap: null,
          ),

          SizedBox(height: AppSpacing.md),

          // Cancelled game banner
          if (isCancelled)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: const CancelledGameBanner(),
            ),

          // Restriction banner
          if (game.userRef != currentUserRef && !isCancelled)
            Consumer<TrustProvider>(
              builder: (context, trust, _) {
                final restriction = trust.myStanding?.currentRestriction;
                if (restriction == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: RestrictionBanner(
                    restriction: restriction,
                    onViewStanding: () => context.pushYourStanding(),
                  ),
                );
              },
            ),

          // Join button section
          if (game.userRef != currentUserRef && !isCancelled)
            Consumer2<TrustProvider, UserProvider>(
              builder: (context, trust, userProvider, _) {
                final isRestricted =
                    trust.myStanding?.currentRestriction != null;
                final userGender = userProvider.currentUser?.gender;

                return JoinGameActionSection(
                  state: JoinGameActionState(
                    game: game,
                    existingRequest: existingRequest,
                    isCheckingRequest: isCheckingRequest,
                    isRestricted: isRestricted,
                    userGender: userGender,
                  ),
                  onJoinPressed: onJoinPressed,
                );
              },
            ),
        ],
      ),
    );
  }
}
