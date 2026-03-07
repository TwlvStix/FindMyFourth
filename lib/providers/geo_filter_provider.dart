import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '/core/utils/app_log.dart';
import '/services/geo_location_service.dart';

/// Source for geo-filter center point.
enum GeoLocationSource { homeCourse, hometown, phoneGps }

class GeoFilterProvider extends ChangeNotifier {
  GeoFilterProvider({GeoLocationService? service})
      : _service = service ?? GeoLocationService();

  final GeoLocationService _service;

  // Dispose safety
  bool _disposed = false;
  Timer? _notifyTimer;

  // State
  bool _isEnabled = false;
  GeoLocationSource _source = GeoLocationSource.homeCourse;
  double? _lat;
  double? _lng;
  double _radiusKm = 40.0;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Stored coordinates for each source
  double? _homeCourseLat;
  double? _homeCourseLng;
  double? _hometownLat;
  double? _hometownLng;

  // Getters
  bool get isEnabled => _isEnabled;
  GeoLocationSource get source => _source;
  double? get lat => _lat;
  double? get lng => _lng;
  double get radiusKm => _radiusKm;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  bool get isCurrentLocation => _source == GeoLocationSource.phoneGps;
  bool get hasLocation => _lat != null && _lng != null;
  bool get hasHomeCourseLocation =>
      _homeCourseLat != null && _homeCourseLng != null;
  bool get hasHometownLocation => _hometownLat != null && _hometownLng != null;
  bool get hasAnyStoredLocation => hasHomeCourseLocation || hasHometownLocation;

  void _scheduleNotify() {
    if (_disposed) return;
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) notifyListeners();
    });
  }

  /// Toggle the geo filter on/off.
  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    _scheduleNotify();
    AppLog.d('📍 GeoFilter: toggled to $_isEnabled');
  }

  /// Set the geo filter enabled state.
  void setEnabled(bool value) {
    if (_isEnabled == value) return;
    _isEnabled = value;
    _scheduleNotify();
    AppLog.d('📍 GeoFilter: set enabled to $_isEnabled');
  }

  /// Set the location source and update lat/lng accordingly.
  Future<void> setSource(GeoLocationSource newSource) async {
    if (_source == newSource) return;

    _source = newSource;
    _locationError = null;

    switch (newSource) {
      case GeoLocationSource.homeCourse:
        _lat = _homeCourseLat;
        _lng = _homeCourseLng;
        AppLog.d('🏠 GeoFilter: switched to home course');
        _scheduleNotify();
        break;
      case GeoLocationSource.hometown:
        _lat = _hometownLat;
        _lng = _hometownLng;
        AppLog.d('🏘️ GeoFilter: switched to hometown');
        _scheduleNotify();
        break;
      case GeoLocationSource.phoneGps:
        // Will trigger GPS permission/fetch
        await switchToCurrentLocation();
        break;
    }
  }

  /// Parse source string from Firestore to enum.
  GeoLocationSource _parseSource(String? sourceStr) {
    switch (sourceStr) {
      case 'hometown':
        return GeoLocationSource.hometown;
      case 'phone_gps':
        return GeoLocationSource.phoneGps;
      case 'home_course':
      default:
        return GeoLocationSource.homeCourse;
    }
  }

  /// Resolve lat/lng based on current source.
  void _resolveLatLngFromSource() {
    switch (_source) {
      case GeoLocationSource.homeCourse:
        _lat = _homeCourseLat;
        _lng = _homeCourseLng;
        break;
      case GeoLocationSource.hometown:
        _lat = _hometownLat;
        _lng = _hometownLng;
        break;
      case GeoLocationSource.phoneGps:
        // Will be fetched when needed
        break;
    }
  }

  /// Initialize from user profile including enabled state and source.
  void initFromUserProfile({
    required bool nearMeEnabled,
    required String? locationSource,
    required double? homeCourseLat,
    required double? homeCourseLng,
    required double? hometownLat,
    required double? hometownLng,
    required double searchRadiusKm,
  }) {
    _isEnabled = nearMeEnabled;
    _homeCourseLat = homeCourseLat;
    _homeCourseLng = homeCourseLng;
    _hometownLat = hometownLat;
    _hometownLng = hometownLng;
    _radiusKm = searchRadiusKm;

    // Set source and resolve lat/lng
    _source = _parseSource(locationSource);
    _resolveLatLngFromSource();

    AppLog.d('📍 GeoFilter: initialized - enabled=$_isEnabled, '
        'source=$_source, radius=$_radiusKm');
    _scheduleNotify();
  }

  /// Switch to device GPS location. Returns false if permission denied.
  Future<bool> switchToCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    _scheduleNotify();

    try {
      var permission = await _service.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await _service.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _isLoadingLocation = false;
        _locationError = permission == LocationPermission.deniedForever
            ? 'Location access denied. Enable in Settings.'
            : 'Location permission denied.';
        // Revert to previous source if GPS fails
        _resolveLatLngFromSource();
        _scheduleNotify();
        return false;
      }

      final pos = await _service.getCurrentPosition();
      _source = GeoLocationSource.phoneGps;
      _lat = pos.latitude;
      _lng = pos.longitude;
      _isLoadingLocation = false;
      _scheduleNotify();
      AppLog.d('📍 GeoFilter: switched to phone GPS');
      return true;
    } catch (e) {
      _isLoadingLocation = false;
      _locationError = 'Could not get your location.';
      // Revert to previous source if GPS fails
      _resolveLatLngFromSource();
      _scheduleNotify();
      AppLog.d('❌ GeoFilter: location error $e');
      return false;
    }
  }

  /// Revert to home course center.
  void switchToHomeCourse() {
    _source = GeoLocationSource.homeCourse;
    _lat = _homeCourseLat;
    _lng = _homeCourseLng;
    _locationError = null;
    _scheduleNotify();
    AppLog.d('🏠 GeoFilter: switched to home course');
  }

  /// Switch to hometown center.
  void switchToHometown() {
    _source = GeoLocationSource.hometown;
    _lat = _hometownLat;
    _lng = _hometownLng;
    _locationError = null;
    _scheduleNotify();
    AppLog.d('🏘️ GeoFilter: switched to hometown');
  }

  // Debounce for radius persistence
  Timer? _radiusPersistTimer;
  VoidCallback? _onRadiusPersist;

  /// Update search radius with debounced persistence.
  void setRadius(double km, {VoidCallback? onPersist}) {
    _radiusKm = km;
    _onRadiusPersist = onPersist;
    _scheduleNotify();

    // Debounce Firestore write by 500ms
    _radiusPersistTimer?.cancel();
    if (onPersist != null) {
      _radiusPersistTimer = Timer(const Duration(milliseconds: 500), () {
        _onRadiusPersist?.call();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _radiusPersistTimer?.cancel();
    super.dispose();
  }
}
