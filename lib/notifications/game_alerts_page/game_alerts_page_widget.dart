import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/models/alert_subscription.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/main_function/create_game/create_game_constants.dart';
import '/utils/app_util.dart';

import 'components/alert_action_bar.dart';
import 'components/alert_filter_card.dart';
import 'components/alert_filter_chips.dart';
import 'components/alert_navigation_card.dart';
import 'components/alert_section_label.dart';
import 'components/alert_status_banners.dart';
import 'components/alert_toggle_card.dart';
import 'components/alert_watching_summary.dart';
import 'game_alerts_page_controller.dart';

/// Premium Game Alerts page
/// Configure which games trigger push notifications
class GameAlertsPageWidget extends StatefulWidget {
  const GameAlertsPageWidget({super.key});

  static String routeName = 'GameAlertsPage';
  static String routePath = '/gameAlertsPage';

  @override
  State<GameAlertsPageWidget> createState() => _GameAlertsPageWidgetState();
}

class _GameAlertsPageWidgetState extends State<GameAlertsPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final GameAlertsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameAlertsPageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await _controller.save();
    if (success && mounted) {
      _controller.showSuccessSnackbar(context, 'Alert settings saved');
      context.pop(_controller.subscription);
    }
  }

  Future<void> _handleReset() async {
    await _controller.showResetConfirmation(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.transparent,
      appBar: _buildAppBar(),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildBody(),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0.0,
      leading: const PremiumBackButton(),
      title: Text(
        'Game Alerts',
        style: AppTypography.headlineMediumSans.copyWith(
          color: AppColors.pure,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return _buildLoadingState();
    }

    if (_controller.subscription == null) {
      return _buildErrorState();
    }

    return _buildContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(height: AppSpacing.md),
          Text(
            'Loading alert settings...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.glassTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        'Failed to load subscription',
        style: AppTypography.bodyLarge.copyWith(color: AppColors.pure),
      ),
    );
  }

  Widget _buildContent() {
    final sub = _controller.subscription!;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            120, // Space for sticky bottom bar
          ),
          children: [
            // Status banners
            if (_controller.errorMessage != null)
              AlertErrorBanner(message: _controller.errorMessage!),
            const AlertPermissionWarning(),

            // Watching summary
            AlertWatchingSummary(subscription: sub),

            // FILTERS section
            const AlertSectionLabel(text: 'FILTERS', isFirst: true),
            _buildFilterCards(sub),

            // SPECIAL section
            const AlertSectionLabel(text: 'SPECIAL'),
            _buildSpecialToggles(sub),

            // COURSES section
            const AlertSectionLabel(text: 'COURSES'),
            AlertNavigationCard(
              title: 'Courses',
              icon: AppPhosphorIcons.golfCourse,
              subtitle: _controller.coursesSubtitle,
              onTap: () => _controller.showCoursesPicker(context),
            ),
          ],
        ),

        // Sticky bottom action bar
        AlertActionBar(
          isSaving: _controller.isSaving,
          hasChanges: _controller.hasChanges,
          onReset: _handleReset,
          onSave: _handleSave,
        ),
      ],
    );
  }

  Widget _buildFilterCards(AlertSubscription sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AlertFilterCard(
          title: 'Game Vibe',
          icon: AppPhosphorIcons.gameVibe,
          selectedValues: sub.gameVibes,
          isExpanded: _controller.expandedFilterIndex == 0,
          onTap: () => _controller.toggleFilterExpanded(0),
          expandedContent: AlertFilterChips(
            selectedValues: sub.gameVibes,
            options: kCreateGameVibeOptions,
            onChanged: (values) {
              _controller.updateSubscription(sub.copyWith(gameVibes: values));
            },
          ),
        ),
        AlertFilterCard(
          title: 'Stakes',
          icon: AppPhosphorIcons.betting,
          selectedValues: sub.stakes,
          isExpanded: _controller.expandedFilterIndex == 1,
          onTap: () => _controller.toggleFilterExpanded(1),
          expandedContent: AlertFilterChips(
            selectedValues: sub.stakes,
            options: kCreateGameStakesOptions,
            onChanged: (values) {
              _controller.updateSubscription(sub.copyWith(stakes: values));
            },
          ),
        ),

        // Primary Format
        AlertFilterCard(
          title: 'Primary Format',
          icon: AppPhosphorIcons.trophy,
          selectedValues: sub.formats,
          isExpanded: _controller.expandedFilterIndex == 2,
          onTap: () => _controller.toggleFilterExpanded(2),
          expandedContent: AlertFilterChips(
            selectedValues: sub.formats,
            options: kCreateGamePrimaryFormatOptions,
            onChanged: (values) {
              _controller.updateSubscription(sub.copyWith(formats: values));
            },
          ),
        ),

        // Handicap Use
        AlertFilterCard(
          title: 'Handicap Use',
          icon: AppPhosphorIcons.scoring,
          selectedValues: sub.handicapUses,
          isExpanded: _controller.expandedFilterIndex == 3,
          onTap: () => _controller.toggleFilterExpanded(3),
          expandedContent: AlertFilterChips(
            selectedValues: sub.handicapUses,
            options: kCreateGameHandicapOptions,
            onChanged: (values) {
              _controller.updateSubscription(sub.copyWith(handicapUses: values));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialToggles(AlertSubscription sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Side Games
        AlertToggleCard(
          title: 'Side Games',
          icon: AppPhosphorIcons.wolf,
          value: sub.special.games,
          onChanged: (value) {
            _controller.updateSubscription(
              sub.copyWith(special: sub.special.copyWith(games: value)),
            );
          },
        ),

        // 2v2 (Teams)
        AlertToggleCard(
          title: '2v2 (Teams)',
          icon: AppPhosphorIcons.teams,
          value: sub.special.twoVTwo,
          onChanged: (value) {
            _controller.updateSubscription(
              sub.copyWith(special: sub.special.copyWith(twoVTwo: value)),
            );
          },
        ),

        // Discounted Games
        AlertToggleCard(
          title: 'Discounted Games',
          icon: AppPhosphorIcons.memberDiscount,
          value: sub.special.discount,
          onChanged: (value) {
            _controller.updateSubscription(
              sub.copyWith(special: sub.special.copyWith(discount: value)),
            );
          },
        ),
      ],
    );
  }
}
