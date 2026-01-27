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
    Map<VibeCategory, VibeImportance>? importance,
    int? importanceVersion,
    DateTime? importanceUpdatedAt,
    this.confirmedAt,
  })  : prefs = Map.unmodifiable(prefs),
        importance =
            Map.unmodifiable(importance ?? _defaultImportanceMap()),
        importanceVersion = importanceVersion ?? 1,
        importanceUpdatedAt = importanceUpdatedAt;

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

  static String promptFor(VibeCategory category) {
    return _prompts[category] ?? titleFor(category);
  }

  static String helperFor(VibeCategory category) {
    return _helpers[category] ?? '';
  }

  static String? labelFor(VibeCategory category, int value) {
    return _labels[category]?[value];
  }

  static const Map<VibeCategory, String> _prompts = {
    VibeCategory.drinking:
        'How do you feel about alcohol in your group during a round?',
    VibeCategory.music:
        'How do you feel about music being played during the round?',
    VibeCategory.weed:
        'How do you feel about cannabis around the group during a round?',
    VibeCategory.chat:
        'How talkative do you like the group to be during the round?',
    VibeCategory.money:
        'How do you feel about gambling and side games (skins, presses, bets) in your group during a round?',
    VibeCategory.competitive:
        'How competitive do you like the group atmosphere to be?',
    VibeCategory.pace:
        'How do you feel about pace expectations in your group?',
  };

  static const Map<VibeCategory, String> _helpers = {
    VibeCategory.drinking:
        "Rate what you're comfortable being around, not whether you personally drink.",
    VibeCategory.music:
        "Rate what you enjoy being around, even if you don't play music yourself.\nRespectful behavior matters. Rate what you enjoy being around.",
    VibeCategory.weed:
        "Rate what you're comfortable being around, not whether you personally use it.",
    VibeCategory.chat:
        "Rate the group energy you enjoy, not how talkative you are as a person.\nRespectful behavior matters. Rate what you enjoy being around.",
    VibeCategory.money:
        'Rate what you enjoy being around, not how much you personally bet.',
    VibeCategory.competitive:
        'Rate the competitive intensity you enjoy being around, not your skill level.',
    VibeCategory.pace:
        "Rate the pace you enjoy being around, not how fast you personally walk.\nRespectful behavior matters. Rate what you enjoy being around.",
  };

  static const Map<VibeCategory, Map<int, String>> _labels = {
    VibeCategory.chat: {
      0: 'Very quiet, minimal talking',
      1: 'Mostly quiet with brief check-ins',
      2: 'Light conversation here and there',
      3: 'Balanced mix of golf and chat',
      4: 'Very social and talkative',
      5: 'Constant conversation, very social',
    },
    VibeCategory.pace: {
      0: "Very relaxed, pace isn't a priority",
      1: 'Easygoing pace, no rushing',
      2: 'Reasonable pace, no stress',
      3: 'Steady pace, keep things moving',
      4: 'Fast pace is important',
      5: 'Very fast, pace-focused round',
    },
    VibeCategory.money: {
      0: 'Prefer none around me',
      1: 'Very limited, only if everyone agrees (low stakes)',
      2: 'Occasional small game is fine',
      3: 'Skins or a casual game is fine',
      4: 'Regular games and action most rounds',
      5: 'Love gambling, bring the games and bets',
    },
    VibeCategory.drinking: {
      0: 'Prefer none around me',
      1: 'Very limited, keep it barely noticeable',
      2: "Occasional is fine if it doesn't affect the round",
      3: 'A couple is fine',
      4: 'Regular drinking is part of the vibe',
      5: 'Love a few drinks in the group',
    },
    VibeCategory.weed: {
      0: 'Prefer none around me',
      1: 'Very limited, discreet only',
      2: "Occasional is fine if it doesn't affect play",
      3: 'Casual use is fine',
      4: 'Regular use is part of the vibe',
      5: 'Fully comfortable with it around the group',
    },
    VibeCategory.music: {
      0: 'Prefer silence around me',
      1: 'Rare, very low volume only',
      2: 'Occasional background music is fine',
      3: 'Music is usually fine at a respectful level',
      4: 'Music most of the round',
      5: 'Music is a big part of the vibe',
    },
    VibeCategory.competitive: {
      0: 'Very relaxed, no competitive pressure',
      1: 'Light competition, mostly casual',
      2: 'Friendly competition',
      3: 'Structured competition but approachable',
      4: 'Highly competitive',
      5: 'Tournament-level intensity',
    },
  };
}
