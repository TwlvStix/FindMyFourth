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
    DateTime? importanceUpdatedAt,
    this.confirmedAt,
  })  : prefs = Map.unmodifiable(prefs),
        importance = Map.unmodifiable(importance ?? _defaultImportanceMap()),
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
    VibeCategory.chat:
        'How talkative do you like the group to be during the round?',
    VibeCategory.money:
        'How do you feel about gambling and side games (skins, presses, bets) in your group during a round?',
    VibeCategory.competitive:
        'How competitive do you like the group atmosphere to be?',
    VibeCategory.pace: 'How do you feel about pace expectations in your group?',
  };

  static const Map<VibeCategory, String> _helpers = {
    VibeCategory.drinking:
        "Rate what you're comfortable being around, not whether you personally drink.",
    VibeCategory.music:
        "Rate what you enjoy being around, even if you don't play music yourself.\nRespectful behavior matters. Rate what you enjoy being around.",
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
    VibeCategory.pace: {
      0: 'I play deliberate. I read every putt.',
      1: 'No rush. I play at my own pace.',
      2: 'Keep it moving but I\'m not stressing.',
      3: 'Steady pace. I don\'t like waiting.',
      4: 'Ready golf. Let\'s go.',
      5: 'If you\'re not ready, I\'m hitting.',
    },
    VibeCategory.chat: {
      0: 'I keep to myself out there.',
      1: 'A few words here and there.',
      2: 'I\'ll chat between shots.',
      3: 'I like a good conversation on the course.',
      4: 'I\'m the one keeping the group laughing.',
      5: 'Non-stop. I might talk during your backswing.',
    },
    VibeCategory.music: {
      0: 'No music. I like the sounds of the course.',
      1: 'Low and quiet if anything.',
      2: 'Background music is fine.',
      3: 'I like music going most of the round.',
      4: 'Speaker\'s on from the first tee.',
      5: 'I\'ve got a playlist ready. It\'s non-negotiable.',
    },
    VibeCategory.drinking: {
      0: 'I don\'t drink on the course.',
      1: 'Maybe one, keep it light.',
      2: 'A couple beers through the round.',
      3: 'A drink in hand most of the round.',
      4: 'Cart girl every time. Cooler\'s stocked.',
      5: 'We\'re here to golf and drink. In that order. Maybe.',
    },
    VibeCategory.money: {
      0: 'No games, no bets. I\'m just playing golf.',
      1: 'A friendly bet for a beer or bragging rights.',
      2: 'Skins or dots. A few bucks to keep it interesting.',
      3: 'A few games running. Enough to make it sting a little.',
      4: 'Multiple games, real money. That\'s how I play.',
      5: 'Big stakes, big action. The bet makes the round.',
    },
    VibeCategory.competitive: {
      0: 'I\'m just out here having fun.',
      1: 'I don\'t really keep score.',
      2: 'I keep score for my own game and handicap.',
      3: 'I\'m trying to beat my group. Every time.',
      4: 'I secretly wish the worst for my playing partners.',
      5: 'Every shot feels like the Masters.',
    },
  };
}
