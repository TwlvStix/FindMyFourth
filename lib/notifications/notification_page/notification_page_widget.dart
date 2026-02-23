import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/alert_subscription.dart';
import '/models/notification_preferences.dart';
import '/notifications/game_alerts_page/game_alerts_page_widget.dart';
import '/services/alert_subscription_service.dart';
import '/services/notification_permission_service.dart';
import '/utils/app_util.dart';

/// Premium Notification Settings Page
///
/// Hierarchical toggle model:
/// - Push notifications (master) - controls everything
///   - Game alerts (submaster) - links to detail page
///   - Chat alerts (submaster) - single toggle
///
/// When Push is OFF:
/// - Game Alerts and Chat Alerts sections are disabled/grayed
/// - gameAlertsEnabled and chatAlertsEnabled are set to false
class NotificationPageWidget extends StatefulWidget {
  const NotificationPageWidget({super.key});

  static String routeName = 'NotificationPage';
  static String routePath = '/notificationPage';

  @override
  State<NotificationPageWidget> createState() =>
      _NotificationPageWidgetState();
}

class _NotificationPageWidgetState extends State<NotificationPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Working copies
  NotificationPreferences? _prefs;
  AlertSubscription? _alertSub;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _hasChanges = false;

  // Quiet hours
  static final List<_DigestOption> _digestOptions = [
    _DigestOption(value: 'instant', label: 'Instant', phosphorIcon: AppPhosphorIcons.notifications),
    _DigestOption(value: 'hourly', label: 'Hourly', phosphorIcon: AppPhosphorIcons.teeTime),
    _DigestOption(value: 'daily', label: 'Daily', phosphorIcon: AppPhosphorIcons.calendarCheck),
    _DigestOption(value: 'off', label: 'Off', phosphorIcon: AppPhosphorIcons.blocked),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      AppLog.d('📱 [NotificationSettings] Loading data for user: $currentUserUid');

      // Load notification preferences and alert subscription
      NotificationPreferences? prefs;
      AlertSubscription? alertSub;

      try {
        prefs = await _loadNotificationPrefs();
        AppLog.d('📱 [NotificationSettings] Loaded notification prefs: ${prefs.toFirestore()}');
      } catch (e) {
        AppLog.d('📱 [NotificationSettings] Error loading prefs, using defaults: $e');
        prefs = NotificationPreferences.defaults();
      }

      try {
        alertSub = await AlertSubscriptionService.loadSubscription(currentUserUid);
        AppLog.d('📱 [NotificationSettings] Loaded alert subscription: ${alertSub != null ? "exists" : "null"}');
      } catch (e) {
        AppLog.d('📱 [NotificationSettings] Error loading alert sub, using defaults: $e');
        alertSub = null;
      }

      // If no alertSub document exists, create the default (enabled, no filters = all games)
      // so the backend will include this user in game notifications without requiring an explicit save.
      if (alertSub == null) {
        final defaultSub = AlertSubscription.defaults(currentUserUid);
        AlertSubscriptionService.saveSubscription(defaultSub).catchError((e) {
          AppLog.d('📱 [NotificationSettings] Failed to auto-save default alertSub: $e');
        });
        alertSub = defaultSub;
      }

      setState(() {
        _prefs = prefs;
        _alertSub = alertSub;
        _isLoading = false;
        _hasChanges = false;
      });

      AppLog.d('📱 [NotificationSettings] Successfully loaded all settings');
    } catch (e, stackTrace) {
      AppLog.d('📱 [NotificationSettings] Critical error loading settings: $e');
      AppLog.d('📱 [NotificationSettings] Stack trace: $stackTrace');

      // Try to set defaults so user can at least use the page
      setState(() {
        _prefs = NotificationPreferences.defaults();
        _alertSub = AlertSubscription.defaults(currentUserUid);
        _errorMessage = 'Could not load settings. Using defaults. Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<NotificationPreferences> _loadNotificationPrefs() async {
    AppLog.d('📱 [NotificationSettings] Loading notification prefs...');

    if (currentUserReference == null) {
      AppLog.d('📱 [NotificationSettings] currentUserReference is null');
      return NotificationPreferences.defaults();
    }

    try {
      final userDoc = await currentUserReference!.get();
      AppLog.d('📱 [NotificationSettings] User doc exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        AppLog.d('📱 [NotificationSettings] User data keys: ${userData?.keys.toList()}');

        final prefsData = userData?['notification_prefs'] as Map<String, dynamic>?;
        AppLog.d('📱 [NotificationSettings] Prefs data exists: ${prefsData != null}');

        if (prefsData != null) {
          return NotificationPreferences.fromMap(prefsData);
        }
      }
    } catch (e) {
      AppLog.d('📱 [NotificationSettings] Error in _loadNotificationPrefs: $e');
      throw e;
    }

    AppLog.d('📱 [NotificationSettings] Returning default prefs');
    return NotificationPreferences.defaults();
  }

  Future<void> _saveNotificationPrefs(NotificationPreferences prefs) async {
    if (currentUserReference == null) return;

    await currentUserReference!.update({
      'notification_prefs': prefs.toFirestore(),
    });
  }

  Future<void> _save() async {
    if (_prefs == null || _alertSub == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Save both notification preferences and alert subscription
      await Future.wait([
        _saveNotificationPrefs(_prefs!),
        AlertSubscriptionService.saveSubscription(_alertSub!),
      ]);

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      if (mounted) {
        // Navigate back to Profile page
        context.pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings saved successfully',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.navy,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save settings: $e';
      });
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.navyDark,
        title: Text(
          'Reset to Defaults?',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'This will reset all notification settings to defaults:\n\n'
          '• Push notifications: ON\n'
          '• Game alerts: OFF\n'
          '• Chat alerts: ON\n'
          '• All filters: Cleared',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.glassTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        // Reset to defaults
        _prefs = NotificationPreferences.defaults();
        _alertSub = AlertSubscription.defaults(currentUserUid);
        _hasChanges = true;
      });
    }
  }

  void _updatePrefs(NotificationPreferences updated) {
    setState(() {
      _prefs = updated;
      _hasChanges = true;
    });
  }

  void _updateAlertSub(AlertSubscription updated) {
    setState(() {
      _alertSub = updated;
      _hasChanges = true;
    });
  }

  Future<void> _togglePushNotifications(bool enabled) async {
    if (enabled) {
      final granted = await _ensureNotificationPermission();
      if (!granted) {
        return;
      }
    }

    // When Push is turned OFF, disable downstream toggles
    if (!enabled) {
      _updatePrefs(
        _prefs!.copyWith(
          pushEnabled: false,
          gameAlerts: _prefs!.gameAlerts.copyWith(enabled: false),
          chatAlerts: _prefs!.chatAlerts.copyWith(enabled: false),
        ),
      );
      _updateAlertSub(_alertSub!.copyWith(enabled: false));
    } else {
      // When turned ON, just enable push
      _updatePrefs(_prefs!.copyWith(pushEnabled: true));
    }
  }

  void _toggleGameAlerts(bool enabled) {
    // Update both notification prefs and alert subscription
    _updatePrefs(
      _prefs!.copyWith(
        gameAlerts: _prefs!.gameAlerts.copyWith(enabled: enabled),
      ),
    );
    _updateAlertSub(_alertSub!.copyWith(enabled: enabled));
  }

  void _toggleChatAlerts(bool enabled) {
    _updatePrefs(
      _prefs!.copyWith(
        chatAlerts: _prefs!.chatAlerts.copyWith(enabled: enabled),
      ),
    );
  }

  void _togglePostRound(bool enabled) {
    _updatePrefs(_prefs!.copyWith(
      trustCategories: _prefs!.trustCategories.copyWith(postRound: enabled),
    ));
  }

  void _toggleTrustAlerts(bool enabled) {
    _updatePrefs(_prefs!.copyWith(
      trustCategories: _prefs!.trustCategories.copyWith(trustAlerts: enabled),
    ));
  }

  void _toggleBadges(bool enabled) {
    _updatePrefs(_prefs!.copyWith(
      trustCategories: _prefs!.trustCategories.copyWith(badges: enabled),
    ));
  }

  Future<void> _navigateToGameAlerts() async {
    if (!_prefs!.pushEnabled || !_prefs!.gameAlerts.enabled) {
      // Don't navigate if disabled
      return;
    }

    // Save alert subscription before navigating to preserve enabled state
    // This ensures the Game Alerts page loads the correct enabled state
    try {
      await AlertSubscriptionService.saveSubscription(_alertSub!);
      AppLog.d('📱 [NotificationSettings] Saved alert subscription before navigation');
    } catch (e) {
      AppLog.d('📱 [NotificationSettings] Error saving alert sub before navigation: $e');
      // Continue anyway - Game Alerts page will handle gracefully
    }

    // Navigate to Game Alerts detail page and get returned subscription
    final updatedSub = await context.pushNamed<AlertSubscription>(
      GameAlertsPageWidget.routeName,
    );

    // If subscription was returned (user saved), use it directly
    // This avoids race conditions with Firestore sync
    if (updatedSub != null) {
      AppLog.d('📱 [NotificationSettings] Received updated subscription: enabled=${updatedSub.enabled}, filters=${updatedSub.getSummary()}');
      if (mounted) {
        setState(() {
          _alertSub = updatedSub;
        });
        AppLog.d('📱 [NotificationSettings] Updated alert subscription from navigation result');
      }
    } else {
      AppLog.d('📱 [NotificationSettings] No subscription returned, reloading from Firestore');
      // User navigated back without saving, reload from Firestore
      if (mounted) {
        await _reloadAlertSubscription();
      }
    }
  }

  /// Reload only the alert subscription without touching notification prefs
  /// Used when returning from Game Alerts detail page
  Future<void> _reloadAlertSubscription() async {
    try {
      final alertSub = await AlertSubscriptionService.loadSubscription(currentUserUid);
      setState(() {
        _alertSub = alertSub ?? AlertSubscription.defaults(currentUserUid);
      });
      AppLog.d('📱 [NotificationSettings] Reloaded alert subscription');
    } catch (e) {
      AppLog.d('📱 [NotificationSettings] Error reloading alert sub: $e');
      // Don't update state if reload fails - keep existing data
    }
  }

  Future<bool> _ensureNotificationPermission() async {
    AppLog.d('📱 [NotificationSettings] Requesting notification permission (user action)');
    final status =
        await NotificationPermissionService().requestPermissionAndRegister();

    // Trigger rebuild to update UI with new cached status
    if (mounted) {
      setState(() {});
    }

    AppLog.d('📱 [NotificationSettings] Permission result: $status');
    return status == NotificationPermissionStatus.granted ||
        status == NotificationPermissionStatus.provisional;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialValue =
        isStart ? _prefs!.quietHours.start : _prefs!.quietHours.end;
    final initialTime = _parseTime(initialValue) ?? TimeOfDay(hour: 22, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) {
      return;
    }
    final formatted = _formatTime(picked);
    setState(() {
      _prefs = _prefs!.copyWith(
        quietHours: _prefs!.quietHours.copyWith(
          start: isStart ? formatted : _prefs!.quietHours.start,
          end: isStart ? _prefs!.quietHours.end : formatted,
        ),
      );
      _hasChanges = true;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Custom styled buttons for better visibility on dark background
  Widget _buildResetButton() {
    final isDisabled = _isSaving;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : _reset,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: isDisabled
                  ? AppColors.stone.withValues(alpha: 0.3)
                  : AppColors.pure.withValues(alpha: 0.4),
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              'Reset',
              style: AppTypography.buttonLarge.copyWith(
                color: isDisabled ? AppColors.stone : AppColors.pure,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isDisabled = _isSaving || !_hasChanges;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : _save,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.stone.withValues(alpha: 0.3)
                : AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(
              color: isDisabled
                  ? Colors.transparent
                  : AppColors.pure.withValues(alpha: 0.3),
              width: 2.0,
            ),
            boxShadow: isDisabled ? [] : [AppElevation.lg],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.pure),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                ] else ...[
                  AppIcon(
                    icon: AppPhosphorIcons.check,
                    size: AppIconSize.button,
                    color: AppColors.pure,
                  ),
                  SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  _isSaving ? 'Saving...' : 'Save Settings',
                  style: AppTypography.buttonLarge.copyWith(
                    color: AppColors.pure,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    String? emoji,
    String? svgPath,
    PhosphorIconData? phosphorIcon,
    required String title,
    String? subtitle,
    required List<Widget> children,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(
              color: disabled
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  subtitle != null ? AppSpacing.xs : AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (phosphorIcon != null)
                          AppIcon(
                            icon: phosphorIcon,
                            size: AppIconSize.button,
                            color: AppColors.pure,
                          )
                        else if (svgPath != null)
                          AppIcon(
                            assetPath: svgPath,
                            size: AppIconSize.button,
                            color: AppColors.pure,
                          )
                        else if (emoji != null)
                          Text(
                            emoji,
                            style: TextStyle(fontSize: 20),
                          ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
                thickness: 1,
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white.withValues(alpha: 0.5);
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.gold;
              }
              return Colors.white.withValues(alpha: 0.2);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    PhosphorIconData? phosphorIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (phosphorIcon != null) ...[
              AppIcon(
                icon: phosphorIcon,
                size: AppIconSize.md,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppIconSize.md,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              time,
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            AppIcon(
              icon: AppPhosphorIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppIconSize.button,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigestModeSelector() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _digestOptions.map((option) {
          final isSelected = _prefs!.digestMode == option.value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _prefs = _prefs!.copyWith(digestMode: option.value);
                _hasChanges = true;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: option.phosphorIcon,
                    size: AppIconSize.button,
                    color: isSelected
                        ? AppColors.navyDark
                        : AppColors.textSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    option.label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.navyDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        leading: const PremiumBackButton(),
        title: Text(
          'Notification Settings',
          style: AppTypography.headlineMediumSans.copyWith(
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.gold,
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Loading settings...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : _prefs == null || _alertSub == null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              icon: AppPhosphorIcons.error,
                              size: AppIconSize.hero,
                              color: AppColors.error,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Failed to load settings',
                              style: AppTypography.headlineSmallSans.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_errorMessage != null) ...[
                              SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.5),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            SizedBox(height: AppSpacing.lg),
                            AppButtonEnhanced(
                              text: 'Retry',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.medium,
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        // Main content
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            120, // Space for sticky bottom bar
                          ),
                          children: [
                            // Header
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: Text(
                                'Manage push notifications, game alerts, and chat alerts.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            SizedBox(height: AppSpacing.lg),

                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: EdgeInsets.all(AppSpacing.md),
                                margin: EdgeInsets.only(bottom: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.5),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AppIcon(
                                      icon: AppPhosphorIcons.error,
                                      color: AppColors.error,
                                      size: AppIconSize.md,
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // MASTER: Push Notifications
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.notifications,
                              title: 'Push Notifications',
                              subtitle:
                                  'Master control for all notifications',
                              children: [
                                _buildToggleRow(
                                  title: 'Enable push notifications',
                                  subtitle:
                                      'Allow notifications for games and chats',
                                  value: _prefs!.pushEnabled,
                                  onChanged: _togglePushNotifications,
                                ),
                              ],
                            ),

                            // Permission status (using cached state, no async in build)
                            Builder(
                              builder: (context) {
                                final status = NotificationPermissionService().cachedStatus;

                                if (status ==
                                    NotificationPermissionStatus
                                        .permanentlyDenied) {
                                  return Container(
                                    margin:
                                        EdgeInsets.only(bottom: AppSpacing.md),
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                      border: Border.all(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        AppIcon(
                                          icon: AppPhosphorIcons.settings,
                                          size: AppIconSize.xl,
                                          color: AppColors.warning,
                                        ),
                                        SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'Notification permission required',
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Please enable notifications in Settings',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: AppSpacing.md),
                                        AppButtonEnhanced(
                                          onPressed: () async {
                                            await NotificationPermissionService()
                                                .openSystemSettings();
                                          },
                                          text: 'Open Settings',
                                          trailingIcon: AppPhosphorIcons.externalLink,
                                          size: AppButtonSize.small,
                                          variant: AppButtonVariant.primary,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return SizedBox.shrink();
                              },
                            ),

                            // SUBMASTER: Game Alerts
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.games,
                              title: 'Game Alerts',
                              subtitle: 'Get notified when games match your preferences',
                              disabled: !_prefs!.pushEnabled,
                              children: [
                                _buildToggleRow(
                                  title: 'Enable game alerts',
                                  value: _prefs!.gameAlerts.enabled,
                                  onChanged: _toggleGameAlerts,
                                ),

                                // Show summary and configure button when enabled
                                if (_prefs!.gameAlerts.enabled && _prefs!.pushEnabled) ...[
                                  Divider(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    height: 1,
                                    thickness: 1,
                                  ),

                                  // Summary
                                  Padding(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            AppIcon(
                                              icon: AppPhosphorIcons.info,
                                              color: AppColors.gold,
                                              size: AppIconSize.xs,
                                            ),
                                            SizedBox(width: AppSpacing.xs),
                                            Text(
                                              'Current filters',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          _alertSub!.getSummary(),
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: AppTypography.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Divider(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    height: 1,
                                    thickness: 1,
                                  ),

                                  // Configure button
                                  _buildNavigationRow(
                                    phosphorIcon: AppPhosphorIcons.settings,
                                    title: 'Configure filters',
                                    subtitle: 'Set game vibe, stakes, format, courses, and more',
                                    onTap: _navigateToGameAlerts,
                                  ),
                                ],
                              ],
                            ),

                            // SUBMASTER: Chat Alerts
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.chat,
                              title: 'Chat Alerts',
                              subtitle: 'Get notified for chat messages',
                              disabled: !_prefs!.pushEnabled,
                              children: [
                                _buildToggleRow(
                                  title: 'Enable chat alerts',
                                  value: _prefs!.chatAlerts.enabled,
                                  onChanged: _toggleChatAlerts,
                                ),
                              ],
                            ),

                            // SUBMASTER: Trust & Reliability
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.standing,
                              title: 'Trust & Reliability',
                              subtitle: 'Check-ins, account standing, and badge updates',
                              disabled: !_prefs!.pushEnabled,
                              children: [
                                _buildToggleRow(
                                  title: 'Post-round check-ins',
                                  subtitle: 'Check-in reminders after your rounds',
                                  value: _prefs!.trustCategories.postRound,
                                  onChanged: _togglePostRound,
                                ),
                                Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  height: 1,
                                  thickness: 1,
                                ),
                                _buildToggleRow(
                                  title: 'Account standing alerts',
                                  subtitle: 'Strikes, cooldowns, and restrictions',
                                  value: _prefs!.trustCategories.trustAlerts,
                                  onChanged: _toggleTrustAlerts,
                                ),
                                Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  height: 1,
                                  thickness: 1,
                                ),
                                _buildToggleRow(
                                  title: 'Badge progress',
                                  subtitle: 'Badge milestones and progress updates',
                                  value: _prefs!.trustCategories.badges,
                                  onChanged: _toggleBadges,
                                ),
                              ],
                            ),

                            // Quiet Hours
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.moon,
                              title: 'Quiet Hours',
                              subtitle: 'Pause notifications during specific hours',
                              children: [
                                _buildToggleRow(
                                  title: 'Enable quiet hours',
                                  value: _prefs!.quietHours.enabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _prefs = _prefs!.copyWith(
                                        quietHours: _prefs!.quietHours
                                            .copyWith(enabled: value),
                                      );
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                                if (_prefs!.quietHours.enabled) ...[
                                  Divider(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  _buildTimeRow(
                                    label: 'Start',
                                    time: _prefs!.quietHours.start,
                                    onTap: () => _pickTime(isStart: true),
                                  ),
                                  Divider(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  _buildTimeRow(
                                    label: 'End',
                                    time: _prefs!.quietHours.end,
                                    onTap: () => _pickTime(isStart: false),
                                  ),
                                ],
                              ],
                            ),

                            // Digest Mode
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.digest,
                              title: 'Digest Mode',
                              subtitle: 'Control notification frequency',
                              children: [
                                _buildDigestModeSelector(),
                              ],
                            ),

                            // Muted Threads
                            _buildSection(
                              phosphorIcon: AppPhosphorIcons.muted,
                              title: 'Muted Threads',
                              children: [
                                _buildNavigationRow(
                                  title: 'Muted threads',
                                  subtitle:
                                      '${_prefs!.mutedThreads.length} muted',
                                  onTap: () {
                                    // TODO: Navigate to muted threads management
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Sticky bottom bar
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.navyDark.withValues(alpha: 0.95),
                                  AppColors.navyDark,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.0, 0.3, 1.0],
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildResetButton(),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    flex: 2,
                                    child: _buildSaveButton(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _DigestOption {
  const _DigestOption({
    required this.value,
    required this.label,
    required this.phosphorIcon,
  });

  final String value;
  final String label;
  final PhosphorIconData phosphorIcon;
}
