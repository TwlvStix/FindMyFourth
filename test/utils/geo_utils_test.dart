import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/utils/geo_utils.dart';

void main() {
  group('Haversine distance calculations', () {
    test('distanceKm returns 0 for identical points', () {
      final distance = distanceKm(40.7128, -74.0060, 40.7128, -74.0060);
      expect(distance, equals(0.0));
    });

    test('distanceMiles returns 0 for identical points', () {
      final distance = distanceMiles(40.7128, -74.0060, 40.7128, -74.0060);
      expect(distance, equals(0.0));
    });

    test('calculates distance between NYC and LA correctly', () {
      // New York City: 40.7128° N, 74.0060° W
      // Los Angeles: 34.0522° N, 118.2437° W
      // Known distance: ~3,944 km / ~2,451 miles
      final km = distanceKm(40.7128, -74.0060, 34.0522, -118.2437);
      final miles = distanceMiles(40.7128, -74.0060, 34.0522, -118.2437);

      // Allow 1% tolerance for rounding
      expect(km, closeTo(3944, 50));
      expect(miles, closeTo(2451, 30));
    });

    test('calculates short distance accurately (SF to Oakland)', () {
      // San Francisco: 37.7749° N, 122.4194° W
      // Oakland: 37.8044° N, 122.2712° W
      // Known distance: ~13 km / ~8 miles
      final km = distanceKm(37.7749, -122.4194, 37.8044, -122.2712);
      final miles = distanceMiles(37.7749, -122.4194, 37.8044, -122.2712);

      expect(km, closeTo(13, 2));
      expect(miles, closeTo(8, 1.5));
    });

    test('calculates distance across equator', () {
      // Quito, Ecuador: 0.1807° S, 78.4678° W
      // Bogota, Colombia: 4.7110° N, 74.0721° W
      // Known distance: ~730 km (varies by coordinate precision)
      final km = distanceKm(-0.1807, -78.4678, 4.7110, -74.0721);

      expect(km, closeTo(730, 30));
    });

    test('calculates distance across international date line', () {
      // Fiji: 17.7134° S, 178.0650° E
      // Samoa: 13.7590° S, 172.1046° W
      // Known distance: ~1,100 km
      final km = distanceKm(-17.7134, 178.0650, -13.7590, -172.1046);

      expect(km, closeTo(1100, 50));
    });

    test('miles to km conversion is consistent', () {
      const kmToMiles = 0.621371;
      final km = distanceKm(40.7128, -74.0060, 34.0522, -118.2437);
      final miles = distanceMiles(40.7128, -74.0060, 34.0522, -118.2437);

      expect(miles, closeTo(km * kmToMiles, 0.01));
    });

    test('distance is symmetric (A to B equals B to A)', () {
      final ab = distanceKm(40.7128, -74.0060, 34.0522, -118.2437);
      final ba = distanceKm(34.0522, -118.2437, 40.7128, -74.0060);

      expect(ab, equals(ba));
    });

    test('handles extreme latitudes (near poles)', () {
      // Near North Pole: 89° N
      // Near South Pole: 89° S
      final km = distanceKm(89.0, 0.0, -89.0, 0.0);

      // Should be close to half Earth's circumference through poles
      // Earth's polar circumference: ~40,008 km, half = ~20,004 km
      expect(km, closeTo(19800, 300));
    });

    test('handles golf-course-scale distances accurately', () {
      // Two points ~5 miles apart (typical "near me" filter range)
      // Phoenix area coordinates
      final lat1 = 33.4484;
      final lng1 = -112.0740;
      // Point approximately 5 miles north
      final lat2 = 33.5211; // ~0.0727 degrees ≈ 5 miles at this latitude
      final lng2 = -112.0740;

      final miles = distanceMiles(lat1, lng1, lat2, lng2);
      expect(miles, closeTo(5.0, 0.5));
    });
  });
}
