import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/fused_gps_step_distance_estimator.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/gps_step_distance_estimator.dart';

final _epoch = DateTime.utc(2026);
final _metresPerDegree = Geolocator.distanceBetween(0, 0, 0, 1);

SensorSample _gps(int second, double metres, {double accuracy = 3}) =>
    SensorSample(
      timestamp: _epoch.add(Duration(seconds: second)),
      sourceId: 'gps',
      type: SampleType.position,
      values: {
        PositionKeys.latitude: 0,
        PositionKeys.longitude: metres / _metresPerDegree,
        PositionKeys.accuracy: accuracy,
      },
    );

SensorSample _steps(int second, double count) => SensorSample(
  timestamp: _epoch.add(Duration(seconds: second)),
  sourceId: 'pedometer',
  type: SampleType.steps,
  values: {StepKeys.cumulativeSteps: count},
);

FusedGpsStepDistanceEstimator _fused({double bridgeMaxSeconds = 60}) =>
    FusedGpsStepDistanceEstimator(
      stepSourceId: 'pedometer',
      bridgeMaxSeconds: bridgeMaxSeconds,
    );

/// Feeds one sample per second: GPS position (or none) and cumulative steps.
void _feed(
  List<DistanceEstimator> estimators,
  int from,
  int to, {
  required double? Function(int second) metres,
  required double? Function(int second) steps,
}) {
  for (var i = from; i <= to; i++) {
    final m = metres(i), n = steps(i);
    for (final e in estimators) {
      if (m != null) e.addSample(_gps(i, m));
      if (n != null) e.addSample(_steps(i, n));
    }
  }
}

void main() {
  test('a clean walk matches the main estimator', () {
    final fused = _fused();
    final main = GpsStepDistanceEstimator(stepSourceId: 'pedometer');
    _feed(
      [fused, main],
      0,
      60,
      metres: (i) => i.toDouble(),
      steps: (i) => 1000.0 + i,
    );
    expect(fused.hasLearnedStepLength, isTrue);
    expect(fused.stepLength, closeTo(1, 1e-6));
    expect(fused.totalDistance, closeTo(main.totalDistance, 1e-6));
    expect(fused.totalDistance, closeTo(60, 1e-6));
    expect(fused.additionalInfo['Removed by step cap'], '0.00 m');
  });

  test('caps GPS jitter while the step counter reports standing', () {
    final fused = _fused();
    final main = GpsStepDistanceEstimator(stepSourceId: 'pedometer');
    _feed(
      [fused, main],
      0,
      30,
      metres: (i) => i.toDouble(),
      steps: (i) => 1000.0 + i,
    );
    // Standing for 30 s: positions alternate by 2.5 m, no new steps.
    _feed(
      [fused, main],
      31,
      70,
      metres: (i) => i.isEven ? 30 : 32.5,
      steps: (_) => 1030,
    );
    final mainExtra = main.totalDistance - 30;
    final fusedExtra = fused.totalDistance - 30;
    expect(mainExtra, greaterThan(90));
    expect(fusedExtra, lessThan(mainExtra / 4));
    expect(fused.confidence.score, greaterThan(0));
  });

  test('a frozen step counter cannot erase consistent GPS movement', () {
    final fused = _fused();
    final main = GpsStepDistanceEstimator(stepSourceId: 'pedometer');
    _feed(
      [fused, main],
      0,
      30,
      metres: (i) => i.toDouble(),
      steps: (i) => 1000.0 + i,
    );
    // Walking on at 1 m/s while the counter stays frozen.
    _feed(
      [fused, main],
      31,
      70,
      metres: (i) => i.toDouble(),
      steps: (_) => 1030,
    );
    expect(main.totalDistance, closeTo(70, 1e-6));
    // Only the 0.5 m allowance per window may be lost at the boundaries.
    expect(fused.totalDistance, closeTo(70, 1));
  });

  test('a GPS gap counts at least the uncertain straight line', () {
    for (final (bridge, expected) in [(60.0, 67.0), (0.0, 55.0)]) {
      final fused = _fused(bridgeMaxSeconds: bridge);
      _feed(
        [fused],
        0,
        30,
        metres: (i) => i.toDouble(),
        steps: (i) => 1000.0 + i,
      );
      // 30 s without usable GPS; the counter registers only half the steps.
      _feed(
        [fused],
        31,
        59,
        metres: (_) => null,
        steps: (i) => 1030.0 + (i - 30) ~/ 2,
      );
      // An inaccurate fix inside the gap must not break the bridge.
      fused.addSample(_gps(45, 45, accuracy: 50));
      _feed(
        [fused],
        60,
        70,
        metres: (i) => i.toDouble(),
        steps: (i) => 1045.0 + (i - 60),
      );
      // GPS 30 m + gap max(30 − 0.5 × (3 + 3), 15 steps × 1 m) + GPS 10 m.
      expect(fused.totalDistance, closeTo(expected, 0.01), reason: '$bridge');
      expect(fused.additionalInfo['Bridges'], bridge > 0 ? '1' : '0');
      expect(fused.additionalInfo['Rejected GPS accuracy'], '1');
    }
  });

  test('without a step counter GPS stays unbounded', () {
    final fused = _fused();
    _feed(
      [fused],
      0,
      40,
      metres: (i) => i.isEven ? i.toDouble() : i + 2.0,
      steps: (_) => null,
    );
    final main = GpsStepDistanceEstimator(stepSourceId: 'pedometer');
    _feed(
      [main],
      0,
      40,
      metres: (i) => i.isEven ? i.toDouble() : i + 2.0,
      steps: (_) => null,
    );
    expect(fused.totalDistance, closeTo(main.totalDistance, 1e-6));
  });

  test('reset clears all state and replay is deterministic', () {
    final fused = _fused();
    void run() => _feed(
      [fused],
      0,
      70,
      metres: (i) => i < 30 ? i.toDouble() : (i.isEven ? 30 : 32.5),
      steps: (i) => 1000.0 + (i < 30 ? i : 30),
    );
    run();
    final first = fused.totalDistance;
    final info = fused.additionalInfo;
    fused.reset();
    expect(fused.totalDistance, 0);
    expect(fused.hasLearnedStepLength, isFalse);
    expect(fused.additionalInfo['Bridges'], '0');
    expect(fused.confidence.score, 0);
    run();
    expect(fused.totalDistance, first);
    expect(fused.additionalInfo, info);
  });

  test('rejects invalid configuration', () {
    expect(
      () => FusedGpsStepDistanceEstimator(
        stepSourceId: 'pedometer',
        capStrideFactor: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => FusedGpsStepDistanceEstimator(
        stepSourceId: 'pedometer',
        bridgeMaxSeconds: double.nan,
      ),
      throwsArgumentError,
    );
  });
}
