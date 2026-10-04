import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/kalman_gps_step_distance_estimator.dart';

import 'calibrated_step_distance_estimator_test.dart' as f;

void main() {
  test('learns length from GPS and carries it through an outage', () {
    final e = KalmanGpsStepDistanceEstimator();
    for (var t = 0; t <= 120; t += 2) {
      e.addSample(f.steps(t.toDouble(), t * 2));
      if (t <= 60) e.addSample(f.gps(t.toDouble(), t * 1.2, accuracy: 1));
    }
    expect(e.totalDistance, closeTo(144, 3));
    expect(e.additionalInfo['Default length active'], 'false');
    expect(e.additionalInfo['GPS fallback distance'], '0.00 m');
  });

  test('GPS jitter during a measured pause adds no distance', () {
    final e = KalmanGpsStepDistanceEstimator();
    for (var t = 0; t <= 60; t++) {
      e.addSample(f.gps(t.toDouble(), t.isEven ? 0 : 2));
      e.addSample(f.steps(t.toDouble(), 100));
    }
    expect(e.totalDistance, 0);
    expect(e.additionalInfo['Calibration windows'], '0');
  });

  test('a reversing window does not calibrate to endpoint displacement', () {
    final e = KalmanGpsStepDistanceEstimator();
    for (var t = 0; t <= 10; t++) {
      e.addSample(f.gps(t.toDouble(), t <= 5 ? t * 2.0 : (10 - t) * 2.0));
      e.addSample(f.steps(t.toDouble(), t * 2));
    }
    expect(e.totalDistance, 15);
    expect(e.additionalInfo['Calibration windows'], '0');
  });

  test('GPS-only and partial step coverage do not double count', () {
    final e = KalmanGpsStepDistanceEstimator();
    e.addSample(f.gps(0, 0));
    e.addSample(f.gps(10, 10));
    expect(e.totalDistance, closeTo(10, .02));
    e.addSample(f.steps(2, 100));
    e.addSample(f.steps(8, 108));
    expect(e.totalDistance, closeTo(10, .02)); // 4 GPS + 6 steps
    e.addSample(f.steps(10, 108)); // measured pause replaces 2 GPS meters
    expect(e.totalDistance, closeTo(8, .02));
  });

  test('reset, source selection, invalid samples and counter resets', () {
    final e = KalmanGpsStepDistanceEstimator();
    void feed() {
      e.addSample(f.steps(0, 100));
      e.addSample(f.steps(5, 110));
      e.addSample(f.steps(4, 999));
      e.addSample(f.steps(6, double.nan));
      e.addSample(f.steps(7, 1000, source: 'watch'));
      e.addSample(f.steps(10, 0));
      e.addSample(f.steps(15, 10));
      e.addSample(f.gps(0, double.nan));
      e.addSample(f.gps(5, 0, accuracy: 100));
    }

    feed();
    expect(e.totalDistance, 15);
    final info = e.additionalInfo;
    e.reset();
    expect(e.totalDistance, 0);
    feed();
    expect(e.totalDistance, 15);
    expect(e.additionalInfo, info);
  });

  test('batched sensor delivery and getter frequency do not change result', () {
    final live = KalmanGpsStepDistanceEstimator();
    final batched = KalmanGpsStepDistanceEstimator();
    for (var t = 0; t <= 60; t += 2) {
      final gps = f.gps(t.toDouble(), t * 1.2, accuracy: 1);
      live.addSample(gps);
      live.addSample(f.steps(t.toDouble(), t * 2));
      expect(live.totalDistance.isFinite, isTrue);
      batched.addSample(gps);
    }
    for (var t = 0; t <= 60; t += 2) {
      batched.addSample(f.steps(t.toDouble(), t * 2));
    }
    expect(batched.totalDistance, live.totalDistance);
    expect(batched.additionalInfo, live.additionalInfo);
  });

  test('poor GPS and implausible jumps cannot calibrate steps', () {
    final e = KalmanGpsStepDistanceEstimator();
    for (var t = 0; t <= 60; t += 5) {
      e.addSample(f.steps(t.toDouble(), t * 2));
      e.addSample(f.gps(t.toDouble(), t.isEven ? 0 : 1000));
    }
    expect(e.totalDistance, 90);
    expect(e.additionalInfo['Calibration windows'], '0');
  });
}
