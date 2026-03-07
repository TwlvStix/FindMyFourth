import 'dart:math';

/// Haversine distance in kilometers between two lat/lng points.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0; // Earth radius in kilometers
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Haversine distance in miles between two lat/lng points.
double distanceMiles(double lat1, double lng1, double lat2, double lng2) {
  const kmToMiles = 0.621371;
  return distanceKm(lat1, lng1, lat2, lng2) * kmToMiles;
}

double _toRad(double deg) => deg * pi / 180;
