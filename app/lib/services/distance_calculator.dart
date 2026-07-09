import 'package:geolocator/geolocator.dart';

class DistanceCalculator {
  Position? _previousPosition;
  double _totalDistance = 0;

  double get totalDistance => _totalDistance;

  // Adds a new position and calculates the distance from the previous position.
  void addPosition(Position newPosition) {
    final previousPosition = _previousPosition;

    if (previousPosition != null) {
      final distance = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      _totalDistance += distance;
    }

    _previousPosition = newPosition;
  }

  void reset() {
    _previousPosition = null;
    _totalDistance = 0;
  }
}
