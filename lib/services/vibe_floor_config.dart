import '/services/remote_config_service.dart';

/// Configuration for the vibe floor feature
///
/// The vibe floor is the minimum compatibility score (0-100) a player
/// must have with the game owner to auto-join. Players below this threshold
/// must request approval from the owner.
class VibeFloorConfig {
  /// Default vibe floor threshold (30% compatibility)
  static const int defaultFloor = 30;

  /// Cooldown period between vibe profile edits (30 days)
  static const int vibeEditCooldownDays = 30;

  /// Get the current vibe floor threshold
  ///
  /// Returns the configured floor value from Remote Config if available,
  /// otherwise falls back to the hardcoded default.
  Future<int> getVibeFloor() async {
    // Use Remote Config singleton - it will return defaults if not initialized
    return RemoteConfigService.instance.getVibeFloor();
  }
}
