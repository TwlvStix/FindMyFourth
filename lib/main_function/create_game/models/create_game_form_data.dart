import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/course.dart';
import '/utils/flexible_week_resolver.dart';

/// Encapsulates all form state for creating a game.
///
/// This model:
/// - Holds all form field values
/// - Provides JSON serialization for draft persistence
/// - Provides Firestore map conversion for game creation
class CreateGameFormData {
  // Selection fields
  String? friendsValue;
  String? courseValue;
  String? memberValue;
  String? rulesSetValue;
  String? styleGameValue;
  String? gameTypeValue;
  String? scoringValue;
  Course? selectedCourse;
  String? selectedCourseRefPath;

  // Schedule
  String scheduleType; // 'confirmed' | 'flexible'
  DateTime? datePicked;
  String? flexibleWeek;
  Set<int> selectedDays;
  Set<String> flexibleTimesOfDay;

  // Team setup
  bool is2v2;
  String? teamStyle;

  // Game rules
  bool isJustForFun;
  String playerEligibility;
  bool requireVibeMatch;

  // Games selection
  Set<String> selectedGames;
  String? otherGameText;

  // Metadata
  String gameName;
  bool memberDiscount;

  CreateGameFormData({
    this.friendsValue,
    this.courseValue,
    this.memberValue,
    this.rulesSetValue,
    this.styleGameValue,
    this.gameTypeValue,
    this.scoringValue,
    this.selectedCourse,
    this.selectedCourseRefPath,
    this.scheduleType = 'confirmed',
    this.datePicked,
    this.flexibleWeek,
    Set<int>? selectedDays,
    Set<String>? flexibleTimesOfDay,
    this.is2v2 = false,
    this.teamStyle,
    this.isJustForFun = false,
    this.playerEligibility = 'open_to_all',
    this.requireVibeMatch = true,
    Set<String>? selectedGames,
    this.otherGameText,
    String? gameName,
    this.memberDiscount = false,
  })  : selectedDays = selectedDays ?? {},
        flexibleTimesOfDay = flexibleTimesOfDay ?? {'anytime'},
        selectedGames = selectedGames ?? {},
        gameName = gameName ?? _generateAutoGameName() {
    if (selectedCourse != null) {
      selectedCourseRefPath = selectedCourse!.reference.path;
      courseValue ??= selectedCourse!.name;
    }
    reconcileDerivedFields();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAME GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<String> _mastersChampions = [
    'Nicklaus',
    'Woods',
    'Spieth',
    'Mickelson',
    'Hogan',
    'Faldo',
    'Player',
    'Watson',
    'Palmer',
    'Scheffler',
  ];

  static const List<String> _fruits = [
    'Apple',
    'Banana',
    'Cherry',
    'Mango',
    'Peach',
    'Pear',
    'Plum',
    'Orange',
    'Kiwi',
    'Grape',
  ];

  static const List<String> _traits = [
    'Bold',
    'Calm',
    'Clever',
    'Daring',
    'Focused',
    'Gritty',
    'Humble',
    'Loyal',
    'Steady',
    'Swift',
  ];

  static String _generateAutoGameName() {
    final random = Random();
    final champion =
        _mastersChampions[random.nextInt(_mastersChampions.length)];
    final fruit = _fruits[random.nextInt(_fruits.length)];
    final trait = _traits[random.nextInt(_traits.length)];
    return '$champion $fruit $trait';
  }

  /// Ensures a game name exists, generating one if needed.
  String ensureGameName() {
    final existing = gameName.trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    gameName = _generateAutoGameName();
    return gameName;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRAFT PERSISTENCE (JSON)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Converts form data to JSON for SharedPreferences storage.
  Map<String, dynamic> toDraftJson() {
    reconcileDerivedFields();
    if (selectedCourse != null) {
      selectedCourseRefPath = selectedCourse!.reference.path;
      courseValue ??= selectedCourse!.name;
    }

    return {
      'date': datePicked?.toIso8601String(),
      'friends': friendsValue,
      'course': courseValue,
      'courseRefPath': selectedCourseRefPath,
      'member': memberValue,
      'memberDiscount': memberDiscount,
      'rulesSet': rulesSetValue,
      'styleGame': styleGameValue,
      'gameType': gameTypeValue,
      'scoring': scoringValue,
      'is2v2': is2v2,
      'teamStyle': teamStyle,
      'selectedGames': selectedGames.toList(),
      'otherGame': otherGameText,
      'gameName': gameName.isEmpty ? null : gameName,
      'scheduleType': scheduleType,
      'flexibleWeek': flexibleWeek,
      'flexibleDays': selectedDays.toList(),
      'flexibleTimeOfDay': flexibleTimesOfDay.join(','),
      'isJustForFun': isJustForFun,
      'playerEligibility': playerEligibility,
      'requireVibeMatch': requireVibeMatch,
    };
  }

  /// Serializes form data to JSON string.
  String toDraftString() => json.encode(toDraftJson());

  /// Creates form data from JSON stored in SharedPreferences.
  ///
  /// Handles legacy formats with fallbacks.
  static CreateGameFormData fromDraftJson(Map<String, dynamic> draft) {
    // Parse flexible times (handle both legacy single string and new comma-separated)
    Set<String> flexTimes = {'anytime'};
    if (draft['flexibleTimeOfDay'] != null) {
      final stored = draft['flexibleTimeOfDay'] as String;
      flexTimes = stored
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (flexTimes.isEmpty) {
        flexTimes = {'anytime'};
      }
    }

    // Parse selected days
    Set<int> days = {};
    if (draft['flexibleDays'] != null) {
      final daysList = draft['flexibleDays'] as List<dynamic>;
      days = Set.from(daysList.cast<int>());
    }

    // Parse selected games
    Set<String> games = {};
    if (draft['selectedGames'] != null) {
      final gamesList = draft['selectedGames'] as List<dynamic>;
      games = Set.from(gamesList.cast<String>());
    }

    return CreateGameFormData(
      datePicked: draft['date'] != null
          ? DateTime.parse(draft['date'] as String)
          : null,
      friendsValue: draft['friends'] as String?,
      courseValue: draft['course'] as String?,
      memberValue: draft['member'] as String?,
      rulesSetValue: draft['rulesSet'] as String?,
      styleGameValue: draft['styleGame'] as String?,
      gameTypeValue: draft['gameType'] as String?,
      scoringValue: draft['scoring'] as String?,
      is2v2: draft['is2v2'] as bool? ?? false,
      teamStyle: draft['teamStyle'] as String?,
      selectedGames: games,
      otherGameText: draft['otherGame'] as String?,
      gameName: draft['gameName'] as String?,
      scheduleType: draft['scheduleType'] as String? ?? 'confirmed',
      flexibleWeek: draft['flexibleWeek'] as String?,
      selectedDays: days,
      flexibleTimesOfDay: flexTimes,
      isJustForFun: draft['isJustForFun'] as bool? ?? false,
      playerEligibility: draft['playerEligibility'] as String? ?? 'open_to_all',
      requireVibeMatch: draft['requireVibeMatch'] as bool? ?? true,
      selectedCourseRefPath: draft['courseRefPath'] as String?,
      memberDiscount: draft['memberDiscount'] as bool? ?? false,
    );
  }

  /// Creates form data from JSON string.
  static CreateGameFormData fromDraftString(String jsonString) {
    return fromDraftJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRESTORE CONVERSION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Converts form data to Firestore document map.
  Map<String, dynamic> toFirestoreMap({
    required String uid,
    required DocumentReference userRef,
    required DocumentReference? chatRef,
  }) {
    final resolvedName = ensureGameName();
    reconcileDerivedFields();

    // Resolve flexible time of day for storage
    final flexTimeForStorage =
        flexibleTimesOfDay.where((t) => t != 'anytime').isEmpty
            ? 'anytime'
            : flexibleTimesOfDay.where((t) => t != 'anytime').join(',');

    return {
      'name_game': resolvedName,
      'date': scheduleType == 'confirmed' ? datePicked : null,
      'num_players': 1, // Default for backend compatibility
      'style_game': styleGameValue,
      'game_type': gameTypeValue,
      'course_play': courseValue,
      'member_discount': memberValue,
      'scoring': scoringValue,
      'friend_game': friendsValue,
      'max_players': 4,
      'rules_setting': rulesSetValue,
      'created_time': DateTime.now(),
      'chatRef': chatRef,
      'userRef': userRef,
      'courseRef': selectedCourse?.reference,
      // Stamp course coordinates for geo filtering
      if (selectedCourse?.latLng != null) ...{
        'course_lat': selectedCourse!.latLng!.latitude,
        'course_lng': selectedCourse!.latLng!.longitude,
      },
      'isCancelled': false,
      'status': 'active',
      'joined_players': [userRef],
      'guest_players': [],
      'uid': uid,
      'is_fun_game': isJustForFun,
      'is_2v2': is2v2,
      'has_side_games': selectedGames.isNotEmpty,
      'schedule_type': scheduleType,
      'player_eligibility': playerEligibility,
      'require_vibe_match': requireVibeMatch,
      if (scheduleType == 'flexible') ...{
        'flexible_week': flexibleWeek,
        'flexible_days': selectedDays.toList(),
        'flexible_time_of_day': flexTimeForStorage,
        // Compute concrete dates at creation time
        if (FlexibleWeekResolver.resolveWeekDates(flexibleWeek)
            case final dates?) ...{
          'flexible_start_date': dates.start,
          'flexible_end_date': dates.end,
        },
      },
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number of players (currently always 1 for backend compatibility).
  int get numPlayers => 1;

  /// Maximum players for a game.
  int get maxPlayers => 4;

  /// Keeps derived/legacy fields in sync.
  ///
  /// `member_discount` in Firestore still uses string values ('Yes'/'No').
  /// `memberDiscount` is the authoritative value in UI state.
  void reconcileDerivedFields() {
    final legacyMemberValue = memberValue?.toLowerCase();
    if (!memberDiscount && legacyMemberValue == 'yes') {
      memberDiscount = true;
    }
    memberValue = memberDiscount ? 'Yes' : 'No';
  }

  /// Updates course selection and keeps mirrored fields in sync.
  void setSelectedCourse(Course? course) {
    selectedCourse = course;
    selectedCourseRefPath = course?.reference.path;
    courseValue = course?.name;
  }

  /// Restores selected course from loaded course options.
  ///
  /// Falls back to course name when draft predates courseRef persistence.
  void hydrateSelectedCourse(List<Course> courses) {
    if (courses.isEmpty) return;
    if (selectedCourse != null) {
      selectedCourseRefPath = selectedCourse!.reference.path;
      courseValue ??= selectedCourse!.name;
      return;
    }

    Course? matchByRef;
    final courseRefPath = selectedCourseRefPath;
    if (courseRefPath != null && courseRefPath.isNotEmpty) {
      for (final course in courses) {
        if (course.reference.path == courseRefPath) {
          matchByRef = course;
          break;
        }
      }
    }

    if (matchByRef != null) {
      setSelectedCourse(matchByRef);
      return;
    }

    final desiredName = courseValue;
    if (desiredName == null || desiredName.isEmpty) return;
    for (final course in courses) {
      if (course.name == desiredName) {
        setSelectedCourse(course);
        return;
      }
    }
  }

  /// Builds a human-readable game summary string.
  String buildGameSummary() {
    // Primary Format
    String format = gameTypeValue ?? '';

    // Add 2v2 Team Style if enabled
    if (is2v2 && teamStyle != null && teamStyle!.isNotEmpty) {
      format += ' + 2v2 ($teamStyle)';
    }

    // Display "Gross + Net" instead of "Both" for better readability
    final handicap =
        scoringValue == 'Both' ? 'Gross + Net' : (scoringValue ?? '');
    final stakes = styleGameValue ?? '';
    final vibe = rulesSetValue ?? '';

    // Build base summary
    String summary = '$format • $handicap • $stakes • $vibe';

    // Add Games if any selected
    if (selectedGames.isNotEmpty) {
      final gamesList = selectedGames.map((game) {
        if (game == 'Other' &&
            otherGameText != null &&
            otherGameText!.isNotEmpty) {
          return otherGameText!;
        }
        return game;
      }).join(', ');
      summary += ' • Games: $gamesList';
    }

    return summary;
  }
}
