import 'package:shared_preferences/shared_preferences.dart';

import '/core/utils/app_log.dart';
import '/main_function/create_game/models/create_game_form_data.dart';

/// Manages draft persistence for game creation forms.
///
/// Uses SharedPreferences to store form state across app sessions.
class CreateGameDraftService {
  static const String _draftKey = 'create_game_draft';

  /// Loads a saved draft from SharedPreferences.
  ///
  /// Returns null if no draft exists or if loading fails.
  Future<CreateGameFormData?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey);
      if (draftJson == null || draftJson.isEmpty) {
        return null;
      }
      return CreateGameFormData.fromDraftString(draftJson);
    } catch (e) {
      AppLog.d('Error loading draft: $e');
      return null;
    }
  }

  /// Saves form data as a draft to SharedPreferences.
  Future<void> saveDraft(CreateGameFormData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey, data.toDraftString());
    } catch (e) {
      AppLog.d('Error saving draft: $e');
    }
  }

  /// Clears the saved draft from SharedPreferences.
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (e) {
      AppLog.d('Error clearing draft: $e');
    }
  }

  /// Checks if a draft exists.
  Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_draftKey);
    } catch (e) {
      AppLog.d('Error checking draft: $e');
      return false;
    }
  }
}
