import 'dart:math' as math;

/// Calculates the great-circle distance between two geographic coordinates
/// using the Haversine formula. Returns distance in meters.
double haversineDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusMeters = 6371000.0;

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180.0;
