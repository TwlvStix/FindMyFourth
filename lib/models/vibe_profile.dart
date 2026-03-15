enum VibeCategory {
  drinking('drinking'),
  music('music'),
  pace('pace'),
  money('money'),
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

enum VibeImportance {
  top('top'),
  normal('normal'),
  bottom('bottom');

  const VibeImportance(this.key);

  final String key;

  static VibeImportance fromKey(String? key) {
    switch (key) {
      case 'top':
        return VibeImportance.top;
      case 'bottom':
        return VibeImportance.bottom;
      case 'normal':
      default:
        return VibeImportance.normal;
    }
  }
}

class VibePreference {
  VibePreference({
    required int value,
    required this.dealbreaker,
    required int threshold,
    required this.isDefault,
  })  : value = _clamp(value),
        threshold = _clamp(threshold);

  static const int minValue = 0;
  static const int maxValue = 5;
  static const int defaultValue = 3;
  static const int defaultThreshold = 1;

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

  static int _clamp(int value) => value.clamp(minValue, maxValue);

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
    Map<VibeCategory, VibeImportance>? importance,
    int? importanceVersion,
    this.importanceUpdatedAt,
    this.confirmedAt,
  })  : prefs = Map.unmodifiable(prefs),
        importance = Map.unmodifiable(importance ?? _defaultImportanceMap()),
        importanceVersion = importanceVersion ?? 1;

  final Map<VibeCategory, VibePreference> prefs;
  final Map<VibeCategory, VibeImportance> importance;
  final int importanceVersion;
  final DateTime? importanceUpdatedAt;
  final DateTime? confirmedAt;

  bool get isComplete => confirmedAt != null;
  bool get isIncomplete => confirmedAt == null;

  static VibeProfile defaults() => VibeProfile(
        prefs: {
          for (final category in VibeCategory.values)
            category: VibePreference.defaults(),
        },
        importance: _defaultImportanceMap(),
        importanceVersion: 1,
      );

  VibePreference preferenceFor(VibeCategory category) {
    return prefs[category] ?? VibePreference.defaults();
  }

  VibeImportance importanceFor(VibeCategory category) {
    return importance[category] ?? VibeImportance.normal;
  }

  VibeProfile copyWith({
    Map<VibeCategory, VibePreference>? prefs,
    Map<VibeCategory, VibeImportance>? importance,
    int? importanceVersion,
    DateTime? importanceUpdatedAt,
    DateTime? confirmedAt,
  }) {
    return VibeProfile(
      prefs: prefs ?? this.prefs,
      importance: importance ?? this.importance,
      importanceVersion: importanceVersion ?? this.importanceVersion,
      importanceUpdatedAt: importanceUpdatedAt ?? this.importanceUpdatedAt,
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
      importance: importance,
      importanceVersion: importanceVersion,
      importanceUpdatedAt: importanceUpdatedAt,
      confirmedAt: when,
    );
  }

  static VibeProfile fromFirestore(Map<String, dynamic>? data) {
    final defaults = VibeProfile.defaults();
    final prefs = Map<VibeCategory, VibePreference>.from(defaults.prefs);
    final importance =
        Map<VibeCategory, VibeImportance>.from(defaults.importance);
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
    final importanceVersion = _toInt(data?['importance_version'], 1);
    final importanceUpdatedAt = _parseDate(data?['importance_updated_at']);
    final rawImportance = data?['importance'];
    if (rawImportance is Map) {
      rawImportance.forEach((key, value) {
        final category = VibeCategory.fromKey(key.toString());
        if (category == null) {
          return;
        }
        importance[category] = VibeImportance.fromKey(value?.toString());
      });
    }

    return VibeProfile(
      prefs: prefs,
      importance: importance,
      importanceVersion: importanceVersion,
      importanceUpdatedAt: importanceUpdatedAt,
      confirmedAt: confirmedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final prefsMap = <String, dynamic>{
      for (final entry in prefs.entries) entry.key.key: entry.value.toMap(),
    };
    final importanceMap = <String, dynamic>{
      for (final entry in importance.entries) entry.key.key: entry.value.key,
    };

    return <String, dynamic>{
      'prefs': prefsMap,
      'importance': importanceMap,
      'importance_version': importanceVersion,
      if (importanceUpdatedAt != null)
        'importance_updated_at': importanceUpdatedAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    };
  }

  static Map<VibeCategory, VibeImportance> _defaultImportanceMap() {
    return {
      for (final category in VibeCategory.values)
        category: VibeImportance.normal,
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
