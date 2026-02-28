import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/providers/group_vibe_provider.dart';
import 'package:find_my_fourth/services/vibe_group_matcher.dart';

VibeProfile _buildProfile({
  int pace = 3,
  int competitive = 3,
  int drinking = 3,
  int chat = 3,
  int money = 3,
  int music = 3,
}) {
  final prefs = <VibeCategory, VibePreference>{
    VibeCategory.pace: VibePreference(
      value: pace,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.competitive: VibePreference(
      value: competitive,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.drinking: VibePreference(
      value: drinking,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.chat: VibePreference(
      value: chat,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.money: VibePreference(
      value: money,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.music: VibePreference(
      value: music,
      dealbreaker: false,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
  };

  return VibeProfile(
    prefs: prefs,
    importance: {
      for (final category in VibeCategory.values)
        category: VibeImportance.normal,
    },
    importanceVersion: 1,
    confirmedAt: DateTime.now(),
  );
}

void main() {
  group('GroupVibeProvider', () {
    test('caches result for key and skips duplicate loads within ttl',
        () async {
      var myVibesLoadCount = 0;
      var memberLoadCount = 0;

      final provider = GroupVibeProvider(
        loadMyVibes: () async {
          myVibesLoadCount += 1;
          return _buildProfile(pace: 4);
        },
      );

      Future<List<GroupVibeMember>> memberLoader(List<String> userIds) async {
        memberLoadCount += 1;
        return <GroupVibeMember>[
          GroupVibeMember(
            id: userIds[0],
            name: 'Member A',
            profile: _buildProfile(pace: 1),
          ),
          GroupVibeMember(
            id: userIds[1],
            name: 'Member B',
            profile: _buildProfile(pace: 2),
          ),
        ];
      }

      const cacheKey = 'game-1:me:user-a,user-b';
      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a', 'user-b'],
        memberLoader: memberLoader,
      );

      expect(provider.getMatch(cacheKey), isNotNull);
      expect(provider.getMemberMatchesById(cacheKey).length, 2);
      expect(myVibesLoadCount, 1);
      expect(memberLoadCount, 1);

      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a', 'user-b'],
        memberLoader: memberLoader,
      );

      expect(myVibesLoadCount, 1);
      expect(memberLoadCount, 1);
      provider.dispose();
    });

    test('forceRefresh reloads even when cache exists', () async {
      var loadCount = 0;
      final provider = GroupVibeProvider(
        loadMyVibes: () async => _buildProfile(),
      );

      Future<List<GroupVibeMember>> memberLoader(List<String> userIds) async {
        loadCount += 1;
        return <GroupVibeMember>[
          GroupVibeMember(
            id: userIds.first,
            name: 'Member A',
            profile: _buildProfile(pace: 5),
          ),
        ];
      }

      const cacheKey = 'game-2:me:user-a';
      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
      );
      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
        forceRefresh: true,
      );

      expect(loadCount, 2);
      provider.dispose();
    });

    test('failed load clears match and member maps for key', () async {
      final provider = GroupVibeProvider(
        loadMyVibes: () async => _buildProfile(),
      );

      const cacheKey = 'game-3:me:user-a';
      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a'],
        memberLoader: (_) async => throw StateError('boom'),
      );

      expect(provider.getMatch(cacheKey), isNull);
      expect(provider.getMemberMatchesById(cacheKey), isEmpty);
      provider.dispose();
    });

    test('invalidateCacheKey forces subsequent load', () async {
      var loadCount = 0;
      final provider = GroupVibeProvider(
        loadMyVibes: () async => _buildProfile(),
      );

      Future<List<GroupVibeMember>> memberLoader(List<String> userIds) async {
        loadCount += 1;
        return <GroupVibeMember>[
          GroupVibeMember(
            id: userIds.first,
            name: 'Member A',
            profile: _buildProfile(pace: 1),
          ),
        ];
      }

      const cacheKey = 'game-4:me:user-a';
      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
      );
      provider.invalidateCacheKey(cacheKey);
      await provider.ensureGroupVibeMatch(
        cacheKey: cacheKey,
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
      );

      expect(loadCount, 2);
      provider.dispose();
    });

    test('invalidateGame clears all cache entries for that game', () async {
      final provider = GroupVibeProvider(
        loadMyVibes: () async => _buildProfile(),
      );

      Future<List<GroupVibeMember>> memberLoader(List<String> userIds) async {
        return <GroupVibeMember>[
          GroupVibeMember(
            id: userIds.first,
            name: 'Member A',
            profile: _buildProfile(pace: 1),
          ),
        ];
      }

      await provider.ensureGroupVibeMatch(
        cacheKey: 'game-5:me:user-a',
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
      );
      await provider.ensureGroupVibeMatch(
        cacheKey: 'game-5:other:user-a',
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
      );
      await provider.ensureGroupVibeMatch(
        cacheKey: 'game-6:me:user-a',
        memberUserIds: const ['user-a'],
        memberLoader: memberLoader,
      );

      provider.invalidateGame('game-5');

      expect(provider.getMatch('game-5:me:user-a'), isNull);
      expect(provider.getMatch('game-5:other:user-a'), isNull);
      expect(provider.getMatch('game-6:me:user-a'), isNotNull);
      provider.dispose();
    });
  });
}
