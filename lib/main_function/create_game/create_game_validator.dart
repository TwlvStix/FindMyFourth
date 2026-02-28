import 'models/create_game_form_data.dart';

/// Validates CreateGameFormData for submission.
///
/// Each validation method returns null if valid, or an error message if invalid.
class CreateGameValidator {
  /// Validates all fields for game submission.
  ///
  /// Returns null if all validations pass, or the first error message encountered.
  static String? validateForSubmission(CreateGameFormData data) {
    return validateCourse(data) ??
        validateVisibility(data) ??
        validateGameDetails(data) ??
        validateSchedule(data) ??
        validateTeamSetup(data) ??
        validateGamesSelection(data);
  }

  /// Validates course selection.
  ///
  /// Course is required for confirmed games but optional for flexible games.
  static String? validateCourse(CreateGameFormData data) {
    if (data.scheduleType == 'confirmed' && data.courseValue == null) {
      return 'Please select a course';
    }
    return null;
  }

  /// Validates visibility (friends vs public) selection.
  static String? validateVisibility(CreateGameFormData data) {
    if (data.friendsValue == null) {
      return 'Please select Friends or Public game';
    }
    return null;
  }

  /// Validates game detail fields (vibe, stakes, format).
  ///
  /// These are only required when not in "Just for Fun" mode.
  static String? validateGameDetails(CreateGameFormData data) {
    if (data.isJustForFun) {
      return null; // Skip validation for fun games
    }

    if (data.rulesSetValue == null) {
      return 'Please select a game vibe';
    }
    if (data.styleGameValue == null) {
      return 'Please select stakes';
    }
    if (data.gameTypeValue == null) {
      return 'Please select a primary format';
    }
    return null;
  }

  /// Validates schedule selection.
  ///
  /// Confirmed games require a date. Flexible games require a week selection.
  static String? validateSchedule(CreateGameFormData data) {
    if (data.scheduleType == 'confirmed') {
      if (data.datePicked == null) {
        return 'Please select a date and time.';
      }
    } else {
      // Flexible mode - week is required
      if (data.flexibleWeek == null) {
        return 'Please select a week for your flexible game.';
      }
    }
    return null;
  }

  /// Validates team setup when 2v2 is enabled.
  static String? validateTeamSetup(CreateGameFormData data) {
    if (data.isJustForFun) {
      return null; // Skip for fun games
    }

    if (data.is2v2 && (data.teamStyle == null || data.teamStyle!.isEmpty)) {
      return 'Please select a team style for 2v2 games.';
    }
    return null;
  }

  /// Validates "Other" game selection requires description.
  static String? validateGamesSelection(CreateGameFormData data) {
    if (data.isJustForFun) {
      return null; // Skip for fun games
    }

    if (data.selectedGames.contains('Other') &&
        (data.otherGameText == null || data.otherGameText!.trim().isEmpty)) {
      return 'Please describe the other game.';
    }
    return null;
  }
}
