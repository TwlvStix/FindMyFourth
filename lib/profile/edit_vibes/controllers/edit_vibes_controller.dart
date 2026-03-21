import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/app_log.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_analytics_service.dart';
import '/services/vibe_edit_cooldown_service.dart';
import '/services/vibe_repository.dart';

/// Result of loading a vibe profile with optional cooldown eligibility.
typedef EditVibesLoadResult = ({
  VibeProfile profile,
  VibeEditEligibilityResult? eligibility,
});

/// Result of confirming vibes.
sealed class EditVibesConfirmResult {}

class EditVibesConfirmSuccess extends EditVibesConfirmResult {
  EditVibesConfirmSuccess(this.profile);
  final VibeProfile profile;
}

class EditVibesConfirmFailure extends EditVibesConfirmResult {
  EditVibesConfirmFailure(this.error);
  final String error;
}

/// Controller for EditVibes screen operations.
///
/// Handles async operations only:
/// - Profile loading via [VibeRepository]
/// - Category updates and dealbreaker toggles
/// - Vibe confirmation with cooldown tracking and analytics
///
/// Does NOT handle UI concerns (dialogs, snackbars, navigation).
class EditVibesController {
  EditVibesController({
    VibeRepository? repository,
    VibeEditCooldownService? cooldownService,
    VibeAnalyticsService? analyticsService,
  })  : _repository = repository ?? VibeRepository(),
        _cooldownService = cooldownService ?? VibeEditCooldownService(),
        _analyticsService = analyticsService ?? VibeAnalyticsService();

  final VibeRepository _repository;
  final VibeEditCooldownService _cooldownService;
  final VibeAnalyticsService _analyticsService;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Loads the vibe profile and cooldown eligibility. Throws on failure.
  Future<EditVibesLoadResult> loadProfile() async {
    final userId = currentUserUid;
    final results = await Future.wait([
      _repository.getMyVibesCached(forceRefresh: true),
      if (userId.isNotEmpty) _cooldownService.canEditVibeProfile(userId),
    ]);
    final profile = results[0] as VibeProfile;
    final eligibility = results.length > 1
        ? results[1] as VibeEditEligibilityResult
        : null;
    return (profile: profile, eligibility: eligibility);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY UPDATES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Persists a category value change. Throws on failure.
  Future<void> commitValueChanged(VibeCategory category, int value) async {
    await _repository.updateCategory(category, value);
  }

  /// Persists a dealbreaker toggle. Throws on failure.
  Future<void> toggleDealbreaker(VibeCategory category, bool value) async {
    await _repository.toggleDealbreaker(category, value);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIRM VIBES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Confirms vibes, records cooldown, and logs analytics. Never throws.
  Future<EditVibesConfirmResult> confirmVibes(
    VibeEditEligibilityResult? eligibility,
  ) async {
    try {
      await _repository.confirmVibes();

      final userId = currentUserUid;
      if (userId.isNotEmpty) {
        final wasFirstEdit = eligibility?.isFirstEdit ?? true;
        final editNumber = (eligibility?.editCount ?? 0) + 1;

        await _cooldownService.recordVibeEdit(userId);

        // Fire-and-forget analytics
        _analyticsService.logVibeProfileEdited(
          editNumber: editNumber,
          wasFirstEdit: wasFirstEdit,
        );
      }

      AppLog.d('✅ EditVibesController.confirmVibes success');
      return EditVibesConfirmSuccess(
        VibeProfile.defaults().confirmed(DateTime.now()),
      );
    } catch (e) {
      AppLog.d('❌ EditVibesController.confirmVibes error: $e');
      return EditVibesConfirmFailure(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the user has changed any preferences from the original.
  bool hasChanges(VibeProfile profile, VibeProfile originalProfile) {
    for (final category in VibeCategory.values) {
      final current = profile.preferenceFor(category);
      final original = originalProfile.preferenceFor(category);
      if (current.value != original.value ||
          current.dealbreaker != original.dealbreaker) {
        return true;
      }
    }
    return false;
  }

  /// Whether the user is in the cooldown period.
  bool isInCooldown(VibeEditEligibilityResult? eligibility) =>
      eligibility != null && !eligibility.canEdit;

  /// Formats the next available edit date for display.
  String formatCooldownDate(VibeEditEligibilityResult? eligibility) {
    final nextDate = eligibility?.nextEditAvailableAt;
    if (nextDate == null) return '';
    return DateFormat.yMMMd().format(nextDate);
  }
}
