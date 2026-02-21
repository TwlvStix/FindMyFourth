import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/util/firestore_util.dart';

/// AlertSubscription model - matches Create Game categories exactly
///
/// Firestore schema (alertSubs collection):
/// - userId: string
/// - enabled: boolean
/// - gameVibes: [string] (values: 'Competitive', 'Casual')
/// - stakes: [string] (values: 'No Money', 'Low Stakes', 'High Stakes')
/// - formats: [string] (values: 'Stroke Play', 'Match Play', 'Stableford')
/// - handicapUses: [string] (values: 'Gross', 'Net', 'Both')
/// - courses: [string] (courseIds)
/// - special: {games: boolean, twoVTwo: boolean, discount: boolean}
/// - createdAt: server timestamp
/// - updatedAt: server timestamp
class AlertSubscription {
  AlertSubscription({
    required this.userId,
    required this.enabled,
    required this.gameVibes,
    required this.stakes,
    required this.formats,
    required this.handicapUses,
    required this.courses,
    required this.special,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final bool enabled;
  final List<String> gameVibes;
  final List<String> stakes;
  final List<String> formats;
  final List<String> handicapUses;
  final List<String> courses;
  final AlertSpecialOptions special;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create default subscription (enabled, all filters empty = matches all games)
  static AlertSubscription defaults(String userId) {
    return AlertSubscription(
      userId: userId,
      enabled: true,
      gameVibes: const [],
      stakes: const [],
      formats: const [],
      handicapUses: const [],
      courses: const [],
      special: AlertSpecialOptions.defaults(),
    );
  }

  /// Create a copy with updated fields
  AlertSubscription copyWith({
    String? userId,
    bool? enabled,
    List<String>? gameVibes,
    List<String>? stakes,
    List<String>? formats,
    List<String>? handicapUses,
    List<String>? courses,
    AlertSpecialOptions? special,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertSubscription(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      gameVibes: gameVibes ?? this.gameVibes,
      stakes: stakes ?? this.stakes,
      formats: formats ?? this.formats,
      handicapUses: handicapUses ?? this.handicapUses,
      courses: courses ?? this.courses,
      special: special ?? this.special,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Load from Firestore document
  static AlertSubscription fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    return AlertSubscription(
      userId: data['userId'] as String? ?? '',
      enabled: data['enabled'] as bool? ?? false,
      gameVibes: _stringListValue(data, 'gameVibes'),
      stakes: _stringListValue(data, 'stakes'),
      formats: _stringListValue(data, 'formats'),
      handicapUses: _stringListValue(data, 'handicapUses'),
      courses: _stringListValue(data, 'courses'),
      special: AlertSpecialOptions.fromMap(_mapValue(data, 'special')),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    final data = mapToFirestore({
      'userId': userId,
      'enabled': enabled,
      'gameVibes': gameVibes,
      'stakes': stakes,
      'formats': formats,
      'handicapUses': handicapUses,
      'courses': courses,
      'special': special.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Only set createdAt on create
    if (!isUpdate) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    return data;
  }

  /// Check if subscription has any active filters
  bool get hasActiveFilters {
    return gameVibes.isNotEmpty ||
        stakes.isNotEmpty ||
        formats.isNotEmpty ||
        handicapUses.isNotEmpty ||
        courses.isNotEmpty ||
        special.games ||
        special.twoVTwo ||
        special.discount;
  }

  /// Get a human-readable summary of active filters
  String getSummary() {
    if (!enabled) {
      return 'Notifications disabled';
    }

    if (!hasActiveFilters) {
      return 'Watching: All games';
    }

    final parts = <String>[];

    if (gameVibes.isNotEmpty) {
      parts.add(gameVibes.join(' + '));
    }
    if (stakes.isNotEmpty) {
      parts.add(stakes.join(' + '));
    }
    if (formats.isNotEmpty) {
      parts.add(formats.join(' + '));
    }
    if (handicapUses.isNotEmpty) {
      parts.add(handicapUses.join(' + '));
    }
    if (courses.isNotEmpty) {
      parts.add('${courses.length} course${courses.length == 1 ? '' : 's'}');
    }
    if (special.games) {
      parts.add('Games');
    }
    if (special.twoVTwo) {
      parts.add('2v2');
    }
    if (special.discount) {
      parts.add('Discounted');
    }

    if (parts.isEmpty) {
      return 'Watching: All games';
    }

    return 'Watching: ${parts.join(' • ')}';
  }

  // Helper methods for parsing
  static List<String> _stringListValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return [];
  }

  static Map<String, dynamic>? _mapValue(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}

/// Special alert options (Games, 2v2, and Discount)
class AlertSpecialOptions {
  AlertSpecialOptions({
    required this.games,
    required this.twoVTwo,
    required this.discount,
  });

  final bool games;    // User wants games with side games (Wolf, Nassau, etc.)
  final bool twoVTwo;  // User wants 2v2/team games
  final bool discount; // User wants games with a discount

  static AlertSpecialOptions defaults() {
    return AlertSpecialOptions(
      games: false,
      twoVTwo: false,
      discount: false,
    );
  }

  AlertSpecialOptions copyWith({
    bool? games,
    bool? twoVTwo,
    bool? discount,
  }) {
    return AlertSpecialOptions(
      games: games ?? this.games,
      twoVTwo: twoVTwo ?? this.twoVTwo,
      discount: discount ?? this.discount,
    );
  }

  static AlertSpecialOptions fromMap(Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return AlertSpecialOptions(
      games: data['games'] as bool? ?? false,
      twoVTwo: data['twoVTwo'] as bool? ?? false,
      discount: data['discount'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'games': games,
      'twoVTwo': twoVTwo,
      'discount': discount,
    };
  }
}
