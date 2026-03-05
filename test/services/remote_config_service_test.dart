import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/services/remote_config_service.dart';
import 'package:find_my_fourth/services/vibe_floor_config.dart';

/// A fake FirebaseRemoteConfig for testing
class FakeFirebaseRemoteConfig implements FirebaseRemoteConfig {
  final Map<String, dynamic> _values = {};
  final Map<String, dynamic> _defaults = {};
  bool setDefaultsCalled = false;
  bool setConfigSettingsCalled = false;
  bool fetchAndActivateCalled = false;
  int setDefaultsCallCount = 0;

  /// Simulated delay for fetchAndActivate (for testing timeouts)
  Duration fetchDelay = Duration.zero;

  /// If set, fetchAndActivate will throw this exception
  Exception? fetchException;

  /// Set a value to be returned by getInt
  void setValue(String key, dynamic value) {
    _values[key] = value;
  }

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    setDefaultsCalled = true;
    setDefaultsCallCount++;
    _defaults.addAll(defaults);
    // Apply defaults to values if not already set
    for (final entry in defaults.entries) {
      _values.putIfAbsent(entry.key, () => entry.value);
    }
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings remoteConfigSettings) async {
    setConfigSettingsCalled = true;
  }

  @override
  Future<bool> fetchAndActivate() async {
    if (fetchDelay > Duration.zero) {
      await Future.delayed(fetchDelay);
    }
    if (fetchException != null) {
      throw fetchException!;
    }
    fetchAndActivateCalled = true;
    return true;
  }

  @override
  int getInt(String key) {
    final value = _values[key];
    if (value is int) return value;
    return 0; // Firebase SDK default for unset int keys
  }

  // Required overrides - not used in our tests
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('RemoteConfigService', () {
    late FakeFirebaseRemoteConfig fakeRemoteConfig;

    setUp(() {
      fakeRemoteConfig = FakeFirebaseRemoteConfig();
      RemoteConfigService.resetForTesting(remoteConfig: fakeRemoteConfig);
    });

    group('ensureDefaults', () {
      test('sets defaults on first call', () async {
        await RemoteConfigService.instance.ensureDefaults();

        expect(fakeRemoteConfig.setDefaultsCalled, isTrue);
        expect(fakeRemoteConfig.setDefaultsCallCount, 1);
      });

      test('is idempotent - multiple calls only set defaults once', () async {
        await RemoteConfigService.instance.ensureDefaults();
        await RemoteConfigService.instance.ensureDefaults();
        await RemoteConfigService.instance.ensureDefaults();

        expect(fakeRemoteConfig.setDefaultsCallCount, 1);
      });

      test('sets vibe_floor_default to 30', () async {
        await RemoteConfigService.instance.ensureDefaults();

        expect(fakeRemoteConfig.getInt('vibe_floor_default'), 30);
      });
    });

    group('getVibeFloor', () {
      test('returns 30 after ensureDefaults is called', () async {
        await RemoteConfigService.instance.ensureDefaults();

        expect(RemoteConfigService.instance.getVibeFloor(), 30);
      });

      test('returns fallback 30 before ensureDefaults when SDK returns 0', () {
        // Before ensureDefaults, SDK returns 0 for unset keys
        // Our defensive fallback should return 30
        final floor = RemoteConfigService.instance.getVibeFloor();

        expect(floor, VibeFloorConfig.defaultFloor);
        expect(floor, 30);
      });

      test('clamps value to 0-100 range', () async {
        await RemoteConfigService.instance.ensureDefaults();

        // Simulate remote config returning out-of-range value
        fakeRemoteConfig.setValue('vibe_floor_default', 150);
        expect(RemoteConfigService.instance.getVibeFloor(), 100);

        fakeRemoteConfig.setValue('vibe_floor_default', -10);
        expect(RemoteConfigService.instance.getVibeFloor(), 0);
      });

      test('returns configured remote value within range', () async {
        await RemoteConfigService.instance.ensureDefaults();

        fakeRemoteConfig.setValue('vibe_floor_default', 50);
        expect(RemoteConfigService.instance.getVibeFloor(), 50);

        fakeRemoteConfig.setValue('vibe_floor_default', 0);
        expect(RemoteConfigService.instance.getVibeFloor(), 0);

        fakeRemoteConfig.setValue('vibe_floor_default', 100);
        expect(RemoteConfigService.instance.getVibeFloor(), 100);
      });
    });

    group('initialize', () {
      test('is idempotent - multiple calls only initialize once', () async {
        await RemoteConfigService.instance.initialize();
        await RemoteConfigService.instance.initialize();
        await RemoteConfigService.instance.initialize();

        // setDefaults is called once (via ensureDefaults)
        expect(fakeRemoteConfig.setDefaultsCallCount, 1);
        // fetchAndActivate is called once
        expect(fakeRemoteConfig.fetchAndActivateCalled, isTrue);
      });

      test('sets isInitialized to true after completion', () async {
        expect(RemoteConfigService.instance.isInitialized, isFalse);

        await RemoteConfigService.instance.initialize();

        expect(RemoteConfigService.instance.isInitialized, isTrue);
      });

      test('sets hasDefaults to true after completion', () async {
        expect(RemoteConfigService.instance.hasDefaults, isFalse);

        await RemoteConfigService.instance.initialize();

        expect(RemoteConfigService.instance.hasDefaults, isTrue);
      });

      test('concurrent calls share one initialization', () async {
        // Start multiple initializations concurrently
        final futures = <Future<void>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(RemoteConfigService.instance.initialize());
        }

        await Future.wait(futures);

        // Should only call setDefaults and fetchAndActivate once
        expect(fakeRemoteConfig.setDefaultsCallCount, 1);
        expect(fakeRemoteConfig.fetchAndActivateCalled, isTrue);
      });
    });

    group('hasDefaults', () {
      test('is false initially', () {
        expect(RemoteConfigService.instance.hasDefaults, isFalse);
      });

      test('is true after ensureDefaults', () async {
        await RemoteConfigService.instance.ensureDefaults();

        expect(RemoteConfigService.instance.hasDefaults, isTrue);
      });
    });

    group('waitUntilReady', () {
      test('returns true immediately if already initialized', () async {
        await RemoteConfigService.instance.initialize();

        final ready = await RemoteConfigService.instance.waitUntilReady();

        expect(ready, isTrue);
      });

      test('returns true when initialization completes within timeout', () async {
        // Small delay but within default 1200ms timeout
        fakeRemoteConfig.fetchDelay = const Duration(milliseconds: 100);

        final ready = await RemoteConfigService.instance.waitUntilReady();

        expect(ready, isTrue);
        expect(RemoteConfigService.instance.isInitialized, isTrue);
      });

      test('returns false on timeout', () async {
        // Delay longer than timeout
        fakeRemoteConfig.fetchDelay = const Duration(milliseconds: 500);

        final ready = await RemoteConfigService.instance.waitUntilReady(
          timeout: const Duration(milliseconds: 50),
        );

        expect(ready, isFalse);
      });

      test('kicks off initialization if not started', () async {
        expect(RemoteConfigService.instance.isInitialized, isFalse);

        // Small delay to ensure we complete
        fakeRemoteConfig.fetchDelay = const Duration(milliseconds: 10);

        final ready = await RemoteConfigService.instance.waitUntilReady();

        expect(ready, isTrue);
        expect(fakeRemoteConfig.fetchAndActivateCalled, isTrue);
      });
    });

    group('initialize exception handling', () {
      test('completes completer even on non-FirebaseException', () async {
        fakeRemoteConfig.fetchException = Exception('Platform error');

        // Should not throw - just log and continue
        await RemoteConfigService.instance.initialize();

        expect(RemoteConfigService.instance.isInitialized, isTrue);
      });

      test('completer is not left hanging on exception', () async {
        fakeRemoteConfig.fetchException = Exception('Platform error');

        await RemoteConfigService.instance.initialize();

        // Completer completes but fetch failed
        expect(RemoteConfigService.instance.isInitialized, isTrue);
        expect(RemoteConfigService.instance.isFetchSucceeded, isFalse);
      });

      test('isFetchSucceeded is false after exception', () async {
        fakeRemoteConfig.fetchException = Exception('Platform error');

        await RemoteConfigService.instance.initialize();

        expect(RemoteConfigService.instance.isFetchSucceeded, isFalse);
      });

      test('isFetchSucceeded is true after successful fetch', () async {
        await RemoteConfigService.instance.initialize();

        expect(RemoteConfigService.instance.isFetchSucceeded, isTrue);
      });

      test('waitUntilReady returns false after fetch exception', () async {
        fakeRemoteConfig.fetchException = Exception('Platform error');

        await RemoteConfigService.instance.initialize();

        final ready = await RemoteConfigService.instance.waitUntilReady();
        expect(ready, isFalse); // Strict contract: false when fetch failed
      });

      test('retry succeeds after initial failure', () async {
        // First attempt fails
        fakeRemoteConfig.fetchException = Exception('Network error');
        await RemoteConfigService.instance.initialize();
        expect(RemoteConfigService.instance.isFetchSucceeded, isFalse);

        // Clear exception for retry
        fakeRemoteConfig.fetchException = null;

        // Retry via waitUntilReady
        final ready = await RemoteConfigService.instance.waitUntilReady();
        expect(ready, isTrue);
        expect(RemoteConfigService.instance.isFetchSucceeded, isTrue);
      });

      test('waitUntilReady returns true only after successful fetch', () async {
        await RemoteConfigService.instance.initialize();

        final ready = await RemoteConfigService.instance.waitUntilReady();
        expect(ready, isTrue);
        expect(RemoteConfigService.instance.isFetchSucceeded, isTrue);
      });
    });
  });

  group('VibeFloorConfig.defaultFloor', () {
    test('constant is 30', () {
      expect(VibeFloorConfig.defaultFloor, 30);
    });
  });
}
