import 'dart:math';

import 'sensor_sample.dart';

// Turns a stream of sensor samples into a walked distance. Implementations
// can use different strategies (GPS, step-based, sensor fusion)
// interchangeably; samples they cannot use are simply ignored.
abstract class DistanceEstimator {
  double get totalDistance;

  void addSample(SensorSample sample);

  void reset();
}

class GpsDistanceEstimator implements DistanceEstimator {
  double? _previousLatitude;
  double? _previousLongitude;
  double _totalDistance = 0;

  @override
  double get totalDistance => _totalDistance;

  @override
  void addSample(SensorSample sample) {
    if (sample.type != SampleTypes.position) {
      return;
    }

    final latitude = sample.values[PositionKeys.latitude];
    final longitude = sample.values[PositionKeys.longitude];

    if (latitude == null || longitude == null) {
      return;
    }

    final previousLatitude = _previousLatitude;
    final previousLongitude = _previousLongitude;

    if (previousLatitude != null && previousLongitude != null) {
      _totalDistance += _haversineMeters(
        previousLatitude,
        previousLongitude,
        latitude,
        longitude,
      );
    }

    _previousLatitude = latitude;
    _previousLongitude = longitude;
  }

  @override
  void reset() {
    _previousLatitude = null;
    _previousLongitude = null;
    _totalDistance = 0;
  }

  // Same earth radius as geolocator's distanceBetween, so results match the
  // previous implementation.
  static const _earthRadiusMeters = 6378137.0;

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLng / 2), 2);

    return 2 * _earthRadiusMeters * asin(sqrt(a));
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
