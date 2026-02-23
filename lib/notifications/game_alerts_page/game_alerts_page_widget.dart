import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/main_function/create_game/create_game_constants.dart';
import '/models/alert_subscription.dart';
import '/models/course.dart';
import '/services/alert_subscription_service.dart';
import '/services/notification_permission_service.dart';
import '/utils/app_util.dart';

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

  // Working copy of subscription
  AlertSubscription? _subscription;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _hasChanges = false;

  // Selected courses (we'll load the full Course objects)
  List<Course> _selectedCourses = [];
  List<Course> _allCourses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load courses first (always works)
      final courses = await _loadAllCourses();

      // Try to load subscription, but handle permission errors gracefully
      AlertSubscription? subscription;
      try {
        subscription = await AlertSubscriptionService.loadSubscription(currentUserUid);
        AppLog.d('📱 [GameAlertsPage] Loaded subscription: ${subscription != null ? 'exists' : 'null'}');
      } catch (e) {
        // Handle permission errors gracefully - use defaults
        AppLog.d('📱 [GameAlertsPage] Error loading subscription (using defaults): $e');
        subscription = null;
      }

      // If no subscription exists, create default
      final sub = subscription ?? AlertSubscription.defaults(currentUserUid);

      // Load selected courses
      final selectedCourses = courses
          .where((course) => sub.courses.contains(course.reference.id))
          .toList();

      setState(() {
        _subscription = sub;
        _allCourses = courses;
        _selectedCourses = selectedCourses;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Course>> _loadAllCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('course')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Course.fromDoc(doc)).toList();
    } catch (e) {
      AppLog.d('❌ Error loading courses: $e');
      return [];
    }
  }

  Future<void> _save() async {
    if (_subscription == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await AlertSubscriptionService.saveSubscription(_subscription!);

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      if (mounted) {
        AppLog.d('📱 [GameAlertsPage] Saving complete. Returning subscription: enabled=${_subscription!.enabled}, filters=${_subscription!.getSummary()}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Alert settings saved',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.navy,
            duration: const Duration(seconds: 2),
          ),
        );

        // Pop back with updated subscription so parent can update immediately
        context.pop(_subscription);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save: $e';
      });
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.navyDark,
        title: Text(
          'Reset Alert Settings?',
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'This will clear all your alert filters and disable notifications. You can always re-enable them later.',
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
        _subscription = AlertSubscription.defaults(currentUserUid);
        _selectedCourses = [];
        _hasChanges = true;
      });
    }
  }

  void _updateSubscription(AlertSubscription updated) {
    setState(() {
      _subscription = updated;
      _hasChanges = true;
    });
  }

  Future<bool> _ensureNotificationPermission() async {
    AppLog.d('📱 [GameAlerts] Requesting notification permission (user action)');
    final status =
        await NotificationPermissionService().requestPermissionAndRegister();

    // Trigger rebuild to update UI with new cached status
    if (mounted) {
      setState(() {});
    }

    AppLog.d('📱 [GameAlerts] Permission result: $status');
    return status == NotificationPermissionStatus.granted ||
        status == NotificationPermissionStatus.provisional;
  }

  void _showCoursesPicker() async {
    final selected = await showModalBottomSheet<List<Course>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoursesPickerSheet(
        allCourses: _allCourses,
        selectedCourses: _selectedCourses,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCourses = selected;
        _subscription = _subscription!.copyWith(
          courses: selected.map((c) => c.reference.id).toList(),
        );
        _hasChanges = true;
      });
    }
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
    required String emoji,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> selectedValues,
    required List<Map<String, dynamic>> options,
    required Function(List<String>) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((option) {
          final value = option['value'] as String;
          final label = option['label'] as String;
          final emoji = option['emoji'] as String?;
          final isSelected = selectedValues.contains(value);

          return GestureDetector(
            onTap: () {
              final newValues = List<String>.from(selectedValues);
              if (isSelected) {
                newValues.remove(value);
              } else {
                newValues.add(value);
              }
              onChanged(newValues);
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
                  if (emoji != null) ...[
                    Text(emoji, style: TextStyle(fontSize: 16)),
                    SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.navyDark
                          : Colors.white.withValues(alpha: 0.9),
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

  Widget _buildToggleRow({
    required String emoji,
    required String title,
    required String subtitle,
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
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: AppSpacing.sm),
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
          'Game Alerts',
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
                        'Loading alert settings...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : _subscription == null
                  ? Center(
                      child: Text(
                        'Failed to load subscription',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Get notified when new games match your preferences.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Leave a category empty to match any value. All selected categories must match for a notification.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
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

                            // Game Vibe
                            _buildSection(
                              emoji: '🎭',
                              title: 'Game Vibe',
                              subtitle: 'Select preferred game atmosphere',
                              children: [
                                _buildMultiSelectChips(
                                  selectedValues: _subscription!.gameVibes,
                                  options: kCreateGameVibeOptions,
                                  onChanged: (values) {
                                    _updateSubscription(
                                      _subscription!
                                          .copyWith(gameVibes: values),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Stakes
                            _buildSection(
                              emoji: '💰',
                              title: 'Stakes',
                              subtitle: 'How much are you playing for?',
                              children: [
                                _buildMultiSelectChips(
                                  selectedValues: _subscription!.stakes,
                                  options: kCreateGameStakesOptions,
                                  onChanged: (values) {
                                    _updateSubscription(
                                      _subscription!.copyWith(stakes: values),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Format
                            _buildSection(
                              emoji: '🏆',
                              title: 'Primary Format',
                              subtitle: 'Scoring format preference',
                              children: [
                                _buildMultiSelectChips(
                                  selectedValues: _subscription!.formats,
                                  options: kCreateGamePrimaryFormatOptions,
                                  onChanged: (values) {
                                    _updateSubscription(
                                      _subscription!.copyWith(formats: values),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Handicap Use
                            _buildSection(
                              emoji: '📊',
                              title: 'Handicap Use',
                              subtitle: 'Gross, net, or both?',
                              children: [
                                _buildMultiSelectChips(
                                  selectedValues: _subscription!.handicapUses,
                                  options: kCreateGameHandicapOptions,
                                  onChanged: (values) {
                                    _updateSubscription(
                                      _subscription!
                                          .copyWith(handicapUses: values),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Courses
                            _buildSection(
                              emoji: '🏌️',
                              title: 'Courses',
                              subtitle:
                                  'Only notify for games at these courses',
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    children: [
                                      if (_selectedCourses.isEmpty)
                                        Text(
                                          'No courses selected (all courses)',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: _selectedCourses
                                              .map(
                                                (course) => Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.md,
                                                    vertical: AppSpacing.sm,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.gold,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppBorderRadius.lg),
                                                  ),
                                                  child: Text(
                                                    course.name,
                                                    style: AppTypography
                                                        .labelMedium
                                                        .copyWith(
                                                      color:
                                                          AppColors.navyDark,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      SizedBox(height: AppSpacing.md),
                                      AppButtonEnhanced(
                                        text: _selectedCourses.isEmpty
                                            ? 'Select Courses'
                                            : 'Edit Courses (${_selectedCourses.length})',
                                        leadingIcon: AppPhosphorIcons.golfCourse,
                                        size: AppButtonSize.medium,
                                        variant: AppButtonVariant.secondary,
                                        onPressed: _showCoursesPicker,
                                        fullWidth: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Special Options
                            _buildSection(
                              emoji: '⚙️',
                              title: 'Special',
                              subtitle: 'Additional game preferences',
                              children: [
                                _buildToggleRow(
                                  emoji: '🎮',
                                  title: 'Games',
                                  subtitle:
                                      'Only notify for games with side games (Wolf, Nassau, etc.)',
                                  value: _subscription!.special.games,
                                  onChanged: (value) {
                                    _updateSubscription(
                                      _subscription!.copyWith(
                                        special: _subscription!.special
                                            .copyWith(games: value),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  height: 1,
                                  thickness: 1,
                                ),
                                _buildToggleRow(
                                  emoji: '👥',
                                  title: '2v2 (Teams)',
                                  subtitle:
                                      'Only notify for 2v2/team format games',
                                  value: _subscription!.special.twoVTwo,
                                  onChanged: (value) {
                                    _updateSubscription(
                                      _subscription!.copyWith(
                                        special: _subscription!.special
                                            .copyWith(twoVTwo: value),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  height: 1,
                                  thickness: 1,
                                ),
                                _buildToggleRow(
                                  emoji: '🏷️',
                                  title: 'Discounted Games',
                                  subtitle:
                                      'Only notify for games with a discount',
                                  value: _subscription!.special.discount,
                                  onChanged: (value) {
                                    _updateSubscription(
                                      _subscription!.copyWith(
                                        special: _subscription!.special
                                            .copyWith(discount: value),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Live Summary
                            Container(
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.navy.withValues(alpha: 0.3),
                                    AppColors.navyDark
                                        .withValues(alpha: 0.4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                                border: Border.all(
                                  color: AppColors.gold
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AppIcon(
                                        icon: AppPhosphorIcons.info,
                                        color: AppColors.gold,
                                        size: AppIconSize.button,
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Summary',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    _subscription!.getSummary(),
                                    style: AppTypography.titleSmall.copyWith(
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
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

/// Course picker bottom sheet
class _CoursesPickerSheet extends StatefulWidget {
  const _CoursesPickerSheet({
    required this.allCourses,
    required this.selectedCourses,
  });

  final List<Course> allCourses;
  final List<Course> selectedCourses;

  @override
  State<_CoursesPickerSheet> createState() => _CoursesPickerSheetState();
}

class _CoursesPickerSheetState extends State<_CoursesPickerSheet> {
  late List<Course> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedCourses);
  }

  List<Course> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return widget.allCourses;
    }

    final query = _searchQuery.toLowerCase();
    return widget.allCourses
        .where((course) => course.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Courses',
                    style: AppTypography.headlineSmallSans.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(
                    'Done',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                prefixIcon: AppIcon(
                  icon: AppPhosphorIcons.search,
                  color: AppColors.textMuted,
                  size: AppIconSize.md,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Courses list
          Expanded(
            child: _filteredCourses.isEmpty
                ? Center(
                    child: Text(
                      'No courses found',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCourses.length,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      final isSelected = _selected
                          .any((c) => c.reference.id == course.reference.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.removeWhere((c) =>
                                  c.reference.id == course.reference.id);
                            } else {
                              _selected.add(course);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(AppSpacing.md),
                          margin: EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              AppIcon(
                                icon: isSelected
                                    ? AppPhosphorIcons.success
                                    : AppPhosphorIcons.circle,
                                color: isSelected
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                                size: AppIconSize.md,
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  course.name,
                                  style: isSelected
                                      ? AppTypography.titleMedium.copyWith(
                                          color: Colors.white,
                                        )
                                      : AppTypography.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: AppTypography.medium,
                                        ),
                                ),
                              ),
                            ],
                          ),
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
