import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/distance_estimator.dart';

void main() {
  test('first position does not increase total distance', () {
    final estimator = GpsDistanceEstimator();

    final firstPosition = createPositionSample(latitude: 0, longitude: 0);

    estimator.addSample(firstPosition);

    expect(estimator.totalDistance, 0);
  });

  test('calculates distance between two positions', () {
    final estimator = GpsDistanceEstimator();

    final firstPosition = createPositionSample(latitude: 0, longitude: 0);

    final secondPosition = createPositionSample(latitude: 0, longitude: 0.001);

    estimator.addSample(firstPosition);
    estimator.addSample(secondPosition);

    expect(estimator.totalDistance, closeTo(111, 2));
  });

  test('reset sets total distance back to zero', () {
    final estimator = GpsDistanceEstimator();

    estimator.addSample(createPositionSample(latitude: 0, longitude: 0));

    estimator.addSample(createPositionSample(latitude: 0, longitude: 0.001));

    expect(estimator.totalDistance, greaterThan(0));

    estimator.reset();

    expect(estimator.totalDistance, 0);
  });
}

SensorSample createPositionSample({
  required double latitude,
  required double longitude,
}) {
  return SensorSample(
    timestamp: DateTime.now(),
    sourceId: 'gps',
    type: SampleType.position,
    values: {
      PositionKeys.latitude: latitude,
      PositionKeys.longitude: longitude,
      PositionKeys.accuracy: 0,
    },
  );
}
