import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/services/vibe_floor_config.dart';

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
  bool _fetchSucceeded = false;
  bool _defaultsSet = false;
  Completer<void>? _initializeCompleter;

  /// Default values for Remote Config keys
  static const Map<String, dynamic> _defaults = {
    'vibe_floor_default': 30,
  };

  /// Set default values (local operation, no network call).
  ///
  /// Safe to call multiple times — idempotent.
  /// Call this before runApp() to ensure safe fallbacks are available immediately.
  Future<void> ensureDefaults() async {
    if (_defaultsSet) return;
    await _remoteConfig.setDefaults(_defaults);
    _defaultsSet = true;
    AppLog.d('📖 RemoteConfigService: Defaults set (vibe_floor=30)');
  }

  /// Wait for Remote Config to be fully initialized (network fetch succeeded).
  ///
  /// Returns true only if fetch succeeded, false on timeout or failure.
  /// If a previous attempt failed, automatically retries.
  /// Use this to implement fail-closed behavior for features that need
  /// the actual remote config value (not just defaults).
  Future<bool> waitUntilReady({
    Duration timeout = const Duration(milliseconds: 1200),
  }) async {
    // Fast path: already successfully fetched
    if (_initialized && _fetchSucceeded) return true;

    // Retry if previous attempt failed
    if (_initialized && !_fetchSucceeded) {
      AppLog.d('📖 RemoteConfigService: Previous fetch failed, retrying...');
      _initialized = false; // Reset to allow retry
    }

    // Start initialization if not in progress
    if (_initializeCompleter == null || _initializeCompleter!.isCompleted) {
      // Don't await - just kick it off
      unawaited(initialize());
    }

    // Wait for completion with timeout
    try {
      await _initializeCompleter!.future.timeout(timeout);
      return _fetchSucceeded; // Return actual fetch status
    } on TimeoutException {
      AppLog.d(
        '⚠️ RemoteConfigService: waitUntilReady timed out after '
        '${timeout.inMilliseconds}ms',
      );
      return false;
    }
  }

  /// Initialize Remote Config with network fetch.
  ///
  /// Idempotent and concurrent-safe via memoized completer.
  /// Call after first frame for non-blocking network operations.
  /// Initialization failure will not crash the app - defaults will be used.
  /// Allows retry after failure (only returns early if already succeeded).
  Future<void> initialize() async {
    // Allow retry if previous fetch failed
    if (_initialized && _fetchSucceeded) {
      return; // Already successfully initialized
    }

    // Concurrent-safe: share one in-flight initialization
    if (_initializeCompleter != null && !_initializeCompleter!.isCompleted) {
      return _initializeCompleter!.future;
    }

    // Reset for retry attempt
    _initializeCompleter = Completer<void>();
    _fetchSucceeded = false;

    try {
      // Ensure defaults are set (idempotent)
      await ensureDefaults();

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 12),
      ));

      final activated = await _remoteConfig.fetchAndActivate();
      _fetchSucceeded = true; // Only set on success
      AppLog.d(
        '📖 RemoteConfigService: Initialized (activated: $activated, '
        'vibe_floor=${_remoteConfig.getInt('vibe_floor_default')})',
      );
    } catch (e) {
      // _fetchSucceeded stays false
      AppLog.d('❌ RemoteConfigService: Initialization failed, using defaults. $e');
    } finally {
      // ALWAYS complete the completer to prevent hanging callers
      _initialized = true;
      if (!_initializeCompleter!.isCompleted) {
        _initializeCompleter!.complete();
      }
    }
  }

  /// Whether the service has been initialized (network fetch attempted)
  bool get isInitialized => _initialized;

  /// Whether the remote fetch actually succeeded (vs just attempted)
  bool get isFetchSucceeded => _fetchSucceeded;

  /// Whether defaults have been set (safe to read values)
  bool get hasDefaults => _defaultsSet;

  /// Get the current vibe floor threshold (0-100)
  ///
  /// Returns the configured value from Remote Config, or the hardcoded default (30)
  /// if defaults haven't been set yet. Clamps to valid range defensively.
  int getVibeFloor() {
    final value = _remoteConfig.getInt('vibe_floor_default');

    // Defensive: if defaults not set and SDK returned 0, use hardcoded fallback
    if (!_defaultsSet && value == 0) {
      AppLog.d(
        '⚠️ RemoteConfigService: getVibeFloor called before defaults set, '
        'returning fallback ${VibeFloorConfig.defaultFloor}',
      );
      return VibeFloorConfig.defaultFloor;
    }

    // Clamp to valid range defensively
    return value.clamp(0, 100);
  }
}
