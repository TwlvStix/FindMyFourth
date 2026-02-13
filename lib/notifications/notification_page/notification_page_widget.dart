import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
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
  static const List<_DigestOption> _digestOptions = [
    _DigestOption(value: 'instant', label: 'Instant', icon: Icons.flash_on),
    _DigestOption(value: 'hourly', label: 'Hourly', icon: Icons.schedule),
    _DigestOption(value: 'daily', label: 'Daily', icon: Icons.calendar_today),
    _DigestOption(value: 'off', label: 'Off', icon: Icons.do_not_disturb),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint('[NotificationSettings] Loading data for user: $currentUserUid');

      // Load notification preferences and alert subscription
      NotificationPreferences? prefs;
      AlertSubscription? alertSub;

      try {
        prefs = await _loadNotificationPrefs();
        debugPrint('[NotificationSettings] Loaded notification prefs: ${prefs.toFirestore()}');
      } catch (e) {
        debugPrint('[NotificationSettings] Error loading prefs, using defaults: $e');
        prefs = NotificationPreferences.defaults();
      }

      try {
        alertSub = await AlertSubscriptionService.loadSubscription(currentUserUid);
        debugPrint('[NotificationSettings] Loaded alert subscription: ${alertSub != null ? "exists" : "null"}');
      } catch (e) {
        debugPrint('[NotificationSettings] Error loading alert sub, using defaults: $e');
        alertSub = null;
      }

      setState(() {
        _prefs = prefs;
        _alertSub = alertSub ?? AlertSubscription.defaults(currentUserUid);
        _isLoading = false;
        _hasChanges = false;
      });

      debugPrint('[NotificationSettings] Successfully loaded all settings');
    } catch (e, stackTrace) {
      debugPrint('[NotificationSettings] Critical error loading settings: $e');
      debugPrint('[NotificationSettings] Stack trace: $stackTrace');

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
    debugPrint('[NotificationSettings] Loading notification prefs...');

    if (currentUserReference == null) {
      debugPrint('[NotificationSettings] currentUserReference is null');
      return NotificationPreferences.defaults();
    }

    try {
      final userDoc = await currentUserReference!.get();
      debugPrint('[NotificationSettings] User doc exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        debugPrint('[NotificationSettings] User data keys: ${userData?.keys.toList()}');

        final prefsData = userData?['notification_prefs'] as Map<String, dynamic>?;
        debugPrint('[NotificationSettings] Prefs data exists: ${prefsData != null}');

        if (prefsData != null) {
          return NotificationPreferences.fromMap(prefsData);
        }
      }
    } catch (e) {
      debugPrint('[NotificationSettings] Error in _loadNotificationPrefs: $e');
      throw e;
    }

    debugPrint('[NotificationSettings] Returning default prefs');
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
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: AppColors.fairway,
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
        backgroundColor: AppColors.fairwayDark,
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
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
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

  Future<void> _navigateToGameAlerts() async {
    if (!_prefs!.pushEnabled || !_prefs!.gameAlerts.enabled) {
      // Don't navigate if disabled
      return;
    }

    // Save alert subscription before navigating to preserve enabled state
    // This ensures the Game Alerts page loads the correct enabled state
    try {
      await AlertSubscriptionService.saveSubscription(_alertSub!);
      debugPrint('[NotificationSettings] Saved alert subscription before navigation');
    } catch (e) {
      debugPrint('[NotificationSettings] Error saving alert sub before navigation: $e');
      // Continue anyway - Game Alerts page will handle gracefully
    }

    // Navigate to Game Alerts detail page and get returned subscription
    final updatedSub = await context.pushNamed<AlertSubscription>(
      GameAlertsPageWidget.routeName,
    );

    // If subscription was returned (user saved), use it directly
    // This avoids race conditions with Firestore sync
    if (updatedSub != null) {
      debugPrint('[NotificationSettings] Received updated subscription: enabled=${updatedSub.enabled}, filters=${updatedSub.getSummary()}');
      if (mounted) {
        setState(() {
          _alertSub = updatedSub;
        });
        debugPrint('[NotificationSettings] Updated alert subscription from navigation result');
      }
    } else {
      debugPrint('[NotificationSettings] No subscription returned, reloading from Firestore');
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
      debugPrint('[NotificationSettings] Reloaded alert subscription');
    } catch (e) {
      debugPrint('[NotificationSettings] Error reloading alert sub: $e');
      // Don't update state if reload fails - keep existing data
    }
  }

  Future<bool> _ensureNotificationPermission() async {
    debugPrint('[NotificationSettings] Requesting notification permission (user action)');
    final status =
        await NotificationPermissionService().requestPermissionAndRegister();

    // Trigger rebuild to update UI with new cached status
    if (mounted) {
      setState(() {});
    }

    debugPrint('[NotificationSettings] Permission result: $status');
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.stone.withValues(alpha: 0.3)
                : AppColors.fairway,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? Colors.transparent
                  : AppColors.pure.withValues(alpha: 0.3),
              width: 2.0,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: AppColors.fairway.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                  SizedBox(width: 8),
                ] else ...[
                  Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppColors.pure,
                  ),
                  SizedBox(width: 8),
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
    required String emoji,
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
            color: AppColors.fairway.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
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
                        Text(
                          emoji,
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
                return AppColors.sunsetGold;
              }
              return Colors.white.withValues(alpha: 0.2);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required String emoji,
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
            Text(emoji, style: TextStyle(fontSize: 24)),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
              size: 24,
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
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              time,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
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
                    ? AppColors.sunsetGold
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.sunsetGold
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: isSelected
                        ? AppColors.fairwayDark
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    option.label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.fairwayDark
                          : Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
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
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: EdgeInsets.only(left: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.fairway.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 28.0,
            ),
          ),
        ),
        title: Text(
          'Notification Settings',
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
                        color: AppColors.sunsetGold,
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
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Failed to load settings',
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_errorMessage != null) ...[
                              SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
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
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.5),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: AppColors.error),
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
                              emoji: '🔔',
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
                                      color: Colors.orange
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange
                                            .withValues(alpha: 0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.settings,
                                            size: 40, color: Colors.orange),
                                        SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'Notification permission required',
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
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
                                          trailingIcon: Icons.open_in_new,
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
                              emoji: '🎮',
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
                                            Icon(
                                              Icons.info_outline,
                                              color: AppColors.sunsetGold,
                                              size: 16,
                                            ),
                                            SizedBox(width: AppSpacing.xs),
                                            Text(
                                              'Current filters',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: Colors.white.withValues(alpha: 0.6),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          _alertSub!.getSummary(),
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
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
                                    emoji: '⚙️',
                                    title: 'Configure filters',
                                    subtitle: 'Set game vibe, stakes, format, courses, and more',
                                    onTap: _navigateToGameAlerts,
                                  ),
                                ],
                              ],
                            ),

                            // SUBMASTER: Chat Alerts
                            _buildSection(
                              emoji: '💬',
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

                            // Quiet Hours
                            _buildSection(
                              emoji: '🌙',
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
                              emoji: '📨',
                              title: 'Digest Mode',
                              subtitle: 'Control notification frequency',
                              children: [
                                _buildDigestModeSelector(),
                              ],
                            ),

                            // Muted Threads
                            _buildSection(
                              emoji: '🔇',
                              title: 'Muted Threads',
                              children: [
                                _buildNavigationRow(
                                  emoji: '',
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
                                  AppColors.fairwayDark.withValues(alpha: 0.95),
                                  AppColors.fairwayDark,
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
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}
