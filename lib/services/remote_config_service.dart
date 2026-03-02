import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';

/// Service for Firebase Remote Config integration
///
/// Provides dynamic configuration values with fallback defaults.
/// Uses a singleton pattern since Remote Config should be initialized once
/// and read from anywhere in the app.
class RemoteConfigService {
  RemoteConfigService._internal({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static RemoteConfigService? _instance;

  /// Get the singleton instance
  ///
  /// Optionally pass a custom FirebaseRemoteConfig for testing.
  static RemoteConfigService get instance {
    _instance ??= RemoteConfigService._internal();
    return _instance!;
  }

  /// Reset the singleton (for testing only)
  @visibleForTesting
  static void resetForTesting({FirebaseRemoteConfig? remoteConfig}) {
    _instance = RemoteConfigService._internal(remoteConfig: remoteConfig);
  }

  final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Default values for Remote Config keys
  static const Map<String, dynamic> _defaults = {
    'vibe_floor_default': 30,
  };

  /// Initialize Remote Config with defaults
  ///
  /// Call once at app startup (non-blocking after first frame).
  /// Initialization failure will not crash the app - defaults will be used.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await _remoteConfig.setDefaults(_defaults);

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 12),
      ));

      final activated = await _remoteConfig.fetchAndActivate();
      AppLog.d(
        '📖 RemoteConfigService: Initialized (activated: $activated, '
        'vibe_floor=${_remoteConfig.getInt('vibe_floor_default')})',
      );
    } on FirebaseException catch (e) {
      AppLog.d('❌ RemoteConfigService: Initialization failed, using defaults. '
          '${e.code} - ${e.message}');
    }

    _initialized = true;
  }

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// Get the current vibe floor threshold (0-100)
  ///
  /// Returns the configured value from Remote Config, or the default (30)
  /// if Remote Config hasn't been fetched or the key doesn't exist.
  int getVibeFloor() {
    return _remoteConfig.getInt('vibe_floor_default');
  }
}
