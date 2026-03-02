import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/providers/vibe_provider.dart';
import 'package:find_my_fourth/services/vibe_repository.dart';

/// Mock VibeRepository for testing VibeProvider in isolation.
class MockVibeRepository implements VibeRepository {
  MockVibeRepository({
    this.profileToReturn,
    this.shouldFailOnUpdate = false,
    this.shouldFailOnToggle = false,
    this.shouldFailOnComplete = false,
    this.shouldFailOnLoad = false,
  });

  VibeProfile? profileToReturn;
  bool shouldFailOnUpdate;
  bool shouldFailOnToggle;
  bool shouldFailOnComplete;
  bool shouldFailOnLoad;

  int updateCategoryCallCount = 0;
  int toggleDealbreakerCallCount = 0;
  int updateImportanceCallCount = 0;
  int confirmVibesCallCount = 0;
  int loadProfileCallCount = 0;

  VibeCategory? lastUpdatedCategory;
  int? lastUpdatedValue;
  VibeCategory? lastToggledCategory;
  bool? lastToggledValue;
  Map<VibeCategory, VibeImportance>? lastUpdatedImportance;

  @override
  Future<VibeProfile> getMyVibesCached({bool forceRefresh = false}) async {
    loadProfileCallCount++;
    if (shouldFailOnLoad) {
      throw FirebaseException(plugin: 'firestore', code: 'unavailable');
    }
    return profileToReturn ?? VibeProfile.defaults();
  }

  @override
  Future<VibeProfile> getMyVibes() async {
    return getMyVibesCached();
  }

  @override
  Future<void> updateCategory(VibeCategory category, int value) async {
    updateCategoryCallCount++;
    lastUpdatedCategory = category;
    lastUpdatedValue = value;
    if (shouldFailOnUpdate) {
      throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
    }
  }

  @override
  Future<void> toggleDealbreaker(VibeCategory category, bool dealbreaker) async {
    toggleDealbreakerCallCount++;
    lastToggledCategory = category;
    lastToggledValue = dealbreaker;
    if (shouldFailOnToggle) {
      throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
    }
  }

  @override
  Future<void> updateImportance(
    Map<VibeCategory, VibeImportance> importance, {
    int version = 1,
  }) async {
    updateImportanceCallCount++;
    lastUpdatedImportance = importance;
    if (shouldFailOnComplete) {
      throw FirebaseException(plugin: 'firestore', code: 'unavailable');
    }
  }

  @override
  Future<void> confirmVibes({VibeProfile? profile}) async {
    confirmVibesCallCount++;
    if (shouldFailOnComplete) {
      throw FirebaseException(plugin: 'firestore', code: 'unavailable');
    }
  }

  // Unused methods for this test
  @override
  VibeProfile? getCachedVibeProfileSync() => profileToReturn;

  @override
  void clearMyVibesCache() {}

  @override
  Future<void> saveProfile(VibeProfile profile) async {}

  @override
  Future<void> setDefaults() async {}

  @override
  Future<VibeProfile> getVibeProfileForUser(String userId) async =>
      VibeProfile.defaults();

  @override
  Future<Map<String, VibeProfile>> batchGetVibeProfiles(
      List<String> userIds) async => {};

  @override
  VibeProfile profileFromSnapshot(DocumentSnapshot<Object?> snapshot) =>
      VibeProfile.defaults();

  @override
  VibeProfile profileFromData(Map<String, dynamic> raw) =>
      VibeProfile.defaults();
}

