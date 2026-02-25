import '/backend/schema/util/firestore_util.dart';

/// Delivery frequency for notification categories.
/// Used for per-category notification timing control.
enum DeliveryFrequency {
  instant,
  hourly,
  daily;

  String toFirestore() => name;

  /// Parse from Firestore value with fallback to global digestMode for migration.
  static DeliveryFrequency fromFirestore(String? value, String? fallbackDigestMode) {
    // Try parsing the value first
    if (value != null) {
      for (final freq in DeliveryFrequency.values) {
        if (freq.name == value) return freq;
      }
    }
    // Fall back to global digestMode for migration from old schema
    if (fallbackDigestMode != null) {
      for (final freq in DeliveryFrequency.values) {
        if (freq.name == fallbackDigestMode) return freq;
      }
    }
    return DeliveryFrequency.instant;
  }
}

/// Preset notification profiles for quick configuration.
enum NotificationProfile {
  allIn,      // Everything on, instant delivery
  gameDay,    // Game alerts instant, trust daily, chat off
  essentials, // Trust only, instant
  quiet;      // Everything off except push enabled

  String toFirestore() => name;

  static NotificationProfile? fromFirestore(String? value) {
    if (value == null) return null;
    for (final profile in NotificationProfile.values) {
      if (profile.name == value) return profile;
    }
    return null;
  }
}

class NotificationPreferences {
  NotificationPreferences({
    required this.pushEnabled,
    required this.gameAlerts,
    required this.chatAlerts,
    required this.quietHours,
    required this.digestMode,
    required this.mutedThreads,
    required this.trustCategories,
    this.activeProfile,
  });

  final bool pushEnabled;
  final NotificationGameAlerts gameAlerts;
  final NotificationChatAlerts chatAlerts;
  final NotificationQuietHours quietHours;

  /// @deprecated Use per-category deliveryFrequency fields instead.
  /// Kept for backwards compatibility during migration from old schema.
  final String digestMode;

  final List<String> mutedThreads;
  final NotificationTrustCategories trustCategories;

  /// Currently active notification profile, or null if using custom settings.
  final NotificationProfile? activeProfile;

  static NotificationPreferences defaults() {
    return NotificationPreferences(
      pushEnabled: true,  // Default to ON per requirements
      gameAlerts: NotificationGameAlerts.defaults(),
      chatAlerts: NotificationChatAlerts.defaults(),
      quietHours: NotificationQuietHours.defaults(),
      digestMode: 'instant',
      mutedThreads: const [],
      trustCategories: NotificationTrustCategories.defaults(),
      activeProfile: NotificationProfile.allIn,
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
    NotificationProfile? activeProfile,
    bool clearActiveProfile = false,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      gameAlerts: gameAlerts ?? this.gameAlerts,
      chatAlerts: chatAlerts ?? this.chatAlerts,
      quietHours: quietHours ?? this.quietHours,
      digestMode: digestMode ?? this.digestMode,
      mutedThreads: mutedThreads ?? this.mutedThreads,
      trustCategories: trustCategories ?? this.trustCategories,
      activeProfile: clearActiveProfile ? null : (activeProfile ?? this.activeProfile),
    );
  }

  static NotificationPreferences fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    final gameAlertsMap = _mapValue(data, 'game_alerts');
    final chatAlertsMap = _mapValue(data, 'chat_alerts');
    final quietHoursMap = _mapValue(data, 'quiet_hours');
    final trustCategoriesMap = _mapValue(data, 'trust_categories');

    // Get global digestMode for backwards-compat fallback
    final digestMode = _stringValue(data, 'digest_mode', 'instant');

