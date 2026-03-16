/// Challenge definition model for the Challenge Board.
///
/// Minimal model for UI consumption. Challenge definitions live as constants
/// in Cloud Functions (challenge_definitions.js); this model mirrors them
/// for display purposes.
library;

/// Category of a challenge.
enum ChallengeCategory {
  courseExplorer('course_explorer', 'Course Explorer'),
  streaks('streaks', 'Streaks'),
  social('social', 'Social'),
  formats('formats', 'Formats');

  const ChallengeCategory(this.value, this.label);
  final String value;
  final String label;

  static ChallengeCategory fromString(String value) {
    return ChallengeCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ChallengeCategory.formats,
    );
  }
}

/// Type of challenge evaluation.
enum ChallengeType {
  set('set'),
  counter('counter'),
  boolean_('boolean'),
  read('read'),
  special('special');

  const ChallengeType(this.value);
  final String value;

  static ChallengeType fromString(String value) {
    return ChallengeType.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ChallengeType.counter,
    );
  }
}

/// Immutable challenge definition.
class Challenge {
  const Challenge({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.target,
    required this.hidden,
    required this.description,
  });

  final String id;
  final String name;
  final ChallengeCategory category;
  final ChallengeType type;
  final int target;
  final bool hidden;
  final String description;

  /// All 24 challenge definitions (19 visible + 5 hidden).
  static const List<Challenge> all = [
    // Course Explorer
    Challenge(id: 'new_course', name: 'New Horizons', category: ChallengeCategory.courseExplorer, type: ChallengeType.set, target: 1, hidden: false, description: 'Play a new course'),
    Challenge(id: 'courses_5', name: 'Branching Out', category: ChallengeCategory.courseExplorer, type: ChallengeType.set, target: 5, hidden: false, description: 'Play 5 different courses'),
    Challenge(id: 'courses_10', name: 'Course Collector', category: ChallengeCategory.courseExplorer, type: ChallengeType.set, target: 10, hidden: false, description: 'Play 10 different courses'),
    Challenge(id: 'courses_18', name: 'The Explorer', category: ChallengeCategory.courseExplorer, type: ChallengeType.set, target: 18, hidden: false, description: 'Play 18 different courses'),
    Challenge(id: 'grand_tour', name: 'Grand Tour', category: ChallengeCategory.courseExplorer, type: ChallengeType.set, target: 0, hidden: false, description: 'Play every course in the system'),
    // Streaks
    Challenge(id: 'streak_3', name: 'On a Roll', category: ChallengeCategory.streaks, type: ChallengeType.read, target: 3, hidden: false, description: 'Maintain a 3-week streak'),
    Challenge(id: 'streak_4', name: 'Consistent', category: ChallengeCategory.streaks, type: ChallengeType.read, target: 4, hidden: false, description: 'Maintain a 4-week streak'),
    Challenge(id: 'streak_10', name: 'Dedicated', category: ChallengeCategory.streaks, type: ChallengeType.read, target: 10, hidden: false, description: 'Achieve a 10-week longest streak'),
    Challenge(id: 'streak_28', name: 'Iron Will', category: ChallengeCategory.streaks, type: ChallengeType.read, target: 28, hidden: false, description: 'Achieve a 28-week longest streak'),
    // Social
    Challenge(id: 'partner_1', name: 'First Foursome', category: ChallengeCategory.social, type: ChallengeType.read, target: 1, hidden: false, description: 'Play with your first partner'),
    Challenge(id: 'partners_10', name: 'Social Golfer', category: ChallengeCategory.social, type: ChallengeType.read, target: 10, hidden: false, description: 'Play with 10 different partners'),
    Challenge(id: 'partners_25', name: 'Networking Pro', category: ChallengeCategory.social, type: ChallengeType.read, target: 25, hidden: false, description: 'Play with 25 different partners'),
    Challenge(id: 'all_strangers', name: 'Leap of Faith', category: ChallengeCategory.social, type: ChallengeType.boolean_, target: 1, hidden: false, description: 'Play a round where no one knew each other beforehand'),
    Challenge(id: 'referral', name: 'Ambassador', category: ChallengeCategory.social, type: ChallengeType.boolean_, target: 1, hidden: false, description: 'Refer a friend who joins the app'),
    // Formats
    Challenge(id: 'try_formats', name: 'Format Explorer', category: ChallengeCategory.formats, type: ChallengeType.set, target: 5, hidden: false, description: 'Play all 5 game formats'),
    Challenge(id: 'side_game_1', name: 'Side Action', category: ChallengeCategory.formats, type: ChallengeType.counter, target: 1, hidden: false, description: 'Play a round with side games'),
    Challenge(id: 'monthly_variety', name: 'Monthly Mix', category: ChallengeCategory.formats, type: ChallengeType.special, target: 3, hidden: false, description: 'Play 3 different formats in the same calendar month'),
    Challenge(id: 'side_games_5', name: 'Side Hustle', category: ChallengeCategory.formats, type: ChallengeType.counter, target: 5, hidden: false, description: 'Play 5 rounds with side games'),
    Challenge(id: 'wildcard_season', name: 'Wildcard Season', category: ChallengeCategory.formats, type: ChallengeType.special, target: 1, hidden: false, description: 'Play all 5 formats and 3+ side game rounds in a season'),
    // Hidden
    Challenge(id: 'dawn_patrol', name: 'Dawn Patrol', category: ChallengeCategory.formats, type: ChallengeType.boolean_, target: 1, hidden: true, description: 'Play a round with a tee time before 7:30 AM'),
    Challenge(id: 'home_course', name: 'Home Course', category: ChallengeCategory.courseExplorer, type: ChallengeType.counter, target: 5, hidden: true, description: 'Play the same course 5 times'),
    Challenge(id: 'small_world', name: 'Small World', category: ChallengeCategory.social, type: ChallengeType.boolean_, target: 1, hidden: true, description: 'Match with the same non-friend stranger in 2+ different rounds'),
    Challenge(id: 'full_circle', name: 'Full Circle', category: ChallengeCategory.social, type: ChallengeType.boolean_, target: 1, hidden: true, description: 'Play with your first-ever partner after 10+ other unique partners'),
    Challenge(id: 'never_miss', name: 'Never Miss', category: ChallengeCategory.streaks, type: ChallengeType.special, target: 1, hidden: true, description: 'Attend every game in a calendar month'),
  ];

  /// Visible challenges only (excludes hidden).
  static List<Challenge> get visible => all.where((c) => !c.hidden).toList();

  /// Lookup by ID.
  static Challenge? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'Challenge($id, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Challenge && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
