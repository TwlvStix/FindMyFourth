import '/backend/schema/util/firestore_util.dart';

class NotificationPreferences {
  NotificationPreferences({
    required this.pushEnabled,
    required this.gameAlerts,
    required this.chatAlerts,
    required this.quietHours,
    required this.digestMode,
    required this.mutedThreads,
  });

  final bool pushEnabled;
  final NotificationGameAlerts gameAlerts;
  final NotificationChatAlerts chatAlerts;
  final NotificationQuietHours quietHours;
  final String digestMode;
  final List<String> mutedThreads;

  static NotificationPreferences defaults() {
    return NotificationPreferences(
      pushEnabled: false,
      gameAlerts: NotificationGameAlerts.defaults(),
      chatAlerts: NotificationChatAlerts.defaults(),
      quietHours: NotificationQuietHours.defaults(),
      digestMode: 'instant',
      mutedThreads: const [],
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    NotificationGameAlerts? gameAlerts,
    NotificationChatAlerts? chatAlerts,
    NotificationQuietHours? quietHours,
    String? digestMode,
    List<String>? mutedThreads,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      gameAlerts: gameAlerts ?? this.gameAlerts,
      chatAlerts: chatAlerts ?? this.chatAlerts,
      quietHours: quietHours ?? this.quietHours,
      digestMode: digestMode ?? this.digestMode,
      mutedThreads: mutedThreads ?? this.mutedThreads,
    );
  }

  static NotificationPreferences fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    final gameAlertsMap = _mapValue(data, 'game_alerts');
    final chatAlertsMap = _mapValue(data, 'chat_alerts');
    final quietHoursMap = _mapValue(data, 'quiet_hours');
    return NotificationPreferences(
      pushEnabled: _boolValue(data, 'push_enabled', false),
      gameAlerts: NotificationGameAlerts.fromMap(gameAlertsMap),
      chatAlerts: NotificationChatAlerts.fromMap(chatAlertsMap),
      quietHours: NotificationQuietHours.fromMap(quietHoursMap),
      digestMode: _stringValue(data, 'digest_mode', 'instant'),
      mutedThreads: _stringListValue(data, 'muted_threads'),
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
    required this.styles,
  });

  final bool enabled;
  final List<String> styles;

  static NotificationGameAlerts defaults() {
    return NotificationGameAlerts(
      enabled: true,
      styles: const ['money', 'vegas', 'competitive', 'for_fun'],
    );
  }

  NotificationGameAlerts copyWith({
    bool? enabled,
    List<String>? styles,
  }) {
    return NotificationGameAlerts(
      enabled: enabled ?? this.enabled,
      styles: styles ?? this.styles,
    );
  }

  static NotificationGameAlerts fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationGameAlerts(
      enabled: NotificationPreferences._boolValue(data, 'enabled', true),
      styles: NotificationPreferences._stringListValue(data, 'styles'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'styles': styles,
    };
  }
}

class NotificationChatAlerts {
  NotificationChatAlerts({
    required this.enabled,
    required this.direct,
    required this.group,
  });

  final bool enabled;
  final bool direct;
  final bool group;

  static NotificationChatAlerts defaults() {
    return NotificationChatAlerts(
      enabled: true,
      direct: true,
      group: true,
    );
  }

  NotificationChatAlerts copyWith({
    bool? enabled,
    bool? direct,
    bool? group,
  }) {
    return NotificationChatAlerts(
      enabled: enabled ?? this.enabled,
      direct: direct ?? this.direct,
      group: group ?? this.group,
    );
  }

  static NotificationChatAlerts fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationChatAlerts(
      enabled: NotificationPreferences._boolValue(data, 'enabled', true),
      direct: NotificationPreferences._boolValue(data, 'direct', true),
      group: NotificationPreferences._boolValue(data, 'group', true),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'direct': direct,
      'group': group,
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
