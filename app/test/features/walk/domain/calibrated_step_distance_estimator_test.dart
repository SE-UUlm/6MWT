import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/calibrated_step_distance_estimator.dart';

SensorSample gps(
  double t,
  double x, {
  double accuracy = 3,
  String source = 'gps',
}) => SensorSample(
  timestamp: DateTime.fromMicrosecondsSinceEpoch(
    (t * 1e6).round(),
    isUtc: true,
  ),
  type: SampleType.position,
  sourceId: source,
  values: {
    PositionKeys.latitude: 0,
    PositionKeys.longitude: x / 6371000 * 180 / math.pi,
    PositionKeys.accuracy: accuracy,
  },
);
SensorSample steps(double t, double n, {String source = 'steps'}) =>
    SensorSample(
      timestamp: DateTime.fromMicrosecondsSinceEpoch(
        (t * 1e6).round(),
        isUtc: true,
      ),
      type: SampleType.steps,
      sourceId: source,
      values: {StepKeys.cumulativeSteps: n},
    );

void main() {
  test('learns known length and reset reproduces streaming result', () {
    final e = CalibratedStepDistanceEstimator();
    void run() {
      for (var t = 0; t <= 60; t += 5) {
        e.addSample(gps(t.toDouble(), t * 1.2));
        e.addSample(steps(t.toDouble(), 100 + t * 2));
      }
    }

    run();
    expect(e.totalDistance, closeTo(72, .2));
    expect(e.additionalInfo['Calibration windows'], '11');
    final distance = e.totalDistance, info = e.additionalInfo;
    e.reset();
    expect(e.totalDistance, 0);
    run();
    expect(e.totalDistance, distance);
    expect(e.additionalInfo, info);
  });
  test('shared timestamps handle delayed sensor start and batched steps', () {
    final e = CalibratedStepDistanceEstimator();
    for (var t = 0; t <= 40; t += 5) {
      e.addSample(gps(t.toDouble(), t * 1.2));
    }
    for (var t = 10; t <= 40; t += 10) {
      e.addSample(steps(t.toDouble(), 100 + t * 2));
    }
    expect(e.totalDistance, closeTo(36, .1));
  });
  test('bad accuracy, missing GPS and counter resets cannot calibrate', () {
    final e = CalibratedStepDistanceEstimator();
    e.addSample(steps(0, 100));
    e.addSample(gps(0, 0));
    e.addSample(gps(5, 5, accuracy: 50));
    e.addSample(gps(10, 10));
    e.addSample(steps(10, 120));
    e.addSample(steps(15, 0));
    e.addSample(steps(20, 10));
    expect(e.totalDistance, 22.5);
    expect(e.additionalInfo['Calibration windows'], '0');
    expect(e.additionalInfo['Step counter resets'], '1');
  });
  test('outlier does not add return jump or calibrate a gap', () {
    final e = CalibratedStepDistanceEstimator();
    for (var t = 0; t <= 20; t += 5) {
      e.addSample(gps(t.toDouble(), t == 10 ? 10000 : t.toDouble()));
      e.addSample(steps(t.toDouble(), t * 2));
    }
    expect(e.totalDistance, 30);
    expect(e.additionalInfo['Calibration windows'], '0');
  });
  test('duplicate, backward and foreign counters do not add steps', () {
    final e = CalibratedStepDistanceEstimator();
    for (final s in [
      steps(0, 100),
      steps(10, 120),
      steps(10, 999),
      steps(5, 999),
      steps(20, 999, source: 'watch'),
      steps(20, 140),
    ]) {
      e.addSample(s);
    }
    expect(e.totalDistance, 30);
  });
  test('later calibration can reduce an earlier estimate', () {
    final e = CalibratedStepDistanceEstimator();
    e.addSample(steps(0, 0));
    e.addSample(steps(10, 20));
    expect(e.totalDistance, 15);
    e.addSample(gps(0, 0));
    e.addSample(gps(5, 5));
    e.addSample(gps(10, 10));
    expect(e.totalDistance, closeTo(10, .1));
  });
  test('no steps means no step distance and configuration is validated', () {
    final e = CalibratedStepDistanceEstimator()
      ..addSample(gps(0, 0))
      ..addSample(gps(5, 5));
    expect(e.totalDistance, 0);
    expect(
      () => StepCalibrationConfig(maxAccuracy: double.nan),
      throwsArgumentError,
    );
  });
}
