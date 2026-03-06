import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/models/alert_subscription.dart';
import '/models/course.dart';
import '/services/alert_subscription_service.dart';
import '/services/course_service.dart';

import 'components/alert_courses_picker_sheet.dart';

/// Controller for GameAlertsPageWidget state and business logic.
///
/// Manages subscription state, course selection, filter accordion,
/// and save/reset operations. Delegates Firestore operations to services.
class GameAlertsPageController extends ChangeNotifier {
  GameAlertsPageController() {
    _loadData();
  }

  final _courseService = CourseService();

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  AlertSubscription? _subscription;
  AlertSubscription? get subscription => _subscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasChanges = false;
  bool get hasChanges => _hasChanges;

  List<Course> _selectedCourses = [];
  List<Course> get selectedCourses => _selectedCourses;

  List<Course> _allCourses = [];
  List<Course> get allCourses => _allCourses;

  int? _expandedFilterIndex;
  int? get expandedFilterIndex => _expandedFilterIndex;

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate courses subtitle for navigation card
  String get coursesSubtitle {
    if (_selectedCourses.isEmpty) {
      return 'All courses';
    }
    if (_selectedCourses.length == 1) {
      return _selectedCourses.first.name;
    }
    return '${_selectedCourses.length} courses';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

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

      _subscription = sub;
      _allCourses = courses;
      _selectedCourses = selectedCourses;
      _isLoading = false;
      _hasChanges = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load courses: $e';
      _isLoading = false;
      notifyListeners();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE & RESET
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> save() async {
    if (_subscription == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AlertSubscriptionService.saveSubscription(_subscription!);

      AppLog.d(
          '📱 [GameAlertsPage] Saving complete. Subscription: enabled=${_subscription!.enabled}, filters=${_subscription!.getSummary()}');

      _isSaving = false;
      _hasChanges = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Failed to save: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> showResetConfirmation(BuildContext context) async {
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
      _subscription = AlertSubscription.defaults(currentUserUid);
      _selectedCourses = [];
      _hasChanges = true;
      _expandedFilterIndex = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION UPDATES
  // ═══════════════════════════════════════════════════════════════════════════

  void updateSubscription(AlertSubscription updated) {
    _subscription = updated;
    _hasChanges = true;
    notifyListeners();
  }

  void toggleFilterExpanded(int index) {
    if (_expandedFilterIndex == index) {
      _expandedFilterIndex = null;
    } else {
      _expandedFilterIndex = index;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COURSE PICKER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> showCoursesPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<List<Course>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => AlertCoursesPickerSheet(
        allCourses: _allCourses,
        selectedCourses: _selectedCourses,
      ),
    );

    if (selected != null) {
      _selectedCourses = selected;
      _subscription = _subscription!.copyWith(
        courses: selected.map((c) => c.reference.id).toList(),
      );
      _hasChanges = true;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SNACKBAR HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.pure),
        ),
        backgroundColor: AppColors.navy,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
