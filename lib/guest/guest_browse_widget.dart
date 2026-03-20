import 'package:flutter/material.dart';

import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_empty_state.dart';
import '/core/widgets/app_loading_state.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/motion/motion_helpers.dart';
import '/core/navigation/nav_extensions.dart';
import '/main_function/games_list/components/unified_game_card.dart';
import '/main_function/games_list/utils/games_list_pipeline.dart';
import '/models/game.dart';
import '/services/game_service.dart';

class GuestBrowseWidget extends StatefulWidget {
  const GuestBrowseWidget({super.key});

  static const String routeName = 'GuestBrowse';
  static const String routePath = '/guest-browse';

  @override
  State<GuestBrowseWidget> createState() => _GuestBrowseWidgetState();
}

class _GuestBrowseWidgetState extends State<GuestBrowseWidget> {
  late final GameService _gameService;
  late final Stream<List<Game>> _gamesStream;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _gamesStream = _gameService.queryPublicGames().map((records) {
      final games = filterActiveGames(
        records.map((r) => Game.fromRecord(r)).toList(),
      );
      games.sort((a, b) =>
          (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)));
      return games;
    });
  }

  void _showSignUpPrompt() {
    showAppBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.navyDark,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.xxl),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xxs),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Join Find My Fourth',
                  style: AppTypography.headlineMediumSans.copyWith(
                    color: AppColors.pure,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign up to join games, find playing partners, and match with golfers who share your vibe.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.lg),
                AppButtonEnhanced(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.context.pushSignUpAccount();
                  },
                  text: 'Sign Up',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  fullWidth: true,
                ),
                SizedBox(height: AppSpacing.sm),
                AppButtonEnhanced(
                  onPressed: () => Navigator.of(context).pop(),
                  text: 'Not now',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.large,
                  fullWidth: true,
                ),
                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        leading: const PremiumBackButton(),
        title: Text(
          'Find a Game',
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pushSignUpAccount(),
            child: Text(
              'Sign Up',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.green,
              ),
            ),
          ),
        ],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: StreamBuilder<List<Game>>(
          stream: _gamesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: AppLoadingState(
                  variant: AppLoadingVariant.spinner,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: AppEmptyState(
                  phosphorIcon: AppPhosphorIcons.golf,
                  title: 'Unable to load games',
                  message: 'Please try again later.',
                ),
              );
            }

            final games = snapshot.data ?? [];
            if (games.isEmpty) {
              return Center(
                child: AppEmptyState(
                  phosphorIcon: AppPhosphorIcons.golf,
                  title: 'No games posted yet',
                  message: 'Be the first — sign up to create a game.',
                  actionText: 'Sign Up',
                  onAction: () => context.pushSignUpAccount(),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: topPadding + 56,
                bottom: AppSpacing.xl,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: UnifiedGameCard(
                    game: games[index],
                    currentUserReference: null,
                    vibeScore: null,
                    showStatusBadge: false,
                    animationIndex: index,
                    onTap: _showSignUpPrompt,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
