import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:find_my_fourth/providers/geo_filter_provider.dart';
import 'package:find_my_fourth/services/geo_location_service.dart';

/// Mock GeoLocationService for testing GeoFilterProvider in isolation.
class MockGeoLocationService implements GeoLocationService {
  MockGeoLocationService({
    this.permissionToReturn = LocationPermission.always,
    this.positionToReturn,
    this.shouldFailOnGetPosition = false,
  });

  LocationPermission permissionToReturn;
  Position? positionToReturn;
  bool shouldFailOnGetPosition;

  int checkPermissionCallCount = 0;
  int requestPermissionCallCount = 0;
  int getPositionCallCount = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCallCount++;
    return permissionToReturn;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCallCount++;
    return permissionToReturn;
  }

  @override
  Future<Position> getCurrentPosition() async {
    getPositionCallCount++;
    if (shouldFailOnGetPosition) {
      throw Exception('Location services disabled');
    }
    return positionToReturn ??
        Position(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
  }
}

void main() {
  group('GeoFilterProvider', () {
    late GeoFilterProvider provider;
    late MockGeoLocationService mockService;
    bool skipTearDownDispose = false;

    setUp(() {
      mockService = MockGeoLocationService();
      provider = GeoFilterProvider(service: mockService);
      skipTearDownDispose = false;
    });

    tearDown(() {
      if (!skipTearDownDispose) {
        provider.dispose();
      }
    });

    group('initial state', () {
      test('starts with filter disabled', () {
        expect(provider.isEnabled, isFalse);
      });

      test('starts with default radius of 40 km', () {
        expect(provider.radiusKm, equals(40.0));
      });

      test('starts with home course as default source', () {
        expect(provider.source, equals(GeoLocationSource.homeCourse));
      });

      test('has no location initially', () {
        expect(provider.hasLocation, isFalse);
        expect(provider.lat, isNull);
        expect(provider.lng, isNull);
      });

      test('has no stored locations initially', () {
        expect(provider.hasHomeCourseLocation, isFalse);
        expect(provider.hasHometownLocation, isFalse);
        expect(provider.hasAnyStoredLocation, isFalse);
      });

      test('is not loading location initially', () {
        expect(provider.isLoadingLocation, isFalse);
      });

      test('has no location error initially', () {
        expect(provider.locationError, isNull);
      });
    });

    group('setEnabled', () {
      test('sets enabled state to true', () {
        provider.setEnabled(true);
        expect(provider.isEnabled, isTrue);
      });

      test('sets enabled state to false', () {
        provider.setEnabled(true);
        provider.setEnabled(false);
        expect(provider.isEnabled, isFalse);
      });

      test('no-op when setting same value (setter guard)', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setEnabled(false); // Already false
        // Allow debounced notify to fire
        expect(provider.isEnabled, isFalse);
        // Should not have scheduled a notify since value unchanged
      });
    });

    group('toggleEnabled', () {
      test('toggles from false to true', () {
        expect(provider.isEnabled, isFalse);
        provider.toggleEnabled();
        expect(provider.isEnabled, isTrue);
      });

      test('toggles from true to false', () {
        provider.setEnabled(true);
        provider.toggleEnabled();
        expect(provider.isEnabled, isFalse);
      });
    });

    group('initFromUserProfile', () {
      test('sets all values correctly', () {
        provider.initFromUserProfile(
          nearMeEnabled: true,
          locationSource: 'hometown',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: 34.0522,
          hometownLng: -118.2437,
          searchRadiusKm: 10.0,
        );

        expect(provider.isEnabled, isTrue);
        expect(provider.source, equals(GeoLocationSource.hometown));
        expect(provider.radiusKm, equals(10.0));
        expect(provider.hasHomeCourseLocation, isTrue);
        expect(provider.hasHometownLocation, isTrue);
        // Since source is hometown, lat/lng should be hometown
        expect(provider.lat, equals(34.0522));
        expect(provider.lng, equals(-118.2437));
      });

      test('resolves lat/lng from home course when source is home_course', () {
        provider.initFromUserProfile(
          nearMeEnabled: false,
          locationSource: 'home_course',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: 34.0522,
          hometownLng: -118.2437,
          searchRadiusKm: 25.0,
        );

        expect(provider.source, equals(GeoLocationSource.homeCourse));
        expect(provider.lat, equals(37.7749));
        expect(provider.lng, equals(-122.4194));
      });

      test('handles null location source (defaults to home course)', () {
        provider.initFromUserProfile(
          nearMeEnabled: false,
          locationSource: null,
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: null,
          hometownLng: null,
          searchRadiusKm: 25.0,
        );

        expect(provider.source, equals(GeoLocationSource.homeCourse));
      });

      test('handles phone_gps source string', () {
        provider.initFromUserProfile(
          nearMeEnabled: false,
          locationSource: 'phone_gps',
          homeCourseLat: null,
          homeCourseLng: null,
          hometownLat: null,
          hometownLng: null,
          searchRadiusKm: 25.0,
        );

        expect(provider.source, equals(GeoLocationSource.phoneGps));
        // GPS location not fetched during init (would be fetched on demand)
        expect(provider.lat, isNull);
        expect(provider.lng, isNull);
      });
    });

    group('setSource', () {
      setUp(() {
        // Initialize with both locations
        provider.initFromUserProfile(
          nearMeEnabled: true,
          locationSource: 'home_course',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: 34.0522,
          hometownLng: -118.2437,
          searchRadiusKm: 25.0,
        );
      });

      test('switches to hometown and updates lat/lng', () async {
        await provider.setSource(GeoLocationSource.hometown);

        expect(provider.source, equals(GeoLocationSource.hometown));
        expect(provider.lat, equals(34.0522));
        expect(provider.lng, equals(-118.2437));
      });

      test('switches to home course and updates lat/lng', () async {
        await provider.setSource(GeoLocationSource.hometown);
        await provider.setSource(GeoLocationSource.homeCourse);

        expect(provider.source, equals(GeoLocationSource.homeCourse));
        expect(provider.lat, equals(37.7749));
        expect(provider.lng, equals(-122.4194));
      });

      test('no-op when setting same source', () async {
        final initialLat = provider.lat;
        await provider.setSource(GeoLocationSource.homeCourse);
        expect(provider.lat, equals(initialLat));
      });

      test('clears location error when switching source', () async {
        // Simulate a GPS error first
        mockService.permissionToReturn = LocationPermission.denied;
        await provider.setSource(GeoLocationSource.phoneGps);
        expect(provider.locationError, isNotNull);

        // Switch to hometown - should clear error
        await provider.setSource(GeoLocationSource.hometown);
        expect(provider.locationError, isNull);
      });
    });

    group('switchToCurrentLocation (GPS)', () {
      test('requests permission and gets position on success', () async {
        mockService.permissionToReturn = LocationPermission.always;
        mockService.positionToReturn = Position(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        final result = await provider.switchToCurrentLocation();

        expect(result, isTrue);
        expect(provider.source, equals(GeoLocationSource.phoneGps));
        expect(provider.lat, equals(40.7128));
        expect(provider.lng, equals(-74.0060));
        expect(provider.isLoadingLocation, isFalse);
        expect(provider.locationError, isNull);
      });

      test('handles permission denied', () async {
        mockService.permissionToReturn = LocationPermission.denied;

        final result = await provider.switchToCurrentLocation();

        expect(result, isFalse);
        expect(provider.source, isNot(equals(GeoLocationSource.phoneGps)));
        expect(provider.locationError, equals('Location permission denied.'));
        expect(provider.isLoadingLocation, isFalse);
      });

      test('handles permission denied forever', () async {
        mockService.permissionToReturn = LocationPermission.deniedForever;

        final result = await provider.switchToCurrentLocation();

        expect(result, isFalse);
        expect(provider.locationError,
            equals('Location access denied. Enable in Settings.'));
      });

      test('handles location service error', () async {
        mockService.permissionToReturn = LocationPermission.always;
        mockService.shouldFailOnGetPosition = true;

        final result = await provider.switchToCurrentLocation();

        expect(result, isFalse);
        expect(provider.locationError, equals('Could not get your location.'));
        expect(provider.isLoadingLocation, isFalse);
      });

      test('reverts to stored location on GPS failure', () async {
        // Initialize with home course
        provider.initFromUserProfile(
          nearMeEnabled: true,
          locationSource: 'home_course',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: null,
          hometownLng: null,
          searchRadiusKm: 25.0,
        );

        mockService.permissionToReturn = LocationPermission.denied;
        await provider.switchToCurrentLocation();

        // Should revert to home course location
        expect(provider.lat, equals(37.7749));
        expect(provider.lng, equals(-122.4194));
      });
    });

    group('switchToHomeCourse / switchToHometown', () {
      setUp(() {
        provider.initFromUserProfile(
          nearMeEnabled: true,
          locationSource: 'phone_gps',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: 34.0522,
          hometownLng: -118.2437,
          searchRadiusKm: 25.0,
        );
      });

      test('switchToHomeCourse updates source and coordinates', () {
        provider.switchToHomeCourse();

        expect(provider.source, equals(GeoLocationSource.homeCourse));
        expect(provider.lat, equals(37.7749));
        expect(provider.lng, equals(-122.4194));
        expect(provider.locationError, isNull);
      });

      test('switchToHometown updates source and coordinates', () {
        provider.switchToHometown();

        expect(provider.source, equals(GeoLocationSource.hometown));
        expect(provider.lat, equals(34.0522));
        expect(provider.lng, equals(-118.2437));
        expect(provider.locationError, isNull);
      });
    });

    group('setRadius', () {
      test('updates radius immediately', () {
        provider.setRadius(10.0);
        expect(provider.radiusKm, equals(10.0));
      });

      test('calls onPersist callback after debounce', () async {
        var persistCalled = false;

        provider.setRadius(15.0, onPersist: () {
          persistCalled = true;
        });

        // Should not be called immediately
        expect(persistCalled, isFalse);

        // Wait for debounce (500ms + buffer)
        await Future.delayed(const Duration(milliseconds: 600));
        expect(persistCalled, isTrue);
      });

      test('debounces rapid radius changes', () async {
        var persistCount = 0;

        provider.setRadius(10.0, onPersist: () => persistCount++);
        provider.setRadius(15.0, onPersist: () => persistCount++);
        provider.setRadius(20.0, onPersist: () => persistCount++);

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));

        // Should only call persist once (the last one)
        expect(persistCount, equals(1));
        expect(provider.radiusKm, equals(20.0));
      });
    });

    group('computed properties', () {
      test('isCurrentLocation returns true only for phoneGps source', () {
        provider.initFromUserProfile(
          nearMeEnabled: false,
          locationSource: 'phone_gps',
          homeCourseLat: null,
          homeCourseLng: null,
          hometownLat: null,
          hometownLng: null,
          searchRadiusKm: 25.0,
        );

        expect(provider.isCurrentLocation, isTrue);

        provider.switchToHomeCourse();
        expect(provider.isCurrentLocation, isFalse);
      });

      test('hasLocation returns true when both lat and lng are set', () {
        expect(provider.hasLocation, isFalse);

        provider.initFromUserProfile(
          nearMeEnabled: false,
          locationSource: 'home_course',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: null,
          hometownLng: null,
          searchRadiusKm: 25.0,
        );

        expect(provider.hasLocation, isTrue);
      });

      test('hasAnyStoredLocation returns true when either location exists', () {
        provider.initFromUserProfile(
          nearMeEnabled: false,
          locationSource: 'home_course',
          homeCourseLat: 37.7749,
          homeCourseLng: -122.4194,
          hometownLat: null,
          hometownLng: null,
          searchRadiusKm: 25.0,
        );

        expect(provider.hasAnyStoredLocation, isTrue);
        expect(provider.hasHomeCourseLocation, isTrue);
        expect(provider.hasHometownLocation, isFalse);
      });
    });

    group('dispose', () {
      test('cancels pending notify timer', () async {
        skipTearDownDispose = true;
        provider.setEnabled(true);
        provider.dispose();

        // Should not throw after dispose
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('cancels pending radius persist timer', () async {
        skipTearDownDispose = true;
        var persistCalled = false;

        provider.setRadius(10.0, onPersist: () {
          persistCalled = true;
        });

        provider.dispose();

        // Wait for debounce period
        await Future.delayed(const Duration(milliseconds: 600));

        // Persist should NOT have been called since disposed
        expect(persistCalled, isFalse);
      });
    });
  });
}
