import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/main_function/create_game/create_game_constants.dart';
import '/models/alert_subscription.dart';
import '/models/course.dart';
import '/services/alert_subscription_service.dart';
import '/services/course_service.dart';
import '/services/notification_permission_service.dart';
import '/utils/app_util.dart';

import 'components/alert_filter_card.dart';
import 'components/alert_filter_chips.dart';
import 'components/alert_navigation_card.dart';
import 'components/alert_section_label.dart';
import 'components/alert_toggle_card.dart';

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
  final _courseService = CourseService();

  // Working copy of subscription
  AlertSubscription? _subscription;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _hasChanges = false;

  // Selected courses (we'll load the full Course objects)
  List<Course> _selectedCourses = [];
  List<Course> _allCourses = [];

  // Accordion state for filter cards
  int? _expandedFilterIndex;

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
        subscription =
            await AlertSubscriptionService.loadSubscription(currentUserUid);
        AppLog.d(
            '📱 [GameAlertsPage] Loaded subscription: ${subscription != null ? 'exists' : 'null'}');
      } catch (e) {
        // Handle permission errors gracefully - use defaults
        AppLog.d(
            '📱 [GameAlertsPage] Error loading subscription (using defaults): $e');
        subscription = null;
      }

      // If no subscription exists, create default
      final sub = subscription ?? AlertSubscription.defaults(currentUserUid);

      // Load selected courses
      final selectedCourses = courses
          .where((course) => sub.courses.contains(course.reference.id))
          .toList();

      updateState(this, () {
        _subscription = sub;
        _allCourses = courses;
        _selectedCourses = selectedCourses;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      updateState(this, () {
        _errorMessage = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Course>> _loadAllCourses() async {
    try {
      return await _courseService.loadAllCourses();
    } catch (e, stackTrace) {
      AppLog.d('❌ Error loading courses: $e');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'GameAlertsPage._loadAllCourses failed',
          fatal: false,
        );
      }
      return [];
    }
  }

  Future<void> _save() async {
    if (_subscription == null) return;

    updateState(this, () {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await AlertSubscriptionService.saveSubscription(_subscription!);

      updateState(this, () {
        _isSaving = false;
        _hasChanges = false;
      });

      if (mounted) {
        AppLog.d(
            '📱 [GameAlertsPage] Saving complete. Returning subscription: enabled=${_subscription!.enabled}, filters=${_subscription!.getSummary()}');

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
      updateState(this, () {
        _isSaving = false;
        _errorMessage = 'Failed to save: $e';
      });
    }
  }

  Future<void> _reset() async {
    final confirmed = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: PhosphorIconsRegular.arrowCounterClockwise,
      title: 'Reset Filters?',
      body:
          'This will clear all your game alert filters. You will receive alerts for all games instead of filtered games.',
      actionLabel: 'Reset',
      cancelLabel: 'Cancel',
    );

    if (confirmed == true) {
      updateState(this, () {
        _subscription = AlertSubscription.defaults(currentUserUid);
        _selectedCourses = [];
        _hasChanges = true;
        _expandedFilterIndex = null;
      });
    }
  }

  void _updateSubscription(AlertSubscription updated) {
    updateState(this, () {
      _subscription = updated;
      _hasChanges = true;
    });
  }

  void _toggleFilterExpanded(int index) {
    updateState(this, () {
      if (_expandedFilterIndex == index) {
        _expandedFilterIndex = null;
      } else {
        _expandedFilterIndex = index;
      }
    });
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
      updateState(this, () {
        _selectedCourses = selected;
        _subscription = _subscription!.copyWith(
          courses: selected.map((c) => c.reference.id).toList(),
        );
        _hasChanges = true;
      });
    }
  }

  /// Generate courses subtitle
  String get _coursesSubtitle {
    if (_selectedCourses.isEmpty) {
      return 'All courses';
    }
    if (_selectedCourses.length == 1) {
      return _selectedCourses.first.name;
    }
    return '${_selectedCourses.length} courses';
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

  /// Build inline summary line at top showing current filter state
  Widget _buildWatchingSummary() {
    if (_subscription == null) return const SizedBox.shrink();

    final summary = _subscription!.getSummary();
    // getSummary() already returns "Watching: ..." so just truncate if needed
    final displaySummary = summary.length > 50
        ? '${summary.substring(0, 47)}...'
        : summary;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          AppIcon(
            icon: AppPhosphorIcons.filter,
            size: AppIconSize.sm,
            color: AppColors.textMuted,
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              displaySummary,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: EdgeInsets.all(AppSpacing.md),
                                margin: EdgeInsets.only(bottom: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.error.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.md),
                                  border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.5),
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

                            // Permission status
                            Builder(
                              builder: (context) {
                                final status =
                                    NotificationPermissionService().cachedStatus;

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
                                      borderRadius: BorderRadius.circular(
                                          AppBorderRadius.md),
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
                                          style:
                                              AppTypography.titleSmall.copyWith(
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Please enable notifications in Settings',
                                          style:
                                              AppTypography.bodySmall.copyWith(
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
                                          trailingIcon:
                                              AppPhosphorIcons.externalLink,
                                          size: AppButtonSize.small,
                                          variant: AppButtonVariant.primary,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),

                            // Inline summary
                            _buildWatchingSummary(),

                            // FILTERS section
                            const AlertSectionLabel(
                              text: 'FILTERS',
                              isFirst: true,
                            ),

                            // Game Vibe
                            AlertFilterCard(
                              title: 'Game Vibe',
                              icon: AppPhosphorIcons.gameVibe,
                              selectedValues: _subscription!.gameVibes,
                              isExpanded: _expandedFilterIndex == 0,
                              onTap: () => _toggleFilterExpanded(0),
                              expandedContent: AlertFilterChips(
                                selectedValues: _subscription!.gameVibes,
                                options: kCreateGameVibeOptions,
                                onChanged: (values) {
                                  _updateSubscription(
                                    _subscription!.copyWith(gameVibes: values),
                                  );
                                },
                              ),
                            ),

                            // Stakes
                            AlertFilterCard(
                              title: 'Stakes',
                              icon: AppPhosphorIcons.betting,
                              selectedValues: _subscription!.stakes,
                              isExpanded: _expandedFilterIndex == 1,
                              onTap: () => _toggleFilterExpanded(1),
                              expandedContent: AlertFilterChips(
                                selectedValues: _subscription!.stakes,
                                options: kCreateGameStakesOptions,
                                onChanged: (values) {
                                  _updateSubscription(
                                    _subscription!.copyWith(stakes: values),
                                  );
                                },
                              ),
                            ),

                            // Primary Format
                            AlertFilterCard(
                              title: 'Primary Format',
                              icon: AppPhosphorIcons.trophy,
                              selectedValues: _subscription!.formats,
                              isExpanded: _expandedFilterIndex == 2,
                              onTap: () => _toggleFilterExpanded(2),
                              expandedContent: AlertFilterChips(
                                selectedValues: _subscription!.formats,
                                options: kCreateGamePrimaryFormatOptions,
                                onChanged: (values) {
                                  _updateSubscription(
                                    _subscription!.copyWith(formats: values),
                                  );
                                },
                              ),
                            ),

                            // Handicap Use
                            AlertFilterCard(
                              title: 'Handicap Use',
                              icon: AppPhosphorIcons.scoring,
                              selectedValues: _subscription!.handicapUses,
                              isExpanded: _expandedFilterIndex == 3,
                              onTap: () => _toggleFilterExpanded(3),
                              expandedContent: AlertFilterChips(
                                selectedValues: _subscription!.handicapUses,
                                options: kCreateGameHandicapOptions,
                                onChanged: (values) {
                                  _updateSubscription(
                                    _subscription!.copyWith(handicapUses: values),
                                  );
                                },
                              ),
                            ),

                            // SPECIAL section
                            const AlertSectionLabel(text: 'SPECIAL'),

                            // Side Games
                            AlertToggleCard(
                              title: 'Side Games',
                              icon: AppPhosphorIcons.wolf,
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

                            // 2v2 (Teams)
                            AlertToggleCard(
                              title: '2v2 (Teams)',
                              icon: AppPhosphorIcons.teams,
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

                            // Discounted Games
                            AlertToggleCard(
                              title: 'Discounted Games',
                              icon: AppPhosphorIcons.memberDiscount,
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

                            // COURSES section
                            const AlertSectionLabel(text: 'COURSES'),

                            // Courses navigation card
                            AlertNavigationCard(
                              title: 'Courses',
                              icon: AppPhosphorIcons.golfCourse,
                              subtitle: _coursesSubtitle,
                              onTap: _showCoursesPicker,
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
                                stops: const [0.0, 0.3, 1.0],
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
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
                AppButtonEnhanced(
                  text: 'Done',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.pop(context, _selected),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              onChanged: (value) => updateState(this, () => _searchQuery = value),
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
                          updateState(this, () {
                            if (isSelected) {
                              _selected.removeWhere(
                                  (c) => c.reference.id == course.reference.id);
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
                                ? AppColors.green.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.green
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
                                    ? AppColors.green
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
