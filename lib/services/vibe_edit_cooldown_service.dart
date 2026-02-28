import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';
import '/services/vibe_floor_config.dart';

/// Result of checking vibe edit eligibility
class VibeEditEligibilityResult {
  final bool canEdit;
  final DateTime? nextEditAvailableAt;
  final bool isFirstEdit;
  final int editCount;

  const VibeEditEligibilityResult({
    required this.canEdit,
    this.nextEditAvailableAt,
    required this.isFirstEdit,
    required this.editCount,
  });

  @override
  String toString() =>
      'VibeEditEligibilityResult(canEdit: $canEdit, '
      'nextEditAvailableAt: $nextEditAvailableAt, '
      'isFirstEdit: $isFirstEdit, editCount: $editCount)';
}

/// Service for managing vibe profile edit cooldowns
///
/// Enforces a 30-day cooldown between vibe profile edits to maintain
/// matching integrity. The first edit is always free (no cooldown).
class VibeEditCooldownService {
  VibeEditCooldownService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Check if user can edit their vibe profile
  ///
  /// First edit is always free (when vibeEditCount == 0).
  /// Subsequent edits require 30 days since last edit.
  ///
  /// Returns [VibeEditEligibilityResult] with:
  /// - canEdit: true if editing is allowed
  /// - nextEditAvailableAt: when cooldown expires (null if can edit)
  /// - isFirstEdit: true if this is the user's first edit
  /// - editCount: current edit count
  Future<VibeEditEligibilityResult> canEditVibeProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() ?? {};

      final editCount = (data['vibe_edit_count'] as int?) ?? 0;
      final lastEditAt = (data['last_vibe_edit_at'] as Timestamp?)?.toDate();

      // First edit is always free
      if (editCount == 0) {
        AppLog.d('⏰ VibeEditCooldown: First edit free for user $userId');
        return VibeEditEligibilityResult(
          canEdit: true,
          nextEditAvailableAt: null,
          isFirstEdit: true,
          editCount: editCount,
        );
      }

      // Check if cooldown has expired
      if (lastEditAt != null) {
        final cooldownEnd = lastEditAt.add(
          Duration(days: VibeFloorConfig.vibeEditCooldownDays),
        );
        final now = DateTime.now();

        if (now.isBefore(cooldownEnd)) {
          // Still in cooldown
          AppLog.d(
            '⏰ VibeEditCooldown: User $userId in cooldown until $cooldownEnd',
          );
          return VibeEditEligibilityResult(
            canEdit: false,
            nextEditAvailableAt: cooldownEnd,
            isFirstEdit: false,
            editCount: editCount,
          );
        }
      }

      // Cooldown has expired or no last edit timestamp
      AppLog.d('⏰ VibeEditCooldown: User $userId can edit (cooldown expired)');
      return VibeEditEligibilityResult(
        canEdit: true,
        nextEditAvailableAt: null,
        isFirstEdit: false,
        editCount: editCount,
      );
    } on FirebaseException catch (e) {
      AppLog.d(
        '❌ VibeEditCooldown.canEditVibeProfile error: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  /// Record a vibe edit
  ///
  /// Increments vibeEditCount and sets lastVibeEditAt to now.
  /// Uses a transaction to avoid race conditions.
  ///
  /// Call this after successfully saving vibe profile changes.
  Future<void> recordVibeEdit(String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        final data = userDoc.data() ?? {};

        final currentCount = (data['vibe_edit_count'] as int?) ?? 0;

        transaction.update(userRef, {
          'vibe_edit_count': currentCount + 1,
          'last_vibe_edit_at': FieldValue.serverTimestamp(),
        });
      });

      AppLog.d('✅ VibeEditCooldown: Recorded edit for user $userId');
    } on FirebaseException catch (e) {
      AppLog.d(
        '❌ VibeEditCooldown.recordVibeEdit error: ${e.code} - ${e.message}',
      );
      rethrow;
    }
  }
}
