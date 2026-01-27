import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';

void main() {
  group('VibeProfile', () {
    test('defaults apply and are incomplete', () {
      final profile = VibeProfile.defaults();

      expect(profile.confirmedAt, isNull);
      expect(profile.isIncomplete, isTrue);

      for (final category in VibeCategory.values) {
        final pref = profile.preferenceFor(category);
        expect(pref.value, VibePreference.defaultValue);
        expect(pref.dealbreaker, isFalse);
        expect(pref.threshold, VibePreference.defaultThreshold);
        expect(pref.isDefault, isTrue);
        expect(profile.importanceFor(category), VibeImportance.normal);
      }
      expect(profile.importanceVersion, 1);
    });

    test('serialization round-trip', () {
      final prefs = {
        for (final category in VibeCategory.values)
          category: VibePreference.defaults(),
      };
      prefs[VibeCategory.music] = VibePreference(
        value: 5,
        dealbreaker: true,
        threshold: 4,
        isDefault: false,
      );
      prefs[VibeCategory.chat] = VibePreference(
        value: 1,
        dealbreaker: false,
        threshold: 2,
        isDefault: false,
      );

      final original = VibeProfile(
        prefs: prefs,
        importance: {
          for (final category in VibeCategory.values)
            category: VibeImportance.normal,
          VibeCategory.music: VibeImportance.top,
          VibeCategory.money: VibeImportance.bottom,
        },
        importanceVersion: 1,
        importanceUpdatedAt: DateTime.utc(2024, 2, 3, 4, 5, 6),
        confirmedAt: DateTime.utc(2024, 1, 2, 3, 4, 5),
      );

      final map = original.toFirestore();
      final restored = VibeProfile.fromFirestore(map);

      expect(restored.confirmedAt, original.confirmedAt);

      final music = restored.preferenceFor(VibeCategory.music);
      expect(music.value, 5);
      expect(music.dealbreaker, isTrue);
      expect(music.threshold, 4);
      expect(music.isDefault, isFalse);

      final chat = restored.preferenceFor(VibeCategory.chat);
      expect(chat.value, 1);
      expect(chat.dealbreaker, isFalse);
      expect(chat.threshold, 2);
      expect(chat.isDefault, isFalse);

      expect(
        restored.importanceFor(VibeCategory.music),
        VibeImportance.top,
      );
      expect(
        restored.importanceFor(VibeCategory.money),
        VibeImportance.bottom,
      );
      expect(restored.importanceVersion, 1);
      expect(restored.importanceUpdatedAt, original.importanceUpdatedAt);
    });

    test('clamps values to valid ranges', () {
      final pref = VibePreference(
        value: 9,
        dealbreaker: true,
        threshold: -2,
        isDefault: false,
      );

      expect(pref.value, VibePreference.maxValue);
      expect(pref.threshold, VibePreference.minValue);
    });
  });
}