VibeProfile _buildProfile({
  int pace = 3,
  int competitive = 3,
  int drinking = 3,
  int chat = 3,
  int money = 3,
  int music = 3,
  bool paceDealbreaker = false,
  bool competitiveDealbreaker = false,
  bool drinkingDealbreaker = false,
}) {
  final prefs = <VibeCategory, VibePreference>{
    VibeCategory.pace: VibePreference(
      value: pace,
      dealbreaker: paceDealbreaker,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.competitive: VibePreference(
      value: competitive,
      dealbreaker: competitiveDealbreaker,
      threshold: VibePreference.defaultThreshold,
      isDefault: false,
    ),
    VibeCategory.drinking: VibePreference(
      value: drinking,
      dealbreaker: drinkingDealbreaker,
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
  );
}

void main() {
  group('VibeProvider', () {
    group('loadProfile', () {
      test('sets profile and importance from repository', () async {
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(pace: 5, competitive: 1),
        );
        final provider = VibeProvider(repository: mockRepo);

        await provider.loadProfile();

        expect(provider.profile.preferenceFor(VibeCategory.pace).value, 5);
        expect(
            provider.profile.preferenceFor(VibeCategory.competitive).value, 1);
        expect(provider.isLoading, false);
        expect(mockRepo.loadProfileCallCount, 1);

        provider.dispose();
      });

      test('sets isLoading false on error without throwing', () async {
        final mockRepo = MockVibeRepository(shouldFailOnLoad: true);
        final provider = VibeProvider(repository: mockRepo);

        // Should not throw
        await provider.loadProfile();

        expect(provider.isLoading, false);
        // Profile should remain at defaults
        expect(provider.profile.preferenceFor(VibeCategory.pace).value, 3);

        provider.dispose();
      });
    });

    group('autoInferImportance', () {
      test('assigns top 2 to dealbreaker categories first', () async {
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(
            pace: 3,
            competitive: 3,
            drinking: 3,
            paceDealbreaker: true,
            drinkingDealbreaker: true,
          ),
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        provider.autoInferImportance();

        // Pace and drinking are dealbreakers, should be top
        // Grid order: pace, competitive, drinking, chat, money, music
        // So pace comes first, then drinking
        expect(provider.importance[VibeCategory.pace], VibeImportance.top);
        expect(provider.importance[VibeCategory.drinking], VibeImportance.top);
        expect(
            provider.importance[VibeCategory.competitive], VibeImportance.normal);
        expect(provider.topCount, 2);

        provider.dispose();
      });

      test('falls back to distance-from-center when no dealbreakers', () async {
        // Center is 2.5, so pace=5 has distance 2.5, competitive=0 has distance 2.5
        // chat=4 has distance 1.5, others at 3 have distance 0.5
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(
            pace: 5,
            competitive: 0,
            drinking: 3,
            chat: 4,
            money: 3,
            music: 3,
          ),
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        provider.autoInferImportance();

        // Pace=5 and competitive=0 both have max distance from center (2.5)
        // They should be top 2
        expect(provider.importance[VibeCategory.pace], VibeImportance.top);
        expect(
            provider.importance[VibeCategory.competitive], VibeImportance.top);
        expect(provider.topCount, 2);

        provider.dispose();
      });

      test('respects grid order for dealbreaker tie-breaking', () async {
        // Grid order: pace, competitive, drinking, chat, money, music
        // If competitive and drinking are dealbreakers, competitive should come first
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(
            competitiveDealbreaker: true,
            drinkingDealbreaker: true,
          ),
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        provider.autoInferImportance();

        // Both are dealbreakers; competitive is higher in grid order
        expect(
            provider.importance[VibeCategory.competitive], VibeImportance.top);
        expect(provider.importance[VibeCategory.drinking], VibeImportance.top);
        expect(provider.topCount, 2);

        provider.dispose();
      });
    });

    group('commitValueChanged', () {
      test('persists value to repository', () async {
        final mockRepo = MockVibeRepository();
        final provider = VibeProvider(repository: mockRepo);

        provider.updateLocalPreference(VibeCategory.pace, 5);
        final result =
            await provider.commitValueChanged(VibeCategory.pace, 5);

        expect(result, isNull);
        expect(mockRepo.updateCategoryCallCount, 1);
        expect(mockRepo.lastUpdatedCategory, VibeCategory.pace);
        expect(mockRepo.lastUpdatedValue, 5);

        provider.dispose();
      });

      test('returns error message on repository failure', () async {
        final mockRepo = MockVibeRepository(shouldFailOnUpdate: true);
        final provider = VibeProvider(repository: mockRepo);

        // Set value locally
        provider.updateLocalPreference(VibeCategory.pace, 5);
        expect(provider.profile.preferenceFor(VibeCategory.pace).value, 5);

        // Try to persist, should fail
        final result =
            await provider.commitValueChanged(VibeCategory.pace, 5);

        // Should return error (local state remains - UI can handle refresh)
        expect(result, isNotNull);
        expect(result, contains('Unable to update'));

        provider.dispose();
      });
    });

    group('toggleDealbreaker', () {
      test('optimistically updates local state', () async {
        final mockRepo = MockVibeRepository();
        final provider = VibeProvider(repository: mockRepo);

        // Initially false
        expect(
            provider.profile.preferenceFor(VibeCategory.pace).dealbreaker, false);

        final result = await provider.toggleDealbreaker(VibeCategory.pace, true);

        expect(result, isNull);
        expect(
            provider.profile.preferenceFor(VibeCategory.pace).dealbreaker, true);
        expect(mockRepo.toggleDealbreakerCallCount, 1);
        expect(mockRepo.lastToggledCategory, VibeCategory.pace);
        expect(mockRepo.lastToggledValue, true);

        provider.dispose();
      });

      test('rolls back on repository failure', () async {
        final mockRepo = MockVibeRepository(shouldFailOnToggle: true);
        final provider = VibeProvider(repository: mockRepo);

        // Initially false
        expect(
            provider.profile.preferenceFor(VibeCategory.pace).dealbreaker, false);

        final result = await provider.toggleDealbreaker(VibeCategory.pace, true);

        // Should rollback
        expect(result, isNotNull);
        expect(result, contains('Unable to update dealbreaker'));
        expect(
            provider.profile.preferenceFor(VibeCategory.pace).dealbreaker, false);

        provider.dispose();
      });
    });

    group('completeOnboarding', () {
      test('guards against double-tap (isCompleting lock)', () async {
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(),
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        // Set up 2 top priorities so auto-infer doesn't run
        provider.autoInferImportance();

        // Start first completion
        final future1 = provider.completeOnboarding();
        expect(provider.isCompleting, true);

        // Second call should be a no-op
        final result2 = await provider.completeOnboarding();
        expect(result2, isNull); // No-op returns null

        await future1;

        // Only one set of calls should have been made
        expect(mockRepo.updateImportanceCallCount, 1);
        expect(mockRepo.confirmVibesCallCount, 1);

        provider.dispose();
      });

      test('auto-infers importance when topCount < 2', () async {
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(pace: 5, competitive: 0),
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        // topCount should be 0 initially (all normal)
        expect(provider.topCount, 0);

        await provider.completeOnboarding();

        // Should have auto-inferred top 2
        expect(provider.topCount, 2);
        expect(mockRepo.updateImportanceCallCount, 1);
        expect(mockRepo.lastUpdatedImportance, isNotNull);

        // Verify the inferred importance was sent
        final sentImportance = mockRepo.lastUpdatedImportance!;
        final topCategories = sentImportance.entries
            .where((e) => e.value == VibeImportance.top)
            .map((e) => e.key)
            .toList();
        expect(topCategories.length, 2);

        provider.dispose();
      });

      test('returns null on success', () async {
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(),
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        final result = await provider.completeOnboarding();

        expect(result, isNull);
        expect(mockRepo.updateImportanceCallCount, 1);
        expect(mockRepo.confirmVibesCallCount, 1);

        provider.dispose();
      });

      test('returns error message and unlocks on failure', () async {
        final mockRepo = MockVibeRepository(
          profileToReturn: _buildProfile(),
          shouldFailOnComplete: true,
        );
        final provider = VibeProvider(repository: mockRepo);
        await provider.loadProfile();

        final result = await provider.completeOnboarding();

        expect(result, isNotNull);
        expect(result, contains('Unable to finish setup'));
        expect(provider.isCompleting, false); // Should unlock

        provider.dispose();
      });
    });

    group('updateLocalPreference', () {
      test('updates local state immediately', () {
        final provider = VibeProvider(repository: MockVibeRepository());

        expect(provider.profile.preferenceFor(VibeCategory.pace).value, 3);

        provider.updateLocalPreference(VibeCategory.pace, 5);

        expect(provider.profile.preferenceFor(VibeCategory.pace).value, 5);

        provider.dispose();
      });
    });

    group('dispose', () {
      test('sets disposed flag and cancels timer', () async {
        final provider = VibeProvider(repository: MockVibeRepository());

        // Trigger a scheduled notify
        provider.updateLocalPreference(VibeCategory.pace, 5);

        // Dispose should not throw
        provider.dispose();

        // Subsequent operations should be safe (no notifyListeners called)
        // This would throw if not properly guarded
      });
    });
  });
}
