import 'package:firebase_auth/firebase_auth.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/app_log.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_repository.dart';

typedef EditVibeImportanceLoadResult = ({
  VibeProfile profile,
  Map<VibeCategory, VibeImportance> importance,
});

sealed class EditVibeImportanceSaveResult {}

class EditVibeImportanceSaveSuccess extends EditVibeImportanceSaveResult {}

class EditVibeImportanceSaveFailure extends EditVibeImportanceSaveResult {
  EditVibeImportanceSaveFailure(this.message);
  final String message;
}

/// Controller for Edit Vibe Importance screen operations.
///
/// Handles async operations (load, save) and pure priority logic.
/// Does NOT handle UI concerns (setState, navigation, haptics).
class EditVibeImportanceController {
  EditVibeImportanceController({VibeRepository? repository})
      : _repository = repository ?? VibeRepository();

  final VibeRepository _repository;

  /// Order for the priority selection grid — heaviest weights first
  /// so users see the most impactful categories at the top.
  static const List<VibeCategory> priorityGridOrder = [
    VibeCategory.pace,
    VibeCategory.competitive,
    VibeCategory.drinking,
    VibeCategory.chat,
    VibeCategory.money,
    VibeCategory.music,
  ];

  static const List<VibeCategory> categories = [
    VibeCategory.chat,
    VibeCategory.music,
    VibeCategory.drinking,
    VibeCategory.pace,
    VibeCategory.money,
    VibeCategory.competitive,
  ];

  /// Loads the vibe profile from the repository. Throws on failure.
  Future<EditVibeImportanceLoadResult> loadProfile() async {
    final profile = await _repository.getMyVibesCached(forceRefresh: true);
    final importance =
        Map<VibeCategory, VibeImportance>.from(profile.importance);
    return (profile: profile, importance: importance);
  }

  /// Count of categories currently set to top priority.
  int topCount(Map<VibeCategory, VibeImportance> importance) =>
      importance.values.where((v) => v == VibeImportance.top).length;

  /// Pre-selects categories with dealbreakers as top priorities.
  /// Respects the max of 2 — if more than 2 dealbreakers exist, only the
  /// first 2 (by grid order) are pre-selected. Falls back to
  /// [autoInferImportance] if still under 2.
  Map<VibeCategory, VibeImportance> initializePriorities(
    VibeProfile profile,
    Map<VibeCategory, VibeImportance> importance,
  ) {
    final updated = Map<VibeCategory, VibeImportance>.from(importance);
    var count = updated.values.where((v) => v == VibeImportance.top).length;

    for (final category in priorityGridOrder) {
      if (count >= 2) break;
      final pref = profile.preferenceFor(category);
      if (pref.dealbreaker && updated[category] != VibeImportance.top) {
        updated[category] = VibeImportance.top;
        count++;
      }
    }

    // If still < 2, infer from slider distance
    if (count < 2) {
      return autoInferImportance(profile, importance);
    }

    return updated;
  }

  /// Auto-infer top 2 priorities from dealbreakers first, then slider
  /// positions. Dealbreaker categories always take priority over
  /// distance-from-center.
  Map<VibeCategory, VibeImportance> autoInferImportance(
    VibeProfile profile,
    Map<VibeCategory, VibeImportance> importance,
  ) {
    final center = (VibePreference.minValue + VibePreference.maxValue) / 2;
    final distances = <VibeCategory, double>{};
    final dealbreakers = <VibeCategory>[];

    for (final category in categories) {
      final pref = profile.preferenceFor(category);
      distances[category] = (pref.value - center).abs();
      if (pref.dealbreaker) {
        dealbreakers.add(category);
      }
    }

    // Sort dealbreakers by their position in the grid order
    dealbreakers.sort((a, b) =>
        priorityGridOrder.indexOf(a).compareTo(priorityGridOrder.indexOf(b)));

    // Sort non-dealbreaker categories by distance descending
    final nonDealbreakers = categories
        .where((c) => !dealbreakers.contains(c))
        .toList()
      ..sort((a, b) => (distances[b] ?? 0).compareTo(distances[a] ?? 0));

    // Build priority list: dealbreakers first (by grid order), then by distance
    final priorityOrder = [...dealbreakers, ...nonDealbreakers];

    final inferred = Map<VibeCategory, VibeImportance>.from(importance);
    for (final category in categories) {
      inferred[category] = VibeImportance.normal;
    }

    // Assign top 2
    for (var i = 0; i < 2 && i < priorityOrder.length; i++) {
      inferred[priorityOrder[i]] = VibeImportance.top;
    }

    return inferred;
  }

  /// Toggle a category's importance. Tapping a selected card deselects it;
  /// tapping an unselected card selects it (replacing the oldest top if
  /// already at 2).
  Map<VibeCategory, VibeImportance> setImportance(
    VibeCategory category,
    Map<VibeCategory, VibeImportance> importance,
  ) {
    final current = importance[category] ?? VibeImportance.normal;

    if (current == VibeImportance.top) {
      return Map<VibeCategory, VibeImportance>.from(importance)
        ..[category] = VibeImportance.normal;
    }

    final count = topCount(importance);

    if (count >= 2) {
      final firstTop = categories.firstWhere(
        (c) => c != category && importance[c] == VibeImportance.top,
        orElse: () => category,
      );
      final updated = Map<VibeCategory, VibeImportance>.from(importance);
      if (firstTop != category) {
        updated[firstTop] = VibeImportance.normal;
      }
      updated[category] = VibeImportance.top;
      return updated;
    }

    return Map<VibeCategory, VibeImportance>.from(importance)
      ..[category] = VibeImportance.top;
  }

  /// Reset all categories to normal importance.
  Map<VibeCategory, VibeImportance> clearImportance() => {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
      };

  /// Persists importance to Firestore. Returns a result — never throws.
  Future<EditVibeImportanceSaveResult> saveImportance(
    Map<VibeCategory, VibeImportance> importance,
  ) async {
    if (topCount(importance) != 2) {
      return EditVibeImportanceSaveFailure('Pick exactly 2 top priorities.');
    }
    if (currentUserUid.isEmpty) {
      return EditVibeImportanceSaveFailure(
        'Please sign in to save priorities.',
      );
    }
    try {
      await _repository.updateImportance(importance);
      return EditVibeImportanceSaveSuccess();
    } on FirebaseException catch (error, stackTrace) {
      AppLog.d('❌ Failed to save vibe priorities: ${error.code}');
      AppLog.d('Stack trace: $stackTrace');
      return EditVibeImportanceSaveFailure(
        error.code == 'permission-denied'
            ? 'Unable to save priorities. Permission denied.'
            : 'Unable to save priorities. Please try again.',
      );
    } catch (error, stackTrace) {
      AppLog.d('❌ Failed to save vibe priorities: $error');
      AppLog.d('Stack trace: $stackTrace');
      return EditVibeImportanceSaveFailure(
        'Unable to save priorities. Please try again.',
      );
    }
  }
}
