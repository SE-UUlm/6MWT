import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

// Turns a stream of positions into a walked distance. Implementations can use
// different strategies (GPS, step-based, sensor fusion) interchangeably.
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

  // Adds a new position and calculates the distance from the previous position.
  @override
  void addSample(SensorSample sample) {
    if (sample.type != SampleType.position) {
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
      final distance = Geolocator.distanceBetween(
        previousLatitude,
        previousLongitude,
        latitude,
        longitude,
      );

      _totalDistance += distance;
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
}
