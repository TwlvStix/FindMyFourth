import 'dart:async';

import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_repository.dart';

/// VibeProvider manages vibe profile state for the vibe onboarding flow.
///
/// Route-scoped provider — should be wrapped around the VibeOnboarding route
/// in app_router.dart, NOT registered globally in main.dart.
///
/// Follows the standard provider pattern:
/// - Constructor injection for testability
/// - _disposed flag checked before notifyListeners()
/// - _scheduleNotify() debounce (50ms timer)
/// - Optimistic updates with rollback on failure
class VibeProvider extends ChangeNotifier {
  VibeProvider({VibeRepository? repository})
      : _repository = repository ?? VibeRepository();

  final VibeRepository _repository;

  // ========================================
  // STATE FIELDS
  // ========================================

  VibeProfile _profile = VibeProfile.defaults();
  Map<VibeCategory, VibeImportance> _importance = {
    for (final category in VibeCategory.values) category: VibeImportance.normal,
  };
  bool _isLoading = false;
  bool _isCompleting = false;
  bool _disposed = false;
  Timer? _notifyTimer;

  /// Order for the priority selection grid — heaviest weights first
  /// so users see the most impactful categories at the top.
  final List<VibeCategory> _priorityGridOrder = const [
    VibeCategory.pace,
    VibeCategory.competitive,
    VibeCategory.drinking,
    VibeCategory.chat,
    VibeCategory.money,
    VibeCategory.music,
  ];

  // ========================================
  // GETTERS
  // ========================================

  VibeProfile get profile => _profile;
  Map<VibeCategory, VibeImportance> get importance => _importance;
  bool get isLoading => _isLoading;
  bool get isCompleting => _isCompleting;

  int get topCount =>
      _importance.values.where((v) => v == VibeImportance.top).length;

  // ========================================
  // PUBLIC METHODS
  // ========================================

  /// Loads the user's vibe profile from the repository.
  ///
  /// Sets [isLoading] to true during fetch, false when complete.
  /// On error, sets [isLoading] to false but does not throw —
  /// caller can check profile state.
  Future<void> loadProfile() async {
    _isLoading = true;
    _scheduleNotify();

    try {
      final profile = await _repository.getMyVibesCached(forceRefresh: true);
      if (_disposed) return;

      _profile = profile;
      _importance = Map<VibeCategory, VibeImportance>.from(profile.importance);
      _isLoading = false;
      _scheduleNotify();
    } catch (e) {
      AppLog.d('❌ VibeProvider.loadProfile error: $e');
      if (_disposed) return;
      _isLoading = false;
      _scheduleNotify();
      // Does not rethrow — caller can check profile state
    }
  }

  /// Updates a preference value locally (no persist).
  ///
  /// Used during slider drag for immediate visual feedback.
  /// Call [commitValueChanged] when the user releases the slider.
  void updateLocalPreference(VibeCategory category, int value) {
    final current = _profile.preferenceFor(category);
    final updatedPrefs = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updatedPrefs[category] = current.copyWith(value: value, isDefault: false);
    _profile = _profile.copyWith(prefs: updatedPrefs);
    _scheduleNotify();
  }

  /// Persists a preference value change to Firestore.
  ///
  /// Call this after [updateLocalPreference] to persist the value.
  /// On failure, returns an error message. Returns null on success.
  ///
  /// Note: This method does NOT rollback local state on failure because
  /// it doesn't track the pre-update value. The UI shows the error message
  /// and can call [loadProfile] to refresh if needed.
  Future<String?> commitValueChanged(VibeCategory category, int value) async {
    try {
      await _repository.updateCategory(category, value);
      return null;
    } catch (e) {
      AppLog.d('❌ VibeProvider.commitValueChanged error: $e');
      if (_disposed) return null;
      return 'Unable to update vibe. Please try again.';
    }
  }

