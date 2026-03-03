import '/backend/backend.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/animation_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import '/models/game.dart';
import '/providers/provider_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'firm_it_up_banner.dart';
import 'firm_it_up_bottom_sheet.dart';
import 'group_vibe_summary_selector.dart';
import 'premium_hero_section.dart';
import 'quick_stats_row.dart';

typedef EditGameDetailsCallback = Future<void> Function(
  BuildContext context,
  Game gameRecord,
);

class GameJoinedDashboardOverviewSection extends StatelessWidget {
  const GameJoinedDashboardOverviewSection({
    super.key,
    required this.game,
    required this.currentUserRef,
    required this.hasAnimated,
    required this.groupVibeCacheKey,
    required this.onEditGameDetails,
  });

  final Game game;
  final DocumentReference? currentUserRef;
  final bool hasAnimated;
  final String? groupVibeCacheKey;
  final EditGameDetailsCallback onEditGameDetails;

  @override
  Widget build(BuildContext context) {
    final isOwner = game.userRef == currentUserRef;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: PremiumHeroSection(game: game),
        )
            .animate(target: hasAnimated ? 1 : 0)
            .fadeIn(
              duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
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
              duration: ReducedMotionService.adjust(MotionTokens.routeEnter),
              curve: MotionTokens.curveEnter,
            ),
        if (game.scheduleType == 'flexible' && isOwner)
          buildAnimatedSection(
            sectionIndex: 0,
            hasAnimated: hasAnimated,
            child: FirmItUpBanner(
              onPressed: () => _handleFirmItUp(context),
            ),
          ),
        buildAnimatedSection(
          sectionIndex: 1,
          hasAnimated: hasAnimated,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: QuickStatsRow(
              game: game,
              isOwner: isOwner,
              onEditPressed:
                  isOwner ? () => onEditGameDetails(context, game) : null,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        if (game.chatRef != null)
          buildAnimatedSection(
            sectionIndex: 2,
            hasAnimated: hasAnimated,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _MessageGroupButton(
                game: game,
                currentUserRef: currentUserRef,
              ),
            ),
          ),
        SizedBox(height: AppSpacing.lg),
        buildAnimatedSection(
          sectionIndex: 3,
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
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _handleFirmItUp(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FirmItUpBottomSheet(
        gameRef: game.reference,
      ),
    );

    if (result != null && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            margin: EdgeInsets.all(AppSpacing.xl),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.green,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Confirming tee time...',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await context.gameProvider.updateGame(
          game.reference.id,
          <String, dynamic>{
            'schedule_type': 'confirmed',
            'date': result['date'],
            'course_play': result['course'],
            'courseRef': result['courseRef'],
            'flexible_week': null,
            'flexible_days': null,
            'flexible_time_of_day': null,
          },
        );

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tee time confirmed!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (error, stackTrace) {
        AppLog.d('Firm It Up failed: $error');
        AppLog.d('Firm It Up stackTrace: $stackTrace');
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to confirm tee time: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _MessageGroupButton extends StatelessWidget {
  const _MessageGroupButton({
    required this.game,
    required this.currentUserRef,
  });

  final Game game;
  final DocumentReference? currentUserRef;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.green, AppColors.greenLight],
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [AppElevation.glowGreen],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              icon: AppPhosphorIcons.chat,
              color: AppColors.pure,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Message Group',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();
    final chatRef = game.chatRef;
    if (chatRef == null) {
      return;
    }
    if (currentUserRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to open the chat.'),
        ),
      );
      return;
    }
    final isMember =
        game.joinedPlayers.any((p) => p.id == currentUserRef!.id);
    if (!isMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join the game to access the group chat.'),
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    context.pushChatDetails(
      chatId: chatRef.id,
    );
  }
}
