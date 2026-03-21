import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/notification_preferences.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/notification_category_card.dart';
import '/notification_settings/components/notification_profile_card.dart';
import '/notification_settings/components/notification_summary_helpers.dart';
import '/notification_settings/components/game_alerts_content.dart';
import '/notification_settings/components/chat_content.dart';
import '/notification_settings/components/trust_content.dart';
import '/notification_settings/components/quiet_hours_content.dart';
import '/notification_settings/components/social_alerts_content.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  static const String routeName = 'NotificationSettings';
  static const String routePath = '/notificationSettings';

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  /// Index of currently expanded card (null = none expanded)
  int? _expandedIndex;

  /// Flag to trigger entrance animations only once
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _hasAnimated = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.selectNotification((p) => p.preferences);
    final activeProfile = prefs.activeProfile;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: const PremiumBackButton(),
        title: Text(
          'Notifications',
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding + 100, // Clear home indicator
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Profiles Section Label
            Text(
              'QUICK PROFILES',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // 2x2 Grid of Profile Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                NotificationProfileCard(
                  profile: NotificationProfile.allIn,
                  icon: AppPhosphorIcons.notifications,
                  title: 'All in',
                  description: 'Every game, every message',
                  isActive: activeProfile == NotificationProfile.allIn,
                  onTap: () => _applyProfile(NotificationProfile.allIn),
                ),
                NotificationProfileCard(
                  profile: NotificationProfile.gameDay,
                  icon: AppPhosphorIcons.teeTime,
                  title: 'Game day',
                  description: 'Games only, no chatter',
                  isActive: activeProfile == NotificationProfile.gameDay,
                  onTap: () => _applyProfile(NotificationProfile.gameDay),
                ),
                NotificationProfileCard(
                  profile: NotificationProfile.essentials,
                  icon: AppPhosphorIcons.shield,
                  title: 'Essentials',
                  description: 'Trust and account only',
                  isActive: activeProfile == NotificationProfile.essentials,
                  onTap: () => _applyProfile(NotificationProfile.essentials),
                ),
                NotificationProfileCard(
                  profile: NotificationProfile.quiet,
                  icon: AppPhosphorIcons.muted,
                  title: 'Quiet',
                  description: 'Pause everything',
                  isActive: activeProfile == NotificationProfile.quiet,
                  onTap: () => _applyProfile(NotificationProfile.quiet),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),

            // Fine-Tune Section Label
            Text(
              'FINE-TUNE',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: AppSpacing.sm),

            // Category Cards
            ..._buildCategoryCards(prefs),

            // Muted threads card hidden until feature is complete.
            // To re-enable: uncomment and add _buildMutedThreadsCard(prefs) here.
          ],
        ),
      ),
    );
  }

  void _applyProfile(NotificationProfile profile) {
    context.notificationProvider.applyProfile(profile);
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  List<Widget> _buildCategoryCards(NotificationPreferences prefs) {
    final cards = [
      _buildGameAlertsCard(prefs),
      _buildChatMessagesCard(prefs),
      _buildSocialCard(prefs),
      _buildTrustCard(prefs),
      _buildQuietHoursCard(prefs),
    ];

    return cards.asMap().entries.map((entry) {
      final index = entry.key;
      final card = entry.value;

      return Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: card
            .animate(target: _hasAnimated ? 1 : 0)
            .fadeIn(
              delay: Duration(milliseconds: index * 24),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            )
            .slideY(
              delay: Duration(milliseconds: index * 24),
              begin: 0.05,
              end: 0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            ),
      );
    }).toList();
  }

  Widget _buildGameAlertsCard(NotificationPreferences prefs) {
    return NotificationCategoryCard(
      title: 'Game alerts',
      summary: getGameAlertsSummary(prefs),
      icon: AppPhosphorIcons.games,
      isEnabled: prefs.gameAlerts.enabled,
      isExpanded: _expandedIndex == 0,
      onToggle: () {
        context.notificationProvider
            .updateGameAlerts(enabled: !prefs.gameAlerts.enabled);
        showNotificationUpdateConfirmation(context);
      },
      onTap: () => _toggleExpanded(0),
      expandedContent: const GameAlertsContent(),
    );
  }

  Widget _buildChatMessagesCard(NotificationPreferences prefs) {
    return NotificationCategoryCard(
      title: 'Chat messages',
      summary: getChatAlertsSummary(prefs),
      icon: AppPhosphorIcons.chat,
      isEnabled: prefs.chatAlerts.enabled,
      isExpanded: _expandedIndex == 1,
      onToggle: () {
        context.notificationProvider
            .updateChatAlerts(enabled: !prefs.chatAlerts.enabled);
        showNotificationUpdateConfirmation(context);
      },
      onTap: () => _toggleExpanded(1),
      expandedContent: const ChatContent(),
    );
  }

  Widget _buildSocialCard(NotificationPreferences prefs) {
    return NotificationCategoryCard(
      title: 'Social',
      summary: prefs.socialAlerts.enabled ? 'On' : 'Off',
      icon: AppPhosphorIcons.golfers,
      isEnabled: prefs.socialAlerts.enabled,
      isExpanded: _expandedIndex == 2,
      onToggle: () {
        context.notificationProvider
            .updateSocialAlerts(enabled: !prefs.socialAlerts.enabled);
        showNotificationUpdateConfirmation(context);
      },
      onTap: () => _toggleExpanded(2),
      expandedContent: const SocialAlertsContent(),
    );
  }

  Widget _buildTrustCard(NotificationPreferences prefs) {
    final isEnabled = isTrustEnabled(prefs);
    return NotificationCategoryCard(
      title: 'Trust and reliability',
      summary: getTrustSummary(prefs),
      icon: AppPhosphorIcons.trust,
      isEnabled: isEnabled,
      isExpanded: _expandedIndex == 3,
      onToggle: () {
        context.notificationProvider
            .updateTrustCategories(enabled: !prefs.trustCategories.enabled);
        showNotificationUpdateConfirmation(context);
      },
      onTap: () => _toggleExpanded(3),
      expandedContent: const TrustContent(),
    );
  }

  Widget _buildQuietHoursCard(NotificationPreferences prefs) {
    return NotificationCategoryCard(
      title: 'Quiet hours',
      summary: getQuietHoursSummary(prefs),
      icon: AppPhosphorIcons.moon,
      isEnabled: prefs.quietHours.enabled,
      isExpanded: _expandedIndex == 4,
      onToggle: () {
        context.notificationProvider
            .updateQuietHours(enabled: !prefs.quietHours.enabled);
        showNotificationUpdateConfirmation(context);
      },
      onTap: () => _toggleExpanded(4),
      expandedContent: const QuietHoursContent(),
    );
  }

}