  /// Toggles a dealbreaker flag with optimistic update.
  ///
  /// Updates local state immediately, then persists.
  /// On failure, rolls back to previous state and returns error message.
  /// Returns null on success.
  Future<String?> toggleDealbreaker(VibeCategory category, bool value) async {
    final current = _profile.preferenceFor(category);
    final previousValue = current.dealbreaker;

    // Optimistic update
    final updatedPrefs = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updatedPrefs[category] = current.copyWith(dealbreaker: value, isDefault: false);
    _profile = _profile.copyWith(prefs: updatedPrefs);
    _scheduleNotify();

    try {
      await _repository.toggleDealbreaker(category, value);
      return null;
    } catch (e) {
      AppLog.d('❌ VibeProvider.toggleDealbreaker error: $e');
      if (_disposed) return null;

      // Rollback
      final rollbackPrefs =
          Map<VibeCategory, VibePreference>.from(_profile.prefs);
      final rollbackCurrent =
          rollbackPrefs[category] ?? VibePreference.defaults();
      rollbackPrefs[category] =
          rollbackCurrent.copyWith(dealbreaker: previousValue);
      _profile = _profile.copyWith(prefs: rollbackPrefs);
      _scheduleNotify();

      return 'Unable to update dealbreaker. Please try again.';
    }
  }

  /// Auto-infers top 2 priorities from dealbreakers first, then slider positions.
  ///
  /// Dealbreaker categories always take priority over distance-from-center.
  /// Pure computation — does not persist.
  void autoInferImportance() {
    const center = (VibePreference.minValue + VibePreference.maxValue) / 2;
    final distances = <VibeCategory, double>{};
    final dealbreakers = <VibeCategory>[];

    for (final category in VibeCategory.values) {
      final pref = _profile.preferenceFor(category);
      distances[category] = (pref.value - center).abs();
      if (pref.dealbreaker) {
        dealbreakers.add(category);
      }
    }

    // Sort dealbreakers by their position in the grid order
    dealbreakers.sort((a, b) =>
        _priorityGridOrder.indexOf(a).compareTo(_priorityGridOrder.indexOf(b)));

    // Sort non-dealbreaker categories by distance descending
    final nonDealbreakers = VibeCategory.values
        .where((c) => !dealbreakers.contains(c))
        .toList()
      ..sort((a, b) => (distances[b] ?? 0).compareTo(distances[a] ?? 0));

    // Build priority list: dealbreakers first (by grid order), then by distance
    final priorityOrder = [...dealbreakers, ...nonDealbreakers];

    final inferred = <VibeCategory, VibeImportance>{
      for (final category in VibeCategory.values)
        category: VibeImportance.normal,
    };

    // Assign top 2
    for (var i = 0; i < 2 && i < priorityOrder.length; i++) {
      inferred[priorityOrder[i]] = VibeImportance.top;
    }

    _importance = inferred;
    _scheduleNotify();
  }

  /// Completes the vibe onboarding flow.
  ///
  /// Guarded against double-tap: if [isCompleting] is already true,
  /// returns immediately with null (no-op).
  ///
  /// Auto-infers importance if [topCount] < 2, then persists importance
  /// and confirms vibes.
  ///
  /// Returns null on success, error message on failure.
  Future<String?> completeOnboarding() async {
    // Guard against double-tap
    if (_isCompleting) {
      return null;
    }

    _isCompleting = true;
    _scheduleNotify();

    // Auto-infer if user hasn't picked 2 top priorities
    if (topCount < 2) {
      autoInferImportance();
    }

    try {
      await _repository.updateImportance(_importance);
      await _repository.confirmVibes(profile: _profile);

      if (_disposed) return null;
      // Keep isCompleting true — navigation should happen
      return null;
    } catch (e) {
      AppLog.d('❌ VibeProvider.completeOnboarding error: $e');
      if (_disposed) return null;

      _isCompleting = false;
      _scheduleNotify();
      return 'Unable to finish setup. Please try again.';
    }
  }

  // ========================================
  // INTERNAL HELPERS
  // ========================================

  /// Debounced notifyListeners to avoid excessive rebuilds.
  ///
  /// Pattern from GameProvider — prevents multiple rapid updates
  /// from causing UI jank.
  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // ========================================
  // DISPOSE CLEANUP
  // ========================================

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    super.dispose();
  }
}