    return NotificationPreferences(
      pushEnabled: _boolValue(data, 'push_enabled', false),
      gameAlerts: NotificationGameAlerts.fromMap(
        gameAlertsMap,
        fallbackDigestMode: digestMode,
      ),
      chatAlerts: NotificationChatAlerts.fromMap(
        chatAlertsMap,
        fallbackDigestMode: digestMode,
      ),
      quietHours: NotificationQuietHours.fromMap(quietHoursMap),
      digestMode: digestMode,
      mutedThreads: _stringListValue(data, 'muted_threads'),
      trustCategories: NotificationTrustCategories.fromMap(
        trustCategoriesMap,
        fallbackDigestMode: digestMode,
      ),
      activeProfile: NotificationProfile.fromFirestore(
        data['active_profile'] as String?,
      ),
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
      'active_profile': activeProfile?.toFirestore(),
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

  /// Create fully-configured preferences from a preset profile.
  /// Note: quietHours and mutedThreads use defaults - caller should preserve
  /// existing values when applying a profile.
  static NotificationPreferences fromProfile(NotificationProfile profile) {
    switch (profile) {
      case NotificationProfile.allIn:
        // Everything on, instant delivery
        return NotificationPreferences(
          pushEnabled: true,
          gameAlerts: NotificationGameAlerts(
            enabled: true,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          chatAlerts: NotificationChatAlerts(
            enabled: true,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          quietHours: NotificationQuietHours.defaults(),
          digestMode: 'instant',
          mutedThreads: const [],
          trustCategories: NotificationTrustCategories(
            enabled: true,
            postRound: true,
            trustAlerts: true,
            badges: true,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          activeProfile: NotificationProfile.allIn,
        );

      case NotificationProfile.gameDay:
        // Game alerts instant, trust daily, chat off
        return NotificationPreferences(
          pushEnabled: true,
          gameAlerts: NotificationGameAlerts(
            enabled: true,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          chatAlerts: NotificationChatAlerts(
            enabled: false,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          quietHours: NotificationQuietHours.defaults(),
          digestMode: 'instant',
          mutedThreads: const [],
          trustCategories: NotificationTrustCategories(
            enabled: true,
            postRound: true,
            trustAlerts: true,
            badges: true,
            deliveryFrequency: DeliveryFrequency.daily,
          ),
          activeProfile: NotificationProfile.gameDay,
        );

      case NotificationProfile.essentials:
        // Trust only, instant - game alerts off, chat off
        return NotificationPreferences(
          pushEnabled: true,
          gameAlerts: NotificationGameAlerts(
            enabled: false,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          chatAlerts: NotificationChatAlerts(
            enabled: false,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          quietHours: NotificationQuietHours.defaults(),
          digestMode: 'instant',
          mutedThreads: const [],
          trustCategories: NotificationTrustCategories(
            enabled: true,
            postRound: true,
            trustAlerts: true,
            badges: true,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          activeProfile: NotificationProfile.essentials,
        );

      case NotificationProfile.quiet:
        // Everything off except push enabled
        return NotificationPreferences(
          pushEnabled: true,
          gameAlerts: NotificationGameAlerts(
            enabled: false,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          chatAlerts: NotificationChatAlerts(
            enabled: false,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          quietHours: NotificationQuietHours.defaults(),
          digestMode: 'instant',
          mutedThreads: const [],
          trustCategories: NotificationTrustCategories(
            enabled: false,
            postRound: true,
            trustAlerts: true,
            badges: true,
            deliveryFrequency: DeliveryFrequency.instant,
          ),
          activeProfile: NotificationProfile.quiet,
        );
    }
  }

  /// Detect if current settings match a preset profile exactly.
  /// Returns null if settings are custom (don't match any preset).
  /// Note: quietHours and mutedThreads are ignored in detection.
  NotificationProfile? detectActiveProfile() {
    // Check allIn: everything on, instant
    if (pushEnabled &&
        gameAlerts.enabled &&
        gameAlerts.deliveryFrequency == DeliveryFrequency.instant &&
        chatAlerts.enabled &&
        chatAlerts.deliveryFrequency == DeliveryFrequency.instant &&
        trustCategories.enabled &&
        trustCategories.postRound &&
        trustCategories.trustAlerts &&
        trustCategories.badges &&
        trustCategories.deliveryFrequency == DeliveryFrequency.instant) {
      return NotificationProfile.allIn;
    }

    // Check gameDay: game alerts instant, chat off, trust daily
    if (pushEnabled &&
        gameAlerts.enabled &&
        gameAlerts.deliveryFrequency == DeliveryFrequency.instant &&
        !chatAlerts.enabled &&
        trustCategories.enabled &&
        trustCategories.postRound &&
        trustCategories.trustAlerts &&
        trustCategories.badges &&
        trustCategories.deliveryFrequency == DeliveryFrequency.daily) {
      return NotificationProfile.gameDay;
    }

    // Check essentials: trust only instant, game alerts off, chat off
    if (pushEnabled &&
        !gameAlerts.enabled &&
        !chatAlerts.enabled &&
        trustCategories.enabled &&
        trustCategories.postRound &&
        trustCategories.trustAlerts &&
        trustCategories.badges &&
        trustCategories.deliveryFrequency == DeliveryFrequency.instant) {
      return NotificationProfile.essentials;
    }

    // Check quiet: everything off except push enabled
    if (pushEnabled &&
        !gameAlerts.enabled &&
        !chatAlerts.enabled &&
        !trustCategories.enabled) {
      return NotificationProfile.quiet;
    }

    // Custom settings
    return null;
  }
}

class NotificationGameAlerts {
  NotificationGameAlerts({
    required this.enabled,
    required this.deliveryFrequency,
  });

  final bool enabled;
  final DeliveryFrequency deliveryFrequency;

  static NotificationGameAlerts defaults() {
    return NotificationGameAlerts(
      enabled: true,
      deliveryFrequency: DeliveryFrequency.instant,
    );
  }

  NotificationGameAlerts copyWith({
    bool? enabled,
    DeliveryFrequency? deliveryFrequency,
  }) {
    return NotificationGameAlerts(
      enabled: enabled ?? this.enabled,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
    );
  }

  static NotificationGameAlerts fromMap(
    Map<String, dynamic>? map, {
    String? fallbackDigestMode,
  }) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationGameAlerts(
      enabled: NotificationPreferences._boolValue(data, 'enabled', false),
      deliveryFrequency: DeliveryFrequency.fromFirestore(
        data['delivery_frequency'] as String?,
        fallbackDigestMode,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'delivery_frequency': deliveryFrequency.toFirestore(),
    };
  }
}

class NotificationChatAlerts {
  NotificationChatAlerts({
    required this.enabled,
    required this.deliveryFrequency,
  });

  final bool enabled;
  final DeliveryFrequency deliveryFrequency;

  static NotificationChatAlerts defaults() {
    return NotificationChatAlerts(
      enabled: true,
      deliveryFrequency: DeliveryFrequency.instant,
    );
  }

  NotificationChatAlerts copyWith({
    bool? enabled,
    DeliveryFrequency? deliveryFrequency,
  }) {
    return NotificationChatAlerts(
      enabled: enabled ?? this.enabled,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
    );
  }

  static NotificationChatAlerts fromMap(
    Map<String, dynamic>? map, {
    String? fallbackDigestMode,
  }) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationChatAlerts(
      enabled: NotificationPreferences._boolValue(data, 'enabled', true),
      deliveryFrequency: DeliveryFrequency.fromFirestore(
        data['delivery_frequency'] as String?,
        fallbackDigestMode,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'delivery_frequency': deliveryFrequency.toFirestore(),
    };
  }
}

class NotificationQuietHours {
  NotificationQuietHours({
    required this.enabled,
    required this.start,
    required this.end,
    required this.activeDays,
  });

  final bool enabled;
  final String start;
  final String end;
  /// Days when quiet hours are active. 1=Monday through 7=Sunday.
  final List<int> activeDays;

  /// Default weekdays (Monday-Friday)
  static const List<int> defaultActiveDays = [1, 2, 3, 4, 5];

  static NotificationQuietHours defaults() {
    return NotificationQuietHours(
      enabled: false,
      start: '22:00',
      end: '07:00',
      activeDays: defaultActiveDays,
    );
  }

  NotificationQuietHours copyWith({
    bool? enabled,
    String? start,
    String? end,
    List<int>? activeDays,
  }) {
    return NotificationQuietHours(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
      activeDays: activeDays ?? this.activeDays,
    );
  }

  static NotificationQuietHours fromMap(Map<String, dynamic>? map) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationQuietHours(
      enabled: NotificationPreferences._boolValue(data, 'enabled', false),
      start: NotificationPreferences._stringValue(data, 'start', '22:00'),
      end: NotificationPreferences._stringValue(data, 'end', '07:00'),
      activeDays: _intListValue(data, 'active_days', defaultActiveDays),
    );
  }

  static List<int> _intListValue(
    Map<String, dynamic> data,
    String key,
    List<int> fallback,
  ) {
    final raw = data[key];
    if (raw is List) {
      final result = raw.whereType<int>().toList();
      return result.isNotEmpty ? result : fallback;
    }
    return fallback;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'start': start,
      'end': end,
      'active_days': activeDays,
    };
  }
}

class NotificationTrustCategories {
  NotificationTrustCategories({
    required this.enabled,
    required this.postRound,
    required this.trustAlerts,
    required this.badges,
    required this.deliveryFrequency,
  });

  /// Master toggle for all trust notifications.
  /// When false, sub-toggles are preserved but no notifications are sent.
  final bool enabled;
  final bool postRound;
  final bool trustAlerts;
  final bool badges;
  final DeliveryFrequency deliveryFrequency;

  static NotificationTrustCategories defaults() {
    return NotificationTrustCategories(
      enabled: true,
      postRound: true,
      trustAlerts: true,
      badges: true,
      deliveryFrequency: DeliveryFrequency.instant,
    );
  }

  NotificationTrustCategories copyWith({
    bool? enabled,
    bool? postRound,
    bool? trustAlerts,
    bool? badges,
    DeliveryFrequency? deliveryFrequency,
  }) {
    return NotificationTrustCategories(
      enabled: enabled ?? this.enabled,
      postRound: postRound ?? this.postRound,
      trustAlerts: trustAlerts ?? this.trustAlerts,
      badges: badges ?? this.badges,
      deliveryFrequency: deliveryFrequency ?? this.deliveryFrequency,
    );
  }

  static NotificationTrustCategories fromMap(
    Map<String, dynamic>? map, {
    String? fallbackDigestMode,
  }) {
    final data = map == null ? <String, dynamic>{} : Map<String, dynamic>.from(map);
    return NotificationTrustCategories(
      // Default enabled to true for backwards compat (existing users had sub-toggles on)
      enabled: NotificationPreferences._boolValue(data, 'enabled', true),
      postRound: NotificationPreferences._boolValue(data, 'post_round', true),
      trustAlerts: NotificationPreferences._boolValue(data, 'trust_alerts', true),
      badges: NotificationPreferences._boolValue(data, 'badges', true),
      deliveryFrequency: DeliveryFrequency.fromFirestore(
        data['delivery_frequency'] as String?,
        fallbackDigestMode,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enabled': enabled,
      'post_round': postRound,
      'trust_alerts': trustAlerts,
      'badges': badges,
      'delivery_frequency': deliveryFrequency.toFirestore(),
    };
  }
}
