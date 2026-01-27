import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';

const double _greatMin = 80;
const double _okayMin = 55;
const double _okayMax = 79;
const double _badMax = 54;

void main() {
  final dataset = _loadDataset();
  final profiles = _buildProfiles(dataset['profiles'] as List<dynamic>);
  final expectations = dataset['expectations'] as List<dynamic>;
  final orderings = dataset['orderings'] as List<dynamic>;

  test('golden pair buckets stay in expected ranges', () {
    for (final entry in expectations) {
      final map = entry as Map<String, dynamic>;
      final aId = map['a'] as String;
      final bId = map['b'] as String;
      final bucket = map['bucket'] as String;

      final a = profiles[aId];
      final b = profiles[bId];
      expect(a, isNotNull, reason: 'Missing profile $aId');
      expect(b, isNotNull, reason: 'Missing profile $bId');

      final result = VibeMatcher.score(a!, b!);
      final score = result.cappedScore ?? result.totalScore;
      final capped = result.cappedScore != null;

      if (bucket == 'great') {
        expect(score, greaterThanOrEqualTo(_greatMin));
      } else if (bucket == 'okay') {
        expect(score, inInclusiveRange(_okayMin, _okayMax));
      } else if (bucket == 'bad') {
        final inRange = score <= _badMax;
        expect(inRange || capped, isTrue,
            reason: 'Bad bucket expects <= $_badMax or capped');
      } else {
        fail('Unknown bucket: $bucket');
      }
    }
  });

  test('golden pair orderings remain stable', () {
    for (final entry in orderings) {
      final map = entry as Map<String, dynamic>;
      final anchorId = map['anchor'] as String;
      final ordering = (map['highToLow'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      final anchor = profiles[anchorId];
      expect(anchor, isNotNull, reason: 'Missing anchor $anchorId');

      double? lastScore;
      for (final otherId in ordering) {
        final other = profiles[otherId];
        expect(other, isNotNull, reason: 'Missing profile $otherId');
        final result = VibeMatcher.score(anchor!, other!);
        final score = result.cappedScore ?? result.totalScore;

        if (lastScore != null) {
          expect(lastScore, greaterThan(score),
              reason: 'Expected $anchorId > $otherId ordering');
        }
        lastScore = score;
      }
    }
  });
}

Map<String, dynamic> _loadDataset() {
  final file = File('testdata/vibe_golden_pairs.json');
  final raw = file.readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

Map<String, VibeProfile> _buildProfiles(List<dynamic> rawProfiles) {
  final profiles = <String, VibeProfile>{};
  for (final entry in rawProfiles) {
    final map = entry as Map<String, dynamic>;
    final id = map['id'] as String;
    final prefs = _prefsFromJson(map['prefs'] as Map<String, dynamic>);
    profiles[id] = VibeProfile(prefs: prefs);
  }
  return profiles;
}

Map<VibeCategory, VibePreference> _prefsFromJson(
  Map<String, dynamic> raw,
) {
  final prefs = <VibeCategory, VibePreference>{};
  for (final category in VibeCategory.values) {
    final rawPref = raw[category.key];
    if (rawPref is Map) {
      final data = Map<String, dynamic>.from(rawPref as Map);
      prefs[category] = VibePreference(
        value: _toInt(data['value'], VibePreference.defaultValue),
        dealbreaker: data['dealbreaker'] is bool
            ? data['dealbreaker'] as bool
            : false,
        threshold: _toInt(data['threshold'], VibePreference.defaultThreshold),
        isDefault: data['is_default'] is bool
            ? data['is_default'] as bool
            : false,
      );
    } else {
      prefs[category] = VibePreference.defaults();
    }
  }
  return prefs;
}

int _toInt(dynamic raw, int fallback) {
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
