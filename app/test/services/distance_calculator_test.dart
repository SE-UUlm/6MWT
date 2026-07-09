import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/services/distance_calculator.dart';

void main() {
  test('first position does not increase total distance', () {
    final calculator = DistanceCalculator();

    final firstPosition = createPosition(latitude: 0, longitude: 0);

    calculator.addPosition(firstPosition);

    expect(calculator.totalDistance, 0);
  });

  test('calculates distance between two positions', () {
    final calculator = DistanceCalculator();

    final firstPosition = createPosition(latitude: 0, longitude: 0);

    final secondPosition = createPosition(latitude: 0, longitude: 0.001);

    calculator.addPosition(firstPosition);
    calculator.addPosition(secondPosition);

    expect(calculator.totalDistance, closeTo(111, 2));
  });

  test('reset sets total distance back to zero', () {
    final calculator = DistanceCalculator();

    calculator.addPosition(createPosition(latitude: 0, longitude: 0));

    calculator.addPosition(createPosition(latitude: 0, longitude: 0.001));

    expect(calculator.totalDistance, greaterThan(0));

    calculator.reset();

    expect(calculator.totalDistance, 0);
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
