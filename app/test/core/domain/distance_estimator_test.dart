import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/distance_estimator.dart';

void main() {
  test('first position does not increase total distance', () {
    final estimator = GpsDistanceEstimator();

    final firstPosition = createPosition(latitude: 0, longitude: 0);

    estimator.addPosition(firstPosition);

    expect(estimator.totalDistance, 0);
  });

  test('calculates distance between two positions', () {
    final estimator = GpsDistanceEstimator();

    final firstPosition = createPosition(latitude: 0, longitude: 0);

    final secondPosition = createPosition(latitude: 0, longitude: 0.001);

    estimator.addPosition(firstPosition);
    estimator.addPosition(secondPosition);

    expect(estimator.totalDistance, closeTo(111, 2));
  });

  test('reset sets total distance back to zero', () {
    final estimator = GpsDistanceEstimator();

    estimator.addPosition(createPosition(latitude: 0, longitude: 0));

    estimator.addPosition(createPosition(latitude: 0, longitude: 0.001));

    expect(estimator.totalDistance, greaterThan(0));

    estimator.reset();

    expect(estimator.totalDistance, 0);
  });
}

Position createPosition({required double latitude, required double longitude}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
