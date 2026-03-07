import 'package:geolocator/geolocator.dart';

/// Service for device GPS operations.
/// Injected into GeoFilterProvider for testability.
class GeoLocationService {
  /// Check current location permission status.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Request location permission from user.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Get current device position.
  /// Uses low accuracy (sufficient for radius queries, faster, less battery).
  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    );
  }
}
