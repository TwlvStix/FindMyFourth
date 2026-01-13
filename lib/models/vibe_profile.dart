enum VibeCategory {
  drinking('drinking'),
  music('music'),
  pace('pace'),
  money('money'),
  weed('weed'),
  chat('chat'),
  competitive('competitive');

  const VibeCategory(this.key);

  final String key;

  static VibeCategory? fromKey(String key) {
    for (final category in VibeCategory.values) {
      if (category.key == key) {
        return category;
      }
    }
    return null;
  }
}

class VibePreference {
  VibePreference({
    required int value,
    required bool dealbreaker,
    required int threshold,
    required bool isDefault,
  })  : value = _clamp(value),
        dealbreaker = dealbreaker,
        threshold = _clamp(threshold),
        isDefault = isDefault;

  static const int minValue = 0;
  static const int maxValue = 5;
  static const int defaultValue = 3;
  static const int defaultThreshold = 2;

  final int value;
  final bool dealbreaker;
  final int threshold;
  final bool isDefault;

  static VibePreference defaults() => VibePreference(
        value: defaultValue,
        dealbreaker: false,
        threshold: defaultThreshold,
        isDefault: true,
      );

  static int normalizeValue(int value) => _clamp(value);

  static VibePreference fromMap(Map<String, dynamic> data) {
    final defaults = VibePreference.defaults();
    final value = _toInt(data['value'], defaults.value);
    final dealbreaker = data['dealbreaker'] is bool
        ? data['dealbreaker'] as bool
        : defaults.dealbreaker;
    final threshold = _toInt(
      data['dealbreaker_threshold'] ?? data['threshold'],
      defaults.threshold,
    );
    final isDefault = data['is_default'] is bool
        ? data['is_default'] as bool
        : defaults.isDefault;
    return VibePreference(
      value: value,
      dealbreaker: dealbreaker,
      threshold: threshold,
      isDefault: isDefault,
    );
  }

  VibePreference copyWith({
    int? value,
    bool? dealbreaker,
    int? threshold,
    bool? isDefault,
  }) {
    return VibePreference(
      value: value ?? this.value,
      dealbreaker: dealbreaker ?? this.dealbreaker,
      threshold: threshold ?? this.threshold,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'value': value,
        'dealbreaker': dealbreaker,
        'dealbreaker_threshold': threshold,
        'is_default': isDefault,
      };

  static int _clamp(int value) => value.clamp(minValue, maxValue) as int;

  static int _toInt(dynamic raw, int fallback) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.round();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? fallback;
    }
    return fallback;
  }
}

class VibeProfile {
  VibeProfile({
    required Map<VibeCategory, VibePreference> prefs,
    this.confirmedAt,
  }) : prefs = Map.unmodifiable(prefs);

  final Map<VibeCategory, VibePreference> prefs;
  final DateTime? confirmedAt;

  bool get isComplete => confirmedAt != null;
  bool get isIncomplete => confirmedAt == null;

  static VibeProfile defaults() => VibeProfile(
        prefs: {
          for (final category in VibeCategory.values)
            category: VibePreference.defaults(),
        },
      );

  VibePreference preferenceFor(VibeCategory category) {
    return prefs[category] ?? VibePreference.defaults();
  }

  VibeProfile copyWith({
    Map<VibeCategory, VibePreference>? prefs,
    DateTime? confirmedAt,
  }) {
    return VibeProfile(
      prefs: prefs ?? this.prefs,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  VibeProfile confirmed(DateTime when) {
    final updatedPrefs = <VibeCategory, VibePreference>{
      for (final entry in prefs.entries)
        entry.key: entry.value.copyWith(isDefault: false),
    };
    return VibeProfile(
      prefs: updatedPrefs,
      confirmedAt: when,
    );
  }

  static VibeProfile fromFirestore(Map<String, dynamic>? data) {
    final defaults = VibeProfile.defaults();
    final prefs = Map<VibeCategory, VibePreference>.from(defaults.prefs);
    final rawPrefs = data?['prefs'];
    final prefsSource = rawPrefs is Map ? rawPrefs : data;

    if (prefsSource is Map) {
      prefsSource.forEach((key, value) {
        final category = VibeCategory.fromKey(key.toString());
        if (category == null || value is! Map) {
          return;
        }
        prefs[category] =
            VibePreference.fromMap(Map<String, dynamic>.from(value));
      });
    }

    final confirmedAt = _parseDate(data?['confirmed_at']);

    return VibeProfile(
      prefs: prefs,
      confirmedAt: confirmedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final prefsMap = <String, dynamic>{
      for (final entry in prefs.entries) entry.key.key: entry.value.toMap(),
    };

    return <String, dynamic>{
      'prefs': prefsMap,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    };
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

class VibeLabels {
  static String titleFor(VibeCategory category) {
    switch (category) {
      case VibeCategory.chat:
        return 'Chat';
      case VibeCategory.pace:
        return 'Pace';
      case VibeCategory.money:
        return 'Money';
      case VibeCategory.drinking:
        return 'Drinking';
      case VibeCategory.weed:
        return 'Weed';
      case VibeCategory.music:
        return 'Music';
      case VibeCategory.competitive:
        return 'Competitive';
    }
  }

  static String? labelFor(VibeCategory category, int value) {
    return _labels[category]?[value];
  }

  static const Map<VibeCategory, Map<int, String>> _labels = {
    VibeCategory.chat: {
      0: 'Quiet round',
      1: 'Mostly quiet',
      2: 'A bit of chat',
      3: 'Social',
      4: 'Chatty',
      5: 'Full gab mode',
    },
    VibeCategory.pace: {
      0: 'Slow and chill',
      1: 'Leisurely',
      2: 'Normal pace',
      3: 'Ready golf',
      4: 'Quick pace',
      5: 'Fast, keep moving',
    },
    VibeCategory.money: {
      0: 'No gambling',
      1: 'Tiny wager',
      2: 'Small skins',
      3: 'Regular game',
      4: 'Spicy game',
      5: 'High stakes',
    },
    VibeCategory.drinking: {
      0: 'Never',
      1: 'Rarely',
      2: 'Sometimes',
      3: 'Often',
      4: 'Buzzed',
      5: 'Party round',
    },
    VibeCategory.weed: {
      0: 'Never',
      1: 'Rarely',
      2: 'Sometimes',
      3: 'Often',
      4: 'Regularly',
      5: 'Always',
    },
    VibeCategory.music: {
      0: 'No music',
      1: 'Very low',
      2: 'Low background',
      3: 'Some tunes',
      4: 'Louder',
      5: 'Speaker vibes',
    },
    VibeCategory.competitive: {
      0: 'Casual only',
      1: 'Lightly competitive',
      2: 'Friendly scorekeeping',
      3: 'Competitive',
      4: 'High stakes',
      5: 'Serious grind',
    },
  };
}
