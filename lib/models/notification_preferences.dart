import '/backend/schema/util/firestore_util.dart';

class NotificationPreferences {
  NotificationPreferences({
    required this.pushEnabled,
    required this.gameAlerts,
    required this.chatAlerts,
    required this.quietHours,
    required this.digestMode,
    required this.mutedThreads,
    required this.trustCategories,
  });

  final bool pushEnabled;
  final NotificationGameAlerts gameAlerts;
  final NotificationChatAlerts chatAlerts;
  final NotificationQuietHours quietHours;
  final String digestMode;
  final List<String> mutedThreads;
  final NotificationTrustCategories trustCategories;

  static NotificationPreferences defaults() {
    return NotificationPreferences(
      pushEnabled: true,  // Default to ON per requirements
      gameAlerts: NotificationGameAlerts.defaults(),
      chatAlerts: NotificationChatAlerts.defaults(),
      quietHours: NotificationQuietHours.defaults(),
      digestMode: 'instant',
      mutedThreads: const [],
      trustCategories: NotificationTrustCategories.defaults(),
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    NotificationGameAlerts? gameAlerts,
    NotificationChatAlerts? chatAlerts,
    NotificationQuietHours? quietHours,
    String? digestMode,
    List<String>? mutedThreads,
    NotificationTrustCategories? trustCategories,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      gameAlerts: gameAlerts ?? this.gameAlerts,
      chatAlerts: chatAlerts ?? this.chatAlerts,
      quietHours: quietHours ?? this.quietHours,
      digestMode: digestMode ?? this.digestMode,
      mutedThreads: mutedThreads ?? this.mutedThreads,
      trustCategories: trustCategories ?? this.trustCategories,
    );
  }

  static NotificationPreferences fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    final gameAlertsMap = _mapValue(data, 'game_alerts');
    final chatAlertsMap = _mapValue(data, 'chat_alerts');
    final quietHoursMap = _mapValue(data, 'quiet_hours');
    final trustCategoriesMap = _mapValue(data, 'trust_categories');
    return NotificationPreferences(
      pushEnabled: _boolValue(data, 'push_enabled', false),
      gameAlerts: NotificationGameAlerts.fromMap(gameAlertsMap),
      chatAlerts: NotificationChatAlerts.fromMap(chatAlertsMap),
      quietHours: NotificationQuietHours.fromMap(quietHoursMap),
      digestMode: _stringValue(data, 'digest_mode', 'instant'),
      mutedThreads: _stringListValue(data, 'muted_threads'),
      trustCategories: NotificationTrustCategories.fromMap(trustCategoriesMap),
    );
  }

  Map<String, dynamic> toFirestore() {
    return mapToFirestore({
      'push_enabled': pushEnabled,
      'game_alerts': gameAlerts.toFirestore(),
      'chat_alerts': chatAlerts.toFirestore(),
      'quiet_hours': quietHours.toFirestore(),
      'digest_mode': digestMode,
      'muted_threads': mutedThreads,
      'trust_categories': trustCategories.toFirestore(),
    });
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

  static bool _boolValue(
    Map<String, dynamic> data,
    String key,
    bool fallback,
  ) {
    final raw = data[key];
    if (raw is bool) {
      return raw;
    }
    return fallback;
  }

  static String _stringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final raw = data[key];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw;
    }
    return fallback;
  }

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
}

class NotificationGameAlerts {
  NotificationGameAlerts({
    required this.enabled,
  });

  final bool enabled;

  static NotificationGameAlerts defaults() {
    return NotificationGameAlerts(
      enabled: true,
    );
  }

  NotificationGameAlerts copyWith({
    bool? enabled,
  }) {
    return NotificationGameAlerts(
      enabled: enabled ?? this.enabled,
    );
  }

  static NotificationGameAlerts fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationGameAlerts(
      enabled: NotificationPreferences._boolValue(data, 'enabled', false),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
    };
  }
}

class NotificationChatAlerts {
  NotificationChatAlerts({
    required this.enabled,
  });

  final bool enabled;

  static NotificationChatAlerts defaults() {
    return NotificationChatAlerts(
      enabled: true,
    );
  }

  NotificationChatAlerts copyWith({
    bool? enabled,
  }) {
    return NotificationChatAlerts(
      enabled: enabled ?? this.enabled,
    );
  }

  static NotificationChatAlerts fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationChatAlerts(
      enabled: NotificationPreferences._boolValue(data, 'enabled', true),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
    };
  }
}

class NotificationQuietHours {
  NotificationQuietHours({
    required this.enabled,
    required this.start,
    required this.end,
  });

  final bool enabled;
  final String start;
  final String end;

  static NotificationQuietHours defaults() {
    return NotificationQuietHours(
      enabled: false,
      start: '22:00',
      end: '07:00',
    );
  }

  NotificationQuietHours copyWith({
    bool? enabled,
    String? start,
    String? end,
  }) {
    return NotificationQuietHours(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  static NotificationQuietHours fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationQuietHours(
      enabled: NotificationPreferences._boolValue(data, 'enabled', false),
      start: NotificationPreferences._stringValue(data, 'start', '22:00'),
      end: NotificationPreferences._stringValue(data, 'end', '07:00'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'start': start,
      'end': end,
    };
  }
}

class NotificationTrustCategories {
  NotificationTrustCategories({
    required this.postRound,
    required this.trustAlerts,
    required this.badges,
  });

  final bool postRound;
  final bool trustAlerts;
  final bool badges;

  static NotificationTrustCategories defaults() {
    return NotificationTrustCategories(
      postRound: true,
      trustAlerts: true,
      badges: true,
    );
  }

  NotificationTrustCategories copyWith({
    bool? postRound,
    bool? trustAlerts,
    bool? badges,
  }) {
    return NotificationTrustCategories(
      postRound: postRound ?? this.postRound,
      trustAlerts: trustAlerts ?? this.trustAlerts,
      badges: badges ?? this.badges,
    );
  }

  static NotificationTrustCategories fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationTrustCategories(
      postRound:   NotificationPreferences._boolValue(data, 'post_round',   true),
      trustAlerts: NotificationPreferences._boolValue(data, 'trust_alerts', true),
      badges:      NotificationPreferences._boolValue(data, 'badges',       true),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'post_round':   postRound,
      'trust_alerts': trustAlerts,
      'badges':       badges,
    };
  }
}
