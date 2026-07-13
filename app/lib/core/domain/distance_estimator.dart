import 'package:geolocator/geolocator.dart';

// Turns a stream of positions into a walked distance. Implementations can use
// different strategies (GPS, step-based, sensor fusion) interchangeably.
abstract class DistanceEstimator {
  double get totalDistance;

  void addPosition(Position position);

  void reset();
}

class GpsDistanceEstimator implements DistanceEstimator {
  Position? _previousPosition;
  double _totalDistance = 0;

  @override
  double get totalDistance => _totalDistance;

  // Adds a new position and calculates the distance from the previous position.
  @override
  void addPosition(Position position) {
    final previousPosition = _previousPosition;

    if (previousPosition != null) {
      final distance = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );

      _totalDistance += distance;
    }

    _previousPosition = position;
  }

  @override
  void reset() {
    _previousPosition = null;
    _totalDistance = 0;
  }
}
