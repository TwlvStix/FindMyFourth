import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/animation_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/vibe/group_vibe_breakdown_sheet.dart';
import '/models/game.dart';
import '/providers/provider_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'firm_it_up_banner.dart';
import 'firm_it_up_bottom_sheet.dart';
import 'group_vibe_summary_selector.dart';
import 'premium_hero_section.dart';

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
        // Premium Hero Section (now includes date/time and Message Group)
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: PremiumHeroSection(
            game: game,
            currentUserRef: currentUserRef,
            isOwner: isOwner,
            onEditPressed:
                isOwner ? () => onEditGameDetails(context, game) : null,
          ),
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
        // Firm It Up Banner (only for flexible game owners)
        if (game.scheduleType == 'flexible' && isOwner)
          buildAnimatedSection(
            sectionIndex: 0,
            hasAnimated: hasAnimated,
            child: FirmItUpBanner(
              onPressed: () => _handleFirmItUp(context),
            ),
          ),
        SizedBox(height: AppSpacing.md),
        // Group Vibe Summary
        buildAnimatedSection(
          sectionIndex: 1,
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
      backgroundColor: AppColors.transparent,
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
