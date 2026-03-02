import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/motion/motion_tokens.dart';
import '/models/notification_preferences.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/notification_category_card.dart';
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
    final provider = context.watchNotificationProvider;
    final prefs = provider.preferences;
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
                _ProfileCard(
                  profile: NotificationProfile.allIn,
                  icon: AppPhosphorIcons.notifications,
                  title: 'All in',
                  description: 'Every game, every message',
                  isActive: activeProfile == NotificationProfile.allIn,
                  onTap: () => _applyProfile(NotificationProfile.allIn),
                ),
                _ProfileCard(
                  profile: NotificationProfile.gameDay,
                  icon: AppPhosphorIcons.teeTime,
                  title: 'Game day',
                  description: 'Games only, no chatter',
                  isActive: activeProfile == NotificationProfile.gameDay,
                  onTap: () => _applyProfile(NotificationProfile.gameDay),
                ),
                _ProfileCard(
                  profile: NotificationProfile.essentials,
                  icon: AppPhosphorIcons.shield,
                  title: 'Essentials',
                  description: 'Trust and account only',
                  isActive: activeProfile == NotificationProfile.essentials,
                  onTap: () => _applyProfile(NotificationProfile.essentials),
                ),
                _ProfileCard(
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

  void _showUpdateConfirmation() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AppIcon(
              icon: AppPhosphorIcons.success,
              size: AppIconSize.md,
              color: AppColors.green,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Settings updated',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          side: BorderSide(
            color: AppColors.green.withValues(alpha: 0.15),
          ),
        ),
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(AppSpacing.md),
      ),
    );
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
      summary: _getGameAlertsSummary(prefs),
      icon: AppPhosphorIcons.games,
      isEnabled: prefs.gameAlerts.enabled,
      isExpanded: _expandedIndex == 0,
      onToggle: () {
        context.notificationProvider
            .updateGameAlerts(enabled: !prefs.gameAlerts.enabled);
        _showUpdateConfirmation();
      },
      onTap: () => _toggleExpanded(0),
      expandedContent: const GameAlertsContent(),
    );
  }

  Widget _buildChatMessagesCard(NotificationPreferences prefs) {
    return NotificationCategoryCard(
      title: 'Chat messages',
      summary: _getChatAlertsSummary(prefs),
      icon: AppPhosphorIcons.chat,
      isEnabled: prefs.chatAlerts.enabled,
      isExpanded: _expandedIndex == 1,
      onToggle: () {
        context.notificationProvider
            .updateChatAlerts(enabled: !prefs.chatAlerts.enabled);
        _showUpdateConfirmation();
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
        _showUpdateConfirmation();
      },
      onTap: () => _toggleExpanded(2),
      expandedContent: const SocialAlertsContent(),
    );
  }

  Widget _buildTrustCard(NotificationPreferences prefs) {
    final isEnabled = _isTrustEnabled(prefs);
    return NotificationCategoryCard(
      title: 'Trust and reliability',
      summary: _getTrustSummary(prefs),
      icon: AppPhosphorIcons.trust,
      isEnabled: isEnabled,
      isExpanded: _expandedIndex == 3,
      onToggle: () {
        context.notificationProvider
            .updateTrustCategories(enabled: !prefs.trustCategories.enabled);
        _showUpdateConfirmation();
      },
      onTap: () => _toggleExpanded(3),
      expandedContent: const TrustContent(),
    );
  }

  Widget _buildQuietHoursCard(NotificationPreferences prefs) {
    return NotificationCategoryCard(
      title: 'Quiet hours',
      summary: _getQuietHoursSummary(prefs),
      icon: AppPhosphorIcons.moon,
      isEnabled: prefs.quietHours.enabled,
      isExpanded: _expandedIndex == 4,
      onToggle: () {
        context.notificationProvider
            .updateQuietHours(enabled: !prefs.quietHours.enabled);
        _showUpdateConfirmation();
      },
      onTap: () => _toggleExpanded(4),
      expandedContent: const QuietHoursContent(),
    );
  }

  // ============================================
  // Summary Text Generation
  // ============================================

  String _getGameAlertsSummary(NotificationPreferences prefs) {
    if (!prefs.gameAlerts.enabled) {
      return 'Off';
    }
    return _formatFrequency(prefs.gameAlerts.deliveryFrequency);
  }

  String _getChatAlertsSummary(NotificationPreferences prefs) {
    if (!prefs.chatAlerts.enabled) {
      return 'Off';
    }
    return _formatFrequency(prefs.chatAlerts.deliveryFrequency);
  }

  String _getTrustSummary(NotificationPreferences prefs) {
    final trust = prefs.trustCategories;

    if (!trust.enabled) {
      return 'Off';
    }

    // Count enabled sub-categories
    int count = 0;
    if (trust.postRound) count++;
    if (trust.trustAlerts) count++;
    if (trust.badges) count++;

    if (count == 0) {
      return 'Off';
    }

    final freq = _formatFrequency(trust.deliveryFrequency);
    if (count == 3) {
      return 'All on · $freq';
    }
    return '$count of 3 on · $freq';
  }

  bool _isTrustEnabled(NotificationPreferences prefs) {
    final trust = prefs.trustCategories;
    return trust.enabled &&
        (trust.postRound || trust.trustAlerts || trust.badges);
  }

  String _getQuietHoursSummary(NotificationPreferences prefs) {
    final qh = prefs.quietHours;
    final status = qh.enabled ? 'On' : 'Off';
    return '$status · ${_formatTime(qh.start)} – ${_formatTime(qh.end)}';
  }

  String _formatFrequency(DeliveryFrequency freq) {
    switch (freq) {
      case DeliveryFrequency.instant:
        return 'Instant';
      case DeliveryFrequency.hourly:
        return 'Hourly';
      case DeliveryFrequency.daily:
        return 'Daily';
    }
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
    required this.onTap,
  });

  final NotificationProfile profile;
  final PhosphorIconData icon;
  final String title;
  final String description;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.routeEnter,
        curve: MotionTokens.curveEnter,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: isActive
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.navyLight.withValues(alpha: 0.2),
            width: 1,
          ),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                )
              : null,
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Center(
                      child: AppIcon(
                        icon: icon,
                        size: AppIconSize.md,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  // Title
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  // Description
                  Text(
                    description,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Active checkmark badge
            if (isActive)
              Positioned(
                top: 8,
                right: 8,
                child: _AnimatedCheckmark(),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCheckmark extends StatefulWidget {
  @override
  State<_AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<_AnimatedCheckmark> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Trigger animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _visible ? 1.0 : 0.0,
      duration: MotionTokens.routeEnter,
      curve: MotionTokens.curveEnter,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: MotionTokens.routeEnter,
        curve: MotionTokens.curveEnter,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: AppIcon(
            icon: AppPhosphorIcons.check,
            size: AppIconSize.xs,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
